import '../models/club.dart';
import '../models/fixture.dart';

class FixtureGenerator {
  static List<Fixture> generateDoubleRoundRobin(
    List<Club> clubs,
  ) {
    final fixtures = <Fixture>[];

    if (clubs.length < 2) {
      return fixtures;
    }

    final teams = List<Club>.from(clubs);

    if (teams.length.isOdd) {
      teams.add(
        Club(
          id: 'BYE',
          name: 'BYE',
          country: '',
          leagueId: '',
          overall: 0,
          budget: 0,
        ),
      );
    }

    final teamCount = teams.length;
    final rounds = teamCount - 1;

    final rotatingTeams = List<Club>.from(teams);

    for (int round = 0; round < rounds; round++) {
      for (int i = 0; i < teamCount ~/ 2; i++) {
        final home = rotatingTeams[i];
        final away = rotatingTeams[teamCount - 1 - i];

        if (home.id != 'BYE' && away.id != 'BYE') {
          final matchDay = 8 + (round * 7);

          fixtures.add(
            Fixture(
              round: round + 1,
              homeClubId: home.id,
              awayClubId: away.id,
              year: 2026,
              month: 7,
              day: matchDay,
            ),
          );
        }
      }

      final last = rotatingTeams.removeLast();
      rotatingTeams.insert(1, last);
    }

    final firstRoundFixtures = List<Fixture>.from(fixtures);

    for (final fixture in firstRoundFixtures) {
      fixtures.add(
        Fixture(
          round: fixture.round + rounds,
          homeClubId: fixture.awayClubId,
          awayClubId: fixture.homeClubId,
          year: 2026,
          month: 9,
          day: fixture.day,
        ),
      );
    }

    return fixtures;
  }

  /// Generates a full autonomous season with real calendar dates.
  /// First round is played Aug-Dec, return round Jan-May.
  static List<Fixture> generateSeasonFixtures(
    List<Club> clubs, {
    required int seasonStartYear,
  }) {
    final fixtures = <Fixture>[];
    if (clubs.length < 2) return fixtures;

    final teams = List<Club>.from(clubs);
    if (teams.length.isOdd) {
      teams.add(Club(
        id: 'BYE_${seasonStartYear}_${clubs.length}',
        name: 'BYE', country: '', leagueId: '', overall: 0, budget: 0,
      ));
    }

    final count = teams.length;
    final rounds = count - 1;
    final rotation = List<Club>.from(teams);
    final firstLeg = <Fixture>[];

    // A new career must never inherit already-played league rounds.
    // The career clock is simulation-owned. A new career begins with the
    // football season itself, not with the device's real date/time.
    // 2026/27 starts on 24 July 2026, so that is the first playable
    // calendar day and the first league matchday anchor.
    final firstMatchDate = DateTime(seasonStartYear, 7, 25);

    for (var round = 0; round < rounds; round++) {
      final date = firstMatchDate.add(Duration(days: round * 7));
      for (var i = 0; i < count ~/ 2; i++) {
        final a = rotation[i];
        final b = rotation[count - 1 - i];
        if (a.id == 'BYE_${seasonStartYear}_${clubs.length}' || b.id == 'BYE_${seasonStartYear}_${clubs.length}') continue;
        final homeFirst = round.isEven;
        firstLeg.add(Fixture(
          round: round + 1,
          homeClubId: homeFirst ? a.id : b.id,
          awayClubId: homeFirst ? b.id : a.id,
          year: date.year, month: date.month, day: date.day,
        ));
      }
      final last = rotation.removeLast();
      rotation.insert(1, last);
    }

    fixtures.addAll(firstLeg);
    for (var i = 0; i < firstLeg.length; i++) {
      final f = firstLeg[i];
      final date = DateTime(seasonStartYear + 1, 1, 9).add(Duration(days: (f.round - 1) * 7));
      fixtures.add(Fixture(
        round: f.round + rounds,
        homeClubId: f.awayClubId,
        awayClubId: f.homeClubId,
        year: date.year, month: date.month, day: date.day,
      ));
    }
    return fixtures;
  }

}
