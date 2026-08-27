/// Persistent youth identity derived from the club's existing parameters.
/// V11.1 keeps the model lightweight so old saves remain compatible.
class AcademyProfile {
  final int quality;
  final int investment;
  final int scoutingNetwork;
  final int youthRecruitment;
  final int developmentQuality;
  final int promotionRate;
  final int localFocus;
  final int internationalFocus;

  const AcademyProfile({
    required this.quality,
    required this.investment,
    required this.scoutingNetwork,
    required this.youthRecruitment,
    required this.developmentQuality,
    required this.promotionRate,
    required this.localFocus,
    required this.internationalFocus,
  });

  factory AcademyProfile.fromClub({
    required int academyQuality,
    required int youthFocus,
    required int reputation,
    required int stability,
  }) {
    final quality = academyQuality.clamp(1, 100).toInt();
    final youth = youthFocus.clamp(1, 100).toInt();
    return AcademyProfile(
      quality: quality,
      investment: ((quality * .60) + (youth * .40)).round().clamp(1, 100).toInt(),
      scoutingNetwork: ((quality * .45) + (reputation * .35) + (youth * .20)).round().clamp(1, 100).toInt(),
      youthRecruitment: ((youth * .60) + (quality * .40)).round().clamp(1, 100).toInt(),
      developmentQuality: ((quality * .65) + (stability * .35)).round().clamp(1, 100).toInt(),
      promotionRate: ((youth * .55) + (quality * .25) + (stability * .20)).round().clamp(1, 100).toInt(),
      localFocus: (100 - ((youth - 50).abs() * .45)).round().clamp(35, 100).toInt(),
      internationalFocus: ((reputation * .35) + (quality * .35) + (youth * .30)).round().clamp(1, 100).toInt(),
    );
  }
}
