/// Stan wieloetapowych negocjacji transferowych.
class Negotiation {
  final String id;
  final String buyerClubId;
  final String sellerClubId;
  final String playerId;
  int round;
  int offeredFee;
  int demandedFee;
  int offeredWage;
  int demandedWage;
  String stage; // opening, counter, final, accepted, rejected
  int patience;

  Negotiation({
    required this.id,
    required this.buyerClubId,
    required this.sellerClubId,
    required this.playerId,
    required this.offeredFee,
    required this.demandedFee,
    this.offeredWage = 0,
    this.demandedWage = 0,
    this.round = 1,
    this.stage = 'opening',
    this.patience = 3,
  });
}
