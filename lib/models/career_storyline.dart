/// V19.2 — Persistent multi-step career storyline.
class CareerStoryline {
  final String id;
  final String playerId;
  final String type;
  String title;
  int stage;
  final int startedAbsoluteDay;
  int lastUpdatedAbsoluteDay;
  bool completed;
  String? outcome;

  CareerStoryline({
    required this.id,
    required this.playerId,
    required this.type,
    required this.title,
    required this.stage,
    required this.startedAbsoluteDay,
    required this.lastUpdatedAbsoluteDay,
    this.completed = false,
    this.outcome,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'playerId': playerId, 'type': type, 'title': title,
    'stage': stage, 'startedAbsoluteDay': startedAbsoluteDay,
    'lastUpdatedAbsoluteDay': lastUpdatedAbsoluteDay,
    'completed': completed, 'outcome': outcome,
  };

  factory CareerStoryline.fromJson(Map<String, dynamic> j) => CareerStoryline(
    id: j['id']?.toString() ?? '', playerId: j['playerId']?.toString() ?? '',
    type: j['type']?.toString() ?? 'career', title: j['title']?.toString() ?? 'Historia kariery',
    stage: j['stage'] ?? 0, startedAbsoluteDay: j['startedAbsoluteDay'] ?? 0,
    lastUpdatedAbsoluteDay: j['lastUpdatedAbsoluteDay'] ?? 0,
    completed: j['completed'] == true, outcome: j['outcome']?.toString(),
  );
}
