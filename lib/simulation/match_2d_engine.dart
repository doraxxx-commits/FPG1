import 'dart:math';
import '../models/player.dart';
import '../models/match_2d.dart';
import 'match_situation_engine.dart';
import 'match_duel_engine.dart';

class Match2DStep {
  final Match2DEvent? event;
  final bool keyMoment;
  const Match2DStep({this.event, this.keyMoment = false});
}

/// Real-time 2D match presentation.
///
/// The league engine remains the source of the official result. This engine
/// is responsible for the minute-by-minute presentation and for pausing on
/// player-controlled key actions. A key action is NOT resolved before the
/// mini-game: applyMiniGameOutcome() resolves it afterwards.
class Match2DEngine {
  final Random random;
  late final MatchSituationEngine _situations;
  late final MatchDuelEngine _duels;
  Match2DState? state;
  String? controlledPlayerId;

  /// Maximum number of player-controlled decisive moments in one match.
  /// This keeps the New Star Soccer-like rhythm: a few important actions,
  /// not a mini-game every time the player touches the ball.
  final int maxPlayerKeyMoments;
  int _playerKeyMoments = 0;
  int _lastPlayerKeyMinute = -100;
  int _addedTime = 0;
  bool _addedTimeCalculated = false;

  final List<Match2DEvent> _events = [];
  final List<int> _homeGoalMinutes = [];
  final List<int> _awayGoalMinutes = [];
  final Set<int> _resolvedScheduledGoalsHome = {};
  final Set<int> _resolvedScheduledGoalsAway = {};

  // The official simulation is only a pre-match estimate. Player actions
  // can now move the final result by a small, realistic amount.
  int _interactiveHomeDelta = 0;
  int _interactiveAwayDelta = 0;
  int _missedPlayerGoals = 0;
  MatchSituation? _activeSituation;
  int _activeBeat = 0;
  String? _activeSituationId;

  Match2DEngine({Random? random, this.maxPlayerKeyMoments = 5})
      : random = random ?? Random() {
    _situations = MatchSituationEngine(random: random);
    _duels = MatchDuelEngine(random: random);
  }

  Match2DState create({
    required List<Player> home,
    required List<Player> away,
    int? targetHomeGoals,
    int? targetAwayGoals,
    String? controlledPlayerId,
  }) {
    this.controlledPlayerId = controlledPlayerId;
    _playerKeyMoments = 0;
    _lastPlayerKeyMinute = -100;
    _interactiveHomeDelta = 0;
    _interactiveAwayDelta = 0;
    _missedPlayerGoals = 0;
    _addedTime = 0;
    _addedTimeCalculated = false;
    _activeSituation = null;
    _activeBeat = 0;
    _activeSituationId = null;

    final homeXI = _pickXI(home);
    final awayXI = _pickXI(away);
    final players = <Match2DPlayer>[
      for (var i = 0; i < homeXI.length; i++)
        make2DPlayer(homeXI[i], Match2DTeam.home, i),
      for (var i = 0; i < awayXI.length; i++)
        make2DPlayer(awayXI[i], Match2DTeam.away, i),
    ];

    Match2DPlayer owner;
    final controlled = controlledPlayerId == null
        ? null
        : players.where((p) => p.id == controlledPlayerId).firstOrNull;
    owner = controlled ??
        players.firstWhere(
          (p) => p.position == PlayerPosition.midfielder &&
              p.team == Match2DTeam.home,
          orElse: () => players.first,
        );

    owner.hasBall = true;
    state = Match2DState(
      players: players,
      ballX: owner.x,
      ballY: owner.y,
      ballOwnerId: owner.id,
      ballTargetOwnerId: null,
      ballTravelProgress: 1.0,
      targetHomeGoals: targetHomeGoals,
      targetAwayGoals: targetAwayGoals,
    );

    _events.clear();
    _homeGoalMinutes
      ..clear()
      ..addAll(_planGoalMinutes(targetHomeGoals ?? 0));
    _awayGoalMinutes
      ..clear()
      ..addAll(_planGoalMinutes(targetAwayGoals ?? 0));
    _resolvedScheduledGoalsHome.clear();
    _resolvedScheduledGoalsAway.clear();

    return state!;
  }

  List<int> _planGoalMinutes(int count) {
    final minutes = <int>{};
    while (minutes.length < count) {
      minutes.add(5 + random.nextInt(86));
    }
    return minutes.toList()..sort();
  }

  Match2DStep tick() {
    final s = state;
    if (s == null || s.finished) return const Match2DStep();

    // The match always reaches 90'. Only then do we calculate stoppage time.
    // The added time is influenced by realistic disruptions: goals,
    // substitutions, injuries and cards. It is clamped to 1–15 minutes.
    if (s.minute == 90 && !_addedTimeCalculated) {
      _addedTime = _calculateStoppageTime();
      s.stoppageTime = _addedTime;
      _addedTimeCalculated = true;
      final event = Match2DEvent(
        type: Match2DEventType.stoppageTime,
        playerId: s.ballOwnerId ?? s.players.first.id,
        description: 'Sędzia dolicza +$_addedTime min.',
        minute: 90,
        x: s.ballX,
        y: s.ballY,
      );
      _events.add(event);
      return Match2DStep(event: event);
    }

    // From 90' onward, minute is stored as total elapsed minutes (91..105),
    // while the UI formats it as 90+1 .. 90+15.
    s.minute++;
    _recordPossessionSecond(s);

    // The 2D view must narrate the same official result. If the pre-match
    // simulation scheduled a goal for this minute, materialise it here instead
    // of dumping missing goals into the final minute. Interactive actions may
    // still change the result by the existing small +/-1 rule.
    final scheduledGoal = _materializeScheduledGoal(s);
    if (scheduledGoal != null) {
      _movePlayers(s);
      return Match2DStep(event: scheduledGoal, keyMoment: false);
    }

    final situationEvent = _advanceSituation(s);
    if (situationEvent != null) {
      _movePlayers(s);
      if (_isMatchOver(s)) {
        final forced = _forceSyncFinalScore(s);
        s.finished = true;
        return Match2DStep(
          event: forced ?? situationEvent,
          keyMoment: forced?.isKeyMoment ?? situationEvent.isKeyMoment,
        );
      }
      return Match2DStep(
        event: situationEvent,
        keyMoment: situationEvent.isKeyMoment,
      );
    }

    _movePlayers(s);
    final event = _maybeAction(s);

    if (_isMatchOver(s)) {
      final forced = _forceSyncFinalScore(s);
      s.finished = true;
      return Match2DStep(
        event: forced ?? event,
        keyMoment: forced?.isKeyMoment ?? event?.isKeyMoment ?? false,
      );
    }

    return Match2DStep(
      event: event,
      keyMoment: event?.isKeyMoment ?? false,
    );
  }

  bool _isMatchOver(Match2DState s) =>
      _addedTimeCalculated && s.minute >= 90 + _addedTime;

  int _calculateStoppageTime() {
    var seconds = 45 + random.nextInt(76); // baseline: 0:45–2:00
    for (final event in _events) {
      switch (event.type) {
        case Match2DEventType.goal:
          seconds += 45 + random.nextInt(31); // 0:45–1:15
          break;
        case Match2DEventType.injury:
          seconds += 60 + random.nextInt(121); // 1:00–3:00
          break;
        case Match2DEventType.substitution:
          seconds += 25 + random.nextInt(26); // 0:25–0:50
          break;
        case Match2DEventType.card:
          seconds += 15 + random.nextInt(21); // 0:15–0:35
          break;
        default:
          break;
      }
    }
    return (seconds / 60).ceil().clamp(1, 15);
  }

  /// UI-friendly clock text: 1'..90', then 90+1'..90+15'.
  String formatMatchMinute([int? minute]) {
    final m = minute ?? state?.minute ?? 0;
    if (m <= 90) return "$m'";
    final added = m - 90;
    return '90+$added\'';
  }

  List<Match2DEvent> get events => List.unmodifiable(_events);

  List<Player> _pickXI(List<Player> source) {
    final sorted = [...source]..sort((a, b) => b.overall.compareTo(a.overall));
    final result = <Player>[];

    void add(PlayerPosition position, int count) {
      for (final player in sorted.where((p) => p.position == position)) {
        if (result.length >= 11 || count == 0) break;
        if (!result.contains(player)) {
          result.add(player);
          count--;
        }
      }
    }

    add(PlayerPosition.goalkeeper, 1);
    add(PlayerPosition.defender, 4);
    add(PlayerPosition.midfielder, 3);
    add(PlayerPosition.winger, 2);
    add(PlayerPosition.striker, 1);

    for (final p in sorted) {
      if (result.length >= 11) break;
      if (!result.contains(p)) result.add(p);
    }
    return result.take(11).toList();
  }

  void _movePlayers(Match2DState s) {
    final owner = s.players.firstWhere(
      (p) => p.id == s.ballOwnerId,
      orElse: () => s.players.first,
    );

    // Passes are real ball transitions instead of instant owner swaps.
    final targetId = s.ballTargetOwnerId;
    if (targetId != null) {
      final target = s.players.firstWhere(
        (p) => p.id == targetId,
        orElse: () => owner,
      );
      s.ballTravelProgress = (s.ballTravelProgress + .22).clamp(0.0, 1.0).toDouble();
      final t = s.ballTravelProgress;
      final smooth = t * t * (3 - 2 * t);
      s.ballX = owner.x + (target.x - owner.x) * smooth;
      s.ballY = owner.y + (target.y - owner.y) * smooth;
      _moveOffBallPlayers(s, owner, owner.team);
      if (t >= 1.0) {
        owner.hasBall = false;
        target.hasBall = true;
        s.ballOwnerId = target.id;
        s.ballTargetOwnerId = null;
        s.ballTravelProgress = 1.0;
      }
      return;
    }

    final possessionTeam = owner.team;
    final direction = possessionTeam == Match2DTeam.home ? 1.0 : -1.0;
    final phase = _phaseForBall(s.ballX, possessionTeam);
    final forwardSpace = _forwardSpace(s, owner);
    final pressure = _nearestOpponentDistance(safePlayers: s.players, player: owner);
    final canCarry = forwardSpace > 9 && pressure > 7;
    if (canCarry) {
      final targetX = (owner.x + direction * .65).clamp(4.0, 96.0).toDouble();
      owner.x += (targetX - owner.x) * .22;
    } else {
      owner.x += (random.nextDouble() - .5) * .18;
    }
    owner.y += (random.nextDouble() - .5) * .12;
    s.ballX += (owner.x - s.ballX) * .48;
    s.ballY += (owner.y - s.ballY) * .48;

    final teammates = s.players.where((p) => p.team == possessionTeam && p.id != owner.id).toList();
    final opponents = s.players.where((p) => p.team != possessionTeam).toList();
    for (final p in s.players) {
      if (p.hasBall) continue;
      double targetX;
      double targetY;
      if (p.team == possessionTeam) {
        final support = _supportTarget(player: p, owner: owner, phase: phase, teammates: teammates);
        targetX = support.$1; targetY = support.$2;
      } else {
        final press = _shouldPress(p, owner, opponents);
        if (press) { targetX = owner.x - direction * 1.5; targetY = owner.y; }
        else { final lane = _coverLaneTarget(p, owner, direction); targetX = lane.$1; targetY = lane.$2; }
      }
      final speed = p.team == possessionTeam ? .10 : .085;
      p.x += (targetX - p.x) * speed;
      p.y += (targetY - p.y) * speed;
      p.x += (random.nextDouble() - .5) * .10;
      p.y += (random.nextDouble() - .5) * .10;
      if (p.position == PlayerPosition.goalkeeper) {
        p.x += (p.homeX - p.x) * .20;
        p.y += (s.ballY - p.y) * .06;
      }
      p.x = p.x.clamp(3.0, 97.0).toDouble();
      p.y = p.y.clamp(3.0, 97.0).toDouble();
      if (random.nextDouble() < .045) p.stamina = max(0, p.stamina - 1);
    }
    if (opponents.any((p) => _distanceXY(p.x, p.y, owner.x, owner.y) < 10) && random.nextDouble() < .12) {
      owner.stamina = max(0, owner.stamina - 1);
    }
  }

  void _moveOffBallPlayers(Match2DState s, Match2DPlayer owner, Match2DTeam possessionTeam) {
    for (final p in s.players) {
      if (p.id == owner.id) continue;
      final sameTeam = p.team == possessionTeam;
      final targetX = p.homeX + (owner.x - p.homeX) * (sameTeam ? .12 : .08);
      final targetY = p.homeY + (owner.y - p.homeY) * (sameTeam ? .10 : .06);
      p.x += (targetX - p.x) * .08;
      p.y += (targetY - p.y) * .08;
      if (p.position == PlayerPosition.goalkeeper) {
        p.x += (p.homeX - p.x) * .20;
        p.y += (s.ballY - p.y) * .04;
      }
      p.x = p.x.clamp(3.0, 97.0).toDouble();
      p.y = p.y.clamp(3.0, 97.0).toDouble();
    }
  }
  Match2DPhase _phaseForBall(double x, Match2DTeam team) {
    final distanceToGoal = team == Match2DTeam.home ? 100 - x : x;
    if (distanceToGoal > 60) return Match2DPhase.buildUp;
    if (distanceToGoal > 38) return Match2DPhase.progression;
    if (distanceToGoal > 20) return Match2DPhase.finalThird;
    return Match2DPhase.shot;
  }

  (double, double) _supportTarget({
    required Match2DPlayer player,
    required Match2DPlayer owner,
    required Match2DPhase phase,
    required List<Match2DPlayer> teammates,
  }) {
    final direction = owner.team == Match2DTeam.home ? 1.0 : -1.0;
    var x = player.homeX;
    var y = player.homeY;

    switch (player.position) {
      case PlayerPosition.goalkeeper:
        return (player.homeX, 50);
      case PlayerPosition.defender:
        // Back four shifts with the ball but remains behind it.
        x += (owner.x - x) * .18;
        y += (owner.y - y) * .10;
        break;
      case PlayerPosition.midfielder:
        // Midfielders create triangles: one closer, one wider/deeper.
        final lateral = player.homeY < 50 ? -1.0 : 1.0;
        x += (owner.x - x) * .30;
        y += (owner.y - y) * .22 + lateral * 2.0;
        break;
      case PlayerPosition.winger:
        // Wingers stretch the pitch, especially before the final third.
        x += (owner.x - x) * (phase == Match2DPhase.finalThird ? .28 : .18);
        y += (player.homeY - 50).sign * .5;
        break;
      case PlayerPosition.striker:
        // Striker attacks the space ahead rather than running directly to the
        // ball. This is the main trigger for through-ball situations.
        x += direction * (phase == Match2DPhase.finalThird ? 5.0 : 2.0);
        y += (owner.y - y) * .16;
        break;
    }

    // Avoid bunching: if another teammate is too close, move toward the
    // nearest open side while preserving the player's role.
    final crowded = teammates.where((p) => p.id != player.id).any(
      (p) => _distanceXY(p.x, p.y, x, y) < 7,
    );
    if (crowded && player.position != PlayerPosition.goalkeeper) {
      y += player.homeY < 50 ? -3.5 : 3.5;
    }
    return (x.clamp(3.0, 97.0).toDouble(), y.clamp(5.0, 95.0).toDouble());
  }

  bool _shouldPress(
    Match2DPlayer defender,
    Match2DPlayer owner,
    List<Match2DPlayer> opponents,
  ) {
    if (defender.position == PlayerPosition.goalkeeper) return false;
    final distance = _distanceXY(defender.x, defender.y, owner.x, owner.y);
    if (distance > 15) return false;

    var nearest = double.infinity;
    for (final p in opponents) {
      if (p.id == defender.id) continue;
      nearest = min(nearest, _distanceXY(p.x, p.y, owner.x, owner.y));
    }
    return distance <= nearest + 2.5;
  }

  (double, double) _coverLaneTarget(
    Match2DPlayer defender,
    Match2DPlayer owner,
    double direction,
  ) {
    final x = defender.homeX + (owner.x - defender.homeX) * .14;
    final y = defender.homeY + (owner.y - defender.homeY) * .20;
    return (x - direction * 1.5, y);
  }

  double _forwardSpace(Match2DState s, Match2DPlayer owner) {
    final direction = owner.team == Match2DTeam.home ? 1.0 : -1.0;
    var best = 35.0;
    for (final p in s.players) {
      if (p.team == owner.team) continue;
      final forward = (p.x - owner.x) * direction;
      final lateral = (p.y - owner.y).abs();
      if (forward >= 0 && lateral < 8) best = min(best, forward);
    }
    return best;
  }

  double _teamMinDistance(
      Match2DState s, Match2DTeam team, double x, double y) {
    var best = double.infinity;
    for (final p in s.players) {
      if (p.team != team) continue;
      best = min(best, _distanceXY(p.x, p.y, x, y));
    }
    return best;
  }

  double _distanceXY(double x1, double y1, double x2, double y2) =>
      sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));

  Match2DEvent? _advanceSituation(Match2DState s) {
    final active = _activeSituation;
    if (active == null) return null;
    if (_activeBeat >= active.beats.length) {
      _activeSituation = null;
      _activeSituationId = null;
      _activeBeat = 0;
      return null;
    }

    final beat = active.beats[_activeBeat++];
    final actor = s.players.firstWhere(
      (p) => p.id == beat.actorId,
      orElse: () => s.players.first,
    );
    final secondary = beat.secondaryId == null
        ? null
        : s.players.where((p) => p.id == beat.secondaryId).firstOrNull;

    // Move the ball to the actor of the next beat. This makes the sequence
    // visually readable even before the animation layer becomes richer.
    final currentOwner = s.players.where((p) => p.id == s.ballOwnerId).firstOrNull;
    if (currentOwner != null && currentOwner.id != actor.id) {
      _setOwner(s, currentOwner, actor);
    }

    final isPlayer = actor.id == controlledPlayerId;
    final canKey = isPlayer &&
        _playerKeyMoments < maxPlayerKeyMoments &&
        s.minute - _lastPlayerKeyMinute >= 6 &&
        (beat.isChance || beat.type == Match2DEventType.tackle);

    if (canKey) {
      final mini = _miniGameFor(beat.type, actor.position);
      if (mini != null) {
        return _keyEvent(
          type: beat.type,
          player: actor,
          secondary: secondary,
          description: beat.description,
          miniGameType: mini,
          x: actor.x,
          y: actor.y,
          s: s,
          situationId: _activeSituationId,
          situationBeat: _activeBeat - 1,
          isChance: beat.isChance,
        );
      }
    }

    // AI resolves non-player beats immediately, so a headless match can use
    // the exact same sequence without needing a UI interaction.
    _resolveAIAttackBeat(s, actor, secondary, beat);
    final event = Match2DEvent(
      type: beat.type,
      playerId: actor.id,
      secondaryPlayerId: secondary?.id,
      description: beat.description,
      minute: s.minute,
      x: s.ballX,
      y: s.ballY,
      isKeyMoment: false,
      situationId: _activeSituationId,
      situationBeat: _activeBeat - 1,
      isChance: beat.isChance,
    );
    _recordEventStats(s, event: event.type, team: actor.team, keyMoment: false);
    _events.add(event);
    return event;
  }

  String? _miniGameFor(Match2DEventType type, PlayerPosition position) {
    final base = switch (type) {
      Match2DEventType.shot when position != PlayerPosition.goalkeeper => 'shot',
      Match2DEventType.pass || Match2DEventType.cross => 'pass',
      Match2DEventType.dribble => 'dribble',
      Match2DEventType.tackle => 'tackle',
      Match2DEventType.save => 'save',
      _ => null,
    };
    if (base == null) return null;
    // Variant selection is deterministic from the situation context, so the
    // same position can receive five genuinely different mini-game prompts.
    final seed = (_activeBeat + sMinuteSeed) % 5;
    const variants = {
      'shot': ['shotPlacement', 'shotPower', 'shotFirstTime', 'shotOneOnOne', 'shotVolley'],
      'pass': ['passThroughBall', 'passQuickOneTwo', 'passCross', 'passSwitch', 'passFinalBall'],
      'dribble': ['dribbleInside', 'dribbleOutside', 'dribbleStopGo', 'dribbleBodyFeint', 'dribbleCounter'],
      'tackle': ['tackleFront', 'tackleSide', 'tackleRecovery', 'tackleInterception', 'tackleLastMan'],
      'save': ['saveGround', 'saveHigh', 'saveNearPost', 'saveOneOnOne', 'savePenalty'],
    };
    return '$base:${variants[base]![seed]}';
  }

  int get sMinuteSeed => state?.minute ?? 0;

  void _resolveAIAttackBeat(
    Match2DState s,
    Match2DPlayer actor,
    Match2DPlayer? secondary,
    MatchSituationBeat beat,
  ) {
    switch (beat.type) {
      case Match2DEventType.pass:
      case Match2DEventType.cross:
        _transferBall(s, actor);
        break;
      case Match2DEventType.dribble:
        final defender = secondary ?? _nearestOpponent(s, actor);
        final duel = _duels.dribble(
          attacker: actor,
          defender: defender,
          space: _forwardSpace(s, actor),
        );
        if (duel.won) {
          _moveAfterDribble(s, actor);
        } else {
          _transferBall(s, actor, toOpponent: true);
        }
        break;
      case Match2DEventType.shot:
        if (_resolveShot(s, actor)) {
          // goal already registered
        } else {
          _transferBall(s, actor, toOpponent: true);
        }
        break;
      default:
        break;
    }
  }

  Match2DEvent? _maybeAction(Match2DState s) {
    // The slower clock gives the 2D match a "football broadcast" rhythm.
    // Transition moments get priority so counters and recoveries feel
    // connected instead of being independent random events.
    final ownerAtStart = s.players.firstWhere(
      (p) => p.id == s.ballOwnerId,
      orElse: () => s.players.first,
    );
    final pressureAtStart = _nearestOpponentDistance(
      safePlayers: s.players,
      player: ownerAtStart,
    );
    if (pressureAtStart < 5.5 && random.nextDouble() < .38) {
      final opponent = _nearestOpponent(s, ownerAtStart);
      final duel = _duels.tackle(
        defender: opponent,
        attacker: ownerAtStart,
        distance: pressureAtStart,
      );
      if (!duel.won) {
        _transferBall(s, ownerAtStart, toOpponent: true);
        final event = Match2DEvent(
          type: Match2DEventType.tackle,
          playerId: opponent.id,
          secondaryPlayerId: ownerAtStart.id,
          description: '${opponent.name} odzyskuje piłkę',
          minute: s.minute,
          x: s.ballX,
          y: s.ballY,
        );
        _recordEventStats(s, event: event.type, team: opponent.team, keyMoment: false);
        _events.add(event);
        return event;
      }
    }

    if (random.nextDouble() > .30) return null;

    final owner = s.players.firstWhere(
      (p) => p.id == s.ballOwnerId,
      orElse: () => s.players.first,
    );

    // Build a connected situation before falling back to a standalone event.
    // Chances are more frequent in dangerous areas and after transitions.
    final phase = _phaseForBall(s.ballX, owner.team);
    final chanceRoll = random.nextDouble();
    if ((phase == Match2DPhase.progression || phase == Match2DPhase.finalThird || phase == Match2DPhase.shot) &&
        chanceRoll < .42) {
      _activeSituation = _situations.build(state: s, owner: owner);
      _activeBeat = 0;
      _activeSituationId = '${s.minute}_${owner.id}_${random.nextInt(100000)}';
      return _advanceSituation(s);
    }

    final nearestOpponent = s.players
        .where((p) => p.team != owner.team)
        .reduce(
          (a, b) => _distanceXY(a.x, a.y, owner.x, owner.y) <
                  _distanceXY(b.x, b.y, owner.x, owner.y)
              ? a
              : b,
        );

    final controlled = _controlledPlayer(s);
    final ownerIsControlled = controlled?.id == owner.id;
    final controlledIsDefender = controlled != null &&
        controlled.team != owner.team &&
        _distanceXY(controlled.x, controlled.y, owner.x, owner.y) < 18;

    final canTriggerPlayerMoment = controlled != null &&
        _playerKeyMoments < maxPlayerKeyMoments &&
        s.minute - _lastPlayerKeyMinute >= 6;

    final distanceToGoal =
        owner.team == Match2DTeam.home ? 100 - owner.x : owner.x;

    // A player-controlled defender gets a real tackle decision instead of
    // waiting for the AI to resolve the duel.
    if (canTriggerPlayerMoment && controlledIsDefender &&
        (owner.position == PlayerPosition.striker ||
            owner.position == PlayerPosition.winger ||
            distanceToGoal < 34)) {
      return _keyEvent(
        type: Match2DEventType.tackle,
        player: controlled!,
        secondary: owner,
        description: '${controlled!.name} wychodzi do odbioru',
        miniGameType: 'tackle',
        x: owner.x,
        y: owner.y,
        s: s,
      );
    }

    if (canTriggerPlayerMoment && ownerIsControlled) {
      final roll = random.nextDouble();

      if (distanceToGoal < 24 && owner.position != PlayerPosition.goalkeeper) {
        return _keyEvent(
          type: Match2DEventType.shot,
          player: owner,
          secondary: nearestOpponent,
          description: '${owner.name} ma okazję na strzał',
          miniGameType: 'shot',
          x: owner.x,
          y: owner.y,
          s: s,
        );
      }

      if (owner.position == PlayerPosition.winger && distanceToGoal < 42) {
        return _keyEvent(
          type: roll < .55
              ? Match2DEventType.dribble
              : Match2DEventType.cross,
          player: owner,
          secondary: nearestOpponent,
          description: roll < .55
              ? '${owner.name} rusza z piłką na obrońcę'
              : '${owner.name} szuka dośrodkowania',
          miniGameType: roll < .55 ? 'dribble' : 'pass',
          x: owner.x,
          y: owner.y,
          s: s,
        );
      }

      if (owner.position == PlayerPosition.midfielder) {
        return _keyEvent(
          type: Match2DEventType.pass,
          player: owner,
          secondary: nearestOpponent,
          description: '${owner.name} widzi podanie otwierające akcję',
          miniGameType: 'pass',
          x: owner.x,
          y: owner.y,
          s: s,
        );
      }

      if (roll < .50) {
        return _keyEvent(
          type: Match2DEventType.dribble,
          player: owner,
          secondary: nearestOpponent,
          description: '${owner.name} próbuje minąć rywala',
          miniGameType: 'dribble',
          x: owner.x,
          y: owner.y,
          s: s,
        );
      }
    }

    // Goalkeeper key moment: an AI opponent shoots near the controlled GK.
    if (canTriggerPlayerMoment && controlled != null &&
        controlled.position == PlayerPosition.goalkeeper &&
        controlled.team != owner.team &&
        distanceToGoal < 25) {
      return _keyEvent(
        type: Match2DEventType.save,
        player: controlled,
        secondary: owner,
        description: '${owner.name} oddaje strzał — bramkarz musi interweniować',
        miniGameType: 'save',
        x: owner.x,
        y: owner.y,
        s: s,
      );
    }

    final roll = random.nextDouble();
    final space = _forwardSpace(s, owner);
    Match2DEventType type;
    String text;

    if (distanceToGoal < 25 && roll < .50) {
      type = Match2DEventType.shot;
      text = '${owner.name} oddaje strzał';
    } else if (phase == Match2DPhase.progression && space > 14 && roll < .48) {
      type = Match2DEventType.pass;
      text = '${owner.name} zagrywa piłkę do wolnej strefy';
    } else if (_distanceXY(
              nearestOpponent.x,
              nearestOpponent.y,
              owner.x,
              owner.y,
            ) <
            14 &&
            roll < .66) {
      type = owner.position == PlayerPosition.defender
          ? Match2DEventType.tackle
          : Match2DEventType.dribble;
      text = type == Match2DEventType.tackle
          ? '${nearestOpponent.name} próbuje odbioru'
          : '${owner.name} próbuje dryblingu';
    } else {
      type = roll < .18 ? Match2DEventType.cross : Match2DEventType.pass;
      text = type == Match2DEventType.cross
          ? '${owner.name} dośrodkowuje'
          : '${owner.name} zagrywa piłkę';
    }

    if (type == Match2DEventType.shot) {
      final goal = _resolveShot(s, owner);
      if (goal) {
        type = Match2DEventType.goal;
        text = 'GOOOL! ${owner.name} trafia do siatki';
      } else {
        type = Match2DEventType.save;
        text = 'Bramkarz broni strzał ${owner.name}';
        _transferBall(s, owner, toOpponent: true);
      }
    } else {
      _transferBall(s, owner, toOpponent: type == Match2DEventType.tackle);
    }

    _recordEventStats(s, event: type, team: owner.team, keyMoment: false);

    final event = Match2DEvent(
      type: type,
      playerId: owner.id,
      secondaryPlayerId: nearestOpponent.id,
      description: text,
      minute: s.minute,
      x: s.ballX,
      y: s.ballY,
      isKeyMoment: false,
    );
    _events.add(event);
    return event;
  }

  Match2DEvent _keyEvent({
    required Match2DEventType type,
    required Match2DPlayer player,
    Match2DPlayer? secondary,
    required String description,
    required String miniGameType,
    required double x,
    required double y,
    required Match2DState s,
    String? situationId,
    int situationBeat = 0,
    bool isChance = false,
  }) {
    _playerKeyMoments++;
    _lastPlayerKeyMinute = s.minute;

    final event = Match2DEvent(
      type: type,
      playerId: player.id,
      secondaryPlayerId: secondary?.id,
      description: description,
      minute: s.minute,
      x: x,
      y: y,
      isKeyMoment: true,
      miniGameType: miniGameType,
      situationId: situationId,
      situationBeat: situationBeat,
      isChance: isChance,
    );
    _recordEventStats(s, event: type, team: player.team, keyMoment: true);
    _events.add(event);
    return event;
  }

  Match2DPlayer? _controlledPlayer(Match2DState s) {
    final id = controlledPlayerId;
    if (id == null) return null;
    for (final p in s.players) {
      if (p.id == id) return p;
    }
    return null;
  }

  Match2DEvent? _materializeScheduledGoal(Match2DState s) {
    final homeDue = _isScheduledGoalMinute(s.minute, true) &&
        s.targetHomeGoals != null && s.homeGoals < s.targetHomeGoals!;
    final awayDue = _isScheduledGoalMinute(s.minute, false) &&
        s.targetAwayGoals != null && s.awayGoals < s.targetAwayGoals!;
    if (!homeDue && !awayDue) return null;

    final home = homeDue && (!awayDue || random.nextBool());
    _registerGoal(s, home);
    final scorer = _bestAttacker(s, home ? Match2DTeam.home : Match2DTeam.away);
    final event = Match2DEvent(
      type: Match2DEventType.goal,
      playerId: scorer.id,
      description: 'GOOOL! ${scorer.name} trafia po dobrze rozegranej akcji',
      minute: s.minute,
      x: scorer.x,
      y: scorer.y,
      isKeyMoment: false,
    );
    _events.add(event);
    _recordEventStats(s, event: event.type, team: scorer.team, keyMoment: false);
    return event;
  }

  bool _resolveShot(Match2DState s, Match2DPlayer shooter) {
    final home = shooter.team == Match2DTeam.home;
    final target = home ? s.targetHomeGoals : s.targetAwayGoals;
    final current = home ? s.homeGoals : s.awayGoals;

    if (target != null) {
      if (current >= target) return false;
      final minutesLeft = max(1, 90 - s.minute);
      final goalsLeft = target - current;
      final scheduled = _isScheduledGoalMinute(s.minute, home);
      final mustScore = goalsLeft >= (minutesLeft ~/ 8) + 1;
      if (scheduled || mustScore || random.nextDouble() < .07) {
        _registerGoal(s, home);
        return true;
      }
      return false;
    }

    if (random.nextDouble() < .16) {
      _registerGoal(s, home);
      return true;
    }
    return false;
  }

  bool _isScheduledGoalMinute(int minute, bool home) {
    final list = home ? _homeGoalMinutes : _awayGoalMinutes;
    return list.contains(minute);
  }

  Match2DEvent? _forceSyncFinalScore(Match2DState s) {
    Match2DEvent? last;
    while (s.targetHomeGoals != null &&
        s.homeGoals < s.targetHomeGoals!) {
      _registerGoal(s, true);
      final scorer = _bestAttacker(s, Match2DTeam.home);
      last = Match2DEvent(
        type: Match2DEventType.goal,
        playerId: scorer.id,
        description: 'GOOOL! ${scorer.name} trafia w końcówce',
        minute: s.minute,
        x: s.ballX,
        y: s.ballY,
        isKeyMoment: false,
      );
      _events.add(last);
    }
    while (s.targetAwayGoals != null &&
        s.awayGoals < s.targetAwayGoals!) {
      _registerGoal(s, false);
      final scorer = _bestAttacker(s, Match2DTeam.away);
      last = Match2DEvent(
        type: Match2DEventType.goal,
        playerId: scorer.id,
        description: 'GOOOL! ${scorer.name} trafia w końcówce',
        minute: s.minute,
        x: s.ballX,
        y: s.ballY,
        isKeyMoment: false,
      );
      _events.add(last);
    }
    return last;
  }

  Match2DPlayer _bestAttacker(Match2DState s, Match2DTeam team) {
    final candidates = s.players
        .where((p) =>
            p.team == team &&
            p.position != PlayerPosition.goalkeeper)
        .toList()
      ..sort((a, b) => b.overall.compareTo(a.overall));
    return candidates.isNotEmpty ? candidates.first : s.players.first;
  }

  void _registerGoal(Match2DState s, bool isHome) {
    if (isHome) {
      s.homeGoals++;
    } else {
      s.awayGoals++;
    }
  }

  /// Resolves the pending player action after a mini-game.
  ///
  /// For official league fixtures the target result is still a hard ceiling:
  /// the visual match cannot create a table result different from the league
  /// engine. The mini-game decides whether the player's opportunity succeeds.
  int get finalHomeGoals => state?.homeGoals ?? 0;
  int get finalAwayGoals => state?.awayGoals ?? 0;

  /// Difference between the pre-match estimate and what happened after
  /// interactive player actions.
  int get interactiveHomeDelta => _interactiveHomeDelta;
  int get interactiveAwayDelta => _interactiveAwayDelta;

  Match2DEvent? applyMiniGameOutcome(
    Match2DEvent originalEvent,
    bool success,
  ) {
    final s = state;
    if (s == null || !originalEvent.isKeyMoment) return null;

    final actor = s.players.firstWhere(
      (p) => p.id == originalEvent.playerId,
      orElse: () => s.players.first,
    );

    Match2DEvent result;

    switch (originalEvent.miniGameType) {
      case 'shot':
        final home = actor.team == Match2DTeam.home;
        final target = home ? (s.targetHomeGoals ?? 0) : (s.targetAwayGoals ?? 0);
        final current = home ? s.homeGoals : s.awayGoals;
        // The baseline result is no longer a hard ceiling. A successful
        // player action may add one decisive goal to the simulated result.
        final interactiveCap = target + 1;
        final budgetLeft = current < interactiveCap;

        if (success && budgetLeft) {
          _registerGoal(s, home);
          if (home) {
            _interactiveHomeDelta++;
          } else {
            _interactiveAwayDelta++;
          }
          result = Match2DEvent(
            type: Match2DEventType.goal,
            playerId: actor.id,
            secondaryPlayerId: originalEvent.secondaryPlayerId,
            description: 'GOOOL! ${actor.name} wykorzystuje okazję!',
            minute: s.minute,
            x: s.ballX,
            y: s.ballY,
            isKeyMoment: true,
          );
        } else {
          _transferBall(s, actor, toOpponent: true);
          _breakActiveSituation();
          result = Match2DEvent(
            type: Match2DEventType.save,
            playerId: actor.id,
            secondaryPlayerId: originalEvent.secondaryPlayerId,
            description: 'Bramkarz zatrzymuje strzał ${actor.name}',
            minute: s.minute,
            x: s.ballX,
            y: s.ballY,
            isKeyMoment: true,
          );
        }
        break;

      case 'pass':
        if (success) {
          _transferBall(s, actor);
          // Successful execution keeps the current situation alive. The next
          // tick advances to its next beat (receiver, cross, finish, etc.).
          result = _resultEvent(
            originalEvent,
            Match2DEventType.pass,
            '${actor.name} zagrywa idealną piłkę',
          );
        } else {
          _transferBall(s, actor, toOpponent: true);
          _breakActiveSituation();
          result = _resultEvent(
            originalEvent,
            Match2DEventType.interception,
            'Podanie ${actor.name} zostaje przecięte',
          );
        }
        break;

      case 'dribble':
        final defender = _nearestOpponent(s, actor);
        if (success) {
          _moveAfterDribble(s, actor);
          // A successful duel opens the next branch of the same attack.
          result = _resultEvent(
            originalEvent,
            Match2DEventType.dribble,
            '${actor.name} mija rywala',
          );
        } else {
          _transferBall(s, actor, toOpponent: true);
          _breakActiveSituation();
          result = _resultEvent(
            originalEvent,
            Match2DEventType.tackle,
            '${defender.name} odbiera piłkę',
          );
        }
        break;

      case 'tackle':
        if (success) {
          _transferBall(s, actor, toOpponent: false);
          result = _resultEvent(
            originalEvent,
            Match2DEventType.tackle,
            '${actor.name} świetnie odbiera piłkę',
          );
        } else {
          final opponent = _nearestOpponent(s, actor);
          _breakActiveSituation();
          result = _resultEvent(
            originalEvent,
            Match2DEventType.dribble,
            '${opponent.name} wychodzi spod pressingu',
          );
        }
        break;

      case 'save':
        // For a save, actor is the goalkeeper and secondary is the shooter.
        final home = actor.team == Match2DTeam.home;
        final target = home ? s.targetAwayGoals : s.targetHomeGoals;
        final current = home ? s.awayGoals : s.homeGoals;
        final budgetLeft = target == null || current < target;

        if (success) {
          // A great goalkeeper intervention can cancel one expected AI goal.
          // We do not rewrite the whole match; we only remove one pending
          // goal from this team's baseline if one is still available.
          final opponentGoals = home ? _homeGoalMinutes : _awayGoalMinutes;
          final resolved = home
              ? _resolvedScheduledGoalsAway
              : _resolvedScheduledGoalsHome;
          final pending = opponentGoals.where((m) => !resolved.contains(m)).toList();
          if (pending.isNotEmpty) {
            resolved.add(pending.last);
            _missedPlayerGoals++;
          }
          _transferBall(s, actor, toOpponent: false);
          _breakActiveSituation();
          result = _resultEvent(
            originalEvent,
            Match2DEventType.save,
            '${actor.name} broni strzał!',
          );
        } else if (budgetLeft) {
          _registerGoal(s, !home);
          _breakActiveSituation();
          final shooter = _nearestOpponent(s, actor);
          result = Match2DEvent(
            type: Match2DEventType.goal,
            playerId: shooter.id,
            secondaryPlayerId: actor.id,
            description: 'GOOOL! Bramkarz nie zdołał obronić',
            minute: s.minute,
            x: s.ballX,
            y: s.ballY,
            isKeyMoment: true,
          );
          _events.add(result);
        } else {
          _transferBall(s, actor, toOpponent: false);
          _breakActiveSituation();
          result = _resultEvent(
            originalEvent,
            Match2DEventType.save,
            '${actor.name} broni strzał',
          );
        }
        break;

      default:
        _transferBall(s, actor);
        result = _resultEvent(
          originalEvent,
          originalEvent.type,
          '${actor.name} wykonuje akcję',
        );
    }

    _events.add(result);
    return result;
  }

  Match2DEvent _resultEvent(
    Match2DEvent original,
    Match2DEventType type,
    String description,
  ) =>
      Match2DEvent(
        type: type,
        playerId: original.playerId,
        secondaryPlayerId: original.secondaryPlayerId,
        description: description,
        minute: original.minute,
        x: original.x,
        y: original.y,
        isKeyMoment: true,
        situationId: original.situationId,
        situationBeat: original.situationBeat,
        isChance: original.isChance,
      );

  void _breakActiveSituation() {
    _activeSituation = null;
    _activeSituationId = null;
    _activeBeat = 0;
  }

  Match2DPlayer _nearestOpponent(Match2DState s, Match2DPlayer actor) {
    final opponents = s.players.where((p) => p.team != actor.team).toList();
    opponents.sort((a, b) => _distanceXY(a.x, a.y, actor.x, actor.y)
        .compareTo(_distanceXY(b.x, b.y, actor.x, actor.y)));
    return opponents.first;
  }

  void _moveAfterDribble(Match2DState s, Match2DPlayer actor) {
    final dir = actor.team == Match2DTeam.home ? 1.0 : -1.0;
    actor.x = (actor.x + dir * 6).clamp(3.0, 97.0).toDouble();
    s.ballX = actor.x;
    s.ballY = actor.y;
  }

  void _transferBall(
    Match2DState s,
    Match2DPlayer owner, {
    bool toOpponent = false,
  }) {
    final pool = toOpponent
        ? s.players.where((p) => p.team != owner.team).toList()
        : s.players
            .where((p) => p.team == owner.team && p.id != owner.id)
            .toList();

    if (pool.isEmpty) return;

    // A controlled player gets a slightly higher chance of receiving normal
    // passes. This creates more playable moments without forcing possession.
    if (!toOpponent && controlledPlayerId != null) {
      final controlled = pool.where((p) => p.id == controlledPlayerId).firstOrNull;
      if (controlled != null && random.nextDouble() < .20) {
        _setOwner(s, owner, controlled);
        return;
      }
    }

    pool.sort(
      (a, b) => _distanceXY(a.x, a.y, s.ballX, s.ballY)
          .compareTo(_distanceXY(b.x, b.y, s.ballX, s.ballY)),
    );

    final target = toOpponent
        ? pool.first
        : _bestPassTarget(owner, pool);

    _setOwner(s, owner, target);
  }

  Match2DPlayer _bestPassTarget(
      Match2DPlayer owner, List<Match2DPlayer> pool) {
    final dir = owner.team == Match2DTeam.home ? 1.0 : -1.0;
    pool.sort((a, b) {
      double score(Match2DPlayer p) {
        final forward = (p.x - owner.x) * dir;
        final distance = _distanceXY(p.x, p.y, owner.x, owner.y);
        final pressure = _nearestOpponentDistance(safePlayers: state!.players, player: p);
        final width = (p.y - 50).abs();
        final roleBonus = switch (p.position) {
          PlayerPosition.striker => 5.0,
          PlayerPosition.winger => 3.0,
          PlayerPosition.midfielder => 2.0,
          _ => 0.0,
        };
        final spaceBonus = pressure.clamp(0, 18) * .55;
        final forwardBonus = forward.clamp(-15, 20) * 1.15;
        final distancePenalty = (distance - 8).abs() * .32;
        final widthPenalty = width > 43 ? (width - 43) * .15 : 0;
        return forwardBonus + spaceBonus + roleBonus - distancePenalty - widthPenalty + random.nextDouble() * 1.5;
      }
      return score(b).compareTo(score(a));
    });
    return pool.first;
  }

  double _nearestOpponentDistance({
    required List<Match2DPlayer> safePlayers,
    required Match2DPlayer player,
  }) {
    var best = double.infinity;
    for (final p in safePlayers) {
      if (p.team == player.team) continue;
      best = min(best, _distanceXY(p.x, p.y, player.x, player.y));
    }
    return best;
  }

  void _recordPossessionSecond(Match2DState s) {
    final ownerId = s.ballOwnerId;
    if (ownerId == null) return;
    final owner = s.players.firstWhere((p) => p.id == ownerId, orElse: () => s.players.first);
    if (owner.team == Match2DTeam.home) {
      s.stats.homePossessionSeconds++;
    } else {
      s.stats.awayPossessionSeconds++;
    }
  }

  void _recordEventStats(
    Match2DState s, {
    required Match2DEventType event,
    required Match2DTeam team,
    required bool keyMoment,
  }) {
    final home = team == Match2DTeam.home;
    switch (event) {
      case Match2DEventType.shot:
        home ? s.stats.homeShots++ : s.stats.awayShots++;
        break;
      case Match2DEventType.save:
        home ? s.stats.awayShotsOnTarget++ : s.stats.homeShotsOnTarget++;
        break;
      case Match2DEventType.pass:
      case Match2DEventType.cross:
        if (home) {
          s.stats.homePasses++;
          s.stats.homeCompletedPasses++;
        } else {
          s.stats.awayPasses++;
          s.stats.awayCompletedPasses++;
        }
        break;
      case Match2DEventType.dribble:
        home ? s.stats.homeDribbles++ : s.stats.awayDribbles++;
        break;
      case Match2DEventType.tackle:
      case Match2DEventType.interception:
        home ? s.stats.homeTackles++ : s.stats.awayTackles++;
        break;
      default:
        break;
    }
    if (keyMoment) {
      home ? s.stats.homeKeyMoments++ : s.stats.awayKeyMoments++;
    }
  }

  void _setOwner(
      Match2DState s, Match2DPlayer oldOwner, Match2DPlayer newOwner) {
    oldOwner.hasBall = false;
    newOwner.hasBall = false;
    s.ballOwnerId = oldOwner.id;
    s.ballTargetOwnerId = newOwner.id;
    s.ballTravelProgress = 0.0;
    s.ballX = oldOwner.x;
    s.ballY = oldOwner.y;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
