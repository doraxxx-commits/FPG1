import '../core/game_engine.dart';
import '../models/club.dart';
import '../models/standing.dart';

/// P2.2-D: read-only season gameplay model used by the UI.
/// It deliberately derives everything from the authoritative league table and
/// fixtures, so the screen cannot create a second source of truth.
class SeasonOverview {
  final int season;
  final int position;
  final int clubCount;
  final Standing standing;
  final String objective;
  final int objectivePosition;
  final int remainingMatches;
  final int completedMatches;

  const SeasonOverview({
    required this.season,
    required this.position,
    required this.clubCount,
    required this.standing,
    required this.objective,
    required this.objectivePosition,
    required this.remainingMatches,
    required this.completedMatches,
  });

  double get seasonProgress {
    final total = completedMatches + remainingMatches;
    if (total <= 0) return 0;
    return (completedMatches / total).clamp(0.0, 1.0);
  }

  bool get objectiveMet => position > 0 && position <= objectivePosition;
}

class SeasonOverviewEngine {
  SeasonOverview build(GameEngine engine) {
    final player = engine.careerPlayer;
    final clubs = engine.leagueClubs;
    final table = engine.leagueEngine.table;
    final clubId = player?.clubId;

    if (clubId == null || table.isEmpty || clubs.isEmpty) {
      return SeasonOverview(
        season: 0,
        position: 0,
        clubCount: 0,
        standing: Standing(clubId: ''),
        objective: 'Brak aktywnej kariery',
        objectivePosition: 0,
        remainingMatches: 0,
        completedMatches: 0,
      );
    }

    final index = table.indexWhere((s) => s.clubId == clubId);
    final position = index < 0 ? 0 : index + 1;
    final club = clubs.firstWhere((c) => c.id == clubId);
    final objectivePosition = _objectivePosition(club, clubs.length);
    final objective = _objectiveLabel(objectivePosition, clubs.length);
    final standing = index < 0 ? Standing(clubId: clubId) : table[index];
    final totalMatches = (clubs.length - 1) * 2;

    return SeasonOverview(
      season: engine.gameState.season,
      position: position,
      clubCount: clubs.length,
      standing: standing,
      objective: objective,
      objectivePosition: objectivePosition,
      remainingMatches: (totalMatches - standing.played).clamp(0, totalMatches),
      completedMatches: standing.played,
    );
  }

  int _objectivePosition(Club club, int clubCount) {
    if (clubCount <= 0) return 0;
    if (club.overall >= 82) return 3.clamp(1, clubCount).toInt();
    if (club.overall >= 76) return 5.clamp(1, clubCount).toInt();
    if (club.overall >= 70) return 8.clamp(1, clubCount).toInt();
    return (clubCount - 3).clamp(1, clubCount).toInt();
  }

  String _objectiveLabel(int target, int count) {
    if (target <= 3 && count >= 3) return 'TOP 3';
    if (target <= 5 && count >= 5) return 'TOP 5';
    if (target <= 8 && count >= 8) return 'TOP 8';
    return 'UTRZYMANIE';
  }
}
