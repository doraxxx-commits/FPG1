class Match {
  final String id;

  final String homeClubId;
  final String awayClubId;

  int homeGoals;
  int awayGoals;

  bool played;

  Match({
    required this.id,
    required this.homeClubId,
    required this.awayClubId,
    this.homeGoals = 0,
    this.awayGoals = 0,
    this.played = false,
  });
}
