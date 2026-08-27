import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';

/// V18.1: World Causality.
///
/// Łączy stany, które powstały wcześniej, z kolejnymi decyzjami. Nie tworzy
/// osobnych "losowych newsów". Zapamiętuje, jak długo trwa problem/sukces,
/// dzięki czemu świat może przejść przez fazy: początek -> eskalacja ->
/// konsekwencja -> stabilizacja.
class WorldCausalityEngine {
  final Random _random;

  final Map<String, int> _clubCrisisDays = {};
  final Map<String, int> _clubRecoveryDays = {};
  final Map<String, int> _financialCrisisDays = {};
  final Map<String, int> _playerRequestDays = {};

  WorldCausalityEngine({Random? random}) : _random = random ?? Random();

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
      final crisis = club.lossesStreak >= 3 ||
          club.boardPressure >= 75 ||
          club.stability <= 35;
      final recovering = club.winsStreak >= 3 &&
          club.boardPressure <= 55 &&
          club.stability >= 45;
      final financial = club.financialHealth <= 30;

      if (crisis) {
        final started = _clubCrisisDays.putIfAbsent(club.id, () => absoluteDay);
        _clubRecoveryDays.remove(club.id);
        final duration = absoluteDay - started + 1;

        // Pierwszy etap: zarząd zaczyna wymagać konkretnego planu.
        if (duration == 3) {
          club.boardPressure = min(100, club.boardPressure + 2);
          events.add(_event(
            year, month, day, 'causal_board', 'Zarząd żąda reakcji',
            '${club.name} pozostaje w kryzysie od kilku dni. Zarząd oczekuje konkretnego planu poprawy.',
            club.id, 3,
          ));
        }

        // Drugi etap: klub zmienia sposób działania, ale nie wymieniamy
        // automatycznie trenera — ManagerWorldEngine nadal podejmuje tę decyzję.
        if (duration == 10) {
          club.transferActivity = max(10, club.transferActivity - 4);
          club.youthFocus = min(95, club.youthFocus + 3);
          events.add(_event(
            year, month, day, 'causal_strategy', 'Klub szuka nowej drogi',
            '${club.name} jest już w dłuższym kryzysie. Klub ogranicza ryzyko transferowe i zwiększa nacisk na rozwój kadry.',
            club.id, 3,
          ));
        }

        // Trzeci etap: kryzys zaczyna mieć wpływ na wartość marki i finanse.
        if (duration >= 21 && duration % 7 == 0) {
          club.fanSupport = max(10, club.fanSupport - 1);
          club.financialHealth = max(5, club.financialHealth - 1);
          if (_random.nextDouble() < .35) {
            events.add(_event(
              year, month, day, 'causal_crisis', 'Kryzys zaczyna kosztować klub',
              '${club.name} nie przełamał kryzysu. Spada wsparcie kibiców, a klub odczuwa to również finansowo.',
              club.id, 3,
            ));
          }
        }
      } else if (recovering) {
        final previous = _clubCrisisDays.remove(club.id);
        final recoveryStart = _clubRecoveryDays.putIfAbsent(club.id, () => absoluteDay);
        final recoveryDays = absoluteDay - recoveryStart + 1;

        if (previous != null && recoveryDays == 1) {
          club.boardConfidence = min(100, club.boardConfidence + 3);
          events.add(_event(
            year, month, day, 'causal_recovery', 'Klub wychodzi z kryzysu',
            '${club.name} odpowiedział wynikami na wcześniejszą presję. Atmosfera w klubie zaczyna się poprawiać.',
            club.id, 3,
          ));
        }

        if (recoveryDays >= 7 && recoveryDays % 7 == 0) {
          club.stability = min(100, club.stability + 1);
          club.fanSupport = min(100, club.fanSupport + 1);
        }
      } else {
        _clubCrisisDays.remove(club.id);
        _clubRecoveryDays.remove(club.id);
      }

      if (financial) {
        final started = _financialCrisisDays.putIfAbsent(club.id, () => absoluteDay);
        final duration = absoluteDay - started + 1;
        if (duration == 14) {
          club.transferActivity = max(10, club.transferActivity - 5);
          club.minimumSigningOverall = max(45, club.minimumSigningOverall - 3);
          events.add(_event(
            year, month, day, 'causal_finance', 'Finanse zmieniają politykę transferową',
            '${club.name} utrzymuje problemy finansowe. Klub obniża wymagania transferowe i szuka tańszych rozwiązań.',
            club.id, 3,
          ));
        }
      } else {
        _financialCrisisDays.remove(club.id);
      }
    }

    for (final player in players) {
      if (!player.transferRequest || player.clubId == null) {
        _playerRequestDays.remove(player.id);
        continue;
      }

      final started = _playerRequestDays.putIfAbsent(player.id, () => absoluteDay);
      final duration = absoluteDay - started + 1;
      final club = clubs.where((c) => c.id == player.clubId).firstOrNull;
      if (club == null) continue;

      if (duration == 7) {
        player.happiness = max(5, player.happiness - 3);
        events.add(_event(
          year, month, day, 'causal_agent', 'Agent zaczyna działać',
          'Agent ${player.name} rozpoczyna aktywne poszukiwanie rozwiązania po żądaniu transferu z ${club.name}.',
          club.id, 3, player.id,
        ));
      }

      if (duration == 21) {
        player.managerRelationship = max(5, player.managerRelationship - 3);
        club.transferActivity = min(100, club.transferActivity + 2);
        events.add(_event(
          year, month, day, 'causal_transfer', 'Rosną napięcia transferowe',
          '${player.name} nadal chce odejść z ${club.name}. Klub jest bardziej otwarty na wysłuchanie ofert.',
          club.id, 4, player.id,
        ));
      }

      if (duration >= 35 && duration % 7 == 0) {
        player.morale = max(10, player.morale - 1);
        if (_random.nextDouble() < .25) {
          events.add(_event(
            year, month, day, 'causal_transfer', 'Sytuacja zawodnika się przeciąga',
            '${player.name} od wielu tygodni pozostaje w sporze dotyczącym swojej przyszłości w ${club.name}.',
            club.id, 3, player.id,
          ));
        }
      }
    }

    return events;
  }

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
        'clubCrisisDays': _clubCrisisDays,
        'clubRecoveryDays': _clubRecoveryDays,
        'financialCrisisDays': _financialCrisisDays,
        'playerRequestDays': _playerRequestDays,
      };

  void restoreFromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    void restore(Map<String, int> target, dynamic raw) {
      if (raw is Map) {
        target.clear();
        for (final e in raw.entries) {
          final value = e.value is num ? (e.value as num).toInt() : int.tryParse('${e.value}');
          if (value != null) target[e.key.toString()] = value;
        }
      }
    }
    restore(_clubCrisisDays, json['clubCrisisDays']);
    restore(_clubRecoveryDays, json['clubRecoveryDays']);
    restore(_financialCrisisDays, json['financialCrisisDays']);
    restore(_playerRequestDays, json['playerRequestDays']);
  }
}
