import 'dart:math';

import '../models/club.dart';
import '../models/fixture.dart';
import '../models/match_result.dart';
import '../models/player.dart';
import 'match_simulation_core.dart';

/// Match engine used by the autonomous football world.
/// It deliberately works with Player (AI world players), not PlayerCareer.
class GlobalMatchEngine {
  final Random _random;
  late final MatchSimulationCore core;

  GlobalMatchEngine({Random? random}) : _random = random ?? Random() {
    core = MatchSimulationCore(random: _random);
  }

  MatchResult simulate({
    required Club home,
    required Club away,
    required List<Player> homePlayers,
    required List<Player> awayPlayers,
    int rivalryIntensity = 0,
  }) {
    final homeXI = _selectXI(homePlayers);
    final awayXI = _selectXI(awayPlayers);

    final coreResult = core.simulate(
      home: _teamInput(home, homeXI),
      away: _teamInput(away, awayXI),
      rivalryIntensity: rivalryIntensity,
    );
    final homeGoals = coreResult.homeGoals;
    final awayGoals = coreResult.awayGoals;

    // Build match statistics from xG/chance volume rather than inventing
    // disconnected numbers. This keeps the match believable and useful for
    // form, news and future UI.
    final homeShots = max(homeGoals + 3, (coreResult.homeXg * (4.8 + _random.nextDouble() * 2.4)).round());
    final awayShots = max(awayGoals + 3, (coreResult.awayXg * (4.8 + _random.nextDouble() * 2.4)).round());
    final homeShotsOnTarget = min(homeShots, max(homeGoals, (homeShots * (0.30 + _random.nextDouble() * 0.18)).round()));
    final awayShotsOnTarget = min(awayShots, max(awayGoals, (awayShots * (0.30 + _random.nextDouble() * 0.18)).round()));
    final possessionHome = (50 + ((coreResult.homeStrength - coreResult.awayStrength) * .65).round() + _random.nextInt(9) - 4).clamp(30, 70).toInt();
    final homeCorners = max(1, (homeShots * (.16 + _random.nextDouble() * .10)).round());
    final awayCorners = max(1, (awayShots * (.16 + _random.nextDouble() * .10)).round());
    final homeFouls = 7 + _random.nextInt(11);
    final awayFouls = 7 + _random.nextInt(11);
    final homeYellow = min(5, (homeFouls * (.12 + _random.nextDouble() * .10)).round());
    final awayYellow = min(5, (awayFouls * (.12 + _random.nextDouble() * .10)).round());
    final homeRed = homeYellow >= 4 && _random.nextDouble() < .08 ? 1 : 0;
    final awayRed = awayYellow >= 4 && _random.nextDouble() < .08 ? 1 : 0;

    final performances = <PlayerMatchPerformance>[];
    final events = <PlayerMatchEvent>[];

    performances.addAll(_performances(
      players: homeXI,
      goals: homeGoals,
      won: homeGoals > awayGoals,
      draw: homeGoals == awayGoals,
      events: events,
    ));
    performances.addAll(_performances(
      players: awayXI,
      goals: awayGoals,
      won: awayGoals > homeGoals,
      draw: homeGoals == awayGoals,
      events: events,
    ));

    _applyMatchToPlayers(homeXI, performances);
    _applyMatchToPlayers(awayXI, performances);
    _applyDisciplineAndInjuries(homeXI, homeYellow, homeRed);
    _applyDisciplineAndInjuries(awayXI, awayYellow, awayRed);

    return MatchResult(
      homeClubId: home.id,
      awayClubId: away.id,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      events: events,
      playerPerformances: performances,
      homeShots: homeShots,
      awayShots: awayShots,
      homeShotsOnTarget: homeShotsOnTarget,
      awayShotsOnTarget: awayShotsOnTarget,
      homeCorners: homeCorners,
      awayCorners: awayCorners,
      homeFouls: homeFouls,
      awayFouls: awayFouls,
      homeYellowCards: homeYellow,
      awayYellowCards: awayYellow,
      homeRedCards: homeRed,
      awayRedCards: awayRed,
      possessionHome: possessionHome,
    );
  }

  MatchSimulationTeamInput _teamInput(Club club, List<Player> xi) {
    final players = xi.isEmpty ? <Player>[] : xi;
    double avg(List<double> values) => values.isEmpty ? club.overall.toDouble() : values.reduce((a, b) => a + b) / values.length;
    return MatchSimulationTeamInput(
      playerAverage: avg(players.map((p) => p.overall.toDouble()).toList()),
      formAverage: avg(players.map((p) => p.form.toDouble()).toList()),
      fitnessAverage: avg(players.map((p) => p.fitness.toDouble()).toList()),
      moraleAverage: avg(players.map((p) => p.morale.toDouble()).toList()),
      clubOverall: club.overall,
      financialHealth: club.financialHealth,
      reputation: club.reputation,
      tacticalIdentity: club.tacticalIdentity,
      managerQuality: club.managerQuality,
    );
  }

  List<Player> _selectXI(List<Player> players) {
    final available = players.where((p) => !p.injured).toList();
    available.sort((a, b) => _selectionScore(b).compareTo(_selectionScore(a)));
    return available.take(min(11, available.length)).toList();
  }

  double _selectionScore(Player p) {
    final fatiguePenalty = p.fatigue * 0.08;
    final fitnessBonus = (p.fitness - 70) * 0.12;
    final formBonus = (p.form - 70) * 0.10;
    final moraleBonus = (p.morale - 70) * 0.04;
    return p.overall + fitnessBonus + formBonus + moraleBonus - fatiguePenalty;
  }

  List<PlayerMatchPerformance> _performances({
    required List<Player> players,
    required int goals,
    required bool won,
    required bool draw,
    required List<PlayerMatchEvent> events,
  }) {
    final result = <PlayerMatchPerformance>[];
    if (players.isEmpty) return result;

    for (final p in players) {
      final minutes = p.fatigue >= 82 || p.fitness < 55 ? 55 + _random.nextInt(25) : 75 + _random.nextInt(16);
      var rating = 6.25 + (p.form - 70) * 0.018 + (p.fitness - 70) * 0.012;
      if (won) rating += 0.35;
      if (!won && !draw) rating -= 0.25;
      rating += (_random.nextDouble() - 0.5) * 0.9;
      rating = rating.clamp(4.5, 9.6).toDouble();

      result.add(PlayerMatchPerformance(
        playerId: p.id,
        minutes: minutes,
        started: true,
        rating: rating,
      ));
      events.add(PlayerMatchEvent(playerId: p.id, minute: 1, type: 'start', rating: rating));
    }

    _assignGoals(result, goals, players, events);
    _assignAssists(result, goals, players);
    return result;
  }

  void _assignGoals(List<PlayerMatchPerformance> performances, int goals, List<Player> players, List<PlayerMatchEvent> events) {
    if (goals <= 0 || performances.isEmpty) return;
    final weighted = <PlayerMatchPerformance>[];
    for (final perf in performances) {
      final p = players.firstWhere((x) => x.id == perf.playerId);
      final weight = switch (p.position) {
        PlayerPosition.striker => 8.0,
        PlayerPosition.winger => 5.0,
        PlayerPosition.midfielder => 3.0,
        PlayerPosition.defender => 1.3,
        PlayerPosition.goalkeeper => 0.15,
      };
      final count = max(1, weight.round());
      for (var i = 0; i < count; i++) weighted.add(perf);
    }
    for (var i = 0; i < goals; i++) {
      final scorer = weighted[_random.nextInt(weighted.length)];
      // A performance object is immutable, so replace it with updated values.
      final index = performances.indexOf(scorer);
      final old = performances[index];
      final goalMinute = 5 + _random.nextInt(86);
      final updated = PlayerMatchPerformance(
        playerId: old.playerId,
        minutes: old.minutes,
        started: old.started,
        rating: min(10.0, old.rating + 0.25),
        goals: old.goals + 1,
        assists: old.assists,
        shots: old.shots + 1,
        shotsOnTarget: old.shotsOnTarget + 1,
        keyPasses: old.keyPasses,
        successfulDribbles: old.successfulDribbles,
        yellowCards: old.yellowCards,
        redCards: old.redCards,
      );
      performances[index] = updated;
      events.add(PlayerMatchEvent(playerId: old.playerId, minute: goalMinute, type: 'goal', rating: updated.rating));
    }
  }

  void _assignAssists(List<PlayerMatchPerformance> performances, int goals, List<Player> players) {
    if (goals <= 0 || performances.length < 2) return;
    for (var i = 0; i < goals; i++) {
      final eligible = performances.where((p) => p.goals == 0).toList();
      if (eligible.isEmpty) return;
      final chosen = eligible[_random.nextInt(eligible.length)];
      final index = performances.indexOf(chosen);
      final old = performances[index];
      performances[index] = PlayerMatchPerformance(
        playerId: old.playerId,
        minutes: old.minutes,
        started: old.started,
        rating: min(10.0, old.rating + 0.12),
        goals: old.goals,
        assists: old.assists + 1,
        shots: old.shots,
        shotsOnTarget: old.shotsOnTarget,
        keyPasses: old.keyPasses + 1,
        successfulDribbles: old.successfulDribbles,
        yellowCards: old.yellowCards,
        redCards: old.redCards,
      );
    }
  }


  void _applyDisciplineAndInjuries(List<Player> players, int yellows, int reds) {
    if (players.isEmpty) return;
    final available = players.where((p) => !p.injured).toList();
    final cardEvents = min(available.length, yellows + reds);
    for (var i = 0; i < cardEvents; i++) {
      final p = available[_random.nextInt(available.length)];
      p.morale = max(10, p.morale - (i < reds ? 4 : 1));
    }
    if (_random.nextDouble() < .045) {
      final victim = available[_random.nextInt(available.length)];
      victim.injured = true;
      victim.injuryDaysRemaining = 3 + _random.nextInt(18);
      victim.fitness = max(0, victim.fitness - 15);
    }
  }

  void _applyMatchToPlayers(List<Player> players, List<PlayerMatchPerformance> performances) {
    for (final p in players) {
      final perf = performances.where((x) => x.playerId == p.id).firstOrNull;
      if (perf == null) continue;
      p.appearances++;
      p.starts++;
      p.minutesPlayed += perf.minutes;
      p.goals += perf.goals;
      p.assists += perf.assists;
      p.fatigue = (p.fatigue + 24 + (perf.minutes - 70).clamp(0, 20)).clamp(0, 100).toInt();
      p.fitness = (p.fitness - 18 - (perf.minutes - 70).clamp(0, 20)).clamp(0, 100).toInt();
      if (perf.rating >= 7.4) p.form = (p.form + 2).clamp(0, 100).toInt();
      if (perf.rating < 5.8) p.form = (p.form - 2).clamp(0, 100).toInt();
      p.morale = (p.morale + (perf.rating >= 7.5 ? 1 : perf.rating < 5.5 ? -1 : 0)).clamp(0, 100).toInt();
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
