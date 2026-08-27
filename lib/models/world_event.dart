/// Wydarzenie generowane przez autonomiczny świat.
/// UI może je później wyświetlać w News/FPG Social bez ingerowania w symulację.
class WorldEvent {
  final int year;
  final int month;
  final int day;
  final String type;
  final String title;
  final String description;
  final String? clubId;
  final String? playerId;
  final int importance;

  const WorldEvent({
    required this.year,
    required this.month,
    required this.day,
    required this.type,
    required this.title,
    required this.description,
    this.clubId,
    this.playerId,
    this.importance = 1,
  });
}
