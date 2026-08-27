import 'player.dart';

/// A youth player before the world turns him into a full persistent Player.
/// The real potential stays internal; scouting only exposes an estimate.
class YouthProspect {
  final String id;
  final String name;
  final int birthYear;
  final int age;
  final PlayerPosition position;
  final String nationality;
  final String region;
  final int rawTalent;
  final int hiddenPotential;
  final int scoutingEstimateMin;
  final int scoutingEstimateMax;
  final int scoutingConfidence;
  final int professionalism;
  final int ambition;
  final int loyalty;
  final int adaptability;
  final int localAffinity;
  final String scoutingPath;
  final String clubId;

  const YouthProspect({
    required this.id,
    required this.name,
    required this.birthYear,
    required this.age,
    required this.position,
    required this.nationality,
    required this.region,
    required this.rawTalent,
    required this.hiddenPotential,
    required this.scoutingEstimateMin,
    required this.scoutingEstimateMax,
    required this.scoutingConfidence,
    required this.professionalism,
    required this.ambition,
    required this.loyalty,
    required this.adaptability,
    required this.localAffinity,
    required this.scoutingPath,
    required this.clubId,
  });
}
