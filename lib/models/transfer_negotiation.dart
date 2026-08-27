/// V18.8 — pełny stan negocjacji transferowej.
/// Trzy strony mają osobne interesy: klub kupujący, klub sprzedający i zawodnik/agent.
class TransferNegotiation {
  final String id;
  final String buyerClubId;
  final String sellerClubId;
  final String playerId;

  int round;
  int offeredFee;
  int demandedFee;
  int offeredWage;
  int demandedWage;
  int offeredYears;
  int demandedYears;
  int offeredSigningBonus;
  int demandedSigningBonus;
  double offeredReleaseClause;
  double demandedReleaseClause;
  int offeredRoleScore;
  int demandedRoleScore;
  String stage; // opening, seller_counter, player_counter, player_accepted, accepted, rejected, cooling
  String playerDecision; // pending, negotiating, accepted, rejected
  int patience;
  int buyerPatience;
  int sellerPatience;
  int playerPatience;

  TransferNegotiation({
    required this.id,
    required this.buyerClubId,
    required this.sellerClubId,
    required this.playerId,
    required this.offeredFee,
    required this.demandedFee,
    required this.offeredWage,
    required this.demandedWage,
    this.offeredYears = 3,
    this.demandedYears = 3,
    this.offeredSigningBonus = 0,
    this.demandedSigningBonus = 0,
    this.offeredReleaseClause = 0,
    this.demandedReleaseClause = 0,
    this.offeredRoleScore = 50,
    this.demandedRoleScore = 50,
    this.round = 1,
    this.stage = 'opening',
    this.playerDecision = 'pending',
    this.patience = 5,
    this.buyerPatience = 5,
    this.sellerPatience = 5,
    this.playerPatience = 5,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'buyerClubId': buyerClubId,
    'sellerClubId': sellerClubId,
    'playerId': playerId,
    'round': round,
    'offeredFee': offeredFee,
    'demandedFee': demandedFee,
    'offeredWage': offeredWage,
    'demandedWage': demandedWage,
    'offeredYears': offeredYears,
    'demandedYears': demandedYears,
    'offeredSigningBonus': offeredSigningBonus,
    'demandedSigningBonus': demandedSigningBonus,
    'offeredReleaseClause': offeredReleaseClause,
    'demandedReleaseClause': demandedReleaseClause,
    'offeredRoleScore': offeredRoleScore,
    'demandedRoleScore': demandedRoleScore,
    'stage': stage,
    'playerDecision': playerDecision,
    'patience': patience,
    'buyerPatience': buyerPatience,
    'sellerPatience': sellerPatience,
    'playerPatience': playerPatience,
  };

  factory TransferNegotiation.fromJson(Map<String, dynamic> j) => TransferNegotiation(
    id: j['id'] ?? '',
    buyerClubId: j['buyerClubId'] ?? '',
    sellerClubId: j['sellerClubId'] ?? '',
    playerId: j['playerId'] ?? '',
    round: j['round'] ?? 1,
    offeredFee: j['offeredFee'] ?? 0,
    demandedFee: j['demandedFee'] ?? 0,
    offeredWage: j['offeredWage'] ?? 0,
    demandedWage: j['demandedWage'] ?? 0,
    offeredYears: j['offeredYears'] ?? 3,
    demandedYears: j['demandedYears'] ?? 3,
    offeredSigningBonus: j['offeredSigningBonus'] ?? 0,
    demandedSigningBonus: j['demandedSigningBonus'] ?? 0,
    offeredReleaseClause: (j['offeredReleaseClause'] ?? 0).toDouble(),
    demandedReleaseClause: (j['demandedReleaseClause'] ?? 0).toDouble(),
    offeredRoleScore: j['offeredRoleScore'] ?? 50,
    demandedRoleScore: j['demandedRoleScore'] ?? 50,
    stage: j['stage'] ?? 'opening',
    playerDecision: j['playerDecision'] ?? 'pending',
    patience: j['patience'] ?? 5,
    buyerPatience: j['buyerPatience'] ?? 5,
    sellerPatience: j['sellerPatience'] ?? 5,
    playerPatience: j['playerPatience'] ?? 5,
  );
}
