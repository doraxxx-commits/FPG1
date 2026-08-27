import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/club.dart';
import 'package:fpg/simulation/league_engine.dart';

void main() {
  test('LeagueEngine replaceMatch changes only the result, not match count', () {
    final clubs = [
      Club(id: 'a', name: 'A', overall: 70),
      Club(id: 'b', name: 'B', overall: 70),
    ];
    final league = LeagueEngine(clubs: clubs);

    league.recordMatch(homeClubId: 'a', awayClubId: 'b', homeGoals: 1, awayGoals: 0);
    expect(league.standings['a']!.played, 1);
    expect(league.standings['b']!.played, 1);
    expect(league.standings['a']!.points, 3);

    league.replaceMatch(
      homeClubId: 'a', awayClubId: 'b',
      oldHomeGoals: 1, oldAwayGoals: 0,
      newHomeGoals: 2, newAwayGoals: 2,
    );

    expect(league.standings['a']!.played, 1);
    expect(league.standings['b']!.played, 1);
    expect(league.standings['a']!.points, 1);
    expect(league.standings['b']!.points, 1);
    expect(league.standings['a']!.goalsFor, 2);
    expect(league.standings['b']!.goalsFor, 2);
  });
}
