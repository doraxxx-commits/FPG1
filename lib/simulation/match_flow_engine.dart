import 'dart:math';
import '../models/player.dart';
import '../models/match_2d.dart';

/// Event-driven football logic shared by the 2D presentation and future
/// headless AI matches. It deliberately does not know about Flutter/UI.
class MatchFlowEngine {
  final Random random;
  MatchFlowEngine({Random? random}) : random = random ?? Random();

  Match2DResult simulateMinute({
    required Match2DState state,
    required Match2DPlayer owner,
    required Match2DPlayer opponent,
    String? controlledPlayerId,
  }) {
    final distanceToGoal = owner.team == Match2DTeam.home ? 100 - owner.x : owner.x;
    final pressure = _distance(owner.x, owner.y, opponent.x, opponent.y);
    final controlled = owner.id == controlledPlayerId;

    if (controlled && owner.position != PlayerPosition.goalkeeper && distanceToGoal < 23) {
      return Match2DResultFactory.key(
        type: Match2DEventType.shot,
        player: owner,
        opponent: opponent,
        miniGame: 'shot',
        text: '${owner.name} ma okazję na strzał',
        state: state,
      );
    }

    if (controlled && owner.position == PlayerPosition.midfielder && pressure > 8) {
      return Match2DResultFactory.key(
        type: Match2DEventType.pass,
        player: owner,
        opponent: opponent,
        miniGame: 'pass',
        text: '${owner.name} widzi podanie otwierające',
        state: state,
      );
    }

    if (controlled && owner.position == PlayerPosition.winger && distanceToGoal < 42) {
      final dribble = random.nextDouble() < .55;
      return Match2DResultFactory.key(
        type: dribble ? Match2DEventType.dribble : Match2DEventType.cross,
        player: owner,
        opponent: opponent,
        miniGame: dribble ? 'dribble' : 'pass',
        text: dribble ? '${owner.name} rusza na obrońcę' : '${owner.name} szuka dośrodkowania',
        state: state,
      );
    }

    if (pressure < 11 && owner.position != PlayerPosition.goalkeeper) {
      return Match2DResultFactory.normal(
        type: Match2DEventType.dribble,
        player: owner,
        opponent: opponent,
        text: '${owner.name} próbuje minąć rywala',
        state: state,
      );
    }

    final cross = distanceToGoal < 38 && random.nextDouble() < .35;
    return Match2DResultFactory.normal(
      type: cross ? Match2DEventType.cross : Match2DEventType.pass,
      player: owner,
      opponent: opponent,
      text: cross ? '${owner.name} dośrodkowuje' : '${owner.name} buduje akcję podaniem',
      state: state,
    );
  }

  double _distance(double x1, double y1, double x2, double y2) =>
      sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}

class Match2DResultFactory {
  static Match2DResult key({required Match2DEventType type, required Match2DPlayer player, required Match2DPlayer opponent, required String miniGame, required String text, required Match2DState state}) => Match2DResult(_event(type, player, opponent, text, state, key: true, mini: miniGame), true);

  static Match2DResult normal({required Match2DEventType type, required Match2DPlayer player, required Match2DPlayer opponent, required String text, required Match2DState state}) => Match2DResult(_event(type, player, opponent, text, state), false);

  static Match2DEvent _event(Match2DEventType type, Match2DPlayer player, Match2DPlayer opponent, String text, Match2DState state, {bool key = false, String? mini}) => Match2DEvent(type: type, playerId: player.id, secondaryPlayerId: opponent.id, description: text, minute: state.minute, x: state.ballX, y: state.ballY, isKeyMoment: key, miniGameType: mini);

}

class Match2DResult {
  final Match2DEvent event;
  final bool keyMoment;
  const Match2DResult(this.event, this.keyMoment);
}
