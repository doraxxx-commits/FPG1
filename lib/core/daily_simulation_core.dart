import 'game_state.dart';

/// V25 — central daily simulation coordinator.
///
/// One simulation day is a transaction with a fixed causal order.
/// UI screens may request the day, but they do not decide which systems run
/// or in what order. Individual engines remain specialists; this class is
/// the conductor that makes them behave like one world.
enum DailySimulationPhase {
  dateAdvanced,
  playerRecovery,
  playerForm,
  squadDecision,
  careerMatches,
  worldAi,
  careerWorldBridge,
  seasonMaintenance,
}

class DailySimulationReport {
  final int year;
  final int month;
  final int day;
  final int absoluteDay;
  final List<DailySimulationPhase> phases;
  final int careerMatchesCompleted;
  final bool seasonAdvanced;

  const DailySimulationReport({
    required this.year,
    required this.month,
    required this.day,
    required this.absoluteDay,
    required this.phases,
    required this.careerMatchesCompleted,
    required this.seasonAdvanced,
  });

  String get dateString =>
      '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year';

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
        'absoluteDay': absoluteDay,
        'phases': phases.map((p) => p.name).toList(),
        'careerMatchesCompleted': careerMatchesCompleted,
        'seasonAdvanced': seasonAdvanced,
      };
}

/// The only owner of the *order* of a simulation day.
///
/// The engines passed to it are deliberately callbacks. This keeps V25 from
/// becoming another giant engine: TrainingEngine, WorldEngine, MatchEngine,
/// relationships, media, transfers etc. continue to own their own rules.
class DailySimulationCore {
  final GameState state;
  DailySimulationReport? lastReport;

  DailySimulationCore({required this.state});

  DailySimulationReport runDay({
    required void Function() recoverPlayer,
    required void Function() updatePlayerForm,
    required void Function() updateCareerPlayerMatchStatus,
    required void Function() resetCareerMatchSnapshot,
    required int Function() playCareerMatches,
    required void Function({
      required int year,
      required int month,
      required int day,
      required bool summerTransferWindow,
      required bool winterTransferWindow,
    }) processWorldDay,
    required void Function() pushCareerStateBeforeWorld,
    required void Function() applyCareerMatchConsequences,
    required void Function() pullCareerStateAfterWorld,
    required bool Function() advanceSeasonIfComplete,
  }) {
    final phases = <DailySimulationPhase>[];

    // Phase 1: advance the simulation calendar. Device time never enters
    // this transaction.
    state.nextDay();
    phases.add(DailySimulationPhase.dateAdvanced);

    // Phase 2: player physical state.
    recoverPlayer();
    phases.add(DailySimulationPhase.playerRecovery);

    updatePlayerForm();
    phases.add(DailySimulationPhase.playerForm);

    // Phase 3: squad selection happens before today's match.
    updateCareerPlayerMatchStatus();
    resetCareerMatchSnapshot();
    phases.add(DailySimulationPhase.squadDecision);

    // Phase 4: the player's league is resolved first, so the career match
    // is available as an input to the world bridge later in the transaction.
    final matches = playCareerMatches();
    phases.add(DailySimulationPhase.careerMatches);

    // Phase 5: resolve the player's real match consequences BEFORE the
    // autonomous world tick. This is important: transfers, media, morale,
    // fame and club AI must see today's actual performance, not yesterday's
    // projection.
    applyCareerMatchConsequences();

    // Phase 6: push the fully updated career state into the same world used
    // by AI.
    pushCareerStateBeforeWorld();

    // Phase 7: all autonomous world systems execute behind one boundary.
    processWorldDay(
      year: state.year,
      month: state.month,
      day: state.day,
      summerTransferWindow: state.transferWindowSummer,
      winterTransferWindow: state.transferWindowWinter,
    );
    phases.add(DailySimulationPhase.worldAi);

    // Phase 8: pull the world consequences back into the career model.
    pullCareerStateAfterWorld();
    phases.add(DailySimulationPhase.careerWorldBridge);

    // Phase 9: season transition is part of the same daily transaction.
    final seasonAdvanced = advanceSeasonIfComplete();
    phases.add(DailySimulationPhase.seasonMaintenance);

    final absoluteDay =
        DateTime(state.year, state.month, state.day)
            .difference(DateTime(2000, 1, 1))
            .inDays;

    lastReport = DailySimulationReport(
      year: state.year,
      month: state.month,
      day: state.day,
      absoluteDay: absoluteDay,
      phases: List.unmodifiable(phases),
      careerMatchesCompleted: matches,
      seasonAdvanced: seasonAdvanced,
    );

    return lastReport!;
  }
}
