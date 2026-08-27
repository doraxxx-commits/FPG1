/// V19.4 — persistent relationship web around a player.
class PlayerRelationships {
  final String playerId;
  int agent;
  int coach;
  int club;
  int fans;
  int media;
  int lastUpdatedAbsoluteDay;
  final List<RelationshipLog> history;

  PlayerRelationships({
    required this.playerId,
    this.agent = 50,
    this.coach = 50,
    this.club = 50,
    this.fans = 50,
    this.media = 50,
    this.lastUpdatedAbsoluteDay = 0,
    List<RelationshipLog>? history,
  }) : history = history ?? [];

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'agent': agent,
    'coach': coach,
    'club': club,
    'fans': fans,
    'media': media,
    'lastUpdatedAbsoluteDay': lastUpdatedAbsoluteDay,
    'history': history.map((e) => e.toJson()).toList(),
  };

  factory PlayerRelationships.fromJson(Map<String, dynamic> j) => PlayerRelationships(
    playerId: j['playerId']?.toString() ?? '',
    agent: _i(j['agent'], 50),
    coach: _i(j['coach'], 50),
    club: _i(j['club'], 50),
    fans: _i(j['fans'], 50),
    media: _i(j['media'], 50),
    lastUpdatedAbsoluteDay: _i(j['lastUpdatedAbsoluteDay'], 0),
    history: j['history'] is List
        ? (j['history'] as List).whereType<Map>().map((x) => RelationshipLog.fromJson(Map<String, dynamic>.from(x))).toList()
        : [],
  );

  static int _i(dynamic v, int fallback) => v is int ? v : int.tryParse('$v') ?? fallback;
}

class RelationshipLog {
  final int absoluteDay;
  final String target;
  final int delta;
  final String reason;

  RelationshipLog({required this.absoluteDay, required this.target, required this.delta, required this.reason});

  Map<String, dynamic> toJson() => {'absoluteDay': absoluteDay, 'target': target, 'delta': delta, 'reason': reason};

  factory RelationshipLog.fromJson(Map<String, dynamic> j) => RelationshipLog(
    absoluteDay: j['absoluteDay'] is int ? j['absoluteDay'] : int.tryParse('${j['absoluteDay']}') ?? 0,
    target: j['target']?.toString() ?? 'club',
    delta: j['delta'] is int ? j['delta'] : int.tryParse('${j['delta']}') ?? 0,
    reason: j['reason']?.toString() ?? '',
  );
}
