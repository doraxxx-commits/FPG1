import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

/// Oddziela reputację zawodnika, trenera i klubu. Reputacja jest pamięcią
/// społeczną, a nie drugim OVR-em.
class ReputationEngine {
  final Map<String, int> playerReputation = {};
  final Map<String, int> managerReputation = {};

  void processDay({required List<Club> clubs, required List<Player> players}) {
    for (final club in clubs) {
      managerReputation[club.id] = _managerScore(club);
      final squad = players.where((p) => p.clubId == club.id).toList();
      for (final player in squad) {
        playerReputation[player.id] = _playerScore(player, club);
      }
    }
  }

  int _managerScore(Club club) {
    final result = (club.managerQuality * .45 +
            club.boardConfidence * .25 +
            club.lastLeaguePositionPositive * .15 +
            club.stability * .15)
        .round();
    return result.clamp(1, 100).toInt();
  }

  int _playerScore(Player player, Club club) {
    final score = player.overall * .55 +
        player.form * .12 +
        player.morale * .08 +
        player.appearances.clamp(0, 50) * .25 +
        club.reputation * .08;
    return score.round().clamp(1, 100).toInt();
  }
}

extension on Club {
  int get lastLeaguePositionPositive => lastLeaguePosition <= 0 ? 50 : max(1, 100 - lastLeaguePosition * 3);
}
