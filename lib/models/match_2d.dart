import 'player.dart';

enum Match2DTeam { home, away }

enum Match2DPhase {
  buildUp,
  progression,
  finalThird,
  shot,
}

enum Match2DEventType {
  pass,
  dribble,
  shot,
  tackle,
  save,
  cross,
  clearance,
  interception,
  goal,
  card,
  injury,
  substitution,
  stoppageTime,
}

class Match2DPlayer {
  final String id;
  final String name;
  final PlayerPosition position;
  final Match2DTeam team;
  final int shirtNumber;
  double x;
  double y;
  final double homeX;
  final double homeY;
  bool hasBall;
  bool controlledByAI;
  int stamina;
  final int overall;

  Match2DPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.team,
    required this.x,
    required this.y,
    required this.shirtNumber,
    required this.overall,
    double? homeX,
    double? homeY,
    this.hasBall = false,
    this.controlledByAI = true,
    this.stamina = 100,
  })  : homeX = homeX ?? x,
        homeY = homeY ?? y;
}

class Match2DEvent {
  final Match2DEventType type;
  final String playerId;
  final String? secondaryPlayerId;
  final String description;
  final int minute;
  final double x;
  final double y;
  final bool isKeyMoment;
  final String? miniGameType;
  final String? situationId;
  final int situationBeat;
  final bool isChance;

  const Match2DEvent({
    required this.type,
    required this.playerId,
    this.secondaryPlayerId,
    required this.description,
    required this.minute,
    required this.x,
    required this.y,
    this.isKeyMoment = false,
    this.miniGameType,
    this.situationId,
    this.situationBeat = 0,
    this.isChance = false,
  });
}

class Match2DStats {
  int homePossessionSeconds = 0;
  int awayPossessionSeconds = 0;
  int homeShots = 0;
  int awayShots = 0;
  int homeShotsOnTarget = 0;
  int awayShotsOnTarget = 0;
  int homePasses = 0;
  int awayPasses = 0;
  int homeCompletedPasses = 0;
  int awayCompletedPasses = 0;
  int homeDribbles = 0;
  int awayDribbles = 0;
  int homeTackles = 0;
  int awayTackles = 0;
  int homeKeyMoments = 0;
  int awayKeyMoments = 0;

  double get homePossessionPercent {
    final total = homePossessionSeconds + awayPossessionSeconds;
    return total == 0 ? 50 : homePossessionSeconds * 100 / total;
  }

  double get awayPossessionPercent => 100 - homePossessionPercent;
}

class Match2DState {
  final List<Match2DPlayer> players;
  final List<Match2DEvent> events;
  double ballX;
  double ballY;
  String? ballOwnerId;
  String? ballTargetOwnerId;
  double ballTravelProgress;
  int minute;
  /// Total minutes elapsed. When minute > 90, the UI renders it as 90+N.
  int stoppageTime;
  int homeGoals;
  int awayGoals;
  bool finished;
  final Match2DStats stats;
  final int? targetHomeGoals;
  final int? targetAwayGoals;

  Match2DState({
    required this.players,
    this.events = const [],
    this.ballX = 50,
    this.ballY = 50,
    this.ballOwnerId,
    this.ballTargetOwnerId,
    this.ballTravelProgress = 1.0,
    this.minute = 0,
    this.stoppageTime = 0,
    this.homeGoals = 0,
    this.awayGoals = 0,
    this.finished = false,
    Match2DStats? stats,
    this.targetHomeGoals,
    this.targetAwayGoals,
  }) : stats = stats ?? Match2DStats();
}

Match2DPlayer make2DPlayer(Player p, Match2DTeam team, int index) {
  final normalized = _startingPosition(p.position, index, team == Match2DTeam.home);
  return Match2DPlayer(
    id: p.id,
    name: p.name,
    position: p.position,
    team: team,
    x: normalized.$1,
    y: normalized.$2,
    homeX: normalized.$1,
    homeY: normalized.$2,
    shirtNumber: index + 1,
    overall: p.overall,
  );
}

(double, double) _startingPosition(
    PlayerPosition position, int index, bool home) {
  switch (position) {
    case PlayerPosition.goalkeeper:
      return (home ? 8 : 92, 50);
    case PlayerPosition.defender:
      return (home ? 25 : 75, 16 + (index % 4) * 23);
    case PlayerPosition.midfielder:
      return (home ? 43 : 57, 16 + (index % 4) * 23);
    case PlayerPosition.winger:
      return (home ? 58 : 42, index.isEven ? 14 : 86);
    case PlayerPosition.striker:
      return (home ? 69 : 31, 50);
  }
}
