import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';

/// Generuje organiczne wydarzenia świata.
///
/// Cel: nie każda historia ma wynikać bezpośrednio z gracza. Kluby mogą
/// przeżywać kryzysy, serie zwycięstw, problemy finansowe, zmiany hierarchii
/// i nagłe eksplozje młodych talentów nawet wtedy, gdy gracz nic nie robi.
class WorldEventEngine {
  final Random _random;
  final List<WorldEvent> recentEvents = [];
  final Map<String, int> clubMomentum = {};
  final Map<String, int> playerHotStreak = {};

  WorldEventEngine({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processDay({
    required int year,
    required int month,
    required int day,
    required List<Club> clubs,
    required List<Player> players,
  }) {
    final generated = <WorldEvent>[];

    for (final club in clubs) {
      final squad = players.where((p) => p.clubId == club.id).toList();
      if (squad.isEmpty) continue;

      final avgForm = squad.fold<double>(0, (s, p) => s + p.form) / squad.length;
      final avgMorale = squad.fold<double>(0, (s, p) => s + p.morale) / squad.length;
      final momentum = clubMomentum[club.id] ?? 0;

      // Świat powoli reaguje na formę, zamiast wykonywać nagłe losowe skoki.
      if (avgForm >= 78 && avgMorale >= 72) {
        clubMomentum[club.id] = min(12, momentum + 1);
        if (_random.nextDouble() < 0.025) {
          generated.add(_event(year, month, day, 'hot_form',
              'Świetna seria ${club.name}',
              '${club.name} jest w znakomitej formie. Atmosfera w szatni wyraźnie rośnie.',
              clubId: club.id, importance: 2));
        }
      } else if (avgForm <= 58 || avgMorale <= 48) {
        clubMomentum[club.id] = max(-12, momentum - 1);
        if (_random.nextDouble() < 0.025) {
          generated.add(_event(year, month, day, 'crisis',
              'Kryzys w ${club.name}',
              '${club.name} notuje słabszy okres. Zarząd oczekuje reakcji sztabu.',
              clubId: club.id, importance: 3));
          club.boardPressure = min(100, club.boardPressure + 2);
        }
      } else if (momentum > 0) {
        clubMomentum[club.id] = momentum - 1;
      } else if (momentum < 0) {
        clubMomentum[club.id] = momentum + 1;
      }

      // Kryzys finansowy generuje konsekwencje społeczne i transferowe.
      if (club.lossesStreak >= 6 && _random.nextDouble() < 0.018) {
        club.boardConfidence = max(0, club.boardConfidence - 4);
        club.stability = max(10, club.stability - 2);
        generated.add(_event(year, month, day, 'manager_pressure',
            'Zarząd traci cierpliwość',
            'Seria słabych wyników zwiększa presję na sztab ${club.name}.',
            clubId: club.id, importance: 4));
      }

      if (club.financialHealth < 30 && _random.nextDouble() < 0.02) {
        generated.add(_event(year, month, day, 'finance',
            'Problemy finansowe ${club.name}',
            'Klub musi ograniczyć wydatki. Sprzedaż zawodników staje się realną opcją.',
            clubId: club.id, importance: 3));
        club.boardPressure = min(100, club.boardPressure + 3);
      }

      // Młody zawodnik może wejść do świadomości świata.
      final talents = squad.where((p) => p.age <= 21 && p.potential - p.overall >= 12).toList();
      if (talents.isNotEmpty && _random.nextDouble() < 0.012) {
        final talent = talents[_random.nextInt(talents.length)];
        playerHotStreak[talent.id] = min(10, (playerHotStreak[talent.id] ?? 0) + 1);
        generated.add(_event(year, month, day, 'talent',
            'Młody talent przyciąga uwagę',
            '${talent.name} z ${club.name} zaczyna być wymieniany wśród najbardziej obiecujących zawodników.',
            clubId: club.id, playerId: talent.id, importance: 2));
      }
    }

    // Długie siedzenie na ławce może wywołać niezadowolenie. Nie jest to
    // automatyczny transfer — tylko początek historii, którą później mogą
    // wykorzystać TransferEngine, trener i FPG Social.
    for (final player in players) {
      if (player.clubId == null || player.consecutiveBenchDays < 18) continue;
      if (_random.nextDouble() < 0.004) {
        player.morale = max(20, player.morale - 5);
        generated.add(_event(year, month, day, 'player_frustration',
            'Niezadowolenie zawodnika',
            '${player.name} jest sfrustrowany brakiem regularnej gry i może rozważyć zmianę klubu.',
            clubId: player.clubId, playerId: player.id, importance: 3));
      }
    }

    // Świat nie produkuje setek newsów dziennie. Rzadkie wydarzenia mają większą wagę.
    recentEvents.addAll(generated);
    if (recentEvents.length > 250) {
      recentEvents.removeRange(0, recentEvents.length - 250);
    }
    return generated;
  }


  void absorbExternalEvents(Iterable<WorldEvent> events) {
    recentEvents.addAll(events);
    if (recentEvents.length > 250) {
      recentEvents.removeRange(0, recentEvents.length - 250);
    }
  }

  WorldEvent _event(
    int year,
    int month,
    int day,
    String type,
    String title,
    String description, {
    String? clubId,
    String? playerId,
    int importance = 1,
  }) {
    return WorldEvent(
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
  }
}
