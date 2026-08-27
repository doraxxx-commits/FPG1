class Rivalry {
  final String id;
  final String clubAId;
  final String clubBId;
  int intensity;
  int matchesPlayed;
  int recentAForm;
  int recentBForm;

  Rivalry({
    required this.id,
    required this.clubAId,
    required this.clubBId,
    this.intensity = 50,
    this.matchesPlayed = 0,
    this.recentAForm = 0,
    this.recentBForm = 0,
  });

  bool involves(String clubId) => clubAId == clubId || clubBId == clubId;
}
