class Standing {
  final String clubId;

  int played;
  int wins;
  int draws;
  int losses;

  int goalsFor;
  int goalsAgainst;

  Standing({
    required this.clubId,
    this.played = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get points {
    return wins * 3 + draws;
  }

  int get goalDifference {
    return goalsFor - goalsAgainst;
  }
}
