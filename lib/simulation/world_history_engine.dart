import 'dart:math';

import '../models/club.dart';

/// Długoterminowa pamięć świata. Dzięki niej wydarzenia z poprzednich sezonów
/// wpływają na reputację, stabilność i zachowanie klubów.
class WorldHistoryEngine {
  final Random random;
  WorldHistoryEngine({Random? random}) : random = random ?? Random();

  void processSeason({required List<Club> clubs, required Map<String, int> positions}) {
    for (final club in clubs) {
      final pos = positions[club.id] ?? 0;
      if (pos <= 0) continue;
      club.lastLeaguePosition = pos;
      club.seasonsManaged++;

      final leaguePressure = pos <= 3 ? 1 : pos >= 15 ? -2 : 0;
      club.historicalReputation = (club.historicalReputation + leaguePressure).clamp(10, 100).toInt();
      club.reputation = ((club.reputation * 0.96) + (club.historicalReputation * 0.04)).round().clamp(1, 100).toInt();

      if (pos == 1) {
        club.domesticTitles++;
        club.lastSeasonOutcome = 'champions';
        club.boardConfidence = min(100, club.boardConfidence + 12);
        club.fanSupport = min(100, club.fanSupport + 8);
      } else if (pos <= 3) {
        club.lastSeasonOutcome = 'europe';
        club.boardConfidence = min(100, club.boardConfidence + 5);
      } else if (pos >= 15) {
        club.lastSeasonOutcome = 'relegation';
        club.boardConfidence = max(0, club.boardConfidence - 15);
        club.fanSupport = max(10, club.fanSupport - 8);
      } else {
        club.lastSeasonOutcome = 'stable';
      }
    }
  }
}
