import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/fixture.dart';
import 'package:fpg/models/match_result.dart';

void main() {
  test('MatchResult survives JSON round-trip without losing match data', () {
    final original = MatchResult(
      homeClubId: 'home',
      awayClubId: 'away',
      homeGoals: 3,
      awayGoals: 2,
      homeShots: 14,
      awayShots: 9,
      homeShotsOnTarget: 7,
      awayShotsOnTarget: 4,
      homeCorners: 6,
      awayCorners: 3,
      homeFouls: 8,
      awayFouls: 12,
      homeYellowCards: 2,
      awayYellowCards: 3,
      possessionHome: 57,
      events: [
        PlayerMatchEvent(playerId: 'p1', minute: 17, type: 'goal', rating: 8.2),
      ],
      playerPerformances: [
        PlayerMatchPerformance(
          playerId: 'p1', minutes: 90, started: true, rating: 8.4,
          goals: 2, assists: 1, shots: 5, shotsOnTarget: 4,
          keyPasses: 2, successfulDribbles: 3,
        ),
      ],
    );

    final restored = MatchResult.fromJson(original.toJson());

    expect(restored.homeGoals, 3);
    expect(restored.awayGoals, 2);
    expect(restored.homeShots, 14);
    expect(restored.awayShotsOnTarget, 4);
    expect(restored.possessionHome, 57);
    expect(restored.events.single.type, 'goal');
    expect(restored.performanceForPlayer('p1')?.goals, 2);
    expect(restored.performanceForPlayer('p1')?.assists, 1);
  });

  test('Fixture stores and restores the complete official result snapshot', () {
    final fixture = Fixture(
      round: 4,
      homeClubId: 'home',
      awayClubId: 'away',
      year: 2026,
      month: 9,
      day: 12,
    );
    final result = MatchResult(
      homeClubId: 'home',
      awayClubId: 'away',
      homeGoals: 1,
      awayGoals: 0,
      homeShots: 11,
      awayShots: 5,
      homeShotsOnTarget: 5,
      awayShotsOnTarget: 2,
      possessionHome: 61,
    );

    fixture.played = true;
    fixture.homeGoals = 1;
    fixture.awayGoals = 0;
    fixture.storeResult(result);

    final restored = fixture.storedResult;
    expect(restored, isNotNull);
    expect(restored!.homeShots, 11);
    expect(restored.awayShots, 5);
    expect(restored.possessionHome, 61);
  });
}
