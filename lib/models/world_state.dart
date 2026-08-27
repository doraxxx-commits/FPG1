class WorldPlayer {
  final String id;
  String name;
  String nationality;
  int age;
  String position;
  int overall;
  int potential;
  int form;
  int morale;
  int fitness;
  double marketValue;
  String? clubId;
  bool retired;
  WorldPlayer({required this.id, required this.name, required this.nationality, required this.age, required this.position, required this.overall, required this.potential, this.form = 50, this.morale = 70, this.fitness = 100, this.marketValue = 0, this.clubId, this.retired = false});
}

class WorldClub {
  final String id;
  String name;
  double budget;
  int overall;
  int boardPressure;
  String strategy;
  int minimumOverall;
  int minPreferredAge;
  int maxPreferredAge;
  final List<String> squadIds;
  WorldClub({required this.id, required this.name, required this.budget, required this.overall, this.boardPressure = 50, this.strategy = 'balanced', this.minimumOverall = 60, this.minPreferredAge = 18, this.maxPreferredAge = 30, List<String>? squadIds}) : squadIds = squadIds ?? [];
}

class WorldDayReport {
  final DateTime date;
  final List<String> events;
  WorldDayReport(this.date, [List<String>? events]) : events = events ?? [];
}

class WorldState {
  DateTime date;
  final Map<String, WorldPlayer> players;
  final Map<String, WorldClub> clubs;
  int season;
  WorldState({required this.date, this.season = 2026, Map<String, WorldPlayer>? players, Map<String, WorldClub>? clubs}) : players = players ?? {}, clubs = clubs ?? {};
}
