import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/core/game_state.dart';
import 'package:fpg/data/world_data.dart';
import 'package:fpg/models/fixture.dart';
import 'package:fpg/simulation/fixture_generator.dart';

void main() {
  test('new career calendar does not miss the first league matchday', () {
    final state = GameState();
    final fixtures = FixtureGenerator.generateSeasonFixtures(
      WorldData.clubs.where((c) => c.leagueId == 'pol_ek').toList(),
      seasonStartYear: state.season,
    );

    expect(fixtures, isNotEmpty);
    final first = fixtures.reduce((a, b) {
      final da = DateTime(a.year, a.month, a.day);
      final db = DateTime(b.year, b.month, b.day);
      return da.isBefore(db) ? a : b;
    });

    // advanceDay() moves 24.07 -> 25.07, so the first fixture must be
    // reachable by the normal daily simulation flow.
    final firstDate = DateTime(first.year, first.month, first.day);
    final nextDate = DateTime(state.year, state.month, state.day).add(const Duration(days: 1));
    expect(firstDate, nextDate);
  });

  test('season fixture set has no duplicate match identity', () {
    final clubs = WorldData.clubs.where((c) => c.leagueId == 'pol_ek').toList();
    final fixtures = FixtureGenerator.generateSeasonFixtures(clubs, seasonStartYear: 2026);

    final keys = fixtures.map((f) => '${f.round}|${f.homeClubId}|${f.awayClubId}').toSet();
    expect(keys.length, fixtures.length);

    final pairCounts = <String, int>{};
    for (final f in fixtures) {
      final ids = [f.homeClubId, f.awayClubId]..sort();
      pairCounts['${ids[0]}|${ids[1]}'] = (pairCounts['${ids[0]}|${ids[1]}'] ?? 0) + 1;
    }
    final expectedPairs = clubs.length * (clubs.length - 1) ~/ 2;
    expect(pairCounts.length, expectedPairs);
    expect(pairCounts.values.every((count) => count == 2), isTrue);
  });

  test('GameState keeps football season stable until 1 July', () {
    final state = GameState(year: 2027, month: 6, day: 29, season: 2026);
    state.nextDay();
    expect(state.season, 2026);
    expect(state.dateString, '30.06.2027');
    state.nextDay();
    expect(state.season, 2027);
    expect(state.dateString, '01.07.2027');
  });
}
