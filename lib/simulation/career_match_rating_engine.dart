import "dart:math";

import "../models/match_result.dart";
import "../models/player_career.dart";
import "../models/player.dart";

/// Pure calculator for the career player's match rating.
/// Keeps minutes, position and match contributions in one deterministic place.
class CareerMatchRatingEngine {
  final Random random;

  CareerMatchRatingEngine({Random? random}) : random = random ?? Random();

  double calculate({
    required PlayerCareer player,
    required MatchResult result,
    required bool playerClubIsHome,
    required bool started,
    required int minutes,
    required int goals,
    required int assists,
  }) {
    if (minutes <= 0) return 0.0;

    final teamGoals = playerClubIsHome ? result.homeGoals : result.awayGoals;
    final opponentGoals = playerClubIsHome ? result.awayGoals : result.homeGoals;
    final shots = playerClubIsHome ? result.homeShots : result.awayShots;
    final shotsOnTarget = playerClubIsHome
        ? result.homeShotsOnTarget
        : result.awayShotsOnTarget;

    var rating = 6.25;

    // Wynik zespołu ma znaczenie, ale nie dominuje nad występem zawodnika.
    if (teamGoals > opponentGoals) rating += 0.35;
    if (teamGoals < opponentGoals) rating -= 0.30;
    if (started) rating += 0.05;
    if (minutes < 30) rating -= 0.10;

    // Pozycja zmienia oczekiwania wobec zawodnika.
    switch (player.position) {
      case PlayerPosition.striker:
        rating += goals * 0.70 + assists * 0.35;
        break;
      case PlayerPosition.winger:
        rating += goals * 0.62 + assists * 0.42;
        break;
      case PlayerPosition.midfielder:
        rating += goals * 0.55 + assists * 0.48;
        break;
      case PlayerPosition.defender:
        rating += goals * 0.75 + assists * 0.30;
        break;
      case PlayerPosition.goalkeeper:
        rating += goals * 1.0 + assists * 0.25;
        break;
    }

    final teamShotRate = shots == 0 ? 0.0 : shotsOnTarget / shots;
    rating += (teamShotRate - 0.34) * 0.35;
    rating += (player.form - 70) * 0.012;
    rating += (player.fitness - 70) * 0.006;
    rating += (random.nextDouble() - 0.5) * 0.50;

    // Jeden słaby występ nie może rozwalić formy ani ratingu.
    return rating.clamp(4.0, 10.0).toDouble();
  }
}
