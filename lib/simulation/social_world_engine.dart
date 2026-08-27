import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';

/// V18.2: Social World.
///
/// The world now contains persistent human relationships rather than only
/// isolated player attributes. Teammate chemistry, manager trust, fan mood
/// and board confidence drift from actual sporting events and can create
/// secondary consequences on later days.
class SocialWorldEngine {
  final Random _random;

  /// Pair key -> chemistry/trust between two teammates (0..100).
  final Map<String, int> _teammateChemistry = {};

  /// Club -> days since the fan base last felt a meaningful positive result.
  final Map<String, int> _fanFrustrationDays = {};

  /// Player -> days of persistent manager tension.
  final Map<String, int> _managerTensionDays = {};

  SocialWorldEngine({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processDay({
    required List<Club> clubs,
    required List<Player> players,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    final events = <WorldEvent>[];

    for (final club in clubs) {
      final squad = players.where((p) => p.clubId == club.id && !p.injured).toList();
      if (squad.length >= 2) {
        // We deliberately sample a small number of pairs per day. A large
        // squad therefore evolves socially without an O(n²) simulation.
        final shuffled = [...squad]..shuffle(_random);
        final sample = shuffled.take(min(8, shuffled.length)).toList();
        for (var i = 0; i + 1 < sample.length; i += 2) {
          final a = sample[i];
          final b = sample[i + 1];
          final key = _pairKey(a.id, b.id);
          var chemistry = _teammateChemistry[key] ?? 60;

          final sharedMood = ((a.morale + b.morale) / 2).round();
          final sameStatus = a.squadStatus == b.squadStatus;
          final positive = sharedMood >= 75 || (sameStatus && sharedMood >= 60);
          final negative = sharedMood <= 35 ||
              a.transferRequest ||
              b.transferRequest ||
              a.morale <= 30 ||
              b.morale <= 30;

          if (positive) chemistry += 1;
          if (negative) chemistry -= 2;
          chemistry = chemistry.clamp(0, 100).toInt();
          _teammateChemistry[key] = chemistry;

          // Strong chemistry gently raises morale; broken chemistry creates
          // tension but is intentionally slower than sporting consequences.
          if (chemistry >= 85) {
            a.morale = min(100, a.morale + 1);
            b.morale = min(100, b.morale + 1);
          } else if (chemistry <= 25) {
            a.morale = max(0, a.morale - 1);
            b.morale = max(0, b.morale - 1);
            if (_random.nextDouble() < .08) {
              events.add(_event(
                year, month, day, 'social_dressing_room', 'Napięcie w szatni',
                'Relacja między ${a.name} i ${b.name} wyraźnie się pogorszyła. Sytuacja zaczyna wpływać na atmosferę w ${club.name}.',
                club.id, 3,
              ));
            }
          }
        }
      }

      // Fans react to the trend, not to one random result. The existing
      // streak fields make this cheap and consistent with the world engine.
      final happy = club.winsStreak >= 2 ||
          (club.unbeatenStreak >= 4 && club.lastResult == 'draw');
      final angry = club.lossesStreak >= 3;

      if (happy) {
        _fanFrustrationDays.remove(club.id);
        if (club.fanSupport < 90 && absoluteDay % 3 == 0) {
          club.fanSupport = min(100, club.fanSupport + 1);
        }
      } else if (angry) {
        final start = _fanFrustrationDays.putIfAbsent(club.id, () => absoluteDay);
        final duration = absoluteDay - start + 1;
        if (duration >= 3 && absoluteDay % 3 == 0) {
          club.fanSupport = max(5, club.fanSupport - 1);
        }
        if (duration == 7) {
          events.add(_event(
            year, month, day, 'social_fans', 'Kibice tracą cierpliwość',
            'Seria słabych wyników ${club.name} powoduje rosnącą frustrację kibiców. Presja wokół klubu wzrasta.',
            club.id, 3,
          ));
        }
      } else if (club.fanSupport > 50 && absoluteDay % 7 == 0) {
        club.fanSupport = max(0, club.fanSupport - 0);
      }

      // The board reacts to both the manager relationship with the squad and
      // the fans. This creates a bridge: squad mood -> fans -> board.
      final squadAverage = squad.isEmpty
          ? 50
          : (squad.map((p) => p.managerRelationship).reduce((a, b) => a + b) / squad.length).round();
      if (squadAverage <= 35 || club.fanSupport <= 25) {
        club.boardConfidence = max(5, club.boardConfidence - 1);
      } else if (squadAverage >= 75 && club.fanSupport >= 65) {
        club.boardConfidence = min(100, club.boardConfidence + 1);
      }
    }

    for (final player in players) {
      if (player.clubId == null) continue;
      final strained = player.managerRelationship <= 30 ||
          player.transferRequest ||
          (player.consecutiveBenchDays >= 7 && player.squadStatus != 'starter');

      if (strained) {
        final started = _managerTensionDays.putIfAbsent(player.id, () => absoluteDay);
        final duration = absoluteDay - started + 1;
        if (duration >= 5 && absoluteDay % 5 == 0) {
          player.happiness = max(0, player.happiness - 1);
        }
        if (duration == 10) {
          final club = clubs.where((c) => c.id == player.clubId).firstOrNull;
          if (club != null) {
            events.add(_event(
              year, month, day, 'social_manager', 'Relacja z trenerem słabnie',
              '${player.name} ma coraz mniejsze zaufanie do trenera ${club.managerName}. To może wpłynąć na jego przyszłość w klubie.',
              club.id, 3, player.id,
            ));
          }
        }
      } else {
        _managerTensionDays.remove(player.id);
        if (player.managerRelationship >= 70 && player.squadStatus == 'starter') {
          player.happiness = min(100, player.happiness + 1);
        }
      }
    }

    return events;
  }

  String _pairKey(String a, String b) => a.compareTo(b) < 0 ? '$a::$b' : '$b::$a';

  WorldEvent _event(
    int year,
    int month,
    int day,
    String type,
    String title,
    String description,
    String clubId,
    int importance, [
    String? playerId,
  ]) => WorldEvent(
        year: year,
        month: month,
        day: day,
        type: type,
        title: title,
        description: description,
        clubId: clubId,
        playerId: playerId,
        importance: importance,
      );

  Map<String, dynamic> toJson() => {
        'teammateChemistry': _teammateChemistry,
        'fanFrustrationDays': _fanFrustrationDays,
        'managerTensionDays': _managerTensionDays,
      };

  void restoreFromJson(Map<String, dynamic>? json) {
    if (json == null) return;

    void restore(Map<String, int> target, dynamic raw) {
      if (raw is! Map) return;
      target.clear();
      for (final entry in raw.entries) {
        final value = entry.value is num
            ? (entry.value as num).toInt()
            : int.tryParse('${entry.value}');
        if (value != null) target[entry.key.toString()] = value;
      }
    }

    restore(_teammateChemistry, json['teammateChemistry']);
    restore(_fanFrustrationDays, json['fanFrustrationDays']);
    restore(_managerTensionDays, json['managerTensionDays']);
  }
}
