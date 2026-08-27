import '../models/club.dart';
import '../models/player.dart';
import 'world_player_generator.dart';

/// P1.1: prevents long-running worlds from reaching an impossible squad size
/// after retirements, while keeping the existing academy pipeline intact.
class SquadDepthEngine {
  static const int minimumSeniorSquad = 18;

  static List<Player> ensureMinimumSeniorSquads({
    required List<Club> clubs,
    required List<Player> players,
    required WorldPlayerGenerator generator,
    required int seasonYear,
  }) {
    final created = <Player>[];

    for (final club in clubs) {
      final senior = players.where((p) =>
          p.clubId == club.id && p.squadStatus != 'academy' && p.squadStatus != 'freeAgent').toList();
      final missing = minimumSeniorSquad - senior.length;
      if (missing <= 0) continue;

      // Generate a normal senior pool, then take positions that the current
      // squad is actually short of. This avoids filling every emergency slot
      // with goalkeepers or one single position.
      final candidates = generator.generateFirstTeamSquad(
        year: seasonYear,
        club: club,
        targetSize: 20,
      );

      final counts = <PlayerPosition, int>{
        for (final p in PlayerPosition.values) p: senior.where((s) => s.position == p).length,
      };
      const desired = <PlayerPosition, int>{
        PlayerPosition.goalkeeper: 2,
        PlayerPosition.defender: 6,
        PlayerPosition.midfielder: 5,
        PlayerPosition.winger: 3,
        PlayerPosition.striker: 2,
      };

      candidates.sort((a, b) {
        final shortageA = (desired[a.position]! - counts[a.position]!).compareTo(
          desired[b.position]! - counts[b.position]!,
        );
        if (shortageA != 0) return -shortageA;
        return b.overall.compareTo(a.overall);
      });

      for (final candidate in candidates) {
        if (created.where((p) => p.id == candidate.id).isNotEmpty) continue;
        if (counts[candidate.position]! >= desired[candidate.position]! &&
            candidates.where((p) => counts[p.position]! < desired[p.position]!).isNotEmpty) {
          continue;
        }
        candidate.squadStatus = 'reserves';
        candidate.contractRole = 'rotation';
        created.add(candidate);
        players.add(candidate);
        counts[candidate.position] = counts[candidate.position]! + 1;
        if (players.where((p) => p.clubId == club.id && p.squadStatus != 'academy' && p.squadStatus != 'freeAgent').length >= minimumSeniorSquad) {
          break;
        }
      }
    }

    return created;
  }
}
