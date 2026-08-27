import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/core/daily_simulation_core.dart';
import 'package:fpg/core/game_state.dart';

void main() {
  test('V25 runs one day in deterministic causal order', () {
    final state = GameState(year: 2026, month: 7, day: 24);
    final core = DailySimulationCore(state: state);
    final calls = <String>[];

    final report = core.runDay(
      recoverPlayer: () => calls.add('recovery'),
      updatePlayerForm: () => calls.add('form'),
      updateCareerPlayerMatchStatus: () => calls.add('squad'),
      resetCareerMatchSnapshot: () => calls.add('snapshot'),
      playCareerMatches: () {
        calls.add('matches');
        return 1;
      },
      processWorldDay: ({
        required int year,
        required int month,
        required int day,
        required bool summerTransferWindow,
        required bool winterTransferWindow,
      }) {
        calls.add('world');
      },
      pushCareerStateBeforeWorld: () => calls.add('push'),
      applyCareerMatchConsequences: () => calls.add('consequences'),
      pullCareerStateAfterWorld: () => calls.add('pull'),
      advanceSeasonIfComplete: () {
        calls.add('season');
        return false;
      },
    );

    expect(state.dateString, '25.07.2026');
    expect(calls, [
      'recovery',
      'form',
      'squad',
      'snapshot',
      'matches',
      'consequences',
      'push',
      'world',
      'pull',
      'season',
    ]);
    expect(report.careerMatchesCompleted, 1);
    expect(report.phases.length, 8);
  });

  test('V25 exposes real match consequences to the world before the world tick', () {
  final state = GameState(year: 2026, month: 7, day: 24);
  final core = DailySimulationCore(state: state);
  final calls = <String>[];

  core.runDay(
    recoverPlayer: () => calls.add('recovery'),
    updatePlayerForm: () => calls.add('form'),
    updateCareerPlayerMatchStatus: () => calls.add('squad'),
    resetCareerMatchSnapshot: () => calls.add('snapshot'),
    playCareerMatches: () {
      calls.add('matches');
      return 1;
    },
    applyCareerMatchConsequences: () => calls.add('consequences'),
    pushCareerStateBeforeWorld: () => calls.add('push'),
    processWorldDay: ({
      required int year,
      required int month,
      required int day,
      required bool summerTransferWindow,
      required bool winterTransferWindow,
    }) => calls.add('world'),
    pullCareerStateAfterWorld: () => calls.add('pull'),
    advanceSeasonIfComplete: () => false,
  );

  expect(calls.indexOf('matches'), lessThan(calls.indexOf('consequences')));
  expect(calls.indexOf('consequences'), lessThan(calls.indexOf('push')));
  expect(calls.indexOf('push'), lessThan(calls.indexOf('world')));
  expect(calls.indexOf('world'), lessThan(calls.indexOf('pull')));
});
}
