import 'dart:math';

import '../models/club.dart';
import '../models/league.dart';
import '../models/match_result.dart';
import '../models/world_event.dart';
import '../models/player.dart';
import 'injury_engine.dart';
import 'global_match_engine.dart';
import 'fixture_generator.dart';
import '../models/fixture.dart';
import '../models/standing.dart';
import 'squad_ai_engine.dart';
import 'development_engine.dart';
import 'finance_engine.dart';
import 'contract_engine.dart';
import 'retirement_engine.dart';
import 'club_ai_engine.dart';
import 'transfer_engine.dart';
import 'world_event_engine.dart';
import 'manager_world_engine.dart';
import 'world_history_engine.dart';
import 'world_simulation_4_engine.dart';
import 'world_player_generator.dart';
import 'youth_scouting_engine.dart';
import 'youth_career_engine.dart';
import 'youth_career_progression_engine.dart';
import 'academy_evolution_engine.dart';
import 'living_world_engine.dart';
import 'world_causality_engine.dart';
import 'social_world_engine.dart';
import 'media_world_engine.dart';
import 'player_fame_engine.dart';
import 'player_career_consequences_engine.dart';
import 'contract_dynamics_engine.dart';
import 'career_event_consequences_engine.dart';
import 'career_storyline_engine.dart';
import 'relationship_web_engine.dart';
import 'relationship_consequences_engine.dart';
import 'relationship_actions_engine.dart';
import 'relationship_events_engine.dart';
import 'career_consequence_engine_v2.dart';
import 'match_narrative_chain_engine.dart';
import '../models/player_career.dart';
import 'market_value_engine.dart';
import 'world_integrity_validator.dart';
import 'squad_depth_engine.dart';

/// Główny koordynator symulacji świata FPG.
///
/// Ten silnik nie steruje UI ani karierą gracza. Jego zadaniem jest
/// sprawić, aby świat AI rozwijał się niezależnie od tego, co robi gracz.
class WorldEngine {
  final int seasonStartYear;
  final List<Club> clubs;
  final List<Player> players;
  final List<League> leagues;
  final Random _random;
  late final SquadAIEngine squadAI;
  late final InjuryEngine injuryEngine;
  late final GlobalMatchEngine globalMatchEngine;
  late final DevelopmentEngine developmentEngine;
  late final FinanceEngine financeEngine;
  late final ContractEngine contractEngine;
  late final RetirementEngine retirementEngine;
  late final ClubAIEngine clubAIEngine;
  late final TransferEngine transferEngine;
  late final WorldEventEngine worldEventEngine;
  late final ManagerWorldEngine managerWorldEngine;
  late final WorldHistoryEngine worldHistoryEngine;
  late final WorldSimulation4Engine worldSimulation4Engine;
  late final WorldPlayerGenerator worldPlayerGenerator;
  late final YouthScoutingEngine youthScoutingEngine;
  late final YouthCareerEngine youthCareerEngine;
  late final YouthCareerProgressionEngine youthCareerProgressionEngine;
  late final AcademyEvolutionEngine academyEvolutionEngine;
  late final LivingWorldEngine livingWorldEngine;
  late final WorldCausalityEngine worldCausalityEngine;
  late final SocialWorldEngine socialWorldEngine;
  late final MediaWorldEngine mediaWorldEngine;
  late final PlayerFameEngine playerFameEngine;
  late final PlayerCareerConsequencesEngine playerCareerConsequencesEngine;
  late final ContractDynamicsEngine contractDynamicsEngine;
  late final CareerEventConsequencesEngine careerEventConsequencesEngine;
  late final CareerStorylineEngine careerStorylineEngine;
  late final RelationshipWebEngine relationshipWebEngine;
  late final RelationshipConsequencesEngine relationshipConsequencesEngine;
  late final RelationshipActionsEngine relationshipActionsEngine;
  late final RelationshipEventsEngine relationshipEventsEngine;
  late final CareerConsequenceEngineV2 careerConsequenceEngineV2;
  late final MatchNarrativeChainEngine matchNarrativeChainEngine;
  late final MarketValueEngine marketValueEngine;
  final Map<String, List<Fixture>> fixturesByLeague = {};
  final Map<String, Map<String, Standing>> standingsByLeague = {};

  /// Events generated during the most recent world tick. UI/news layers can
  /// consume these without inventing a second, unrelated universe.
  final List<WorldEvent> lastDayEvents = [];

  /// Official autonomous match results produced during the most recent
  /// world tick. MatchResult is the single source of truth for tables,
  /// player form and future News/FPG Social layers.
  final List<MatchResult> lastDayMatchResults = [];

  /// V19.9: career match consequences survive save/load and are applied only once.


  /// Trwała pamięć świata używana przez News/UI. Ostatnie 500 wydarzeń jest
  /// przechowywane, aby świat miał historię także po przejściu wielu dni.
  final List<WorldEvent> worldEventHistory = [];

  List<WorldEvent> get recentWorldEvents =>
      List.unmodifiable(worldEventEngine.recentEvents);

  /// Read-only diagnostic information about the last simulated day.
  /// Useful for the future News/FPG Social layer and for automated tests.
  Map<String, int> get lastDaySummary => {
    'matches': lastDayMatchResults.length,
    'events': lastDayEvents.length,
    'goals': lastDayMatchResults.fold<int>(
      0, (sum, result) => sum + result.homeGoals + result.awayGoals,
    ),
  };

  /// Persistent snapshot of the autonomous competition layer. Match results
  /// themselves are derived from played fixtures; standings are persisted so
  /// loading a save never re-simulates an already played match.
  Map<String, dynamic> toJson() {
    return {
      'fixturesByLeague': {
        for (final entry in fixturesByLeague.entries)
          entry.key: entry.value.map((f) => {
                'round': f.round,
                'homeClubId': f.homeClubId,
                'awayClubId': f.awayClubId,
                'year': f.year,
                'month': f.month,
                'day': f.day,
                'played': f.played,
                'homeGoals': f.homeGoals,
                'awayGoals': f.awayGoals,
              }).toList(),
      },
      'worldEventHistory': worldEventHistory.map((e) => {
        'year': e.year, 'month': e.month, 'day': e.day, 'type': e.type,
        'title': e.title, 'description': e.description, 'clubId': e.clubId,
        'playerId': e.playerId, 'importance': e.importance,
      }).toList(),
      'worldCausality': worldCausalityEngine.toJson(),
      'socialWorld': socialWorldEngine.toJson(),
      'mediaWorld': mediaWorldEngine.toJson(),
      'worldSimulation4': worldSimulation4Engine.toJson(),
      'contractDynamics': contractDynamicsEngine.toJson(),
      'careerEventConsequences': careerEventConsequencesEngine.toJson(),
      'careerStorylines': careerStorylineEngine.toJson(),
      'relationshipWeb': relationshipWebEngine.toJson(),
      'relationshipConsequences': relationshipConsequencesEngine.toJson(),
      'relationshipActions': relationshipActionsEngine.toJson(),
      'relationshipEvents': relationshipEventsEngine.toJson(),
      'careerConsequenceV2': careerConsequenceEngineV2.toJson(),
      'matchNarrativeChains': matchNarrativeChainEngine.toJson(),
      'standingsByLeague': {
        for (final entry in standingsByLeague.entries)
          entry.key: {
            for (final standing in entry.value.values)
              standing.clubId: {
                'played': standing.played,
                'wins': standing.wins,
                'draws': standing.draws,
                'losses': standing.losses,
                'goalsFor': standing.goalsFor,
                'goalsAgainst': standing.goalsAgainst,
              },
          },
      },
    };
  }

  /// Restores the competition layer after players/clubs have been restored.
  void restoreFromJson(Map<String, dynamic> json) {
    final rawFixtures = json['fixturesByLeague'];
    if (rawFixtures is Map) {
      fixturesByLeague.clear();
      for (final entry in rawFixtures.entries) {
        final list = <Fixture>[];
        if (entry.value is List) {
          for (final raw in entry.value) {
            if (raw is! Map) continue;
            list.add(Fixture(
              round: raw['round'] ?? 0,
              homeClubId: raw['homeClubId'] ?? '',
              awayClubId: raw['awayClubId'] ?? '',
              year: raw['year'] ?? 2026,
              month: raw['month'] ?? 1,
              day: raw['day'] ?? 1,
              played: raw['played'] ?? false,
              homeGoals: raw['homeGoals'],
              awayGoals: raw['awayGoals'],
            ));
          }
        }
        fixturesByLeague[entry.key.toString()] = list;
      }
    }

    final rawHistory = json['worldEventHistory'];
    if (rawHistory is List) {
      worldEventHistory.clear();
      for (final raw in rawHistory) {
        if (raw is! Map) continue;
        worldEventHistory.add(WorldEvent(
          year: raw['year'] ?? 2026, month: raw['month'] ?? 1, day: raw['day'] ?? 1,
          type: raw['type'] ?? 'world_activity', title: raw['title'] ?? 'Wydarzenie',
          description: raw['description'] ?? '', clubId: raw['clubId'], playerId: raw['playerId'],
          importance: raw['importance'] ?? 1,
        ));
      }
      if (worldEventHistory.length > 500) {
        worldEventHistory.removeRange(0, worldEventHistory.length - 500);
      }
    }

    worldCausalityEngine.restoreFromJson(
      json['worldCausality'] is Map ? Map<String, dynamic>.from(json['worldCausality']) : null,
    );
    socialWorldEngine.restoreFromJson(
      json['socialWorld'] is Map ? Map<String, dynamic>.from(json['socialWorld']) : null,
    );
    mediaWorldEngine.restoreFromJson(
      json['mediaWorld'] is Map ? Map<String, dynamic>.from(json['mediaWorld']) : null,
    );
    worldSimulation4Engine.restoreFromJson(
      json['worldSimulation4'] is Map ? Map<String, dynamic>.from(json['worldSimulation4']) : null,
    );
    contractDynamicsEngine.restoreFromJson(
      json['contractDynamics'] is Map ? Map<String, dynamic>.from(json['contractDynamics']) : null,
    );
    careerEventConsequencesEngine.restoreFromJson(
      json['careerEventConsequences'] is Map ? Map<String, dynamic>.from(json['careerEventConsequences']) : null,
    );
    careerStorylineEngine.restoreFromJson(
      json['careerStorylines'] is Map ? Map<String, dynamic>.from(json['careerStorylines']) : null,
    );
    relationshipWebEngine.restoreFromJson(
      json['relationshipWeb'] is Map ? Map<String, dynamic>.from(json['relationshipWeb']) : null,
    );
    relationshipConsequencesEngine.restoreFromJson(
      json['relationshipConsequences'] is Map ? Map<String, dynamic>.from(json['relationshipConsequences']) : null,
    );
    relationshipActionsEngine.restoreFromJson(
      json['relationshipActions'] is Map ? Map<String, dynamic>.from(json['relationshipActions']) : null,
    );
    relationshipEventsEngine.restoreFromJson(
      json['relationshipEvents'] is Map ? Map<String, dynamic>.from(json['relationshipEvents']) : null,
    );
    careerConsequenceEngineV2.restoreFromJson(
      json['careerConsequenceV2'] is Map ? Map<String, dynamic>.from(json['careerConsequenceV2']) : null,
    );
    matchNarrativeChainEngine.restoreFromJson(
      json['matchNarrativeChains'] is Map ? Map<String, dynamic>.from(json['matchNarrativeChains']) : null,
    );

    final rawStandings = json['standingsByLeague'];
    if (rawStandings is Map) {
      standingsByLeague.clear();
      for (final entry in rawStandings.entries) {
        final map = <String, Standing>{};
        if (entry.value is Map) {
          for (final row in (entry.value as Map).entries) {
            final raw = row.value;
            if (raw is! Map) continue;
            map[row.key.toString()] = Standing(
              clubId: row.key.toString(),
              played: raw['played'] ?? 0,
              wins: raw['wins'] ?? 0,
              draws: raw['draws'] ?? 0,
              losses: raw['losses'] ?? 0,
              goalsFor: raw['goalsFor'] ?? 0,
              goalsAgainst: raw['goalsAgainst'] ?? 0,
            );
          }
        }
        standingsByLeague[entry.key.toString()] = map;
      }
    }
  }

  WorldEngine({
    required this.clubs,
    required this.players,
    required this.leagues,
    int seasonStartYear = 2026,
    Random? random,
  }) : seasonStartYear = seasonStartYear, _random = random ?? Random() {
    squadAI = SquadAIEngine(random: _random);
    injuryEngine = InjuryEngine(random: _random);
    globalMatchEngine = GlobalMatchEngine(random: _random);
    developmentEngine = DevelopmentEngine(random: _random);
    financeEngine = FinanceEngine();
    contractEngine = ContractEngine(random: _random);
    retirementEngine = RetirementEngine(random: _random);
    clubAIEngine = ClubAIEngine(random: _random);
    transferEngine = TransferEngine(random: _random);
    worldEventEngine = WorldEventEngine(random: _random);
    managerWorldEngine = ManagerWorldEngine(random: _random);
    worldHistoryEngine = WorldHistoryEngine(random: _random);
    worldSimulation4Engine = WorldSimulation4Engine(random: _random);
    worldPlayerGenerator = WorldPlayerGenerator(random: _random);
    youthScoutingEngine = YouthScoutingEngine(random: _random);
    youthCareerEngine = YouthCareerEngine(random: _random);
    youthCareerProgressionEngine = YouthCareerProgressionEngine(random: _random);
    academyEvolutionEngine = AcademyEvolutionEngine(random: _random);
    livingWorldEngine = LivingWorldEngine(random: _random);
    worldCausalityEngine = WorldCausalityEngine(random: _random);
    socialWorldEngine = SocialWorldEngine(random: _random);
    mediaWorldEngine = MediaWorldEngine(random: _random);
    playerFameEngine = PlayerFameEngine(random: _random);
    playerCareerConsequencesEngine = PlayerCareerConsequencesEngine(random: _random);
    contractDynamicsEngine = ContractDynamicsEngine(random: _random);
    careerEventConsequencesEngine = CareerEventConsequencesEngine(random: _random);
    careerStorylineEngine = CareerStorylineEngine(random: _random);
    relationshipWebEngine = RelationshipWebEngine(random: _random);
    relationshipConsequencesEngine = RelationshipConsequencesEngine(random: _random);
    relationshipActionsEngine = RelationshipActionsEngine();
    relationshipEventsEngine = RelationshipEventsEngine(random: _random);
    careerConsequenceEngineV2 = CareerConsequenceEngineV2(random: _random);
    matchNarrativeChainEngine = MatchNarrativeChainEngine();
    marketValueEngine = MarketValueEngine();
    _initializeGlobalLeagues();
  }

  WorldEvent worldEventForPlayer({required String type, required String title, required String description, required String playerId, int importance = 1}) => worldSimulation4Engine.worldEventForPlayer(type: type, title: title, description: description, playerId: playerId, importance: importance);

  /// Uruchamiane raz na każdy dzień świata.
  void processDay({
    required int year,
    required int month,
    required int day,
    required bool summerTransferWindow,
    required bool winterTransferWindow,
  }) {
    lastDayEvents.clear();
    lastDayMatchResults.clear();

    _syncClubRosters();
    final absoluteDay = _absoluteDay(year, month, day);

    // A day has an explicit causal order: recover -> choose squad ->
    // play matches -> apply consequences -> run social/market decisions.
    _processPlayerDailyState();
    injuryEngine.processDay(players);

    // Every club trains every day. This is deliberately subtle: the daily
    // loop creates continuity, while the seasonal development engine remains
    // responsible for major progression.
    developmentEngine.processDay(players, clubs);

    _processSquadAI(absoluteDay);

    // V13: trener jest częścią żyjącego świata. Zapamiętujemy stan przed
    // decyzją AI, aby zmiana szkoleniowca była prawdziwym wydarzeniem, a nie
    // cichą zmianą pola w modelu.
    final managerBefore = <String, String>{
      for (final club in clubs) club.id: club.managerName,
    };
    managerWorldEngine.processDay(clubs);
    for (final club in clubs) {
      final before = managerBefore[club.id];
      if (before != null && before != club.managerName) {
        lastDayEvents.add(WorldEvent(
          year: year,
          month: month,
          day: day,
          type: 'manager_change',
          title: 'Zmiana trenera',
          description: '${club.name} rozstał się z trenerem $before. Nowym trenerem został ${club.managerName}.',
          clubId: club.id,
          importance: 4,
        ));
      }
    }

    _simulateGlobalMatches(year, month, day);

    // V26: market value is refreshed AFTER real match production and BEFORE
    // scouting/transfer decisions. The market therefore prices what players
    // actually did, not stale OVR-only values.
    for (final player in players) {
      marketValueEngine.refreshWorldPlayer(player);
    }

    // V11.1C: po meczach aktualizujemy ścieżkę kariery młodych zawodników.
    // Dzięki temu debiut/minuty wpływają na status, zanim ruszy rynek transferowy.
    final youthCareerDayEvents = youthCareerProgressionEngine.processDay(
      year: year,
      month: month,
      day: day,
      absoluteDay: absoluteDay,
      clubs: clubs,
      players: players,
    );
    lastDayEvents.addAll(youthCareerDayEvents);

    _processWeeklyClubEconomy(year, month, day);

    // Wypożyczenia rozliczamy na podstawie absolutnego dnia świata.
    final loanLogs = transferEngine.processLoanReturns(
      clubs: clubs, players: players, absoluteDay: absoluteDay,
    );
    if (summerTransferWindow || winterTransferWindow) {
      loanLogs.addAll(transferEngine.processWindow(
        clubs: clubs,
        players: players,
        summer: summerTransferWindow,
        winter: winterTransferWindow,
        absoluteDay: absoluteDay,
      ));
    }
    _processLivingClubDynamics();
    _processLivingWorldPulse(
      year: year,
      month: month,
      day: day,
      absoluteDay: absoluteDay,
      transferWindow: summerTransferWindow || winterTransferWindow,
    );

    final socialLogs = worldSimulation4Engine.processDay(
      clubs: clubs,
      players: players,
      absoluteDay: absoluteDay,
      year: year,
      month: month,
      day: day,
      transferWindow: summerTransferWindow || winterTransferWindow,
    );

    _syncClubRosters();
    _recalculateClubStrength();

    worldEventEngine.absorbExternalEvents(worldSimulation4Engine.recentEvents);
    worldSimulation4Engine.recentEvents.clear();

    // V18: istniejące silniki świata są teraz spięte dodatkową warstwą
    // reakcji. Decyzje wynikają z presji, minut, finansów i formy zamiast
    // być niezależnymi losowaniami.
    final livingEvents = livingWorldEngine.processDay(
      clubs: clubs, players: players, absoluteDay: absoluteDay,
      year: year, month: month, day: day,
    );
    lastDayEvents.addAll(livingEvents);

    final organicEvents = worldEventEngine.processDay(
      year: year,
      month: month,
      day: day,
      clubs: clubs,
      players: players,
    );
    lastDayEvents.addAll(organicEvents);

    // V18.1: konsekwencje mają pamięć. Kryzys, poprawa finansów i żądanie
    // transferu mogą eskalować przez kolejne dni zamiast resetować się.
    final causalEvents = worldCausalityEngine.processDay(
      clubs: clubs,
      players: players,
      absoluteDay: absoluteDay,
      year: year,
      month: month,
      day: day,
    );
    lastDayEvents.addAll(causalEvents);

    // V18.2: relacje społeczne są kolejną warstwą przyczynowości.
    // Szatnia, trener, kibice i zarząd reagują na realny stan dnia, a ich
    // pamięć przechodzi do kolejnych dni i zapisów gry.
    final socialEvents = socialWorldEngine.processDay(
      clubs: clubs,
      players: players,
      absoluteDay: absoluteDay,
      year: year,
      month: month,
      day: day,
    );
    lastDayEvents.addAll(socialEvents);

    // V18.3: media interprets the same world events instead of generating a
    // disconnected stream. Stories persist and can evolve across days.
    final generatedMediaStories = mediaWorldEngine.processDay(
      events: List<WorldEvent>.from(lastDayEvents),
      clubs: clubs,
      players: players,
      absoluteDay: absoluteDay,
      year: year,
      month: month,
      day: day,
    );

    // V18.4: media now has measurable consequences for covered players.
    playerFameEngine.processDay(
      players: players,
      events: List<WorldEvent>.from(lastDayEvents),
      mediaStories: generatedMediaStories,
      absoluteDay: absoluteDay,
    );

    // V18.5: fame becomes career pressure and opportunity.
    final careerConsequences = playerCareerConsequencesEngine.processDay(
      players: players,
      year: year,
      month: month,
      day: day,
      absoluteDay: absoluteDay,
    );
    lastDayEvents.addAll(careerConsequences);

    // V18.7: kontrakty reagują na aktualną sławę, reputację, formę,
    // marketing oraz siłę agenta. Negocjacje mają pamięć i są zapisywane.
    final contractEvents = contractDynamicsEngine.processDay(
      clubs: clubs,
      players: players,
      absoluteDay: absoluteDay,
    );
    for (final log in contractEvents) {
      lastDayEvents.add(WorldEvent(
        year: year,
        month: month,
        day: day,
        type: 'contract',
        title: log.startsWith('KONTRAKT') ? 'Nowe warunki kontraktu' : 'Negocjacje kontraktowe',
        description: log,
        importance: 3,
      ));
    }

    // V19.1: decyzje kariery rozwijają się w czasie. Presja kontraktowa,
    // transferowa, medialna, sponsorska i reakcje kibiców stają się
    // kolejnymi wydarzeniami tego samego świata.
    final careerEvents = careerEventConsequencesEngine.processDay(
      players: players,
      clubs: clubs,
      year: year,
      month: month,
      day: day,
      absoluteDay: absoluteDay,
    );
    lastDayEvents.addAll(careerEvents);

    // V19.2: isolated consequences become persistent multi-stage storylines.
    final storylineEvents = careerStorylineEngine.processDay(
      players: players,
      clubs: clubs,
      year: year,
      month: month,
      day: day,
      absoluteDay: absoluteDay,
    );
    lastDayEvents.addAll(storylineEvents);

    // V19.4: relacje są osobną, trwałą warstwą świata. Reagują na formę,
    // minuty, kontrakt, media i decyzje, a ich historia trafia do save.
    final relationshipEvents = relationshipWebEngine.processDay(
      players: players, absoluteDay: absoluteDay, year: year, month: month, day: day,
    );
    lastDayEvents.addAll(relationshipEvents);

    // V19.5: relacje mają teraz realne skutki kariery — wsparcie, konflikty,
    // ochrona, aktywność agenta i eskalacja sytuacji kontraktowej.
    final relationshipConsequences = relationshipConsequencesEngine.processDay(
      players: players,
      relationshipWeb: relationshipWebEngine,
      absoluteDay: absoluteDay,
      year: year,
      month: month,
      day: day,
    );
    lastDayEvents.addAll(relationshipConsequences);

    // V19.7: relationship thresholds can open interactive scenes. A scene
    // stays pending until the player chooses a response.
    final relationshipScenes = relationshipEventsEngine.processDay(
      players: players, web: relationshipWebEngine, absoluteDay: absoluteDay,
    );
    for (final scene in relationshipScenes) {
      lastDayEvents.add(WorldEvent(
        year: year, month: month, day: day, type: 'relationship_scene',
        title: scene.title, description: scene.description, playerId: scene.playerId, importance: 4,
      ));
    }

    // V20.1: aktywne historie meczowe pamiętają, że kolejny występ ma znaczenie.
    final matchNarrativeEvents = matchNarrativeChainEngine.processDay(
      players: players, absoluteDay: absoluteDay, year: year, month: month, day: day,
    );
    lastDayEvents.addAll(matchNarrativeEvents);

    if (summerTransferWindow || winterTransferWindow) {
      final transferLogs = _processTransferMarket(
        isSummer: summerTransferWindow,
        isWinter: winterTransferWindow,
      );
      // TransferEngine logs are later consumed by News/FPG Social.
      // We keep the strings here instead of generating unrelated posts.
      for (final log in [...loanLogs, ...socialLogs, ...transferLogs]) {
        lastDayEvents.add(WorldEvent(
          year: year,
          month: month,
          day: day,
          type: log.startsWith('TRANSFER') || log.startsWith('WYPOŻYCZENIE')
              ? 'transfer'
              : 'world_activity',
          title: log.split(':').first,
          description: log,
          importance: 2,
        ));
      }
    } else {
      for (final log in [...loanLogs, ...socialLogs]) {
        lastDayEvents.add(WorldEvent(
          year: year,
          month: month,
          day: day,
          type: 'world_activity',
          title: log.split(':').first,
          description: log,
          importance: 1,
        ));
      }
    }

    // Historia jest zapisywana dopiero po wszystkich decyzjach dnia, w tym
    // po transferach. Dzięki temu zapis dnia jest kompletny.
    worldEventHistory.addAll(lastDayEvents);
    if (worldEventHistory.length > 500) {
      worldEventHistory.removeRange(0, worldEventHistory.length - 500);
    }
  }

  /// Simulates fixtures that are already in the past when a career/save is
  /// created or loaded. Without this, an 8 August fixture would remain
  /// unplayed forever when the world starts on 23 August.
  void catchUpToDate({required int year, required int month, required int day}) {
    for (final entry in fixturesByLeague.entries) {
      if (entry.key == 'pol_ek') continue;
      final standings = standingsByLeague[entry.key];
      if (standings == null) continue;

      for (final fixture in entry.value) {
        if (fixture.played) continue;
        final fixtureDate = DateTime(fixture.year, fixture.month, fixture.day);
        final currentDate = DateTime(year, month, day);
        if (fixtureDate.isAfter(currentDate)) continue;

        final home = _findClub(fixture.homeClubId);
        final away = _findClub(fixture.awayClubId);
        if (home == null || away == null) continue;

        final result = globalMatchEngine.simulate(
          home: home,
          away: away,
          homePlayers: _playersOfClub(home.id),
          awayPlayers: _playersOfClub(away.id),
          rivalryIntensity: worldSimulation4Engine.rivalryEngine
              .intensityBetween(home.id, away.id),
        );

        fixture.played = true;
        fixture.homeGoals = result.homeGoals;
        fixture.awayGoals = result.awayGoals;
        _recordStanding(standings, result);
        lastDayMatchResults.add(result);
        _emitMatchWorldEvent(
          result: result,
          home: home,
          away: away,
          year: fixture.year,
          month: fixture.month,
          day: fixture.day,
        );
        _applyMatchConsequences(
          home: home,
          away: away,
          result: result,
          absoluteDay: _absoluteDay(fixture.year, fixture.month, fixture.day),
          year: fixture.year,
          month: fixture.month,
          day: fixture.day,
        );
      }
    }
  }


  void _initializeGlobalLeagues() {
    final grouped = <String, List<Club>>{};
    for (final club in clubs) {
      grouped.putIfAbsent(club.leagueId, () => []).add(club);
    }
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      final leagueId = entry.key;
      fixturesByLeague[leagueId] = FixtureGenerator.generateSeasonFixtures(
        entry.value,
        seasonStartYear: seasonStartYear,
      );
      standingsByLeague[leagueId] = {
        for (final club in entry.value) club.id: Standing(clubId: club.id),
      };
    }
  }

  void _simulateGlobalMatches(int year, int month, int day) {
    for (final entry in fixturesByLeague.entries) {
      // The career league is currently simulated by GameEngine so the
      // player's interactive match can consume its exact result.
      if (entry.key == 'pol_ek') continue;
      final standings = standingsByLeague[entry.key];
      if (standings == null) continue;

      for (final fixture in entry.value) {
        if (fixture.played || fixture.year != year || fixture.month != month || fixture.day != day) continue;
        final home = _findClub(fixture.homeClubId);
        final away = _findClub(fixture.awayClubId);
        if (home == null || away == null) continue;
        final homePlayers = _playersOfClub(home.id);
        final awayPlayers = _playersOfClub(away.id);
        final result = globalMatchEngine.simulate(
          home: home, away: away,
          homePlayers: homePlayers, awayPlayers: awayPlayers,
          rivalryIntensity: worldSimulation4Engine.rivalryEngine.intensityBetween(home.id, away.id),
        );
        fixture.played = true;
        fixture.homeGoals = result.homeGoals;
        fixture.awayGoals = result.awayGoals;
        _recordStanding(standings, result);
        lastDayMatchResults.add(result);
        _emitMatchWorldEvent(
          result: result,
          home: home,
          away: away,
          year: year,
          month: month,
          day: day,
        );
        _applyMatchConsequences(
          home: home,
          away: away,
          result: result,
          absoluteDay: _absoluteDay(year, month, day),
          year: year,
          month: month,
          day: day,
        );
      }
    }
  }

  void _applyMatchConsequences({
    required Club home,
    required Club away,
    required MatchResult result,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    final homeWin = result.homeGoals > result.awayGoals;
    final awayWin = result.awayGoals > result.homeGoals;
    final draw = result.homeGoals == result.awayGoals;

    _updateClubMatchMemory(home, result.homeGoals, result.awayGoals,
        win: homeWin, draw: draw, absoluteDay: absoluteDay,
        year: year, month: month, day: day);
    _updateClubMatchMemory(away, result.awayGoals, result.homeGoals,
        win: awayWin, draw: draw, absoluteDay: absoluteDay,
        year: year, month: month, day: day);

    final allPerformances = result.playerPerformances;
    for (final performance in allPerformances) {
      final player = players.where((p) => p.id == performance.playerId).firstOrNull;
      if (player == null) continue;

      // Dobry występ buduje pewność siebie, słaby ją zabiera. Reakcja jest
      // mała, bo forma ma wynikać z wielu meczów, nie z jednego rzutu kością.
      if (performance.rating >= 8.0) {
        player.morale = min(100, player.morale + 2);
        player.managerRelationship = min(100, player.managerRelationship + 1);
      } else if (performance.rating < 5.7) {
        player.morale = max(20, player.morale - 2);
      }

      if (performance.minutes >= 75 && player.fatigue >= 75) {
        player.fitness = max(0, player.fitness - 2);
      }

      if (performance.minutes > 0 && player.appearances == 1 && player.age <= 23 && player.debutDay == 0) {
        player.debutDay = absoluteDay;
        player.careerStage = 'firstTeam';
        lastDayEvents.add(WorldEvent(
          year: year,
          month: month,
          day: day,
          type: 'debut',
          title: 'Debiut młodego zawodnika',
          description: '${player.name} zaliczył pierwszy występ w seniorskiej piłce.',
          clubId: player.clubId,
          playerId: player.id,
          importance: 4,
        ));
      }
    }

    // Seria wyników wpływa na całą atmosferę. Dodatni momentum daje mały
    // bonus, kryzys działa odwrotnie. Nie zmieniamy OVR — zmieniamy warunki,
    // w których OVR jest wykorzystywany przez następne mecze.
    for (final club in [home, away]) {
      final pressure = club.lossesStreak >= 4 ? 2 : club.winsStreak >= 4 ? -2 : 0;
      club.boardPressure = (club.boardPressure + pressure).clamp(10, 100).toInt();
      if (club.lossesStreak >= 5) {
        club.stability = max(10, club.stability - 2);
        club.fanSupport = max(10, club.fanSupport - 2);
        club.boardConfidence = max(5, club.boardConfidence - 3);
        club.financialHealth = max(5, club.financialHealth - 1);
      } else if (club.winsStreak >= 5) {
        club.stability = min(100, club.stability + 1);
        club.fanSupport = min(100, club.fanSupport + 2);
        club.boardConfidence = min(100, club.boardConfidence + 2);
        club.financialHealth = min(100, club.financialHealth + 1);
      }

      // V14: seria wyników ma ekonomiczny skutek. To powoduje, że świat
      // zaczyna tworzyć łańcuch przyczynowo-skutkowy zamiast niezależnych
      // losowań: wyniki -> kibice -> finanse -> zarząd -> trener.
      if (club.lastResult == 'win') {
        club.budget += 1200 + club.fanSupport * 45;
      } else if (club.lastResult == 'loss') {
        club.budget = max(0, club.budget - 650 - (100 - club.fanSupport) * 12);
      }
    }
  }

  void _updateClubMatchMemory(
    Club club,
    int goalsFor,
    int goalsAgainst, {
    required bool win,
    required bool draw,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    club.matchesPlayedThisSeason++;
    club.goalsForThisSeason += goalsFor;
    club.goalsAgainstThisSeason += goalsAgainst;
    club.lastMatchAbsoluteDay = absoluteDay;

    if (goalsAgainst == 0) club.cleanSheetsThisSeason++;

    if (draw) {
      club.lastResult = 'draw';
      club.winsStreak = 0;
      club.lossesStreak = 0;
      club.unbeatenStreak++;
    } else if (win) {
      club.lastResult = 'win';
      club.winsStreak++;
      club.lossesStreak = 0;
      club.unbeatenStreak++;
    } else {
      club.lastResult = 'loss';
      club.winsStreak = 0;
      club.lossesStreak++;
      club.unbeatenStreak = 0;
    }
  }

  void _emitMatchWorldEvent({
    required MatchResult result,
    required Club home,
    required Club away,
    required int year,
    required int month,
    required int day,
  }) {
    final score = '${result.homeGoals}:${result.awayGoals}';
    final winner = result.homeWon ? home : result.awayWon ? away : null;
    final title = winner == null
        ? '${home.name} remisuje z ${away.name}'
        : '${winner.name} wygrywa';
    final importance = result.totalGoals >= 5 || result.isDraw ? 2 : 1;

    lastDayEvents.add(WorldEvent(
      year: year,
      month: month,
      day: day,
      type: 'match',
      title: title,
      description: '${home.name} $score ${away.name}.',
      clubId: winner?.id,
      importance: importance,
    ));
  }

  void _recordStanding(Map<String, Standing> standings, MatchResult result) {
    final home = standings[result.homeClubId];
    final away = standings[result.awayClubId];
    if (home == null || away == null) return;
    home.played++; away.played++;
    home.goalsFor = (home.goalsFor + result.homeGoals).toInt();
    home.goalsAgainst = (home.goalsAgainst + result.awayGoals).toInt();
    away.goalsFor = (away.goalsFor + result.awayGoals).toInt();
    away.goalsAgainst = (away.goalsAgainst + result.homeGoals).toInt();

    if (result.homeGoals > result.awayGoals) { home.wins++; away.losses++; }
    else if (result.homeGoals < result.awayGoals) { away.wins++; home.losses++; }
    else { home.draws++; away.draws++; }
  }

  List<Standing> tableForLeague(String leagueId) {
    final table = [...(standingsByLeague[leagueId]?.values ?? const <Standing>[])];
    table.sort((a, b) {
      final points = b.points.compareTo(a.points);
      if (points != 0) return points;
      final gd = b.goalDifference.compareTo(a.goalDifference);
      if (gd != 0) return gd;
      return b.goalsFor.compareTo(a.goalsFor);
    });
    return table;
  }

  /// Uruchamiane na koniec sezonu, zanim świat rozpocznie kolejny rok.
  /// V19.9 — feeds the player's real match into the living career world.
  List<WorldEvent> processCareerMatchConsequences({
    required PlayerCareer career,
    required int year,
    required int month,
    required int day,
    required int homeGoals,
    required int awayGoals,
    required bool playerClubIsHome,
    required bool appeared,
    required bool started,
    required int minutes,
    required double rating,
    required int goals,
    required int assists,
  }) {
    final worldPlayer = players.where((p) => p.id == career.id).firstOrNull;
    if (worldPlayer == null || career.clubId == null) return const [];
    final absoluteDay = _absoluteDay(year, month, day);
    final events = careerConsequenceEngineV2.processMatch(
      player: worldPlayer,
      relationshipWeb: relationshipWebEngine,
      absoluteDay: absoluteDay,
      year: year,
      month: month,
      day: day,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      playerClubIsHome: playerClubIsHome,
      appeared: appeared,
      started: started,
      minutes: minutes,
      rating: rating,
      goals: goals,
      assists: assists,
    );
    lastDayEvents.addAll(events);

    final narrativeEvents = matchNarrativeChainEngine.processMatch(
      player: worldPlayer,
      absoluteDay: absoluteDay,
      year: year,
      month: month,
      day: day,
      appeared: appeared,
      started: started,
      minutes: minutes,
      rating: rating,
      goals: goals,
      assists: assists,
      won: playerClubIsHome ? homeGoals > awayGoals : awayGoals > homeGoals,
    );
    lastDayEvents.addAll(narrativeEvents);
    worldEventHistory.addAll(events);
    worldEventHistory.addAll(narrativeEvents);
    if (worldEventHistory.length > 500) {
      worldEventHistory.removeRange(0, worldEventHistory.length - 500);
    }
    worldEventEngine.absorbExternalEvents(events);
    return events;
  }

  void processEndOfSeason({required int nextSeasonStartYear}) {
    _syncClubRosters();

    // Najpierw cały świat starzeje się o jeden sezon.
    for (final player in players) {
      player.age++;
    }

    // Kolejność jest celowa: najpierw rozwój, następnie finanse i kontrakty,
    // potem emerytury/regeneracja. Dzięki temu nowe pokolenie wchodzi do
    // świata dopiero po zakończeniu pełnego sezonu.
    developmentEngine.processSeason(players, clubs: clubs);
    financeEngine.processSeason(clubs);
    contractEngine.processSeason(clubs, players);
    final academyEvents = academyEvolutionEngine.processSeason(clubs: clubs, players: players);
    for (final event in academyEvents) {
      lastDayEvents.add(WorldEvent(
        year: nextSeasonStartYear, month: 7, day: 1, type: 'academy_reputation',
        title: 'Zmienia się reputacja akademii', description: event, importance: 2,
      ));
    }

    final retired = retirementEngine.processSeason(players: players, clubs: clubs);
    for (final player in retired) {
      players.remove(player);
      _findClub(player.clubId ?? '')?.removePlayer(player.id);
    }

    // P1.1: retirement can create an impossible senior squad before the next
    // transfer window. Add a small emergency senior intake only when a club
    // falls below the playable minimum. The normal academy pipeline remains
    // responsible for long-term youth development.
    final emergencySenior = SquadDepthEngine.ensureMinimumSeniorSquads(
      clubs: clubs,
      players: players,
      generator: worldPlayerGenerator,
      seasonYear: nextSeasonStartYear,
    );
    for (final player in emergencySenior) {
      lastDayEvents.add(WorldEvent(
        year: nextSeasonStartYear,
        month: 7,
        day: 1,
        type: 'squad_depth',
        title: 'Uzupełnienie kadry',
        description: '${player.name} dołącza do ${_findClub(player.clubId ?? '')?.name ?? 'klubu'} po zakończeniu sezonu, aby utrzymać minimalną liczebność pierwszej kadry.',
        clubId: player.clubId,
        playerId: player.id,
        importance: 1,
      ));
    }

    // V11.1: retirements are now replenished by a living academy/scouting
    // ecosystem. A club first discovers a prospect, receives an imperfect
    // scouting estimate, and only then materialises him as a Player.
    final academyIntake = <Player>[];
    for (final club in clubs) {
      final prospects = youthScoutingEngine.discover(
        year: nextSeasonStartYear,
        club: club,
        players: players,
      );
      for (final prospect in prospects) {
        final player = worldPlayerGenerator.fromProspect(
          year: nextSeasonStartYear,
          club: club,
          prospect: prospect,
        );
        academyIntake.add(player);
        lastDayEvents.add(WorldEvent(
          year: nextSeasonStartYear,
          month: 7,
          day: 1,
          type: 'academy',
          title: 'Skauting odkrył młodego zawodnika',
          description: '${player.name}, ${player.age} lat, ${player.position.name}, ${prospect.scoutingEstimateMin}-${prospect.scoutingEstimateMax} POT (pewność ${prospect.scoutingConfidence}%) trafia do akademii ${club.name}. Źródło: ${prospect.scoutingPath}, region: ${prospect.region}.',
          clubId: club.id,
          importance: prospect.scoutingEstimateMax >= 85 ? 3 : 1,
        ));
      }
    }
    players.addAll(academyIntake);

    final youthCareerEvents = youthCareerEngine.processSeason(
      year: nextSeasonStartYear,
      clubs: clubs,
      players: players,
    );
    lastDayEvents.addAll(youthCareerEvents);

    worldSimulation4Engine.processSeason(
      clubs: clubs,
      players: players,
      seasonYear: nextSeasonStartYear,
    );

    _syncClubRosters();
    _applySeasonFinancialMovement();

    // Zapamiętujemy sezon przed zmianą poziomów lig. Historia ma opisywać
    // to, co klub faktycznie osiągnął, a nie jego nową ligę.
    final seasonPositions = <String, int>{};
    for (final league in leagues) {
      final table = tableForLeague(league.id);
      for (var i = 0; i < table.length; i++) {
        seasonPositions[table[i].clubId] = i + 1;
      }
    }
    worldHistoryEngine.processSeason(clubs: clubs, positions: seasonPositions);

    _applyPromotionAndRelegation();
    _syncClubRosters();
    _recalculateClubStrength();

    for (final club in clubs) {
      club.winsStreak = 0;
      club.unbeatenStreak = 0;
      club.lossesStreak = 0;
      club.matchesPlayedThisSeason = 0;
      club.goalsForThisSeason = 0;
      club.goalsAgainstThisSeason = 0;
      club.cleanSheetsThisSeason = 0;
      club.lastResult = 'none';
      club.lastMatchAbsoluteDay = 0;
    }

    // Reset autonomicznych rozgrywek na nowy sezon.
    fixturesByLeague.clear();
    standingsByLeague.clear();
    final grouped = <String, List<Club>>{};
    for (final club in clubs) {
      grouped.putIfAbsent(club.leagueId, () => []).add(club);
    }
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      fixturesByLeague[entry.key] = FixtureGenerator.generateSeasonFixtures(
        entry.value,
        seasonStartYear: nextSeasonStartYear,
      );
      standingsByLeague[entry.key] = {
        for (final club in entry.value) club.id: Standing(clubId: club.id),
      };
    }
  }

  void _applyPromotionAndRelegation() {
    // Każdy kraj może posiadać kilka poziomów. Zamieniamy tylko kluby, które
    // faktycznie należą do sąsiadujących poziomów tego samego kraju.
    for (final country in leagues.map((l) => l.country).toSet()) {
      final countryLeagues = leagues.where((l) => l.country == country).toList()
        ..sort((a, b) => a.level.compareTo(b.level));

      for (var i = 0; i < countryLeagues.length - 1; i++) {
        final upper = countryLeagues[i];
        final lower = countryLeagues[i + 1];
        final upperTable = tableForLeague(upper.id);
        final lowerTable = tableForLeague(lower.id);
        if (upperTable.length < 2 || lowerTable.length < 2) continue;

        final relegatedCount = min(2, upperTable.length);
        final promotedCount = min(2, lowerTable.length);
        final relegated = upperTable.reversed.take(relegatedCount).map((s) => _findClub(s.clubId)).whereType<Club>().toList();
        final promoted = lowerTable.take(promotedCount).map((s) => _findClub(s.clubId)).whereType<Club>().toList();

        for (final club in relegated) club.leagueId = lower.id;
        for (final club in promoted) club.leagueId = upper.id;
      }
    }
  }

  void _applySeasonFinancialMovement() {
    for (final club in clubs) {
      // Nagrody i przychody sezonowe rosną wraz z poziomem klubu.
      final seasonIncome =
          250000 + (club.overall * 18000) + (club.reputation * 6000);

      // Słaba kondycja finansowa zwiększa presję na zarząd.
      final financialPenalty = (100 - club.financialHealth) * 5000;

      club.budget = max(0, club.budget + seasonIncome - financialPenalty);

      if (club.budget < 1000000) {
        club.financialHealth = max(10, club.financialHealth - 3);
      } else if (club.budget > 50000000) {
        club.financialHealth = min(100, club.financialHealth + 2);
      }
    }
  }

  void _syncClubRosters() {
    for (final club in clubs) {
      club.playerIds.clear();
    }

    for (final player in players) {
      final clubId = player.clubId;
      if (clubId == null) continue;

      final club = _findClub(clubId);
      club?.addPlayer(player.id);
    }
  }

  void _processPlayerDailyState() {
    for (final player in players) {
      // Świat AI regeneruje się także wtedy, gdy gracz niczego nie robi.
      if (player.fatigue > 0) {
        final recovery = player.fatigue >= 75 ? 3 : 5;
        player.fatigue = max(0, player.fatigue - recovery);
      }

      if (player.fitness < 100 && player.fatigue < 45) {
        player.fitness = min(100, player.fitness + 1);
      }

      // Forma nie skacze losowo o kilkanaście punktów. Powoli wraca do
      // poziomu neutralnego, a zmęczenie przesuwa ją w dół.
      if (player.form > 70) {
        player.form--;
      } else if (player.form < 70) {
        player.form++;
      }

      if (player.injured) {
        player.form = max(0, player.form - 1);
      }

      if (player.fatigue >= 75) {
        player.form = max(0, player.form - 1);
        player.morale = max(0, player.morale - 1);
      }
    }
  }


  void _processSquadAI(int absoluteDay) {
    for (final club in clubs) {
      squadAI.processClub(
        club: club,
        players: players,
        absoluteDay: absoluteDay,
      );
    }
  }

  void _processWeeklyClubEconomy(int year, int month, int day) {
    final absoluteDay = _absoluteDay(year, month, day);
    if (absoluteDay % 7 != 0) return;
    financeEngine.processWeekly(clubs, players);

    // V14/V15: ekonomia reaguje na wyniki i popularność. Kluby w kryzysie
    // zaczynają oszczędzać, a dobrze zarządzane zwiększają środki na kadrę.
    for (final club in clubs) {
      final momentum = club.winsStreak - club.lossesStreak;
      if (club.financialHealth < 25) {
        club.transferActivity = max(15, club.transferActivity - 2);
        club.youthFocus = min(95, club.youthFocus + 1);
        club.boardPressure = min(100, club.boardPressure + 2);
      } else if (club.financialHealth > 80 && momentum >= 2) {
        club.transferActivity = min(95, club.transferActivity + 1);
        club.boardPressure = max(15, club.boardPressure - 1);
      }

      final fanRevenue = (club.fanSupport - 50) * 180;
      club.budget = max(0, club.budget + fanRevenue);
    }
  }

  void _recalculateClubStrength() {
    for (final club in clubs) {
      final squad = _playersOfClub(club.id);
      if (squad.isEmpty) continue;

      final sorted = [...squad]
        ..sort((a, b) => b.overall.compareTo(a.overall));

      final relevant = sorted.take(18).toList();
      double weightedSum = 0;
      double weights = 0;

      for (var i = 0; i < relevant.length; i++) {
        final weight = i < 11 ? 1.0 : 0.45;
        weightedSum += relevant[i].overall * weight;
        weights += weight;
      }

      if (weights == 0) continue;

      final squadStrength = weightedSum / weights;
      final financialModifier = (club.financialHealth - 70) * 0.025;
      final tacticalModifier = (club.tacticalIdentity - 50) * 0.035;
      final managerModifier = (club.managerQuality - 50) * 0.025;
      final stabilityModifier = (club.stability - 70) * 0.012;
      final target = (squadStrength + financialModifier + tacticalModifier + managerModifier + stabilityModifier).clamp(1.0, 99.0);

      // OVR klubu zmienia się stopniowo. Jeden transfer nie powinien nagle
      // przeskoczyć klubu z 70 do 85.
      final delta = target - club.overall;
      final step = delta.clamp(-2.0, 2.0);
      club.overall = (club.overall + step).round().clamp(1, 99).toInt();
    }
  }

  void _processLivingClubDynamics() {
    for (final club in clubs) {
      final squad = _playersOfClub(club.id);
      if (squad.isEmpty) continue;

      final avgForm = squad.fold<double>(0, (sum, p) => sum + p.form) / squad.length;
      final avgMorale = squad.fold<double>(0, (sum, p) => sum + p.morale) / squad.length;
      final avgFitness = squad.fold<double>(0, (sum, p) => sum + p.fitness) / squad.length;

      // Wyniki i atmosfera wpływają na kibiców, zarząd i stabilność.
      if (avgForm >= 76 && avgMorale >= 70) {
        club.fanSupport = min(100, club.fanSupport + 1);
        club.stability = min(100, club.stability + 1);
        club.boardPressure = max(20, club.boardPressure - 1);
      } else if (avgForm <= 58 || avgMorale <= 45) {
        club.fanSupport = max(10, club.fanSupport - 1);
        club.stability = max(10, club.stability - 1);
        club.boardPressure = min(100, club.boardPressure + 1);
      }

      // Silny trener i akademia mają znaczenie w długim okresie, ale nie
      // powinny magicznie zmieniać klub z dnia na dzień.
      if (club.financialHealth >= 70 && club.academyQuality >= 70) {
        club.stability = min(100, club.stability + 1);
      }
      if (avgFitness < 55) {
        club.stability = max(10, club.stability - 1);
      }

      // Presja zarządu rośnie również wtedy, gdy klub jest drogi w utrzymaniu.
      final wageBill = squad.fold<double>(0, (sum, p) => sum + p.weeklyWage);
      if (club.budget < wageBill * 4) {
        club.boardPressure = min(100, club.boardPressure + 1);
      }
    }
  }


  /// Small autonomous "world pulse". These are not decorative random news:
  /// each event is triggered by the current state of a club/player and
  /// changes that state. This makes non-player clubs feel active between
  /// matches and transfer windows.
  void _processLivingWorldPulse({
    required int year,
    required int month,
    required int day,
    required int absoluteDay,
    required bool transferWindow,
  }) {
    if (clubs.isEmpty) return;

    // V13: świat nie "budzi się" tylko co kilka dni dla jednego klubu.
    // Każdy dzień ma kilka kandydatów do reakcji, ale tylko zdarzenia z
    // odpowiednio wysoką presją są publikowane. Dzięki temu symulacja jest
    // aktywna, lecz newsy nie zalewają gracza losowymi komunikatami.
    final candidates = [...clubs]..sort((a, b) {
      double score(Club c) =>
          c.boardPressure * .40 +
          (100 - c.stability) * .25 +
          c.lossesStreak * 7 +
          (100 - c.financialHealth) * .18 +
          (c.winsStreak >= 4 ? 12 : 0);
      return score(b).compareTo(score(a));
    });

    final count = min(4, candidates.length);
    for (var i = 0; i < count; i++) {
      final club = candidates[i];
      final squad = _playersOfClub(club.id);
      if (squad.isEmpty) continue;

      final avgMorale = squad.fold<double>(0, (sum, p) => sum + p.morale) / squad.length;
      final avgForm = squad.fold<double>(0, (sum, p) => sum + p.form) / squad.length;
      final trigger = _random.nextDouble();

      // Kryzys sportowy -> rozmowa zarządu / zmiana celu.
      if (club.lossesStreak >= 4 && club.boardPressure >= 70 && trigger < .34) {
        club.boardPressure = min(100, club.boardPressure + 2);
        club.boardConfidence = max(10, club.boardConfidence - 3);
        lastDayEvents.add(WorldEvent(
          year: year, month: month, day: day,
          type: 'board_pressure',
          title: 'Rośnie presja na klub',
          description: '${club.name} ma serię słabych wyników. Zarząd oczekuje natychmiastowej poprawy.',
          clubId: club.id, importance: 3,
        ));
        continue;
      }

      // Finansowy kryzys wymusza decyzję, a nie tylko odejmuje pieniądze.
      if (club.financialHealth < 40 && trigger < .30) {
        club.transferActivity = max(10, club.transferActivity - 2);
        club.minimumSigningOverall = max(45, club.minimumSigningOverall - 2);
        lastDayEvents.add(WorldEvent(
          year: year, month: month, day: day,
          type: 'finance',
          title: 'Klub zaciska pasa',
          description: '${club.name} ogranicza wydatki transferowe z powodu problemów finansowych.',
          clubId: club.id, importance: 3,
        ));
        continue;
      }

      // Dobra forma -> klub odważniej inwestuje w akademię i młodzież.
      if (avgForm >= 76 && avgMorale >= 72 && trigger < .24) {
        club.academyQuality = min(100, club.academyQuality + 1);
        club.youthFocus = min(100, club.youthFocus + 1);
        club.stability = min(100, club.stability + 1);
        lastDayEvents.add(WorldEvent(
          year: year, month: month, day: day,
          type: 'club_growth',
          title: 'Klub rozwija akademię',
          description: '${club.name} wykorzystuje dobrą atmosferę i inwestuje w rozwój młodzieży.',
          clubId: club.id, importance: 2,
        ));
        continue;
      }

      // Młody zawodnik może poprosić o większą rolę. Zmienia to jego morale,
      // relację z trenerem i status, więc następne decyzje AI mają podstawę.
      final unhappyYoung = squad.where((p) =>
          p.age <= 23 && p.morale < 48 && p.overall >= club.overall - 5).toList();
      if (unhappyYoung.isNotEmpty && trigger < .28) {
        unhappyYoung.sort((a, b) => b.overall.compareTo(a.overall));
        final player = unhappyYoung.first;
        player.managerRelationship = max(20, player.managerRelationship - 2);
        player.morale = max(20, player.morale - 1);
        club.boardPressure = min(100, club.boardPressure + 1);
        lastDayEvents.add(WorldEvent(
          year: year, month: month, day: day,
          type: 'player_unrest',
          title: 'Niezadowolenie zawodnika',
          description: '${player.name} oczekuje większej roli w ${club.name}.',
          clubId: club.id, playerId: player.id, importance: 3,
        ));
        continue;
      }
    }

    // Raz na tydzień świat tworzy kilka realistycznych zmian warunków:
    // sponsorzy, frekwencja i koszty są pochodną formy, wyników i reputacji.
    if (absoluteDay % 7 == 0) {
      for (final club in clubs) {
        final attendanceEffect = (club.fanSupport - 50) * 900;
        final performanceEffect = (club.winsStreak - club.lossesStreak) * 7000;
        final revenue = max(0, 25000 + club.reputation * 1200 + attendanceEffect + performanceEffect);
        final costs = 12000 + club.overall * 450;
        club.budget = max(0, club.budget + revenue - costs);
        club.financialHealth = (club.financialHealth +
                (revenue > costs * 1.5 ? 1 : revenue < costs * .65 ? -1 : 0))
            .clamp(10, 100);
      }
    }
  }

  List<String> _processTransferMarket({
    required bool isSummer,
    required bool isWinter,
  }) {
    // V18.8: finalne transfery prowadzi TransferNegotiationV2Engine.
    // Stary TransferEngine zostaje dla zwrotów wypożyczeń, ale nie może już
    // wykonywać natychmiastowych zakupów obok negocjacji 3-stronnych.
    return const [];
  }

  double _transferScore(Club buyer, Player player) {
    final ageDistance = player.age < buyer.preferredMinAge
        ? buyer.preferredMinAge - player.age
        : player.age > buyer.preferredMaxAge
            ? player.age - buyer.preferredMaxAge
            : 0;

    final potentialBonus = max(0, player.potential - player.overall) *
        (buyer.youthFocus / 100.0);
    final reputationBonus = buyer.reputation * 0.03;

    return player.overall * 2.2 +
        potentialBonus -
        ageDistance * 2.5 +
        reputationBonus;
  }

  int _calculateTransferFee(Player player, Club buyer) {
    final ageFactor = player.age <= 23
        ? 1.25
        : player.age <= 28
            ? 1.05
            : 0.75;

    final clubFactor = 0.85 + buyer.reputation / 300.0;
    return max(
      250000,
      (player.value * ageFactor * clubFactor).round(),
    );
  }

  List<Player> _playersOfClub(String clubId) =>
      players.where((player) => player.clubId == clubId).toList();

  Club? _findClub(String id) {
    for (final club in clubs) {
      if (club.id == id) return club;
    }
    return null;
  }

  /// P0.7: validates the persistent player/club graph after a simulation tick.
  /// The report is diagnostic only and never mutates the world.
  WorldIntegrityReport validateWorldIntegrity() {
    _syncClubRosters();
    return WorldIntegrityValidator.validate(clubs: clubs, players: players);
  }

  int absoluteDayForDate(int year, int month, int day) => _absoluteDay(year, month, day);

  int _absoluteDay(int year, int month, int day) {
    var total = 0;
    for (var y = 1; y < year; y++) {
      total += _isLeapYear(y) ? 366 : 365;
    }

    const monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    for (var m = 1; m < month; m++) {
      total += monthDays[m - 1];
      if (m == 2 && _isLeapYear(year)) total++;
    }

    return total + day;
  }

  bool _isLeapYear(int year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
  }
}


extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
