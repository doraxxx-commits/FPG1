import 'dart:math';

import '../data/world_data.dart';

import '../models/club.dart';
import '../models/fixture.dart';
import '../models/league.dart';
import '../models/match_result.dart';
import '../models/player.dart';
import '../models/player_career.dart';
import '../models/player_contract.dart';

import '../simulation/fixture_generator.dart';
import '../simulation/league_engine.dart';
import '../simulation/match_engine.dart';
import '../simulation/world_engine.dart';
import '../simulation/career_world_bridge.dart';
import '../simulation/world_player_generator.dart';
import '../simulation/market_value_engine.dart';
import '../simulation/career_match_rating_engine.dart';

import 'game_state.dart';
import 'daily_simulation_core.dart';
import 'training_engine.dart';
import '../database/world_save.dart';

class GameEngine {
  final GameState state;

  late final List<League> leagues;
  late final List<Club> clubs;
  late final List<Player> players;

  late final LeagueEngine leagueEngine;
  late final MatchEngine matchEngine;
  late final WorldEngine worldEngine;

  late final List<Fixture> fixtures;

  final TrainingEngine trainingEngine = TrainingEngine();
  late final DailySimulationCore dailySimulationCore;
  final CareerWorldBridge careerWorldBridge = CareerWorldBridge();

  final Random _random = Random();
  final MarketValueEngine marketValueEngine = MarketValueEngine();
  late final CareerMatchRatingEngine careerMatchRatingEngine;

  // Idempotency guard: one fixture may update career statistics only once.
  final Set<String> _processedCareerFixtureKeys = <String>{};

  // P2.2-A — one meaningful career action per simulation day.
  bool _dailyCareerActionConsumed = false;
  String? _dailyCareerAction;

  bool get dailyCareerActionConsumed => _dailyCareerActionConsumed;
  String? get dailyCareerAction => _dailyCareerAction;

  PlayerCareer? careerPlayer;

  // V19.9 — snapshot of the player's real match for the post-match world bridge.
  bool _careerMatchToday = false;
  bool _careerMatchAppeared = false;
  bool _careerMatchStarted = false;
  int _careerMatchMinutes = 0;
  int _careerMatchGoals = 0;
  int _careerMatchAssists = 0;
  double _careerMatchRating = 6.0;
  int _careerMatchHomeGoals = 0;
  int _careerMatchAwayGoals = 0;
  String? _careerMatchClubId;
  bool _careerMatchClubIsHome = false;

  // career_home_screen.dart wywołuje `engine.gameState` (SaveManager),
  // a jedyne pole nazywało się `state` — alias, żeby nie trzeba było
  // przerabiać ekranu ani łamać reszty kodu, który używa `state`.
  GameState get gameState => state;

  /// Gwarantuje, że każdy klub ma pełną kadrę (min. 16 zawodników), zanim
  /// jakikolwiek mecz (2D albo symulowany) spróbuje z niej korzystać.
  /// WorldData dostarcza tylko garstkę testowych piłkarzy — reszta kadry
  /// jest generowana raz, przy starcie nowej gry.
  void _ensureFullSquads() {
    final generator = WorldPlayerGenerator(random: _random);
    for (final club in clubs) {
      final current = players.where((p) => p.clubId == club.id).length;
      if (current >= 16) continue;
      players.addAll(
        generator.generateFirstTeamSquad(
          year: state.year,
          club: club,
          targetSize: 20 - current,
        ),
      );
    }
  }

  // ==========================================================
  // KONSTRUKTOR
  // ==========================================================

  GameEngine({
    GameState? state,
  }) : state = state ?? GameState() {
    dailySimulationCore = DailySimulationCore(state: this.state);
    leagues = WorldData.leagues;
    clubs = WorldData.clubs;
    // Kopia, nie referencja do statycznej listy — WorldData.players ma tylko
    // 2 zaszyte na sztywno testowe rekordy. Bez tego prawie każdy klub miał
    // 0 zawodników, co objawiało się np. "4 kropkami zamiast 22" w meczu 2D.
    players = [...WorldData.players];
    _ensureFullSquads();

    final leagueClubs = clubs
        .where(
          (club) => club.leagueId == 'pol_ek',
        )
        .toList();

    leagueEngine = LeagueEngine(
      clubs: leagueClubs,
    );

    matchEngine = MatchEngine();
    careerMatchRatingEngine = CareerMatchRatingEngine(random: _random);

    worldEngine = WorldEngine(
      clubs: clubs,
      players: players,
      leagues: leagues,
      seasonStartYear: this.state.season,
    );

    fixtures = FixtureGenerator.generateSeasonFixtures(
      leagueClubs,
      seasonStartYear: this.state.season,
    );

    // A new career starts at the season start on the simulation calendar.
    // Never simulate fixtures before the player's simulation start date.
    // The world simulation may catch up its background events, but the
    // player's league must not gain phantom results or points.
    worldEngine.catchUpToDate(
      year: this.state.year,
      month: this.state.month,
      day: this.state.day,
    );
  }

  void _catchUpCareerLeague() {
    final currentDate = DateTime(state.year, state.month, state.day);
    for (final fixture in fixtures) {
      if (fixture.played) continue;
      final fixtureDate = DateTime(fixture.year, fixture.month, fixture.day);
      if (fixtureDate.isAfter(currentDate)) continue;
      playFixture(fixture);
    }
  }

  // ==========================================================
  // TWORZENIE ZAWODNIKA
  // ==========================================================

  void createPlayer({
    required String firstName,
    required String lastName,
    required String nationality,
    required int age,
    required int height,
    required PlayerPosition position,
    required int pace,
    required int shooting,
    required int passing,
    required int dribbling,
    required int defending,
    required int physical,
  }) {
    final player = PlayerCareer(
      id: 'career_player_001',
      firstName: firstName,
      lastName: lastName,
      nationality: nationality,
      age: age,
      height: height,
      position: position,
      overall: 1,
      potential: 85,
      pace: pace,
      shooting: shooting,
      passing: passing,
      dribbling: dribbling,
      defending: defending,
      physical: physical,
    );

    player.refreshOverall();

    careerPlayer = player;
    careerWorldBridge.attach(career: player, worldPlayers: players, clubs: clubs);
    careerWorldBridge.pushCareerState(player);
    marketValueEngine.refreshCareerPlayer(player);
  }

  // ==========================================================
  // PEŁNY ZAPIS / ODCZYT OFFLINE
  // ==========================================================

  /// Serializable snapshot of the career-match transaction state.
  /// This is intentionally kept in GameEngine because it represents transient
  /// state that is not part of PlayerCareer itself.
  Map<String, dynamic> get careerMatchSnapshot => {
    'today': _careerMatchToday,
    'appeared': _careerMatchAppeared,
    'started': _careerMatchStarted,
    'minutes': _careerMatchMinutes,
    'goals': _careerMatchGoals,
    'assists': _careerMatchAssists,
    'rating': _careerMatchRating,
    'homeGoals': _careerMatchHomeGoals,
    'awayGoals': _careerMatchAwayGoals,
    'clubId': _careerMatchClubId,
    'clubIsHome': _careerMatchClubIsHome,
    'processedFixtureKeys': _processedCareerFixtureKeys.toList(),
    'dailyCareerActionConsumed': _dailyCareerActionConsumed,
    'dailyCareerAction': _dailyCareerAction,
  };

  void _restoreCareerMatchSnapshot(dynamic raw) {
    if (raw is! Map) return;
    final m = Map<String, dynamic>.from(raw);
    _careerMatchToday = m['today'] == true;
    _careerMatchAppeared = m['appeared'] == true;
    _careerMatchStarted = m['started'] == true;
    _careerMatchMinutes = (m['minutes'] as num?)?.toInt() ?? 0;
    _careerMatchGoals = (m['goals'] as num?)?.toInt() ?? 0;
    _careerMatchAssists = (m['assists'] as num?)?.toInt() ?? 0;
    _careerMatchRating = (m['rating'] as num?)?.toDouble() ?? 6.0;
    _careerMatchHomeGoals = (m['homeGoals'] as num?)?.toInt() ?? 0;
    _careerMatchAwayGoals = (m['awayGoals'] as num?)?.toInt() ?? 0;
    _careerMatchClubId = m['clubId'] as String?;
    _careerMatchClubIsHome = m['clubIsHome'] == true;
    _processedCareerFixtureKeys
      ..clear()
      ..addAll((m['processedFixtureKeys'] is List)
          ? (m['processedFixtureKeys'] as List).whereType<String>()
          : const <String>[]);
    _dailyCareerActionConsumed = m['dailyCareerActionConsumed'] == true;
    _dailyCareerAction = m['dailyCareerAction'] as String?;
  }

  Future<bool> saveWorld() => WorldSave.save(this);

  Future<bool> loadWorld() async {
    final snapshot = await WorldSave.load();
    if (snapshot == null) return false;
    final rawState = snapshot['gameState'];
    if (rawState is Map) {
      final restored = GameState.fromJson(Map<String, dynamic>.from(rawState));
      state.year = restored.year;
      state.month = restored.month;
      state.day = restored.day;
      state.season = restored.season;
      state.transferWindowSummer = restored.transferWindowSummer;
      state.transferWindowWinter = restored.transferWindowWinter;
    }

    final rawPlayers = snapshot['players'];
    if (rawPlayers is List) {
      // V11 creates and retires real world players. The save therefore has to
      // restore the complete collection, not only mutate players that existed
      // in the original static WorldData list.
      final restoredPlayers = <Player>[];
      for (final p in rawPlayers) {
        if (p is Map) {
          restoredPlayers.add(Player.fromJson(Map<String, dynamic>.from(p)));
        }
      }
      if (restoredPlayers.isNotEmpty) {
        players
          ..clear()
          ..addAll(restoredPlayers);
      }
    }

    final rawClubs = snapshot['clubs'];
    if (rawClubs is List) {
      // Clubs can change league, budget, overall and roster membership over
      // many seasons, so restore the complete collection as well.
      final restoredClubs = <Club>[];
      for (final c in rawClubs) {
        if (c is Map) {
          restoredClubs.add(Club.fromJson(Map<String, dynamic>.from(c)));
        }
      }
      if (restoredClubs.isNotEmpty) {
        clubs
          ..clear()
          ..addAll(restoredClubs);
      }
    }

    final rawFixtures = snapshot['fixtures'];
    if (rawFixtures is List) {
      final byKey = <String, Map<String, dynamic>>{};
      for (final raw in rawFixtures) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          final key = '${m['round']}|${m['homeClubId']}|${m['awayClubId']}';
          byKey[key] = m;
        }
      }
      for (final fixture in fixtures) {
        final key = '${fixture.round}|${fixture.homeClubId}|${fixture.awayClubId}';
        final raw = byKey[key];
        if (raw == null) continue;
        fixture.played = raw['played'] == true;
        fixture.homeGoals = raw['homeGoals'] is num ? (raw['homeGoals'] as num).toInt() : null;
        fixture.awayGoals = raw['awayGoals'] is num ? (raw['awayGoals'] as num).toInt() : null;
        final rawResult = raw['resultSnapshot'];
        fixture.resultSnapshot = rawResult is Map
            ? Map<String, dynamic>.from(rawResult)
            : null;
      }
    }

    final rawWorldEngine = snapshot['worldEngine'];
    if (rawWorldEngine is Map) {
      worldEngine.restoreFromJson(Map<String, dynamic>.from(rawWorldEngine));
    }

    // Fixtures are authoritative for the league table. This also migrates
    // older saves that had players/clubs but no persisted standings.
    rebuildLeagueFromFixtures();

    _restoreCareerMatchSnapshot(snapshot['careerMatchSnapshot']);

    final rawCareer = snapshot['careerPlayer'];
    if (rawCareer is Map) {
      careerPlayer = PlayerCareer.fromJson(Map<String, dynamic>.from(rawCareer));
      careerWorldBridge.attach(career: careerPlayer!, worldPlayers: players, clubs: clubs);
      careerWorldBridge.pushCareerState(careerPlayer!);
    }
    return true;
  }

  // ==========================================================
  // NASTĘPNY DZIEŃ / METODA COMPATIBILITY FOR UI
  // ==========================================================

  void nextDay() {
    advanceDay();
  }

  /// DEV: advances only the autonomous football world. The player's career
  /// match is deliberately NOT played, so this can be used to stress-test
  /// transfers, managers, values and world events without cheating the
  /// player's calendar.
  int simulateWorldOnlyDays(int days) {
    final count = days.clamp(1, 365);
    for (var i = 0; i < count; i++) {
      state.nextDay();
      worldEngine.processDay(
        year: state.year,
        month: state.month,
        day: state.day,
        summerTransferWindow: summerTransferWindow,
        winterTransferWindow: winterTransferWindow,
      );
    }
    return count;
  }

  /// V25: every simulation day enters through one central coordinator.
  ///
  /// The coordinator owns causal order; specialist engines still own the
  /// actual football/world rules.
  DailySimulationReport advanceDay() {
    // The previous day is committed before the calendar advances. This makes
    // training/match actions exclusive to their calendar day.
    _dailyCareerActionConsumed = false;
    _dailyCareerAction = null;
    return dailySimulationCore.runDay(
      recoverPlayer: recoverPlayer,
      updatePlayerForm: updatePlayerForm,
      updateCareerPlayerMatchStatus: updateCareerPlayerMatchStatus,
      resetCareerMatchSnapshot: _resetCareerMatchSnapshot,
      playCareerMatches: () {
        playMatchesForToday();
        return fixtures.where((f) =>
            f.played &&
            f.year == state.year &&
            f.month == state.month &&
            f.day == state.day).length;
      },
      pushCareerStateBeforeWorld: () {
        if (careerPlayer == null) return;
        careerWorldBridge.attach(
          career: careerPlayer!,
          worldPlayers: players,
          clubs: clubs,
        );
        careerWorldBridge.pushCareerState(careerPlayer!);
      },
      processWorldDay: ({
        required int year,
        required int month,
        required int day,
        required bool summerTransferWindow,
        required bool winterTransferWindow,
      }) {
        worldEngine.processDay(
          year: year,
          month: month,
          day: day,
          summerTransferWindow: summerTransferWindow,
          winterTransferWindow: winterTransferWindow,
        );
      },
      applyCareerMatchConsequences: () {
        if (careerPlayer != null && _careerMatchToday) {
          worldEngine.processCareerMatchConsequences(
            career: careerPlayer!,
            year: state.year,
            month: state.month,
            day: state.day,
            homeGoals: _careerMatchHomeGoals,
            awayGoals: _careerMatchAwayGoals,
            playerClubIsHome: _careerMatchClubIsHome,
            appeared: _careerMatchAppeared,
            started: _careerMatchStarted,
            minutes: _careerMatchMinutes,
            rating: _careerMatchRating,
            goals: _careerMatchGoals,
            assists: _careerMatchAssists,
          );
        }
      },
      pullCareerStateAfterWorld: () {
        if (careerPlayer != null) {
          careerWorldBridge.pullWorldState(
            careerPlayer!,
            worldPlayers: players,
            clubs: clubs,
          );
        }
      },
      advanceSeasonIfComplete: () {
        if (!leagueEngine.isSeasonComplete()) return false;

        // A double-round league can finish before the football season's
        // calendar boundary (the return leg currently ends in spring).
        // Do not generate the next season while the calendar is still in
        // the old campaign: doing so would create July fixtures in the past
        // and leave the new season unreachable by exact-date simulation.
        // The transition is committed on/after 30 June, immediately before
        // GameState rolls into the next season on 1 July.
        final calendarEnd = DateTime(state.year, 6, 30);
        final currentDate = DateTime(state.year, state.month, state.day);
        if (currentDate.isBefore(calendarEnd)) return false;

        _advanceSeason();
        return true;
      },
    );
  }

  int _calculateCareerPlayerGoals({required PlayerCareer player, required MatchResult result, required bool playerClubIsHome, required int minutes}) {
    final teamGoals = playerClubIsHome ? result.homeGoals : result.awayGoals;
    if (teamGoals <= 0 || minutes <= 0) return 0;
    final share = switch (player.position) {
      PlayerPosition.striker => 0.38,
      PlayerPosition.winger => 0.24,
      PlayerPosition.midfielder => 0.12,
      PlayerPosition.defender => 0.04,
      PlayerPosition.goalkeeper => 0.005,
    };
    var goals = 0;
    for (var i = 0; i < teamGoals; i++) { if (_random.nextDouble() < share * (minutes / 90)) goals++; }
    return goals.clamp(0, teamGoals);
  }

  int _calculateCareerPlayerAssists({required PlayerCareer player, required MatchResult result, required bool playerClubIsHome, required int minutes}) {
    final teamGoals = playerClubIsHome ? result.homeGoals : result.awayGoals;
    if (teamGoals <= 0 || minutes <= 0) return 0;
    final share = switch (player.position) {
      PlayerPosition.striker => 0.12,
      PlayerPosition.winger => 0.28,
      PlayerPosition.midfielder => 0.34,
      PlayerPosition.defender => 0.08,
      PlayerPosition.goalkeeper => 0.01,
    };
    var assists = 0;
    for (var i = 0; i < teamGoals; i++) { if (_random.nextDouble() < share * (minutes / 90)) assists++; }
    return assists.clamp(0, teamGoals);
  }

  // ==========================================================
  // PRZEJŚCIE DO NOWEGO SEZONU
  // ==========================================================

  void _advanceSeason() {
    // Świat ma własny cykl rozwoju, starzenia, kontraktów, finansów
    // i emerytur. GameEngine tylko go uruchamia.
    worldEngine.processEndOfSeason(nextSeasonStartYear: state.year);

    // Starzenie gracza kariery
    if (careerPlayer != null) {
      careerPlayer!.age += 1;
    }

    // 3. Reset tabeli i wygenerowanie nowego terminarza
    final leagueClubs = clubs
        .where(
          (club) => club.leagueId == 'pol_ek',
        )
        .toList();

    fixtures = FixtureGenerator.generateSeasonFixtures(
      leagueClubs,
      seasonStartYear: state.year,
    );
    leagueEngine.resetSeason();
  }

  // ==========================================================
  // INFORMACJE O UDZIALE ZAWODNIKA W MECZU
  // ==========================================================

  bool get careerPlayerCanPlay {
    if (careerPlayer == null) {
      return false;
    }

    final player = careerPlayer!;

    // Bez klubu nie można grać.
    if (player.clubId == null) {
      return false;
    }

    // Aktualizacja decyzji trenera.
    player.updateMatchStatus();

    return player.canPlayMatch;
  }

  // ==========================================================
  // CZY ZAWODNIK JEST W KADRZE MECZOWEJ
  // ==========================================================

  bool get careerPlayerInMatchSquad {
    if (careerPlayer == null) {
      return false;
    }

    return careerPlayer!.inMatchSquad;
  }

  // ==========================================================
  // CZY ZAWODNIK JEST W PODSTAWOWYM SKŁADZIE
  // ==========================================================

  bool get careerPlayerIsStarter {
    if (careerPlayer == null) {
      return false;
    }

    return careerPlayer!.isRegularStarter;
  }

  // ==========================================================
  // STATUS MECZOWY ZAWODNIKA
  // ==========================================================

  String get careerPlayerMatchStatus {
    if (careerPlayer == null) {
      return 'Brak zawodnika';
    }

    return careerPlayer!.squadStatus;
  }

  // ==========================================================
  // WYSTĘP ZAWODNIKA W MECZU
  // ==========================================================

  void processCareerPlayerMatch({
    required Fixture fixture,
    required MatchResult result,
  }) {
    if (careerPlayer == null) return;

    final player = careerPlayer!;
    if (player.clubId == null) return;

    final playerClubIsHome = fixture.homeClubId == player.clubId;
    final playerClubIsAway = fixture.awayClubId == player.clubId;
    if (!playerClubIsHome && !playerClubIsAway) return;

    final fixtureKey = '${fixture.round}|${fixture.homeClubId}|${fixture.awayClubId}|${fixture.year}-${fixture.month}-${fixture.day}';
    // Hard idempotency guard. Save/Load also persists this set.
    if (!_processedCareerFixtureKeys.add(fixtureKey)) {
      return;
    }

    _careerMatchToday = true;
    _dailyCareerActionConsumed = true;
    _dailyCareerAction = 'match';
    _careerMatchClubId = player.clubId;
    _careerMatchClubIsHome = playerClubIsHome;
    _careerMatchHomeGoals = result.homeGoals;
    _careerMatchAwayGoals = result.awayGoals;

    player.updateMatchStatus();
    if (!player.canPlayMatch) return;

    bool started = player.isStarter;
    int minutes = 0;
    if (started) {
      minutes = _random.nextInt(100) < 75 ? 90 : 60 + _random.nextInt(30);
    } else if (player.inMatchSquad && _random.nextInt(100) < 60) {
      final substitutionMinute = 55 + _random.nextInt(26);
      minutes = max(10, 90 - substitutionMinute);
    }
    if (minutes <= 0) return;

    final goals = _calculateCareerPlayerGoals(
      player: player, result: result, playerClubIsHome: playerClubIsHome, minutes: minutes);
    final assists = _calculateCareerPlayerAssists(
      player: player, result: result, playerClubIsHome: playerClubIsHome, minutes: minutes);

    final rating = careerMatchRatingEngine.calculate(
      player: player, result: result, playerClubIsHome: playerClubIsHome,
      started: started, minutes: minutes, goals: goals, assists: assists);

    final teamShots = playerClubIsHome ? result.homeShots : result.awayShots;
    final teamOnTarget = playerClubIsHome ? result.homeShotsOnTarget : result.awayShotsOnTarget;
    final shotShare = player.position == PlayerPosition.striker
        ? 0.28 : player.position == PlayerPosition.winger
            ? 0.20 : player.position == PlayerPosition.midfielder
                ? 0.13 : player.position == PlayerPosition.defender ? 0.06 : 0.02;
    final expectedShots = max(0, (teamShots * shotShare * minutes / 90).round());
    final shots = max(goals, expectedShots);
    final shotsOnTarget = min(shots, max(goals, (shots * (teamShots == 0 ? 0.35 : teamOnTarget / teamShots)).round()));
    final keyPassesShare = player.position == PlayerPosition.midfielder || player.position == PlayerPosition.winger ? 0.10 : 0.04;
    final keyPasses = (result.totalGoals * keyPassesShare * minutes / 90).round() + (assists > 0 ? assists : 0);
    final dribbleShare = player.position == PlayerPosition.winger || player.position == PlayerPosition.striker ? 0.08 : 0.03;
    final dribbles = (minutes * dribbleShare).round();
    final yellow = _random.nextDouble() < (minutes / 90) * 0.10 ? 1 : 0;
    final red = yellow == 1 && _random.nextDouble() < 0.015 ? 1 : 0;

    _careerMatchAppeared = true;
    _careerMatchStarted = started;
    _careerMatchMinutes = minutes;
    _careerMatchRating = rating;
    _careerMatchGoals = goals;
    _careerMatchAssists = assists;

    player.addCareerAppearance(minutes: minutes, started: started, rating: rating);
    for (var i = 0; i < goals; i++) player.addCareerGoal();
    for (var i = 0; i < assists; i++) player.addCareerAssist();
    player.matchStats.shots += shots.round();
    player.matchStats.shotsOnTarget += shotsOnTarget.round();
    player.matchStats.keyPasses += max(0, keyPasses).round();
    player.matchStats.successfulDribbles += max(0, dribbles).round();
    player.matchStats.yellowCards += yellow;
    player.matchStats.redCards += red;

    final matchFatigue = started ? 25 + ((minutes - 60) ~/ 6) : 8 + (minutes ~/ 5);
    player.fatigue = (player.fatigue + matchFatigue).clamp(0, 100);
    player.fitness = (player.fitness - matchFatigue).clamp(0, 100);

    if (rating >= 7.5) {
      player.form = (player.form + 3).clamp(0, 100);
    } else if (rating >= 7.0) {
      player.form = (player.form + 2).clamp(0, 100);
    } else if (rating < 5.5) {
      player.form = (player.form - 2).clamp(0, 100);
    } else if (rating < 6.0) {
      player.form = (player.form - 1).clamp(0, 100);
    }
  }

  void _resetCareerMatchSnapshot() {
    _careerMatchToday = false;
    _careerMatchAppeared = false;
    _careerMatchStarted = false;
    _careerMatchMinutes = 0;
    _careerMatchGoals = 0;
    _careerMatchAssists = 0;
    _careerMatchRating = 6.0;
    _careerMatchHomeGoals = 0;
    _careerMatchAwayGoals = 0;
    _careerMatchClubId = null;
    _careerMatchClubIsHome = false;
  }

  void playMatchesForToday() {
    completeFixturesForDate(state.year, state.month, state.day);
  }

  /// Generates the official pre-match target without committing the fixture.
  /// Interactive 2D matches use this preview so the final score is committed
  /// only when the match actually finishes. This keeps table/statistics/save
  /// state transactional and prevents a half-played match from counting.
  MatchResult previewFixture(Fixture fixture) {
    if (fixture.played) {
      final stored = fixture.storedResult;
      if (stored != null) return stored;
      if (fixture.homeGoals == null || fixture.awayGoals == null) {
        throw StateError('Played fixture ${fixture.homeClubId}-${fixture.awayClubId} has no score.');
      }
      return MatchResult(
        homeClubId: fixture.homeClubId,
        awayClubId: fixture.awayClubId,
        homeGoals: fixture.homeGoals!,
        awayGoals: fixture.awayGoals!,
      );
    }
    final home = clubs.firstWhere((club) => club.id == fixture.homeClubId);
    final away = clubs.firstWhere((club) => club.id == fixture.awayClubId);
    return matchEngine.simulate(home: home, away: away);
  }

  MatchResult playFixture(Fixture fixture) {
    // A fixture is a transaction: once it is completed it must never be
    // simulated/recorded a second time. This is the central guard that keeps
    // Match Screen, Table, World Tick and Save/Load on the same timeline.
    if (fixture.played) {
      if (fixture.homeGoals == null || fixture.awayGoals == null) {
        throw StateError('Played fixture ${fixture.homeClubId}-${fixture.awayClubId} has no score.');
      }
      final stored = fixture.storedResult;
      if (stored != null) return stored;
      return MatchResult(
        homeClubId: fixture.homeClubId,
        awayClubId: fixture.awayClubId,
        homeGoals: fixture.homeGoals!,
        awayGoals: fixture.awayGoals!,
      );
    }

    final home = clubs.firstWhere((club) => club.id == fixture.homeClubId);
    final away = clubs.firstWhere((club) => club.id == fixture.awayClubId);
    final result = matchEngine.simulate(home: home, away: away);

    fixture.played = true;
    fixture.homeGoals = result.homeGoals;
    fixture.awayGoals = result.awayGoals;
    fixture.storeResult(result);

    leagueEngine.recordMatch(
      homeClubId: result.homeClubId,
      awayClubId: result.awayClubId,
      homeGoals: result.homeGoals,
      awayGoals: result.awayGoals,
    );

    processCareerPlayerMatch(fixture: fixture, result: result);
    if (!validateLeagueIntegrity()) {
      throw StateError('League integrity failed after fixture completion.');
    }
    return result;
  }

  /// Completes every unplayed fixture scheduled for one exact calendar day.
  /// This is intentionally the only bulk-match entry point used by day flow.
  int completeFixturesForDate(int year, int month, int day) {
    var completed = 0;
    final todays = fixtures.where((f) =>
        !f.played && f.year == year && f.month == month && f.day == day).toList();
    for (final fixture in todays) {
      playFixture(fixture);
      completed++;
    }
    return completed;
  }


  /// Applies the final score produced by the interactive match layer.
  /// The fixture was already recorded with the pre-match estimate so the
  /// rest of the world can use one source of truth; this method reconciles
  /// the table once the player has finished the match.
  void reconcileInteractiveFixtureResult({
    required Fixture fixture,
    required int finalHomeGoals,
    required int finalAwayGoals,
  }) {
    if (fixture.played &&
        fixture.homeGoals == finalHomeGoals &&
        fixture.awayGoals == finalAwayGoals) {
      return;
    }

    final wasPlayed = fixture.played;
    final oldHome = fixture.homeGoals;
    final oldAway = fixture.awayGoals;

    fixture.played = true;
    fixture.homeGoals = finalHomeGoals;
    fixture.awayGoals = finalAwayGoals;
    final stored = fixture.storedResult;
    fixture.storeResult(MatchResult(
      homeClubId: stored?.homeClubId ?? fixture.homeClubId,
      awayClubId: stored?.awayClubId ?? fixture.awayClubId,
      homeGoals: finalHomeGoals,
      awayGoals: finalAwayGoals,
      events: stored?.events ?? const [],
      playerPerformances: stored?.playerPerformances ?? const [],
      homeShots: stored?.homeShots ?? 0,
      awayShots: stored?.awayShots ?? 0,
      homeShotsOnTarget: stored?.homeShotsOnTarget ?? 0,
      awayShotsOnTarget: stored?.awayShotsOnTarget ?? 0,
      homeCorners: stored?.homeCorners ?? 0,
      awayCorners: stored?.awayCorners ?? 0,
      homeFouls: stored?.homeFouls ?? 0,
      awayFouls: stored?.awayFouls ?? 0,
      homeYellowCards: stored?.homeYellowCards ?? 0,
      awayYellowCards: stored?.awayYellowCards ?? 0,
      homeRedCards: stored?.homeRedCards ?? 0,
      awayRedCards: stored?.awayRedCards ?? 0,
      possessionHome: stored?.possessionHome ?? 50,
    ));

    if (wasPlayed) {
      leagueEngine.replaceMatch(
        homeClubId: fixture.homeClubId,
        awayClubId: fixture.awayClubId,
        oldHomeGoals: oldHome ?? 0,
        oldAwayGoals: oldAway ?? 0,
        newHomeGoals: finalHomeGoals,
        newAwayGoals: finalAwayGoals,
      );
    } else {
      leagueEngine.recordMatch(
        homeClubId: fixture.homeClubId,
        awayClubId: fixture.awayClubId,
        homeGoals: finalHomeGoals,
        awayGoals: finalAwayGoals,
      );
      // Career statistics are committed exactly once, using the final
      // interactive result rather than the pre-match preview.
      processCareerPlayerMatch(
        fixture: fixture,
        result: fixture.storedResult!,
      );
    }

    if (!validateLeagueIntegrity()) {
      throw StateError('League integrity failed after interactive fixture reconciliation.');
    }
  }

  /// Cheap runtime invariant check used after every league mutation. It
  /// catches the exact class of bugs where a fixture says one thing while the
  /// table says another. It never mutates state.
  bool validateLeagueIntegrity() {
    final expected = <String, List<int>>{};
    for (final c in leagueEngine.clubs) {
      expected[c.id] = [0, 0, 0, 0, 0, 0];
    }
    for (final f in fixtures) {
      if (!f.played || f.homeGoals == null || f.awayGoals == null) continue;
      final h = expected[f.homeClubId];
      final a = expected[f.awayClubId];
      if (h == null || a == null) continue;
      h[0]++; a[0]++; h[1] += f.homeGoals!; h[2] += f.awayGoals!;
      a[1] += f.awayGoals!; a[2] += f.homeGoals!;
      if (f.homeGoals! > f.awayGoals!) { h[3]++; a[5]++; }
      else if (f.homeGoals! < f.awayGoals!) { a[3]++; h[5]++; }
      else { h[4]++; a[4]++; }
    }
    for (final e in expected.entries) {
      final s = leagueEngine.standings[e.key];
      if (s == null) return false;
      final x = e.value;
      if (s.played != x[0] || s.goalsFor != x[1] || s.goalsAgainst != x[2] ||
          s.wins != x[3] || s.draws != x[4] || s.losses != x[5]) return false;
    }
    return true;
  }

  /// Rebuilds the league table from persisted fixtures. This is the single
  /// source of truth after loading a save and prevents a table/fixture split.
  void rebuildLeagueFromFixtures() {
    leagueEngine.resetSeason();
    for (final fixture in fixtures) {
      if (!fixture.played) continue;
      final hg = fixture.homeGoals;
      final ag = fixture.awayGoals;
      if (hg == null || ag == null) continue;
      leagueEngine.recordMatch(
        homeClubId: fixture.homeClubId,
        awayClubId: fixture.awayClubId,
        homeGoals: hg,
        awayGoals: ag,
      );
    }
  }

  // ==========================================================
  // TRENING
  // ==========================================================

  TrainingResult trainPlayer(
    TrainingType type,
  ) {
    if (careerPlayer == null) {
      throw StateError(
        'Brak aktywnego zawodnika.',
      );
    }

    final player = careerPlayer!;

    if (_dailyCareerActionConsumed) {
      throw StateError(
        'Dzisiejsza akcja kariery została już wykonana. Przejdź do następnego dnia.',
      );
    }

    if (careerHasMatchToday) {
      throw StateError(
        'Dzisiaj jest mecz. Trening możesz wykonać w dniu bez spotkania.',
      );
    }

    if (player.fatigue >= 90) {
      throw StateError(
        'Zawodnik jest zbyt zmęczony na kolejny trening.',
      );
    }

    final result = trainingEngine.train(
      player,
      type,
    );

    player.fatigue = (
      player.fatigue + result.fatigue
    ).clamp(0, 100);

    player.fitness = (
      player.fitness - result.fatigue
    ).clamp(0, 100);

    player.refreshOverall();

    // Dobry trening wpływa na zaufanie trenera.
    player.rewardTrainingTrust();
    _dailyCareerActionConsumed = true;
    _dailyCareerAction = 'training';

    return result;
  }

  // ==========================================================
  // REGENERACJA
  // ==========================================================

  void recoverPlayer() {
    if (careerPlayer == null) {
      return;
    }

    final player = careerPlayer!;

    final recovery = player.fatigue >= 70
        ? 5
        : player.fatigue >= 40
            ? 8
            : 10;

    player.fatigue = (
      player.fatigue - recovery
    ).clamp(0, 100);

    player.fitness = (
      player.fitness + recovery
    ).clamp(0, 100);
  }

  // ==========================================================
  // FORMA ZAWODNIKA
  // ==========================================================

  void updatePlayerForm() {
    if (careerPlayer == null) {
      return;
    }

    final player = careerPlayer!;

    if (player.fatigue >= 80) {
      player.form = (
        player.form - 2
      ).clamp(0, 100);
    } else if (player.fatigue >= 60) {
      player.form = (
        player.form - 1
      ).clamp(0, 100);
    } else if (player.fatigue <= 25) {
      player.form = (
        player.form + 1
      ).clamp(0, 100);
    }
  }

  // ==========================================================
  // DECYZJA TRENERA O STATUSIE ZAWODNIKA
  // ==========================================================

  void updateCareerPlayerMatchStatus() {
    if (careerPlayer == null) {
      return;
    }

    final player = careerPlayer!;

    // Jeżeli zawodnik nie ma klubu, nie może być wybierany do kadry.
    if (player.clubId == null) {
      player.inMatchSquad = false;
      player.isStarter = false;
      player.squadStatus = 'Bez klubu';
      return;
    }

    player.updateMatchStatus();

    if (!player.canPlayMatch) {
      player.isStarter = false;
    }
  }

  // ==========================================================
  // PRZYPISANIE DO KLUBU
  // ==========================================================

  void assignPlayerToClub(
    String clubId,
  ) {
    if (careerPlayer == null) {
      throw StateError(
        'Najpierw utwórz zawodnika.',
      );
    }

    final club = clubs.firstWhere(
      (club) => club.id == clubId,
    );

    final player = careerPlayer!;

    player.clubId = clubId;

    player.shirtNumber = 27;

    player.managerRelationship = 50;

    player.updateMatchStatus();

    final marketValue =
        calculateStartingMarketValue(
      player,
      club,
    );

    final salary =
        calculateStartingSalary(
      player,
      club,
    );

    player.contract = PlayerContract(
      clubId: club.id,
      yearsRemaining: 3,
      weeklySalary: salary,
      marketValue: marketValue,
      squadNumber: player.shirtNumber,
      squadStatus: player.squadStatus,
      managerTrust: player.managerRelationship,
    );
  }

  // ==========================================================
  // WARTOŚĆ POCZĄTKOWA ZAWODNIKA
  // ==========================================================

  double calculateStartingMarketValue(
    PlayerCareer player,
    Club club,
  ) {
    final ageFactor = player.age <= 21
        ? 1.25
        : player.age <= 25
            ? 1.10
            : 0.90;

    final potentialFactor =
        player.potential / 70;

    final clubFactor =
        club.overall / 70;

    return 250000 *
        player.overall *
        ageFactor *
        potentialFactor *
        clubFactor;
  }

  // ==========================================================
  // PENSJA POCZĄTKOWA
  // ==========================================================

  double calculateStartingSalary(
    PlayerCareer player,
    Club club,
  ) {
    const baseSalary = 150.0;

    final overallFactor =
        player.overall / 50;

    final clubFactor =
        club.overall / 70;

    return baseSalary *
        overallFactor *
        clubFactor;
  }

  // ==========================================================
  // TERMINARZ
  // ==========================================================

  List<Fixture> get todayFixtures {
    return fixtures.where(
      (fixture) =>
          fixture.year == state.year &&
          fixture.month == state.month &&
          fixture.day == state.day,
    ).toList();
  }

  List<Fixture> get playedFixtures {
    return fixtures.where(
      (fixture) => fixture.played,
    ).toList();
  }

  List<Fixture> get upcomingFixtures {
    return fixtures.where(
      (fixture) => !fixture.played,
    ).toList();
  }

  /// Najbliższy nierozegrany mecz zawodnika, niezależnie od tego czy
  /// przypada dzisiaj czy za kilka dni. UI używa tego do pokazania
  /// prawdziwego następnego spotkania zamiast sztucznego przycisku meczu.
  Fixture? get nextCareerFixture {
    final clubId = careerPlayer?.clubId;
    if (clubId == null) return null;
    final now = DateTime(state.year, state.month, state.day);
    final matches = fixtures.where((f) {
      if (f.played) return false;
      if (f.homeClubId != clubId && f.awayClubId != clubId) return false;
      return !DateTime(f.year, f.month, f.day).isBefore(now);
    }).toList();
    matches.sort((a, b) => DateTime(a.year, a.month, a.day)
        .compareTo(DateTime(b.year, b.month, b.day)));
    return matches.isEmpty ? null : matches.first;
  }

  bool get careerHasMatchToday {
    final clubId = careerPlayer?.clubId;
    if (clubId == null) return false;
    return fixtures.any((f) => !f.played &&
        f.year == state.year && f.month == state.month && f.day == state.day &&
        (f.homeClubId == clubId || f.awayClubId == clubId));
  }

  // ==========================================================
  // DATA
  // ==========================================================

  /// The football calendar is controlled exclusively by player actions.
  /// Device clock / wall-clock time never advances the career.
  bool get isSimulationStart =>
      state.year == state.season && state.month == 7 && state.day == 24;

  /// Advances exactly one in-game day. This is the only normal way to move
  /// the career calendar forward; finishing a match does not consume a day.
  void advanceSimulationDay() => advanceDay();

  String get currentDate {
    return state.dateString;
  }

  // ==========================================================
  // SEZON
  // ==========================================================

  int get currentSeason {
    return state.season;
  }

  // ==========================================================
  // OKNO TRANSFEROWE - LATO
  // ==========================================================

  int get currentAbsoluteDay => worldEngine.absoluteDayForDate(state.year, state.month, state.day);

  bool get summerTransferWindow {
    return state.transferWindowSummer;
  }

  // ==========================================================
  // OKNO TRANSFEROWE - ZIMA
  // ==========================================================

  bool get winterTransferWindow {
    return state.transferWindowWinter;
  }

  // ==========================================================
  // KLUBY EKSTRAKLASY
  // ==========================================================

  List<Club> get leagueClubs {
    return clubs
        .where(
          (club) => club.leagueId == 'pol_ek',
        )
        .toList();
  }

  // ==========================================================
  // KLUBY DOSTĘPNE NA START KARIERY
  // ==========================================================

  List<Club> get careerStartClubs {
    return clubs
        .where(
          (club) => club.leagueId == 'pol_ek',
        )
        .toList();
  }

  // ==========================================================
  // WYBÓR KLUBU NA START KARIERY
  // ==========================================================

  void startCareerAtClub(
    String clubId,
  ) {
    if (careerPlayer == null) {
      throw StateError(
        'Najpierw utwórz zawodnika.',
      );
    }

    assignPlayerToClub(clubId);
  }

  // ==========================================================
  // AKTUALNY KLUB ZAWODNIKA
  // ==========================================================

  Club? get careerClub {
    if (careerPlayer == null) {
      return null;
    }

    final clubId = careerPlayer!.clubId;

    if (clubId == null) {
      return null;
    }

    for (final club in clubs) {
      if (club.id == clubId) {
        return club;
      }
    }

    return null;
  }

  // ==========================================================
  // CZY ZAWODNIK MA KLUB
  // ==========================================================

  bool get hasCareerClub {
    return careerPlayer?.clubId != null;
  }
}
