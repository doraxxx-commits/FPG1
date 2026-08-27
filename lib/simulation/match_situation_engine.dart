import 'dart:math';
import '../models/match_2d.dart';
import '../models/player.dart';

/// Builds short, connected attacking sequences for the 2D match.
/// It is deliberately UI-free so the same logic can later drive headless AI
/// fixtures.
class MatchSituationEngine {
  final Random random;
  MatchSituationEngine({Random? random}) : random = random ?? Random();

  MatchSituation build({
    required Match2DState state,
    required Match2DPlayer owner,
  }) {
    final team = owner.team;
    final direction = team == Match2DTeam.home ? 1.0 : -1.0;
    final distanceToGoal = team == Match2DTeam.home ? 100 - owner.x : owner.x;
    final teammates = state.players
        .where((p) => p.team == team && p.id != owner.id)
        .toList();
    final opponents = state.players.where((p) => p.team != team).toList();

    final receiver = _bestReceiver(owner, teammates, opponents, direction);
    final striker = _bestAttacker(teammates, team);
    final nearestDefender = _nearest(opponents, owner.x, owner.y);

    // Counter attack: after a turnover, exploit the space before the defence
    // can recover. This is intentionally more direct than a normal possession.
    if (distanceToGoal > 40 && _spaceAhead(owner, opponents, direction) > 18 &&
        random.nextDouble() < .35) {
      return MatchSituation(
        kind: MatchSituationKind.counter,
        beats: [
          MatchSituationBeat(
            type: Match2DEventType.pass,
            actorId: owner.id,
            secondaryId: striker.id,
            description: '${owner.name} uruchamia kontrę',
          ),
          MatchSituationBeat(
            type: Match2DEventType.dribble,
            actorId: striker.id,
            secondaryId: nearestDefender.id,
            description: '${striker.name} rusza z piłką w wolną przestrzeń',
          ),
          MatchSituationBeat(
            type: Match2DEventType.shot,
            actorId: striker.id,
            secondaryId: nearestDefender.id,
            description: '${striker.name} dochodzi do sytuacji strzeleckiej',
            isChance: true,
          ),
        ],
      );
    }

    // Wing attack: stretch the defence, then cross or cut back.
    if (owner.position == PlayerPosition.winger ||
        (owner.y < 25 || owner.y > 75) && distanceToGoal < 48) {
      final target = receiver.position == PlayerPosition.striker ? receiver : striker;
      return MatchSituation(
        kind: MatchSituationKind.wingAttack,
        beats: [
          MatchSituationBeat(
            type: Match2DEventType.dribble,
            actorId: owner.id,
            secondaryId: nearestDefender.id,
            description: '${owner.name} atakuje boczny sektor',
          ),
          MatchSituationBeat(
            type: Match2DEventType.cross,
            actorId: owner.id,
            secondaryId: target.id,
            description: '${owner.name} zagrywa piłkę w pole karne',
          ),
          MatchSituationBeat(
            type: Match2DEventType.shot,
            actorId: target.id,
            secondaryId: nearestDefender.id,
            description: '${target.name} dochodzi do dośrodkowania',
            isChance: true,
          ),
        ],
      );
    }

    // Central combination: midfielder -> striker -> finish.
    if ((owner.position == PlayerPosition.midfielder ||
            owner.position == PlayerPosition.striker) &&
        distanceToGoal < 55) {
      return MatchSituation(
        kind: MatchSituationKind.centralCombination,
        beats: [
          MatchSituationBeat(
            type: Match2DEventType.pass,
            actorId: owner.id,
            secondaryId: receiver.id,
            description: '${owner.name} gra na jeden kontakt',
          ),
          MatchSituationBeat(
            type: Match2DEventType.pass,
            actorId: receiver.id,
            secondaryId: striker.id,
            description: '${receiver.name} zagrywa piłkę za linię obrony',
          ),
          MatchSituationBeat(
            type: Match2DEventType.shot,
            actorId: striker.id,
            secondaryId: nearestDefender.id,
            description: '${striker.name} wychodzi sam na sam z bramką',
            isChance: true,
          ),
        ],
      );
    }

    // Safe build-up. It creates a believable chain without forcing a chance.
    return MatchSituation(
      kind: MatchSituationKind.buildUp,
      beats: [
        MatchSituationBeat(
          type: Match2DEventType.pass,
          actorId: owner.id,
          secondaryId: receiver.id,
          description: '${owner.name} spokojnie buduje akcję',
        ),
        MatchSituationBeat(
          type: Match2DEventType.pass,
          actorId: receiver.id,
          secondaryId: striker.id,
          description: '${receiver.name} przesuwa akcję do przodu',
        ),
      ],
    );
  }

  Match2DPlayer _bestReceiver(
    Match2DPlayer owner,
    List<Match2DPlayer> teammates,
    List<Match2DPlayer> opponents,
    double direction,
  ) {
    teammates.sort((a, b) => _passScore(b, owner, opponents, direction)
        .compareTo(_passScore(a, owner, opponents, direction)));
    return teammates.first;
  }

  double _passScore(Match2DPlayer p, Match2DPlayer owner,
      List<Match2DPlayer> opponents, double direction) {
    final forward = (p.x - owner.x) * direction;
    final nearestOpponent = _nearest(opponents, p.x, p.y);
    final pressure = _distance(p.x, p.y, nearestOpponent.x, nearestOpponent.y);
    final distance = _distance(owner.x, owner.y, p.x, p.y);
    return forward * 1.2 + pressure * .75 - (distance - 10).abs() * .25 +
        (p.position == PlayerPosition.midfielder ? 3 : 0) +
        (p.position == PlayerPosition.winger ? 2 : 0);
  }

  Match2DPlayer _bestAttacker(List<Match2DPlayer> players, Match2DTeam team) {
    final attackers = players
        .where((p) => p.position == PlayerPosition.striker ||
            p.position == PlayerPosition.winger)
        .toList();
    attackers.sort((a, b) => b.overall.compareTo(a.overall));
    return attackers.isNotEmpty ? attackers.first : players.first;
  }

  Match2DPlayer _nearest(List<Match2DPlayer> players, double x, double y) {
    return players.reduce((a, b) =>
        _distance(a.x, a.y, x, y) < _distance(b.x, b.y, x, y) ? a : b);
  }

  double _spaceAhead(Match2DPlayer owner, List<Match2DPlayer> opponents,
      double direction) {
    var best = 40.0;
    for (final p in opponents) {
      final forward = (p.x - owner.x) * direction;
      final lateral = (p.y - owner.y).abs();
      if (forward > 0 && lateral < 12) best = min(best, forward);
    }
    return best;
  }

  double _distance(double x1, double y1, double x2, double y2) =>
      sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}

enum MatchSituationKind { buildUp, counter, wingAttack, centralCombination }

class MatchSituationBeat {
  final Match2DEventType type;
  final String actorId;
  final String? secondaryId;
  final String description;
  final bool isChance;

  const MatchSituationBeat({
    required this.type,
    required this.actorId,
    this.secondaryId,
    required this.description,
    this.isChance = false,
  });
}

class MatchSituation {
  final MatchSituationKind kind;
  final List<MatchSituationBeat> beats;
  const MatchSituation({required this.kind, required this.beats});
}
