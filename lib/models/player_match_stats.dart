import 'dart:math';

class PlayerMatchStats {
  // ==========================================================
  // WYSTĘPY
  // ==========================================================

  int appearances = 0;
  int starts = 0;
  int substituteAppearances = 0;

  int minutes = 0;

  // ==========================================================
  // GOLE / ASYSTY
  // ==========================================================

  int goals = 0;
  int assists = 0;

  // ==========================================================
  // KARTKI
  // ==========================================================

  int yellowCards = 0;
  int redCards = 0;

  // ==========================================================
  // STRZAŁY
  // ==========================================================

  int shots = 0;
  int shotsOnTarget = 0;

  // ==========================================================
  // GRA
  // ==========================================================

  int keyPasses = 0;
  int successfulDribbles = 0;

  // ==========================================================
  // OCENA
  // ==========================================================

  double averageRating = 0.0;

  // ==========================================================
  // DODANIE WYSTĘPU
  // ==========================================================

  void addAppearance({
    required int playedMinutes,
    required bool started,
    required double rating,
  }) {
    if (playedMinutes <= 0) {
      return;
    }

    appearances++;

    if (started) {
      starts++;
    } else {
      substituteAppearances++;
    }

    minutes += playedMinutes;

    final totalRating =
        averageRating * (appearances - 1);

    averageRating =
        (totalRating + rating) / appearances;
  }

  // ==========================================================
  // DODANIE GOLA
  // ==========================================================

  void addGoal() {
    goals++;
  }

  // ==========================================================
  // DODANIE ASYSTY
  // ==========================================================

  void addAssist() {
    assists++;
  }

  // ==========================================================
  // STRZAŁ
  // ==========================================================

  void addShot({
    required bool onTarget,
  }) {
    shots++;

    if (onTarget) {
      shotsOnTarget++;
    }
  }

  // ==========================================================
  // KLUCZOWE PODANIE
  // ==========================================================

  void addKeyPass() {
    keyPasses++;
  }

  // ==========================================================
  // UDANY DRYBLING
  // ==========================================================

  void addSuccessfulDribble() {
    successfulDribbles++;
  }

  // ==========================================================
  // ŻÓŁTA KARTKA
  // ==========================================================

  void addYellowCard() {
    yellowCards++;
  }

  // ==========================================================
  // CZERWONA KARTKA
  // ==========================================================

  void addRedCard() {
    redCards++;
  }

  // ==========================================================
  // SKUTECZNOŚĆ STRZAŁÓW
  // ==========================================================

  double get shotAccuracy {
    if (shots == 0) {
      return 0.0;
    }

    return shotsOnTarget / shots;
  }

  // ==========================================================
  // GOLE NA MECZ
  // ==========================================================

  double get goalsPerAppearance {
    if (appearances == 0) {
      return 0.0;
    }

    return goals / appearances;
  }

  // ==========================================================
  // ASYSTY NA MECZ
  // ==========================================================

  double get assistsPerAppearance {
    if (appearances == 0) {
      return 0.0;
    }

    return assists / appearances;
  }

  // ==========================================================
  // ŚREDNIA MINUT NA MECZ
  // ==========================================================

  double get averageMinutes {
    if (appearances == 0) {
      return 0.0;
    }

    return minutes / appearances;
  }

  // ==========================================================
  // ŚREDNIA OCENA
  // ==========================================================

  double get rating {
    return averageRating;
  }

  // ==========================================================
  // ŁĄCZNY UDZIAŁ PRZY GOLACH
  // ==========================================================

  int get goalContributions {
    return goals + assists;
  }

  // ==========================================================
  // CZY ZAWODNIK MA STATYSTYKI
  // ==========================================================

  bool get hasPlayed {
    return appearances > 0;
  }

  // ==========================================================
  // RESET STATYSTYK
  // ==========================================================

  void reset() {
    appearances = 0;
    starts = 0;
    substituteAppearances = 0;

    minutes = 0;

    goals = 0;
    assists = 0;

    yellowCards = 0;
    redCards = 0;

    shots = 0;
    shotsOnTarget = 0;

    keyPasses = 0;
    successfulDribbles = 0;

    averageRating = 0.0;
  }
  Map<String, dynamic> toJson() => {
    'appearances': appearances,
    'starts': starts,
    'substituteAppearances': substituteAppearances,
    'minutes': minutes,
    'goals': goals,
    'assists': assists,
    'yellowCards': yellowCards,
    'redCards': redCards,
    'shots': shots,
    'shotsOnTarget': shotsOnTarget,
    'keyPasses': keyPasses,
    'successfulDribbles': successfulDribbles,
    'averageRating': averageRating,
  };

  void loadFromJson(Map<String, dynamic> json) {
    int asInt(String key, int fallback) => (json[key] as num?)?.toInt() ?? fallback;
    double asDouble(String key, double fallback) => (json[key] as num?)?.toDouble() ?? fallback;
    appearances = asInt('appearances', appearances);
    starts = asInt('starts', starts);
    substituteAppearances = asInt('substituteAppearances', substituteAppearances);
    minutes = asInt('minutes', minutes);
    goals = asInt('goals', goals);
    assists = asInt('assists', assists);
    yellowCards = asInt('yellowCards', yellowCards);
    redCards = asInt('redCards', redCards);
    shots = asInt('shots', shots);
    shotsOnTarget = asInt('shotsOnTarget', shotsOnTarget);
    keyPasses = asInt('keyPasses', keyPasses);
    successfulDribbles = asInt('successfulDribbles', successfulDribbles);
    averageRating = asDouble('averageRating', averageRating);
  }

}
