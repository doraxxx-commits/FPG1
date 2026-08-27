class Club {
  // ==========================================================
  // PODSTAWOWE INFORMACJE
  // ==========================================================

  final String id;

  String name;
  String country;
  String leagueId;

  // ==========================================================
  // SIŁA KLUBU
  // ==========================================================

  int overall;
  int budget;

  int reputation;
  int financialHealth;

  // Parametry zachowania AI klubu. Nie są stałym OVR-em — opisują
  // sposób podejmowania decyzji przez zarząd i skauting.
  int minimumSigningOverall;
  int preferredMinAge;
  int preferredMaxAge;
  int youthFocus;
  int transferActivity;
  int boardPressure;

  // Życie klubu: parametry zmieniają się wraz z wynikami i finansami.
  int managerQuality;
  int fanSupport;
  int tacticalIdentity;
  int academyQuality;
  int academyReputation;
  int academyTechnical;
  int academyPhysical;
  int academyCreative;
  int academyTactical;
  int academyLocal;
  int academyInternational;
  int stability;

  // Tożsamość trenera i pamięć zarządu. Te wartości zmieniają się w czasie,
  // dzięki czemu klub nie jest statycznym rekordem danych.
  String managerStyle;
  String managerId;
  String managerName;
  int managerReputation;
  int managerTenureDays;
  int boardConfidence;
  int lastLeaguePosition;
  int seasonsManaged;
  int promotions;
  int relegations;
  int domesticTitles;
  int europeanTitles;
  int historicalReputation;
  String lastSeasonOutcome;

  // Pamięć sezonu — pozwala światu reagować na serię wyników, a nie tylko
  // na pojedynczy mecz. Dzięki temu klub ma własną historię i momentum.
  int winsStreak;
  int unbeatenStreak;
  int lossesStreak;
  int matchesPlayedThisSeason;
  int goalsForThisSeason;
  int goalsAgainstThisSeason;
  int cleanSheetsThisSeason;
  String lastResult;
  int lastMatchAbsoluteDay;

  // ==========================================================
  // KADRA ZAWODNIKÓW
  // ==========================================================
  //
  // Lista ID zawodników należących do klubu.
  //
  // Dzięki temu później MatchEngine będzie mógł:
  //
  // klub
  //   ↓
  // jego zawodnicy
  //   ↓
  // występ zawodników
  //   ↓
  // PlayerMatchPerformance
  //
  // Domyślnie lista jest pusta, dzięki czemu wszystkie
  // dotychczasowe dane WorldData nadal będą działać.
  // ==========================================================

  final List<String> playerIds;

  // ==========================================================
  // KONSTRUKTOR
  // ==========================================================

  Club({
    required this.id,
    required this.name,
    this.country = 'Polska',
    this.leagueId = 'unknown',
    required this.overall,
    this.budget = 1000000,
    this.reputation = 50,
    this.financialHealth = 75,
    this.minimumSigningOverall = 60,
    this.preferredMinAge = 18,
    this.preferredMaxAge = 30,
    this.youthFocus = 50,
    this.transferActivity = 50,
    this.boardPressure = 50,
    this.managerQuality = 50,
    this.fanSupport = 50,
    this.tacticalIdentity = 50,
    this.academyQuality = 50,
    this.academyReputation = 50,
    this.academyTechnical = 60,
    this.academyPhysical = 50,
    this.academyCreative = 60,
    this.academyTactical = 55,
    this.academyLocal = 70,
    this.academyInternational = 35,
    this.stability = 70,
    this.managerStyle = 'balanced',
    this.managerId = '',
    this.managerName = 'Manager',
    this.managerReputation = 50,
    this.managerTenureDays = 0,
    this.boardConfidence = 70,
    this.lastLeaguePosition = 0,
    this.seasonsManaged = 0,
    this.promotions = 0,
    this.relegations = 0,
    this.domesticTitles = 0,
    this.europeanTitles = 0,
    this.historicalReputation = 50,
    this.lastSeasonOutcome = 'none',
    this.winsStreak = 0,
    this.unbeatenStreak = 0,
    this.lossesStreak = 0,
    this.matchesPlayedThisSeason = 0,
    this.goalsForThisSeason = 0,
    this.goalsAgainstThisSeason = 0,
    this.cleanSheetsThisSeason = 0,
    this.lastResult = 'none',
    this.lastMatchAbsoluteDay = 0,
    List<String>? playerIds,
  }) : playerIds = playerIds ?? [];

  // ==========================================================
  // DODANIE ZAWODNIKA DO KLUBU
  // ==========================================================

  void addPlayer(
    String playerId,
  ) {
    if (playerId.isEmpty) {
      return;
    }

    if (playerIds.contains(playerId)) {
      return;
    }

    playerIds.add(playerId);
  }

  // ==========================================================
  // USUNIĘCIE ZAWODNIKA Z KLUBU
  // ==========================================================

  void removePlayer(
    String playerId,
  ) {
    playerIds.remove(playerId);
  }

  // ==========================================================
  // CZY KLUB POSIADA ZAWODNIKA
  // ==========================================================

  bool hasPlayer(
    String playerId,
  ) {
    return playerIds.contains(playerId);
  }

  // ==========================================================
  // LICZBA ZAWODNIKÓW
  // ==========================================================

  int get squadSize {
    return playerIds.length;
  }

  // ==========================================================
  // CZY KLUB MA KADRĘ
  // ==========================================================

  bool get hasSquad {
    return playerIds.isNotEmpty;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'country': country, 'leagueId': leagueId, 'overall': overall, 'budget': budget,
    'reputation': reputation, 'financialHealth': financialHealth, 'minimumSigningOverall': minimumSigningOverall,
    'preferredMinAge': preferredMinAge, 'preferredMaxAge': preferredMaxAge, 'youthFocus': youthFocus,
    'transferActivity': transferActivity, 'boardPressure': boardPressure, 'managerQuality': managerQuality,
    'fanSupport': fanSupport, 'tacticalIdentity': tacticalIdentity, 'academyQuality': academyQuality,
    'academyReputation': academyReputation, 'academyTechnical': academyTechnical,
    'academyPhysical': academyPhysical, 'academyCreative': academyCreative,
    'academyTactical': academyTactical, 'academyLocal': academyLocal,
    'academyInternational': academyInternational, 'stability': stability, 'managerStyle': managerStyle, 'managerId': managerId, 'managerName': managerName,
    'managerReputation': managerReputation, 'managerTenureDays': managerTenureDays, 'boardConfidence': boardConfidence,
    'lastLeaguePosition': lastLeaguePosition, 'seasonsManaged': seasonsManaged, 'promotions': promotions,
    'relegations': relegations, 'domesticTitles': domesticTitles, 'europeanTitles': europeanTitles,
    'historicalReputation': historicalReputation, 'lastSeasonOutcome': lastSeasonOutcome, 'winsStreak': winsStreak,
    'unbeatenStreak': unbeatenStreak, 'lossesStreak': lossesStreak, 'matchesPlayedThisSeason': matchesPlayedThisSeason,
    'goalsForThisSeason': goalsForThisSeason, 'goalsAgainstThisSeason': goalsAgainstThisSeason,
    'cleanSheetsThisSeason': cleanSheetsThisSeason, 'lastResult': lastResult, 'lastMatchAbsoluteDay': lastMatchAbsoluteDay,
    'playerIds': playerIds,
  };

  factory Club.fromJson(Map<String, dynamic> j) => Club(
    id: j['id'], name: j['name'], country: j['country'] ?? 'Polska', leagueId: j['leagueId'],
    overall: j['overall'] ?? 50, budget: j['budget'] ?? 0, reputation: j['reputation'] ?? 50,
    financialHealth: j['financialHealth'] ?? 75, minimumSigningOverall: j['minimumSigningOverall'] ?? 60,
    preferredMinAge: j['preferredMinAge'] ?? 18, preferredMaxAge: j['preferredMaxAge'] ?? 30,
    youthFocus: j['youthFocus'] ?? 50, transferActivity: j['transferActivity'] ?? 50, boardPressure: j['boardPressure'] ?? 50,
    managerQuality: j['managerQuality'] ?? 50, fanSupport: j['fanSupport'] ?? 50, tacticalIdentity: j['tacticalIdentity'] ?? 50,
    academyQuality: j['academyQuality'] ?? 50,
    academyReputation: j['academyReputation'] ?? j['academyQuality'] ?? 50,
    academyTechnical: j['academyTechnical'] ?? 60, academyPhysical: j['academyPhysical'] ?? 50,
    academyCreative: j['academyCreative'] ?? 60, academyTactical: j['academyTactical'] ?? 55,
    academyLocal: j['academyLocal'] ?? 70, academyInternational: j['academyInternational'] ?? 35,
    stability: j['stability'] ?? 70, managerStyle: j['managerStyle'] ?? 'balanced',
    managerId: j['managerId'] ?? '', managerName: j['managerName'] ?? 'Manager', managerReputation: j['managerReputation'] ?? 50,
    managerTenureDays: j['managerTenureDays'] ?? 0, boardConfidence: j['boardConfidence'] ?? 70,
    lastLeaguePosition: j['lastLeaguePosition'] ?? 0, seasonsManaged: j['seasonsManaged'] ?? 0, promotions: j['promotions'] ?? 0,
    relegations: j['relegations'] ?? 0, domesticTitles: j['domesticTitles'] ?? 0, europeanTitles: j['europeanTitles'] ?? 0,
    historicalReputation: j['historicalReputation'] ?? 50, lastSeasonOutcome: j['lastSeasonOutcome'] ?? 'none',
    winsStreak: j['winsStreak'] ?? 0, unbeatenStreak: j['unbeatenStreak'] ?? 0, lossesStreak: j['lossesStreak'] ?? 0,
    matchesPlayedThisSeason: j['matchesPlayedThisSeason'] ?? 0, goalsForThisSeason: j['goalsForThisSeason'] ?? 0,
    goalsAgainstThisSeason: j['goalsAgainstThisSeason'] ?? 0, cleanSheetsThisSeason: j['cleanSheetsThisSeason'] ?? 0,
    lastResult: j['lastResult'] ?? 'none', lastMatchAbsoluteDay: j['lastMatchAbsoluteDay'] ?? 0,
    playerIds: List<String>.from(j['playerIds'] ?? const []),
  );

}
