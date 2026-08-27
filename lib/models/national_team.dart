class NationalTeam {
  final String country;
  String managerName;
  int managerQuality;
  int reputation;
  List<String> playerIds;
  int matchesPlayed;
  int wins;
  int draws;
  int losses;
  int goalsFor;
  int goalsAgainst;
  int competitiveMatches;
  int friendlyMatches;
  int tournamentMatches;
  int tournamentWins;
  int tournamentTitles;

  NationalTeam({
    required this.country,
    this.managerName = 'National Manager',
    this.managerQuality = 60,
    this.reputation = 50,
    List<String>? playerIds,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.competitiveMatches = 0,
    this.friendlyMatches = 0,
    this.tournamentMatches = 0,
    this.tournamentWins = 0,
    this.tournamentTitles = 0,
  }) : playerIds = playerIds ?? [];
}
