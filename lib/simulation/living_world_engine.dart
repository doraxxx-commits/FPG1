import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';

/// V18: warstwa reakcji świata.
///
/// Większość FPG posiada już osobne silniki transferów, szatni, zarządu,
/// trenerów i zainteresowania transferowego. Ten silnik nie zastępuje ich.
/// Jego zadaniem jest połączyć ich skutki w dłuższe, czytelne łańcuchy
/// przyczynowo-skutkowe: wyniki -> presja -> decyzja -> konsekwencja.
class LivingWorldEngine {
  final Random _random;
  final Map<String, int> _cooldowns = {};

  LivingWorldEngine({Random? random}) : _random = random ?? Random();

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
      if (squad.isEmpty) continue;

      // 1. Kryzys sportowy zmusza trenera do reakcji zamiast samego
      // generowania kolejnego newsa.
      if (club.lossesStreak >= 3 && club.boardPressure >= 60 &&
          _ready('${club.id}:tactics', absoluteDay, 10)) {
        final oldStyle = club.managerStyle;
        final newStyle = _reactionStyle(oldStyle, club);
        if (newStyle != oldStyle) {
          club.managerStyle = newStyle;
          club.tacticalIdentity = (club.tacticalIdentity +
                  (newStyle == 'counter' || newStyle == 'physical' ? 2 : -1))
              .clamp(20, 95).round();
          club.boardConfidence = max(5, club.boardConfidence - 1);
          events.add(WorldEvent(
            year: year,
            month: month,
            day: day,
            type: 'manager_reaction',
            title: 'Trener reaguje na kryzys',
            description: '${club.name} zmienia podejście taktyczne z $oldStyle na $newStyle po serii słabych wyników.',
            clubId: club.id,
            importance: 3,
          ));
        }
      }

      // 2. Zawodnik nie może wiecznie siedzieć bez minut. Po odpowiednio
      // długim okresie niezadowolenie staje się realną decyzją kariery.
      final unhappy = squad.where((p) =>
          p.age <= 28 &&
          p.overall >= club.overall - 4 &&
          (p.consecutiveBenchDays >= 18 || p.consecutiveUnusedDays >= 21) &&
          p.morale <= 55 &&
          !p.transferRequest).toList();

      if (unhappy.isNotEmpty && _ready('${club.id}:player', absoluteDay, 7)) {
        unhappy.sort((a, b) {
          final aScore = a.overall + a.personality.ambition + a.consecutiveBenchDays;
          final bScore = b.overall + b.personality.ambition + b.consecutiveBenchDays;
          return bScore.compareTo(aScore);
        });
        final player = unhappy.first;
        final probability = .35 + player.personality.ambition / 250;
        if (_random.nextDouble() < probability) {
          player.transferRequest = true;
          player.happiness = max(10, player.happiness - 8);
          player.managerRelationship = max(10, player.managerRelationship - 4);
          events.add(WorldEvent(
            year: year,
            month: month,
            day: day,
            type: 'transfer_request',
            title: 'Zawodnik żąda transferu',
            description: '${player.name} chce odejść z ${club.name}, ponieważ od dłuższego czasu nie dostaje wystarczająco dużo minut.',
            clubId: club.id,
            playerId: player.id,
            importance: 4,
          ));
        }
      }

      // 3. Problemy finansowe wpływają na strategię, a nie tylko na liczbę
      // w budżecie. Klub zaczyna szukać oszczędności i młodzieży.
      if (club.financialHealth <= 25 && _ready('${club.id}:finance', absoluteDay, 14)) {
        final oldActivity = club.transferActivity;
        club.transferActivity = max(10, club.transferActivity - 3);
        club.youthFocus = min(100, club.youthFocus + 2);
        club.boardPressure = min(100, club.boardPressure + 1);
        if (oldActivity != club.transferActivity) {
          events.add(WorldEvent(
            year: year,
            month: month,
            day: day,
            type: 'financial_strategy',
            title: 'Klub zmienia strategię finansową',
            description: '${club.name} ogranicza aktywność transferową i mocniej stawia na młodzież z powodu słabej kondycji finansowej.',
            clubId: club.id,
            importance: 3,
          ));
        }
      }

      // 4. Stabilny klub może świadomie budować młodzież, ale tylko wtedy,
      // gdy ma warunki sportowe i finansowe.
      if (club.financialHealth >= 75 &&
          club.stability >= 75 &&
          club.youthFocus >= 65 &&
          _ready('${club.id}:academy', absoluteDay, 30) &&
          _random.nextDouble() < .18) {
        club.academyQuality = min(100, club.academyQuality + 1);
        events.add(WorldEvent(
          year: year,
          month: month,
          day: day,
          type: 'academy_investment',
          title: 'Klub inwestuje w akademię',
          description: '${club.name} przeznacza dodatkowe środki na rozwój akademii.',
          clubId: club.id,
          importance: 2,
        ));
      }
    }

    return events;
  }

  bool _ready(String key, int day, int cooldown) {
    final previous = _cooldowns[key];
    if (previous != null && day - previous < cooldown) return false;
    _cooldowns[key] = day;
    return true;
  }

  String _reactionStyle(String current, Club club) {
    if (club.overall >= 78) {
      return current == 'possession' ? 'balanced' : 'possession';
    }
    if (club.financialHealth < 40) return 'counter';
    if (club.youthFocus >= 70) return 'youth';
    return current == 'counter' ? 'balanced' : 'counter';
  }
}
