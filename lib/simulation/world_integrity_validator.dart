import '../models/club.dart';
import '../models/player.dart';

/// P0.7 integrity checks for the persistent football world.
///
/// These checks are intentionally side-effect free: they detect corruption
/// instead of silently repairing it, so tests and debug builds can identify
/// the first bad simulation tick.
class WorldIntegrityReport {
  final List<String> errors;
  const WorldIntegrityReport(this.errors);
  bool get isValid => errors.isEmpty;
}

class WorldIntegrityValidator {
  static WorldIntegrityReport validate({
    required List<Club> clubs,
    required List<Player> players,
  }) {
    final errors = <String>[];
    final clubIds = <String>{};
    for (final club in clubs) {
      if (!clubIds.add(club.id)) {
        errors.add('DUPLICATE_CLUB_ID:${club.id}');
      }
    }

    final playerIds = <String>{};
    final seenInClubs = <String, String>{};
    final clubSet = clubIds;
    for (final player in players) {
      if (!playerIds.add(player.id)) {
        errors.add('DUPLICATE_PLAYER_ID:${player.id}');
      }
      if (player.clubId != null && !clubSet.contains(player.clubId)) {
        errors.add('PLAYER_WITH_UNKNOWN_CLUB:${player.id}:${player.clubId}');
      }
      if (player.loanFromClubId != null && !clubSet.contains(player.loanFromClubId)) {
        errors.add('LOAN_WITH_UNKNOWN_PARENT:${player.id}:${player.loanFromClubId}');
      }
      if (player.loanFromClubId != null && player.loanFromClubId == player.clubId) {
        errors.add('LOAN_PARENT_EQUALS_CURRENT_CLUB:${player.id}:${player.clubId}');
      }
      if (player.loanFromClubId != null && player.loanUntilDay <= 0) {
        errors.add('LOAN_WITHOUT_REMAINING_DAYS:${player.id}');
      }
      if (player.clubId == null && player.squadStatus != 'freeAgent' && player.hasProfessionalContract) {
        errors.add('CONTRACTED_PLAYER_WITHOUT_CLUB:${player.id}');
      }
      if (player.clubId != null && player.squadStatus == 'freeAgent') {
        errors.add('FREE_AGENT_WITH_CLUB:${player.id}:${player.clubId}');
      }
    }

    for (final club in clubs) {
      final ids = <String>{};
      for (final id in club.playerIds) {
        if (!ids.add(id)) errors.add('DUPLICATE_ROSTER_ENTRY:${club.id}:$id');
        final previous = seenInClubs[id];
        if (previous != null && previous != club.id) {
          errors.add('PLAYER_IN_MULTIPLE_ROSTERS:$id:$previous:${club.id}');
        }
        seenInClubs[id] = club.id;
        if (!playerIds.contains(id)) errors.add('ROSTER_UNKNOWN_PLAYER:${club.id}:$id');
      }
    }

    for (final player in players) {
      if (player.clubId != null && seenInClubs[player.id] != player.clubId) {
        errors.add('ROSTER_PLAYER_CLUB_MISMATCH:${player.id}:${player.clubId}:${seenInClubs[player.id]}');
      }
    }

    return WorldIntegrityReport(errors);
  }
}
