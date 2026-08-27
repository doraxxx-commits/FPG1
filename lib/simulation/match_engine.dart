import 'dart:math';

import '../models/club.dart';
import '../models/match_result.dart';
import '../models/player_career.dart';
import '../models/player.dart';
import 'match_simulation_core.dart';

class MatchEngine {
  final Random _random;
  late final MatchSimulationCore core;

  MatchEngine({
    Random? random,
  }) : _random = random ?? Random() {
    core = MatchSimulationCore(random: _random);
  }

  // ==========================================================
  // SYMULACJA MECZU
  // ==========================================================

  MatchResult simulate({
    required Club home,
    required Club away,

    // Opcjonalne składy zawodników.
    List<PlayerCareer> homePlayers = const [],
    List<PlayerCareer> awayPlayers = const [],
  }) {
    final coreResult = core.simulate(
      home: _teamInput(home, homePlayers),
      away: _teamInput(away, awayPlayers),
    );

    final homeGoals = coreResult.homeGoals;
    final awayGoals = coreResult.awayGoals;

    // ==========================================================
    // STATYSTYKI INDYWIDUALNE
    // ==========================================================

    final playerPerformances =
        <PlayerMatchPerformance>[];

    final events =
        <PlayerMatchEvent>[];

    // ----------------------------------------------------------
    // WYSTĘPY GOSPODARZY
    // ----------------------------------------------------------

    playerPerformances.addAll(
      _generatePlayerPerformances(
        players: homePlayers,
        teamGoals: homeGoals,
        teamWon: homeGoals > awayGoals,
        teamDraw: homeGoals == awayGoals,
        events: events,
      ),
    );

    // ----------------------------------------------------------
    // WYSTĘPY GOŚCI
    // ----------------------------------------------------------

    playerPerformances.addAll(
      _generatePlayerPerformances(
        players: awayPlayers,
        teamGoals: awayGoals,
        teamWon: awayGoals > homeGoals,
        teamDraw: homeGoals == awayGoals,
        events: events,
      ),
    );

    // ==========================================================
    // WYNIK MECZU
    // ==========================================================

    final stats = _matchStats(
      coreResult: coreResult,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
    );

    return MatchResult(
      homeClubId: home.id,
      awayClubId: away.id,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      events: events,
      playerPerformances: playerPerformances,
      homeShots: stats['homeShots']!,
      awayShots: stats['awayShots']!,
      homeShotsOnTarget: stats['homeShotsOnTarget']!,
      awayShotsOnTarget: stats['awayShotsOnTarget']!,
      homeCorners: stats['homeCorners']!,
      awayCorners: stats['awayCorners']!,
      homeFouls: stats['homeFouls']!,
      awayFouls: stats['awayFouls']!,
      homeYellowCards: stats['homeYellowCards']!,
      awayYellowCards: stats['awayYellowCards']!,
      homeRedCards: stats['homeRedCards']!,
      awayRedCards: stats['awayRedCards']!,
      possessionHome: stats['possessionHome']!,
    );
  }

  MatchSimulationTeamInput _teamInput(Club club, List<PlayerCareer> players) {
    double avg(List<double> values, double fallback) => values.isEmpty ? fallback : values.reduce((a, b) => a + b) / values.length;
    return MatchSimulationTeamInput(
      playerAverage: avg(players.map((p) => p.overall.toDouble()).toList(), club.overall.toDouble()),
      formAverage: avg(players.map((p) => p.form.toDouble()).toList(), 70),
      fitnessAverage: avg(players.map((p) => p.fitness.toDouble()).toList(), 75),
      moraleAverage: avg(players.map((p) => p.morale.toDouble()).toList(), 70),
      clubOverall: club.overall,
      financialHealth: club.financialHealth,
      reputation: club.reputation,
      tacticalIdentity: club.tacticalIdentity,
      managerQuality: club.managerQuality,
    );
  }

  // ==========================================================
  // GENEROWANIE WYSTĘPÓW ZAWODNIKÓW
  // ==========================================================

  List<PlayerMatchPerformance>
      _generatePlayerPerformances({
    required List<PlayerCareer> players,
    required int teamGoals,
    required bool teamWon,
    required bool teamDraw,
    required List<PlayerMatchEvent> events,
  }) {
    if (players.isEmpty) {
      return [];
    }

    final performances =
        <PlayerMatchPerformance>[];

    final starters = _selectStartingXI(players);

    // ========================================================
    // PODSTAWOWY SKŁAD
    // ========================================================

    for (final player in starters) {
      final minutes =
          _generateStarterMinutes(player);

      final rating =
          _generatePlayerRating(
        player,
        teamWon: teamWon,
        teamDraw: teamDraw,
        minutes: minutes,
      );

      final performance =
          PlayerMatchPerformance(
        playerId: player.id,
        minutes: minutes,
        started: true,
        rating: rating,
      );

      performances.add(performance);

      events.add(
        PlayerMatchEvent(
          playerId: player.id,
          minute: 1,
          type: 'start',
          rating: rating,
        ),
      );
    }

    // ========================================================
    // REZERWOWY
    // ========================================================

    final starterIds = starters.map((p) => p.id).toSet();
    final substitutes = players
        .where((p) => !starterIds.contains(p.id))
        .where(_isEligible)
        .toList()
      ..sort((a, b) => _selectionScore(b).compareTo(_selectionScore(a)));
    final bench = substitutes.take(5).toList();

    for (final player in bench) {
      final enters =
          _random.nextDouble() < 0.45;

      if (!enters) {
        continue;
      }

      final minutes =
          randomInt(10, 35);

      final entryMinute =
          randomInt(46, 80);

      final rating =
          _generatePlayerRating(
        player,
        teamWon: teamWon,
        teamDraw: teamDraw,
        minutes: minutes,
      );

      final performance =
          PlayerMatchPerformance(
        playerId: player.id,
        minutes: minutes,
        started: false,
        rating: rating,
      );

      performances.add(performance);

      events.add(
        PlayerMatchEvent(
          playerId: player.id,
          minute: entryMinute,
          type: 'substitution_in',
          rating: rating,
        ),
      );
    }

    // ========================================================
    // ROZDZIELENIE GOLI
    // ========================================================

    _assignGoals(
      performances: performances,
      goals: teamGoals,
      events: events,
      players: players,
    );

    // ========================================================
    // ASYSTY
    // ========================================================

    _assignAssists(
      performances: performances,
      goals: teamGoals,
    );

    // ========================================================
    // DODATKOWE STATYSTYKI
    // ========================================================

    for (final performance in performances) {
      final index = performances.indexOf(performance);
      performances[index] = _generateAdditionalStats(performance);
    }

    return performances;
  }

  // ==========================================================
  // WYBÓR XI — jakość + pozycja + stan zawodnika
  // ==========================================================

  List<PlayerCareer> _selectStartingXI(List<PlayerCareer> players) {
    final available = players.where(_isEligible).toList();
    if (available.length <= 11) return List<PlayerCareer>.from(available);

    final selected = <PlayerCareer>[];
    final remaining = List<PlayerCareer>.from(available);

    // Bazowa struktura 4-3-3. Jeżeli kadra nie ma wymaganej liczby
    // zawodników na pozycji, brakujące miejsca uzupełniamy najlepszymi
    // dostępnymi zawodnikami zamiast wymuszać błędny skład.
    const quotas = <PlayerPosition, int>{
      PlayerPosition.goalkeeper: 1,
      PlayerPosition.defender: 4,
      PlayerPosition.midfielder: 3,
      PlayerPosition.winger: 2,
      PlayerPosition.striker: 1,
    };

    for (final entry in quotas.entries) {
      final candidates = remaining
          .where((p) => p.position == entry.key)
          .toList()
        ..sort((a, b) => _selectionScore(b).compareTo(_selectionScore(a)));
      final take = min(entry.value, candidates.length);
      for (final player in candidates.take(take)) {
        selected.add(player);
        remaining.remove(player);
      }
    }

    if (selected.length < 11) {
      remaining.sort((a, b) => _selectionScore(b).compareTo(_selectionScore(a)));
      selected.addAll(remaining.take(11 - selected.length));
    }

    return selected.take(11).toList();
  }

  bool _isEligible(PlayerCareer p) {
    if (p.fatigue >= 95 || p.fitness <= 20) return false;
    return true;
  }

  double _selectionScore(PlayerCareer p) {
    var score = p.overall.toDouble();
    score += (p.form - 70) * 0.35;
    score += (p.fitness - 70) * 0.25;
    score += (p.morale - 70) * 0.10;
    score += (p.managerRelationship - 50) * 0.18;
    if (p.fatigue > 65) score -= (p.fatigue - 65) * 0.35;
    if (p.isRegularStarter) score += 1.0;
    return score;
  }

  // ==========================================================
  // MINUTY PODSTAWOWEGO ZAWODNIKA
  // ==========================================================

  int _generateStarterMinutes(
    PlayerCareer player,
  ) {
    if (player.fatigue >= 80) {
      return randomInt(55, 80);
    }

    if (player.fitness <= 50) {
      return randomInt(60, 85);
    }

    return randomInt(80, 95);
  }

  // ==========================================================
  // OCENA ZAWODNIKA
  // ==========================================================

  double _generatePlayerRating(
    PlayerCareer player, {
    required bool teamWon,
    required bool teamDraw,
    required int minutes,
  }) {
    double rating = 6.0;

    rating +=
        (player.overall - 60) * 0.025;

    rating +=
        (player.form - 70) * 0.015;

    rating +=
        (player.fitness - 70) * 0.01;

    if (teamWon) {
      rating += 0.45;
    } else if (teamDraw) {
      rating += 0.10;
    } else {
      rating -= 0.30;
    }

    rating +=
        randomDouble(-0.65, 0.65);

    if (minutes < 30) {
      rating -= 0.15;
    }

    return rating.clamp(4.0, 10.0);
  }

  // ==========================================================
  // PRZYPISANIE GOLI
  // ==========================================================

  void _assignGoals({
    required List<PlayerMatchPerformance> performances,
    required int goals,
    required List<PlayerMatchEvent> events,
    required List<PlayerCareer> players,
  }) {
    if (goals <= 0 || performances.isEmpty) {
      return;
    }

    for (int i = 0; i < goals; i++) {
      final player =
          _selectGoalScorer(performances, players);

      if (player == null) {
        continue;
      }

      final index =
          performances.indexOf(player);

      final updated =
          PlayerMatchPerformance(
        playerId: player.playerId,
        minutes: player.minutes,
        started: player.started,
        rating: (player.rating + 0.20)
            .clamp(0.0, 10.0),
        goals: player.goals + 1,
        assists: player.assists,
        shots: player.shots + 1,
        shotsOnTarget:
            player.shotsOnTarget + 1,
        keyPasses: player.keyPasses,
        successfulDribbles:
            player.successfulDribbles,
        yellowCards:
            player.yellowCards,
        redCards:
            player.redCards,
      );

      performances[index] = updated;

      events.add(
        PlayerMatchEvent(
          playerId: player.playerId,
          minute: randomInt(5, 90),
          type: 'goal',
          rating: updated.rating,
        ),
      );
    }
  }

  // ==========================================================
  // WYBÓR STRZELCA
  // ==========================================================

  PlayerMatchPerformance? _selectGoalScorer(
    List<PlayerMatchPerformance> performances,
    List<PlayerCareer> players,
  ) {
    if (performances.isEmpty) return null;

    final weighted = <PlayerMatchPerformance>[];
    for (final performance in performances) {
      final player = players.firstWhere(
        (p) => p.id == performance.playerId,
        orElse: () => players.first,
      );

      final positionWeight = switch (player.position) {
        PlayerPosition.striker => 8.0,
        PlayerPosition.winger => 5.0,
        PlayerPosition.midfielder => 3.0,
        PlayerPosition.defender => 1.2,
        PlayerPosition.goalkeeper => 0.15,
      };
      final quality = (player.shooting * 0.55 +
              player.overall * 0.25 +
              player.form * 0.12 +
              player.fitness * 0.08) / 100.0;
      final minutesFactor = performance.minutes / 90.0;
      final weight = max(0.05, positionWeight * quality * max(0.35, minutesFactor));
      final count = max(1, (weight * 3).round());
      for (var i = 0; i < count; i++) weighted.add(performance);
    }

    return weighted[_random.nextInt(weighted.length)];
  }

  // ==========================================================
  // PRZYPISANIE ASYST
  // ==========================================================

  void _assignAssists({
    required List<PlayerMatchPerformance> performances,
    required int goals,
  }) {
    if (goals <= 0 ||
        performances.length < 2) {
      return;
    }

    for (int i = 0; i < goals; i++) {
      if (_random.nextDouble() > 0.75) {
        continue;
      }

      final candidates =
          List<PlayerMatchPerformance>.from(
        performances,
      );

      candidates.shuffle(_random);

      final assister =
          candidates.first;

      final index =
          performances.indexOf(assister);

      final updated =
          PlayerMatchPerformance(
        playerId: assister.playerId,
        minutes: assister.minutes,
        started: assister.started,
        rating: (assister.rating + 0.10)
            .clamp(0.0, 10.0),
        goals: assister.goals,
        assists: assister.assists + 1,
        shots: assister.shots,
        shotsOnTarget:
            assister.shotsOnTarget,
        keyPasses:
            assister.keyPasses + 1,
        successfulDribbles:
            assister.successfulDribbles,
        yellowCards:
            assister.yellowCards,
        redCards:
            assister.redCards,
      );

      performances[index] = updated;
    }
  }

  // ==========================================================
  // DODATKOWE STATYSTYKI
  // ==========================================================

  PlayerMatchPerformance _generateAdditionalStats(
    PlayerMatchPerformance performance,
  ) {
    final minutes = performance.minutes;
    if (minutes <= 0) return performance;

    final extraShots = randomInt(0, max(0, (minutes / 18).round()));
    final totalShots = performance.shots + extraShots;
    final extraOnTarget = extraShots == 0
        ? 0
        : randomInt(0, extraShots);
    final totalOnTarget = min(totalShots, performance.shotsOnTarget + extraOnTarget);

    final keyPasses = performance.keyPasses +
        randomInt(0, max(0, (minutes / 25).round()));
    final dribbles = performance.successfulDribbles +
        randomInt(0, max(0, (minutes / 30).round()));
    final yellow = performance.yellowCards +
        (_random.nextDouble() < 0.12 ? 1 : 0);
    final red = performance.redCards +
        (_random.nextDouble() < 0.015 ? 1 : 0);

    return PlayerMatchPerformance(
      playerId: performance.playerId,
      minutes: performance.minutes,
      started: performance.started,
      rating: performance.rating,
      goals: performance.goals,
      assists: performance.assists,
      shots: totalShots,
      shotsOnTarget: totalOnTarget,
      keyPasses: keyPasses,
      successfulDribbles: dribbles,
      yellowCards: yellow,
      redCards: red,
    );
  }

  // ==========================================================
  // STATYSTYKI MECZU
  // ==========================================================

  Map<String, int> _matchStats({
    required MatchSimulationCoreResult coreResult,
    required int homeGoals,
    required int awayGoals,
  }) {
    final homeShots = max(homeGoals + 3,
        (coreResult.homeXg * (4.8 + _random.nextDouble() * 2.4)).round());
    final awayShots = max(awayGoals + 3,
        (coreResult.awayXg * (4.8 + _random.nextDouble() * 2.4)).round());
    final homeShotsOnTarget = min(homeShots,
        max(homeGoals, (homeShots * (0.30 + _random.nextDouble() * 0.18)).round()));
    final awayShotsOnTarget = min(awayShots,
        max(awayGoals, (awayShots * (0.30 + _random.nextDouble() * 0.18)).round()));
    final possessionHome = (50 +
        ((coreResult.homeStrength - coreResult.awayStrength) * .65).round() +
        _random.nextInt(9) - 4).clamp(30, 70).toInt();
    final homeCorners = max(1, (homeShots * (.16 + _random.nextDouble() * .10)).round());
    final awayCorners = max(1, (awayShots * (.16 + _random.nextDouble() * .10)).round());
    final homeFouls = 7 + _random.nextInt(11);
    final awayFouls = 7 + _random.nextInt(11);
    final homeYellow = min(5, (homeFouls * (.12 + _random.nextDouble() * .10)).round());
    final awayYellow = min(5, (awayFouls * (.12 + _random.nextDouble() * .10)).round());
    final homeRed = homeYellow >= 4 && _random.nextDouble() < .08 ? 1 : 0;
    final awayRed = awayYellow >= 4 && _random.nextDouble() < .08 ? 1 : 0;
    return {
      'homeShots': homeShots, 'awayShots': awayShots,
      'homeShotsOnTarget': homeShotsOnTarget, 'awayShotsOnTarget': awayShotsOnTarget,
      'homeCorners': homeCorners, 'awayCorners': awayCorners,
      'homeFouls': homeFouls, 'awayFouls': awayFouls,
      'homeYellowCards': homeYellow, 'awayYellowCards': awayYellow,
      'homeRedCards': homeRed, 'awayRedCards': awayRed,
      'possessionHome': possessionHome,
    };
  }

  // ==========================================================
  // SIŁA DRUŻYNY
  // ==========================================================

  double _calculateStrength(
    Club club,
    bool home,
  ) {
    double strength =
        club.overall.toDouble();

    if (home) {
      strength += 3;
    }

    strength +=
        club.financialHealth * 0.02;

    strength +=
        club.reputation * 0.01;

    strength +=
        _random.nextDouble() * 8 - 4;

    return strength;
  }

  // ==========================================================
  // GENEROWANIE GOLI
  // ==========================================================

  int _generateGoals(
    double strength,
  ) {
    final normalized =
        ((strength - 55) / 20)
            .clamp(0.2, 2.8);

    final chance =
        _random.nextDouble();

    if (chance < 0.10) {
      return 0;
    }

    if (chance < 0.35) {
      return normalized > 1.5 ? 1 : 0;
    }

    if (chance < 0.75) {
      return normalized
          .round()
          .clamp(0, 3);
    }

    if (chance < 0.95) {
      return (normalized + 1)
          .round()
          .clamp(0, 4);
    }

    return (normalized + 2)
        .round()
        .clamp(0, 5);
  }

  // ==========================================================
  // LOSOWA LICZBA
  // ==========================================================

  int randomInt(
    int min,
    int max,
  ) {
    if (max < min) {
      throw ArgumentError(
        'max nie może być mniejsze od min.',
      );
    }

    return min +
        _random.nextInt(
          max - min + 1,
        );
  }

  // ==========================================================
  // LOSOWA LICZBA ZMIENNOPRZECINKOWA
  // ==========================================================

  double randomDouble(
    double min,
    double max,
  ) {
    if (max < min) {
      throw ArgumentError(
        'max nie może być mniejsze od min.',
      );
    }

    return min +
        _random.nextDouble() *
            (max - min);
  }
}
