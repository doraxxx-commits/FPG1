import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

/// AI trenera odpowiedzialne za hierarchię kadry.
///
/// Silnik nie losuje po prostu jedenastki. Najpierw buduje hierarchię
/// zawodników według jakości, formy, kondycji, morale, relacji z trenerem,
/// wieku i wykorzystania w ostatnich dniach.
class SquadAIEngine {
  final Random _random;

  SquadAIEngine({Random? random}) : _random = random ?? Random();

  void processClub({required Club club, required List<Player> players, required int absoluteDay}) {
    final squad = players.where((p) => p.clubId == club.id && !p.injured && p.squadStatus != 'academy').toList();
    if (squad.isEmpty) return;

    for (final player in squad) {
      player.squadStatus = 'reserves';
    }

    final groups = <PlayerPosition, List<Player>>{};
    for (final position in PlayerPosition.values) {
      groups[position] = squad.where((p) => p.position == position).toList();
    }

    for (final entry in groups.entries) {
      final list = entry.value;
      list.sort((a, b) => _selectionScore(b, club, absoluteDay)
          .compareTo(_selectionScore(a, club, absoluteDay)));

      // Realistyczna hierarchia pozycji: pierwszy jest podstawowym,
      // kolejny zmiennikiem. Nie wymuszamy jednak jedenastki tutaj —
      // MatchEngine wykorzysta te statusy podczas dnia meczowego.
      if (list.isNotEmpty) list[0].squadStatus = 'startingXI';
      if (list.length > 1) list[1].squadStatus = 'substitute';
      for (var i = 2; i < list.length; i++) {
        list[i].squadStatus = i < 5 ? 'reserves' : 'outOfSquad';
      }
    }

    // Przy bardzo napiętym kalendarzu trener rotuje zawodników.
    if (squad.length >= 18 && _random.nextDouble() < _rotationProbability(club)) {
      _rotateOnePlayer(squad, absoluteDay);
    }

    _updateManagerRelationships(squad);
  }

  double _selectionScore(Player p, Club club, int day) {
    var score = p.overall.toDouble();
    score += (p.form - 70) * 0.35;
    score += (p.fitness - 70) * 0.25;
    score += (p.morale - 70) * 0.10;
    score += (p.managerRelationship - 50) * 0.18;

    // Młodzi z wysokim potencjałem dostają mały bonus w klubach stawiających
    // na młodzież, ale potencjał nigdy nie przebija aktualnej jakości całkowicie.
    score += max(0, p.potential - p.overall) * (club.youthFocus / 1000.0);

    if (p.fatigue > 65) score -= (p.fatigue - 65) * 0.35;
    if (p.consecutiveBenchDays > 10) score += 1.5;
    if (p.consecutiveUnusedDays > 14) score += 2.5;

    return score;
  }

  double _rotationProbability(Club club) {
    return (0.08 + club.transferActivity / 1000.0).clamp(0.08, 0.18);
  }

  void _rotateOnePlayer(List<Player> squad, int day) {
    final starters = squad.where((p) => p.squadStatus == 'startingXI').toList();
    final substitutes = squad.where((p) => p.squadStatus == 'substitute').toList();
    if (starters.isEmpty || substitutes.isEmpty) return;

    final starter = starters[_random.nextInt(starters.length)];
    final replacement = substitutes.first;
    starter.squadStatus = 'substitute';
    replacement.squadStatus = 'startingXI';
    starter.morale = min(100, starter.morale + 1);
    replacement.morale = min(100, replacement.morale + 2);
  }

  void _updateManagerRelationships(List<Player> squad) {
    for (final player in squad) {
      switch (player.squadStatus) {
        case 'startingXI':
          player.consecutiveBenchDays = 0;
          player.consecutiveUnusedDays = 0;
          player.managerRelationship = min(100, player.managerRelationship + 1);
          break;
        case 'substitute':
          player.consecutiveBenchDays++;
          player.consecutiveUnusedDays = 0;
          if (player.consecutiveBenchDays > 14) {
            player.managerRelationship = max(20, player.managerRelationship - 1);
            player.morale = max(25, player.morale - 1);
          }
          break;
        case 'outOfSquad':
          player.consecutiveUnusedDays++;
          player.consecutiveBenchDays = 0;
          if (player.consecutiveUnusedDays > 10) {
            player.managerRelationship = max(15, player.managerRelationship - 1);
            player.morale = max(20, player.morale - 1);
          }
          break;
        default:
          player.consecutiveBenchDays++;
      }
    }
  }
}
