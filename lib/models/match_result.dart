// ==========================================================
// WYDARZENIE ZAWODNIKA W MECZU
// ==========================================================

class PlayerMatchEvent {
  final String playerId;

  final int minute;

  final String type;

  final double? rating;

  PlayerMatchEvent({
    required this.playerId,
    required this.minute,
    required this.type,
    this.rating,
  });
}

// ==========================================================
// STATYSTYKI ZAWODNIKA W MECZU
// ==========================================================

class PlayerMatchPerformance {
  final String playerId;

  final int minutes;
  final bool started;

  final double rating;

  final int goals;
  final int assists;

  final int shots;
  final int shotsOnTarget;

  final int keyPasses;
  final int successfulDribbles;

  final int yellowCards;
  final int redCards;

  PlayerMatchPerformance({
    required this.playerId,
    required this.minutes,
    required this.started,
    required this.rating,
    this.goals = 0,
    this.assists = 0,
    this.shots = 0,
    this.shotsOnTarget = 0,
    this.keyPasses = 0,
    this.successfulDribbles = 0,
    this.yellowCards = 0,
    this.redCards = 0,
  });
}

// ==========================================================
// WYNIK MECZU
// ==========================================================

class MatchResult {
  final String homeClubId;
  final String awayClubId;

  final int homeGoals;
  final int awayGoals;

  // ==========================================================
  // WYDARZENIA MECZOWE
  // ==========================================================

  final List<PlayerMatchEvent> events;

  // ==========================================================
  // STATYSTYKI ZAWODNIKÓW
  // ==========================================================

  final List<PlayerMatchPerformance> playerPerformances;

  // Match-level statistics used by the world engine, career history and UI.
  final int homeShots;
  final int awayShots;
  final int homeShotsOnTarget;
  final int awayShotsOnTarget;
  final int homeCorners;
  final int awayCorners;
  final int homeFouls;
  final int awayFouls;
  final int homeYellowCards;
  final int awayYellowCards;
  final int homeRedCards;
  final int awayRedCards;
  final int possessionHome;


  // ==========================================================
  // KONSTRUKTOR
  // ==========================================================

  Map<String, dynamic> toJson() => {
        'homeClubId': homeClubId,
        'awayClubId': awayClubId,
        'homeGoals': homeGoals,
        'awayGoals': awayGoals,
        'homeShots': homeShots,
        'awayShots': awayShots,
        'homeShotsOnTarget': homeShotsOnTarget,
        'awayShotsOnTarget': awayShotsOnTarget,
        'homeCorners': homeCorners,
        'awayCorners': awayCorners,
        'homeFouls': homeFouls,
        'awayFouls': awayFouls,
        'homeYellowCards': homeYellowCards,
        'awayYellowCards': awayYellowCards,
        'homeRedCards': homeRedCards,
        'awayRedCards': awayRedCards,
        'possessionHome': possessionHome,
        'events': events.map((e) => {
          'playerId': e.playerId,
          'minute': e.minute,
          'type': e.type,
          'rating': e.rating,
        }).toList(),
        'playerPerformances': playerPerformances.map((p) => {
          'playerId': p.playerId,
          'minutes': p.minutes,
          'started': p.started,
          'rating': p.rating,
          'goals': p.goals,
          'assists': p.assists,
          'shots': p.shots,
          'shotsOnTarget': p.shotsOnTarget,
          'keyPasses': p.keyPasses,
          'successfulDribbles': p.successfulDribbles,
          'yellowCards': p.yellowCards,
          'redCards': p.redCards,
        }).toList(),
      };

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] is List ? json['events'] as List : const [];
    final rawPerformances = json['playerPerformances'] is List
        ? json['playerPerformances'] as List
        : const [];
    return MatchResult(
      homeClubId: json['homeClubId'] as String,
      awayClubId: json['awayClubId'] as String,
      homeGoals: (json['homeGoals'] as num?)?.toInt() ?? 0,
      awayGoals: (json['awayGoals'] as num?)?.toInt() ?? 0,
      homeShots: (json['homeShots'] as num?)?.toInt() ?? 0,
      awayShots: (json['awayShots'] as num?)?.toInt() ?? 0,
      homeShotsOnTarget: (json['homeShotsOnTarget'] as num?)?.toInt() ?? 0,
      awayShotsOnTarget: (json['awayShotsOnTarget'] as num?)?.toInt() ?? 0,
      homeCorners: (json['homeCorners'] as num?)?.toInt() ?? 0,
      awayCorners: (json['awayCorners'] as num?)?.toInt() ?? 0,
      homeFouls: (json['homeFouls'] as num?)?.toInt() ?? 0,
      awayFouls: (json['awayFouls'] as num?)?.toInt() ?? 0,
      homeYellowCards: (json['homeYellowCards'] as num?)?.toInt() ?? 0,
      awayYellowCards: (json['awayYellowCards'] as num?)?.toInt() ?? 0,
      homeRedCards: (json['homeRedCards'] as num?)?.toInt() ?? 0,
      awayRedCards: (json['awayRedCards'] as num?)?.toInt() ?? 0,
      possessionHome: (json['possessionHome'] as num?)?.toInt() ?? 50,
      events: rawEvents.whereType<Map>().map((e) => PlayerMatchEvent(
        playerId: e['playerId'] as String,
        minute: (e['minute'] as num?)?.toInt() ?? 0,
        type: e['type'] as String,
        rating: (e['rating'] as num?)?.toDouble(),
      )).toList(),
      playerPerformances: rawPerformances.whereType<Map>().map((p) => PlayerMatchPerformance(
        playerId: p['playerId'] as String,
        minutes: (p['minutes'] as num?)?.toInt() ?? 0,
        started: p['started'] == true,
        rating: (p['rating'] as num?)?.toDouble() ?? 0,
        goals: (p['goals'] as num?)?.toInt() ?? 0,
        assists: (p['assists'] as num?)?.toInt() ?? 0,
        shots: (p['shots'] as num?)?.toInt() ?? 0,
        shotsOnTarget: (p['shotsOnTarget'] as num?)?.toInt() ?? 0,
        keyPasses: (p['keyPasses'] as num?)?.toInt() ?? 0,
        successfulDribbles: (p['successfulDribbles'] as num?)?.toInt() ?? 0,
        yellowCards: (p['yellowCards'] as num?)?.toInt() ?? 0,
        redCards: (p['redCards'] as num?)?.toInt() ?? 0,
      )).toList(),
    );
  }

  MatchResult({
    required this.homeClubId,
    required this.awayClubId,
    required this.homeGoals,
    required this.awayGoals,
    this.events = const [],
    this.playerPerformances = const [],
    this.homeShots = 0,
    this.awayShots = 0,
    this.homeShotsOnTarget = 0,
    this.awayShotsOnTarget = 0,
    this.homeCorners = 0,
    this.awayCorners = 0,
    this.homeFouls = 0,
    this.awayFouls = 0,
    this.homeYellowCards = 0,
    this.awayYellowCards = 0,
    this.homeRedCards = 0,
    this.awayRedCards = 0,
    this.possessionHome = 50,
  });

  // ==========================================================
  // CZY BYŁ REMIS
  // ==========================================================

  bool get isDraw {
    return homeGoals == awayGoals;
  }

  // ==========================================================
  // CZY WYGRAŁ GOSPODARZ
  // ==========================================================

  bool get homeWon {
    return homeGoals > awayGoals;
  }

  // ==========================================================
  // CZY WYGRAŁ GOŚĆ
  // ==========================================================

  bool get awayWon {
    return awayGoals > homeGoals;
  }

  // ==========================================================
  // ŁĄCZNA LICZBA GOLI
  // ==========================================================

  int get totalGoals {
    return homeGoals + awayGoals;
  }

  // ==========================================================
  // WYSZUKIWANIE WYSTĘPU ZAWODNIKA
  // ==========================================================

  PlayerMatchPerformance? performanceForPlayer(
    String playerId,
  ) {
    for (final performance
        in playerPerformances) {
      if (performance.playerId == playerId) {
        return performance;
      }
    }

    return null;
  }

  // ==========================================================
  // CZY ZAWODNIK ZDOBYŁ GOLA
  // ==========================================================

  bool playerScored(
    String playerId,
  ) {
    final performance =
        performanceForPlayer(playerId);

    if (performance == null) {
      return false;
    }

    return performance.goals > 0;
  }

  // ==========================================================
  // CZY ZAWODNIK ZALICZYŁ ASYSTĘ
  // ==========================================================

  bool playerAssisted(
    String playerId,
  ) {
    final performance =
        performanceForPlayer(playerId);

    if (performance == null) {
      return false;
    }

    return performance.assists > 0;
  }

  // ==========================================================
  // CZY ZAWODNIK WYSTĄPIŁ
  // ==========================================================

  bool playerAppeared(
    String playerId,
  ) {
    final performance =
        performanceForPlayer(playerId);

    if (performance == null) {
      return false;
    }

    return performance.minutes > 0;
  }
}
