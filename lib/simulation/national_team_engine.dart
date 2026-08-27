import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';
import '../models/national_team.dart';

/// Reprezentacja jest osobnym obiegiem od klubów. Powołania wynikają z formy,
/// OVR, reputacji i regularnej gry. Wyniki nie są tylko losowe.
class NationalTeamEngine {
  final Random _random;
  final Map<String, NationalTeam> teams = {};

  NationalTeamEngine({Random? random}) : _random = random ?? Random();

  void ensureTeams(Iterable<Club> clubs) {
    for (final country in clubs.map((c) => c.country).toSet()) {
      teams.putIfAbsent(country, () => NationalTeam(country: country, reputation: _countryStrength(country)));
    }
  }

  void processSeason({required List<Club> clubs, required List<Player> players, required int seasonYear}) {
    ensureTeams(clubs);
    for (final team in teams.values) {
      final candidates = players.where((p) => p.nationality == team.country && p.age <= 38 && !p.injured).toList();
      candidates.sort((a, b) => _score(b).compareTo(_score(a)));
      team.playerIds = candidates.take(26).map((p) => p.id).toList();
      if (team.playerIds.length < 11) continue;

      final matches = seasonYear % 2 == 0 ? 5 : 4;
      for (var i = 0; i < matches; i++) {
        final isTournament = seasonYear % 4 == 0 && i >= matches - 2;
        final isFriendly = i == 0;
        final selected = candidates.take(18).toList();
        final avg = selected.fold<double>(0, (s, p) => s + p.overall) / selected.length;
        final strength = avg + team.reputation * .15 + team.managerQuality * .15;
        final opponent = 55 + _random.nextInt(36);
        final roll = strength - opponent + (_random.nextDouble() * 16 - 8);
        final goalsFor = max(0, (1 + roll / 18 + _random.nextDouble() * 2).round());
        final goalsAgainst = max(0, (1 - roll / 20 + _random.nextDouble() * 2).round());
        team.matchesPlayed++;
        team.goalsFor += goalsFor;
        team.goalsAgainst += goalsAgainst;
        if (isFriendly) team.friendlyMatches++;
        else team.competitiveMatches++;
        if (isTournament) team.tournamentMatches++;
        if (roll > 6) team.wins++;
        else if (roll < -6) team.losses++;
        else team.draws++;

        final starters = selected.take(11).toList();
        for (final p in starters) {
          p.nationalCallUps++;
          p.lastNationalCallUpYear = seasonYear;
          if (_random.nextDouble() < .92) {
            p.internationalCaps++;
            if (goalsFor > 0 && _random.nextDouble() < _goalProbability(p)) {
              p.internationalGoals++;
            }
            if (goalsFor > 0 && _random.nextDouble() < .22) {
              p.internationalAssists++;
            }
          }
        }
      }
    }
  }

  double _goalProbability(Player p) {
    switch (p.position) {
      case PlayerPosition.striker:
        return .34;
      case PlayerPosition.winger:
        return .22;
      case PlayerPosition.midfielder:
        return .12;
      case PlayerPosition.defender:
        return .045;
      case PlayerPosition.goalkeeper:
        return .002;
    }
  }

  double _score(Player p) => p.overall * .65 + p.form * .2 + p.morale * .05 + p.appearances.clamp(0, 40) * .25;

  int _countryStrength(String country) {
    const values = {'Anglia': 88, 'Francja': 88, 'Hiszpania': 87, 'Niemcy': 86, 'Brazylia': 89, 'Argentyna': 89, 'Włochy': 84, 'Portugalia': 84, 'Holandia': 82, 'Belgia': 80, 'Polska': 70};
    return values[country] ?? 55;
  }
}
