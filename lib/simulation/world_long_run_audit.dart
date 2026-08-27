import '../models/club.dart';
import '../models/player.dart';
import 'world_integrity_validator.dart';

/// P1.2 — compact diagnostic snapshot for multi-season world simulations.
///
/// The audit is intentionally read-only. It never repairs the world; it makes
/// long-run drift visible so a regression can be tied to a specific season.
class WorldLongRunAuditSnapshot {
  final int seasonYear;
  final int playerCount;
  final int clubCount;
  final int freeAgentCount;
  final int loanCount;
  final int duplicatePlayerIds;
  final int duplicateClubIds;
  final int unknownClubAssignments;
  final int minSeniorSquad;
  final int maxSeniorSquad;
  final double averagePlayerAge;
  final double averageOverall;
  final int minOverall;
  final int maxOverall;
  final int eliteCount;
  final int potentialBreaches;

  const WorldLongRunAuditSnapshot({
    required this.seasonYear,
    required this.playerCount,
    required this.clubCount,
    required this.freeAgentCount,
    required this.loanCount,
    required this.duplicatePlayerIds,
    required this.duplicateClubIds,
    required this.unknownClubAssignments,
    required this.minSeniorSquad,
    required this.maxSeniorSquad,
    required this.averagePlayerAge,
    required this.averageOverall,
    required this.minOverall,
    required this.maxOverall,
    required this.eliteCount,
    required this.potentialBreaches,
  });

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'playerCount': playerCount,
        'clubCount': clubCount,
        'freeAgentCount': freeAgentCount,
        'loanCount': loanCount,
        'duplicatePlayerIds': duplicatePlayerIds,
        'duplicateClubIds': duplicateClubIds,
        'unknownClubAssignments': unknownClubAssignments,
        'minSeniorSquad': minSeniorSquad,
        'maxSeniorSquad': maxSeniorSquad,
        'averagePlayerAge': averagePlayerAge,
        'averageOverall': averageOverall,
        'minOverall': minOverall,
        'maxOverall': maxOverall,
        'eliteCount': eliteCount,
        'potentialBreaches': potentialBreaches,
      };
}

class WorldLongRunAudit {
  static WorldLongRunAuditSnapshot snapshot({
    required int seasonYear,
    required List<Club> clubs,
    required List<Player> players,
  }) {
    final report = WorldIntegrityValidator.validate(clubs: clubs, players: players);
    final seniorCounts = <int>[];
    for (final club in clubs) {
      seniorCounts.add(players.where((p) =>
          p.clubId == club.id &&
          p.squadStatus != 'academy' &&
          p.squadStatus != 'freeAgent').length);
    }

    int count(String prefix) => report.errors.where((e) => e.startsWith(prefix)).length;
    final ageTotal = players.fold<int>(0, (sum, player) => sum + player.age);
    final overallTotal = players.fold<int>(0, (sum, player) => sum + player.overall);
    final minOverall = players.isEmpty ? 0 : players.map((p) => p.overall).reduce((a, b) => a < b ? a : b);
    final maxOverall = players.isEmpty ? 0 : players.map((p) => p.overall).reduce((a, b) => a > b ? a : b);
    final eliteCount = players.where((p) => p.overall >= 90).length;
    final potentialBreaches = players.where((p) => p.potential > 0 && p.overall > p.potential).length;

    return WorldLongRunAuditSnapshot(
      seasonYear: seasonYear,
      playerCount: players.length,
      clubCount: clubs.length,
      freeAgentCount: players.where((p) => p.clubId == null && p.squadStatus == 'freeAgent').length,
      loanCount: players.where((p) => p.loanFromClubId != null).length,
      duplicatePlayerIds: count('DUPLICATE_PLAYER_ID'),
      duplicateClubIds: count('DUPLICATE_CLUB_ID'),
      unknownClubAssignments: count('PLAYER_WITH_UNKNOWN_CLUB'),
      minSeniorSquad: seniorCounts.isEmpty ? 0 : seniorCounts.reduce((a, b) => a < b ? a : b),
      maxSeniorSquad: seniorCounts.isEmpty ? 0 : seniorCounts.reduce((a, b) => a > b ? a : b),
      averagePlayerAge: players.isEmpty ? 0 : ageTotal / players.length,
      averageOverall: players.isEmpty ? 0 : overallTotal / players.length,
      minOverall: minOverall,
      maxOverall: maxOverall,
      eliteCount: eliteCount,
      potentialBreaches: potentialBreaches,
    );
  }

  static void assertHealthy(WorldLongRunAuditSnapshot snapshot) {
    if (snapshot.duplicatePlayerIds != 0 ||
        snapshot.duplicateClubIds != 0 ||
        snapshot.unknownClubAssignments != 0) {
      throw StateError('WORLD_IDENTITY_CORRUPTION:${snapshot.toJson()}');
    }
    if (snapshot.minSeniorSquad < 18) {
      throw StateError('WORLD_SQUAD_TOO_SMALL:${snapshot.toJson()}');
    }
    if (snapshot.potentialBreaches != 0) {
      throw StateError('WORLD_POTENTIAL_BREACH:${snapshot.toJson()}');
    }
    if (snapshot.maxOverall > 99 || snapshot.minOverall < 1) {
      throw StateError('WORLD_OVR_OUT_OF_RANGE:${snapshot.toJson()}');
    }
  }
}
