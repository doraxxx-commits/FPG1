import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/club.dart';
import 'package:fpg/models/fixture.dart';
import 'package:fpg/models/match_result.dart';
import 'package:fpg/models/player_career.dart';
import 'package:fpg/models/player.dart';
import 'package:fpg/simulation/career_match_rating_engine.dart';

void main() {
  test('rating respects minutes and contributions while staying in range', () {
    final player = PlayerCareer(
      id: 'p1', firstName: 'Test', lastName: 'Player', nationality: 'PL',
      age: 19, height: 180, position: PlayerPosition.striker, overall: 70, potential: 85,
      pace: 75, shooting: 80, passing: 60, dribbling: 75, defending: 30, physical: 65,
    );
    final result = MatchResult(homeClubId: 'h', awayClubId: 'a', homeGoals: 2, awayGoals: 1,
      homeShots: 12, awayShots: 8, homeShotsOnTarget: 6, awayShotsOnTarget: 3);
    final engine = CareerMatchRatingEngine(random: Random(1));
    final rating = engine.calculate(player: player, result: result, playerClubIsHome: true,
      started: true, minutes: 90, goals: 1, assists: 0);
    expect(rating, inInclusiveRange(4.0, 10.0));
  });

  test('zero minutes produce no rating', () {
    final player = PlayerCareer(id: 'p2', firstName: 'A', lastName: 'B', age: 20, height: 180,
      position: PlayerPosition.midfielder, overall: 65, potential: 80, pace: 60, shooting: 50,
      passing: 70, dribbling: 65, defending: 45, physical: 60);
    final result = MatchResult(homeClubId: 'h', awayClubId: 'a', homeGoals: 0, awayGoals: 0);
    expect(CareerMatchRatingEngine(random: Random(2)).calculate(
      player: player, result: result, playerClubIsHome: true, started: false, minutes: 0, goals: 0, assists: 0), 0.0);
  });
}
