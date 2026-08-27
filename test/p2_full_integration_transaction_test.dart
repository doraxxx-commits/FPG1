import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/core/game_engine.dart';
import 'package:fpg/core/game_state.dart';
import 'package:fpg/models/player.dart';

void main() {
  test('P2.0 interactive fixture is transactional: preview does not update table, commit does', () {
    final engine = GameEngine(state: GameState(year: 2026, month: 7, day: 24, season: 2026));
    final club = engine.clubs.firstWhere((c) => c.leagueId == 'pol_ek');
    final fixture = engine.fixtures.firstWhere((f) =>
        !f.played &&
        (f.homeClubId == club.id || f.awayClubId == club.id));

    engine.createPlayer(
      firstName: 'Test', lastName: 'Player', nationality: 'PL', age: 19,
      height: 180, position: PlayerPosition.striker,
      pace: 75, shooting: 75, passing: 65, dribbling: 75,
      defending: 40, physical: 70,
    );
    engine.careerPlayer!.clubId = club.id;
    engine.careerWorldBridge.pushCareerState(engine.careerPlayer!);

    final beforePlayed = engine.leagueEngine.standings.values
        .fold<int>(0, (sum, s) => sum + s.played);
    final preview = engine.previewFixture(fixture);
    final afterPreviewPlayed = engine.leagueEngine.standings.values
        .fold<int>(0, (sum, s) => sum + s.played);

    expect(fixture.played, isFalse);
    expect(beforePlayed, afterPreviewPlayed);
    expect(preview.homeGoals, greaterThanOrEqualTo(0));
    expect(preview.awayGoals, greaterThanOrEqualTo(0));

    engine.reconcileInteractiveFixtureResult(
      fixture: fixture,
      finalHomeGoals: 2,
      finalAwayGoals: 1,
    );

    final afterCommitPlayed = engine.leagueEngine.standings.values
        .fold<int>(0, (sum, s) => sum + s.played);
    expect(fixture.played, isTrue);
    expect(fixture.homeGoals, 2);
    expect(fixture.awayGoals, 1);
    expect(afterCommitPlayed, beforePlayed + 2);

    // Replaying the same finalization is idempotent: the table cannot gain
    // another match and career appearance cannot be duplicated.
    final appearances = engine.careerPlayer!.careerAppearances;
    engine.reconcileInteractiveFixtureResult(
      fixture: fixture,
      finalHomeGoals: 2,
      finalAwayGoals: 1,
    );
    final afterSecondCommitPlayed = engine.leagueEngine.standings.values
        .fold<int>(0, (sum, s) => sum + s.played);

    expect(afterSecondCommitPlayed, afterCommitPlayed);
    expect(engine.careerPlayer!.careerAppearances, appearances);
    expect(engine.validateLeagueIntegrity(), isTrue);
  });
}
