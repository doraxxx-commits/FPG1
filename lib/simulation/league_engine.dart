import '../models/club.dart';
import '../models/standing.dart';

class LeagueEngine {
  final List<Club> clubs;
  final Map<String, Standing> standings = {};

  LeagueEngine({
    required this.clubs,
  }) {
    _initialize();
  }

  void _initialize() {
    for (final club in clubs) {
      standings[club.id] = Standing(
        clubId: club.id,
      );
    }
  }

  List<Standing> get table {
    final result = standings.values.toList();

    result.sort((a, b) {
      if (a.points != b.points) {
        return b.points.compareTo(a.points);
      }

      if (a.goalDifference != b.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      }

      return b.goalsFor.compareTo(a.goalsFor);
    });

    return result;
  }

  void recordMatch({
    required String homeClubId,
    required String awayClubId,
    required int homeGoals,
    required int awayGoals,
  }) {
    final home = standings[homeClubId];
    final away = standings[awayClubId];

    if (home == null || away == null) {
      return;
    }

    home.played++;
    away.played++;

    home.goalsFor += homeGoals;
    home.goalsAgainst += awayGoals;

    away.goalsFor += awayGoals;
    away.goalsAgainst += homeGoals;

    if (homeGoals > awayGoals) {
      home.wins++;
      away.losses++;
    } else if (homeGoals < awayGoals) {
      away.wins++;
      home.losses++;
    } else {
      home.draws++;
      away.draws++;
    }
  }


  /// Replaces a result that was already recorded.
  /// Used by the interactive match layer when the player's actions
  /// legitimately change the previously estimated result.
  void replaceMatch({
    required String homeClubId,
    required String awayClubId,
    required int oldHomeGoals,
    required int oldAwayGoals,
    required int newHomeGoals,
    required int newAwayGoals,
  }) {
    final home = standings[homeClubId];
    final away = standings[awayClubId];
    if (home == null || away == null) return;

    void removeResult(Standing h, Standing a, int hg, int ag) {
      h.goalsFor -= hg;
      h.goalsAgainst -= ag;
      a.goalsFor -= ag;
      a.goalsAgainst -= hg;
      if (hg > ag) {
        h.wins = (h.wins - 1).clamp(0, 9999).toInt();
        a.losses = (a.losses - 1).clamp(0, 9999).toInt();
      } else if (hg < ag) {
        a.wins = (a.wins - 1).clamp(0, 9999).toInt();
        h.losses = (h.losses - 1).clamp(0, 9999).toInt();
      } else {
        h.draws = (h.draws - 1).clamp(0, 9999).toInt();
        a.draws = (a.draws - 1).clamp(0, 9999).toInt();
      }
    }

    void addResult(Standing h, Standing a, int hg, int ag) {
      h.goalsFor += hg;
      h.goalsAgainst += ag;
      a.goalsFor += ag;
      a.goalsAgainst += hg;
      if (hg > ag) {
        h.wins++;
        a.losses++;
      } else if (hg < ag) {
        a.wins++;
        h.losses++;
      } else {
        h.draws++;
        a.draws++;
      }
    }

    removeResult(home, away, oldHomeGoals, oldAwayGoals);
    addResult(home, away, newHomeGoals, newAwayGoals);
  }

  // ==========================================================
  // CZY SEZON SIĘ ZAKOŃCZYŁ
  // ==========================================================
  //
  // Wywoływane przez GameEngine.advanceDay(), ale wcześniej ta metoda
  // w ogóle nie istniała w LeagueEngine — kolejny przykład kodu
  // odwołującego się do czegoś, czego nie było.
  // ==========================================================

  bool isSeasonComplete() {
    if (clubs.isEmpty) {
      return false;
    }

    final expectedMatches = (clubs.length - 1) * 2;

    return standings.values.every(
      (standing) => standing.played >= expectedMatches,
    );
  }

  // ==========================================================
  // RESET TABELI NA NOWY SEZON
  // ==========================================================

  void resetSeason() {
    standings.clear();
    _initialize();
  }
}
