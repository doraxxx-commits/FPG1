import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/core/game_state.dart';
import 'package:fpg/models/club.dart';
import 'package:fpg/simulation/fixture_generator.dart';

void main() {
  test('season calendar rolls from 30 June to 1 July and advances season', () {
    final state = GameState(year: 2027, month: 6, day: 30, season: 2026);

    state.nextDay();

    expect(state.dateString, '01.07.2027');
    expect(state.season, 2027);
    expect(state.transferWindowSummer, isTrue);
  });

  test('new season fixtures start in the new season year, not the completed one', () {
    final clubs = List.generate(4, (i) => Club(
      id: 'c$i',
      name: 'Club $i',
      overall: 70,
      leagueId: 'pol_ek',
    ));

    final fixtures = FixtureGenerator.generateSeasonFixtures(
      clubs,
      seasonStartYear: 2027,
    );

    expect(fixtures, isNotEmpty);
    expect(fixtures.every((f) => f.year == 2027 || f.year == 2028), isTrue);
    expect(fixtures.where((f) => f.round <= 3).every((f) => f.year == 2027), isTrue);
    expect(fixtures.where((f) => f.round > 3).every((f) => f.year == 2028), isTrue);
  });
}
