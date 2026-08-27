class ManagerCandidate {
  final String id;
  final String name;
  final String preferredStyle;
  final int quality;
  final int reputation;
  final int youthDevelopment;
  final int tacticalIdentity;
  final int wageDemand;
  bool employed;

  ManagerCandidate({
    required this.id,
    required this.name,
    required this.preferredStyle,
    required this.quality,
    required this.reputation,
    required this.youthDevelopment,
    required this.tacticalIdentity,
    required this.wageDemand,
    this.employed = false,
  });
}
