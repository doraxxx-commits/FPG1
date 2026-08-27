class LoanNegotiation {
  final String id;
  final String parentClubId;
  final String destinationClubId;
  final String playerId;
  int round;
  int loanFee;
  double wageShare;
  int guaranteedMinutes;
  double buyoutClause;
  String stage; // opening, counter, accepted, rejected

  LoanNegotiation({
    required this.id,
    required this.parentClubId,
    required this.destinationClubId,
    required this.playerId,
    this.round = 1,
    this.loanFee = 0,
    this.wageShare = 0.5,
    this.guaranteedMinutes = 0,
    this.buyoutClause = 0,
    this.stage = 'opening',
  });
}
