import '../models/club.dart';
import '../models/player_career.dart';
import '../models/squad_status.dart';

class ManagerEngine {
  // ==========================================================
  // DECYZJA TRENERA
  // ==========================================================

  SquadStatus decideSquadStatus({
    required PlayerCareer player,
    required Club club,
  }) {
    // ----------------------------------------------------------
    // Jeżeli zawodnik nie należy do klubu
    // ----------------------------------------------------------

    if (player.clubId != club.id) {
      return SquadStatus.outOfSquad;
    }

    // ----------------------------------------------------------
    // Bazowa ocena zawodnika
    // ----------------------------------------------------------

    double score = player.overall.toDouble();

    // ----------------------------------------------------------
    // POTENCJAŁ MŁODEGO ZAWODNIKA
    // ----------------------------------------------------------

    if (player.age <= 21) {
      score += 2;
    }

    // ----------------------------------------------------------
    // FORMA
    // ----------------------------------------------------------

    if (player.form >= 85) {
      score += 5;
    } else if (player.form >= 75) {
      score += 3;
    } else if (player.form < 50) {
      score -= 5;
    } else if (player.form < 35) {
      score -= 8;
    }

    // ----------------------------------------------------------
    // FITNESS
    // ----------------------------------------------------------

    if (player.fitness >= 90) {
      score += 3;
    } else if (player.fitness >= 75) {
      score += 1;
    } else if (player.fitness < 50) {
      score -= 6;
    } else if (player.fitness < 30) {
      score -= 12;
    }

    // ----------------------------------------------------------
    // RELACJA Z TRENEREM
    // ----------------------------------------------------------

    if (player.managerRelationship >= 85) {
      score += 5;
    } else if (player.managerRelationship >= 70) {
      score += 3;
    } else if (player.managerRelationship < 40) {
      score -= 5;
    } else if (player.managerRelationship < 25) {
      score -= 10;
    }

    // ----------------------------------------------------------
    // MORALE
    // ----------------------------------------------------------

    if (player.morale >= 85) {
      score += 2;
    } else if (player.morale < 40) {
      score -= 3;
    }

    // ----------------------------------------------------------
    // OSTATECZNA DECYZJA
    // ----------------------------------------------------------

    if (score >= 80) {
      return SquadStatus.startingXI;
    }

    if (score >= 68) {
      return SquadStatus.substitute;
    }

    if (score >= 55) {
      return SquadStatus.reserves;
    }

    return SquadStatus.outOfSquad;
  }

  // ==========================================================
  // AKTUALIZACJA STATUSU
  // ==========================================================

  void updatePlayerStatus({
    required PlayerCareer player,
    required Club club,
  }) {
    if (player.contract == null) {
      return;
    }

    final newStatus = decideSquadStatus(
      player: player,
      club: club,
    );

    // newStatus to enum SquadStatus, a contract.squadStatus jest String —
    // przypisanie enuma wprost by się nie skompilowało.
    player.contract!.squadStatus = newStatus.name;
  }
}
