/// Wieloetapowe negocjacje przedłużenia kontraktu zawodnika.
class ContractNegotiation {
  final String id;
  final String clubId;
  final String playerId;
  int round;
  int offeredWage;
  int demandedWage;
  int offeredYears;
  int demandedYears;
  int offeredAppearanceBonus;
  int demandedAppearanceBonus;
  int offeredGoalBonus;
  int demandedGoalBonus;
  double offeredReleaseClause;
  double demandedReleaseClause;
  String stage; // opening, counter, accepted, rejected
  int patience;

  ContractNegotiation({
    required this.id,
    required this.clubId,
    required this.playerId,
    required this.offeredWage,
    required this.demandedWage,
    required this.offeredYears,
    required this.demandedYears,
    required this.offeredAppearanceBonus,
    required this.demandedAppearanceBonus,
    required this.offeredGoalBonus,
    required this.demandedGoalBonus,
    required this.offeredReleaseClause,
    required this.demandedReleaseClause,
    this.round = 1,
    this.stage = 'opening',
    this.patience = 4,
  });
}
