import 'dart:math';
import '../models/match_2d.dart';

/// Resolves football duels using attributes, stamina, space and pressure.
/// It never creates a goal by itself; it only decides who wins the duel and
/// what kind of continuation the Match2DEngine should request.
class MatchDuelEngine {
  final Random random;
  MatchDuelEngine({Random? random}) : random = random ?? Random();

  DuelResult dribble({
    required Match2DPlayer attacker,
    required Match2DPlayer defender,
    required double space,
  }) {
    final attack = _score(attacker.overall, attacker.stamina, space, 0.7);
    final defence = _score(defender.overall, defender.stamina, 20 - space, 0.8);
    return _resolve(attack, defence, DuelAction.dribble);
  }

  DuelResult tackle({
    required Match2DPlayer defender,
    required Match2DPlayer attacker,
    required double distance,
  }) {
    final timing = (12 - distance).clamp(0, 12).toDouble();
    final defence = _score(defender.overall, defender.stamina, timing, 1.0);
    final attack = _score(attacker.overall, attacker.stamina, distance, .65);
    return _resolve(defence, attack, DuelAction.tackle);
  }

  DuelResult aerial({
    required Match2DPlayer attacker,
    required Match2DPlayer defender,
    required double space,
  }) {
    final a = _score(attacker.overall, attacker.stamina, space, .75);
    final d = _score(defender.overall, defender.stamina, 18 - space, .75);
    return _resolve(a, d, DuelAction.aerial);
  }

  double _score(int overall, int stamina, double context, double weight) {
    final fatigue = (100 - stamina) * .18;
    final noise = random.nextDouble() * 10 - 5;
    return overall + context * weight - fatigue + noise;
  }

  DuelResult _resolve(double first, double second, DuelAction action) {
    final delta = first - second;
    if (delta >= 12) {
      return DuelResult(action: action, outcome: DuelOutcome.cleanWin, margin: delta);
    }
    if (delta >= 0) {
      return DuelResult(action: action, outcome: DuelOutcome.win, margin: delta);
    }
    if (delta > -10) {
      return DuelResult(action: action, outcome: DuelOutcome.contested, margin: delta);
    }
    return DuelResult(action: action, outcome: DuelOutcome.loss, margin: delta);
  }
}

enum DuelAction { dribble, tackle, aerial }
enum DuelOutcome { cleanWin, win, contested, loss }

class DuelResult {
  final DuelAction action;
  final DuelOutcome outcome;
  final double margin;
  const DuelResult({required this.action, required this.outcome, required this.margin});

  bool get won => outcome == DuelOutcome.cleanWin || outcome == DuelOutcome.win;
  bool get clean => outcome == DuelOutcome.cleanWin;
}
