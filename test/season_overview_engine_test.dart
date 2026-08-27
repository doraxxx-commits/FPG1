import 'package:flutter_test/flutter_test.dart';
import '../lib/core/game_engine.dart';
import '../lib/simulation/season_overview_engine.dart';

void main() {
  test('season overview derives position and remaining matches from league table', () {
    final engine = GameEngine();
    final player = engine.players.first;
    engine.createPlayer(
      firstName: 'Test', lastName: 'Player', nationality: 'PL', age: 19,
      height: 180, position: player.position, pace: 70, shooting: 70,
      passing: 70, dribbling: 70, defending: 60, physical: 70,
    );
    engine.startCareerAtClub(engine.leagueClubs.first.id);
    final overview = SeasonOverviewEngine().build(engine);
    expect(overview.clubCount, greaterThan(1));
    expect(overview.position, inInclusiveRange(1, overview.clubCount));
    expect(overview.remainingMatches, greaterThan(0));
    expect(overview.seasonProgress, lessThanOrEqualTo(1));
  });
}
