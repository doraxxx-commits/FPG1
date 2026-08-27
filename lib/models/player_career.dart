import '../models/player.dart';
import '../models/player_contract.dart';
import '../models/player_match_stats.dart';

/// Zawodnik kariery gracza.
///
/// UWAGA: ten plik wcześniej zawierał przypadkowo wklejoną kopię klasy
/// GameEngine (z lib/core/game_engine.dart) zamiast prawdziwej klasy
/// PlayerCareer. Przez to PlayerCareer nie istniał nigdzie w projekcie,
/// mimo że jest używany w grze (GameEngine, TrainingEngine, MatchEngine,
/// ManagerEngine i większość ekranów). Poniżej właściwa definicja,
/// odtworzona na podstawie tego, jak pola/metody są używane w reszcie kodu.
class PlayerCareer {
  // ==========================================================
  // TOŻSAMOŚĆ
  // ==========================================================

  final String id;

  String firstName;
  String lastName;

  String nationality;
  int age;
  int height;

  PlayerPosition position;

  // ==========================================================
  // UMIEJĘTNOŚCI
  // ==========================================================

  int overall;
  int potential;

  int pace;
  int shooting;
  int passing;
  int dribbling;
  int defending;
  int physical;

  // ==========================================================
  // KLUB / KONTRAKT
  // ==========================================================

  String? clubId;
  int shirtNumber;

  PlayerContract? contract;

  // ==========================================================
  // STAN ZAWODNIKA
  // ==========================================================

  int fatigue;
  int fitness;
  int form;

  int morale;
  int happiness;

  // V18.4 public profile.
  int fame;
  int reputation;
  int fanSupport;
  int mediaPressure;
  int marketability;
  int transferPull;
  int sponsorInterest;
  int sponsorTier;
  int sponsorIncome;
  int agentAttention;
  int interviewInvites;
  int mediaAppearances;
  int shirtDemand;
  int coachPressure;
  int fanMoments;
  int clubInterestLevel;
  int marketingValue;
  int commercialEvents;

  int managerRelationship;
  int teamRelationship;

  // Integracja z World Simulation 4.0.
  String? agentId;
  int agentInfluence;
  bool transferRequest;
  int internationalCaps;
  int internationalGoals;
  int internationalAssists;
  int nationalCallUps;
  int lastNationalCallUpYear;
  int wageExpectation;
  int appearanceBonus;
  int goalBonus;
  int assistBonus;
  int trophyBonus;
  double releaseClause;
  int contractYearsRemaining;

  // ==========================================================
  // STATUS MECZOWY
  // ==========================================================

  bool inMatchSquad;
  bool isStarter;
  bool isRegularStarter;
  String squadStatus;

  // ==========================================================
  // STATYSTYKI KARIERY
  // ==========================================================

  int careerAppearances;
  int careerGoals;
  int careerAssists;

  final PlayerMatchStats matchStats = PlayerMatchStats();

  // ==========================================================
  // KONSTRUKTOR
  // ==========================================================

  PlayerCareer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.nationality = 'PL',
    required this.age,
    required this.height,
    required this.position,
    required this.overall,
    required this.potential,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    this.clubId,
    this.shirtNumber = 10,
    this.contract,
    this.fatigue = 0,
    this.fitness = 100,
    this.form = 70,
    this.morale = 70,
    this.happiness = 70,
    this.fame = 0,
    this.reputation = 50,
    this.fanSupport = 35,
    this.mediaPressure = 0,
    this.marketability = 0,
    this.transferPull = 0,
    this.sponsorInterest = 0,
    this.sponsorTier = 0,
    this.sponsorIncome = 0,
    this.agentAttention = 0,
    this.interviewInvites = 0,
    this.mediaAppearances = 0,
    this.shirtDemand = 0,
    this.coachPressure = 0,
    this.fanMoments = 0,
    this.clubInterestLevel = 0,
    this.marketingValue = 0,
    this.commercialEvents = 0,
    this.managerRelationship = 50,
    this.teamRelationship = 50,
    this.agentId,
    this.agentInfluence = 50,
    this.transferRequest = false,
    this.internationalCaps = 0,
    this.internationalGoals = 0,
    this.internationalAssists = 0,
    this.nationalCallUps = 0,
    this.lastNationalCallUpYear = 0,
    this.wageExpectation = 10,
    this.appearanceBonus = 0,
    this.goalBonus = 0,
    this.assistBonus = 0,
    this.trophyBonus = 0,
    this.releaseClause = 0,
    this.contractYearsRemaining = 1,
    this.inMatchSquad = false,
    this.isStarter = false,
    this.isRegularStarter = false,
    this.squadStatus = 'Bez klubu',
    this.careerAppearances = 0,
    this.careerGoals = 0,
    this.careerAssists = 0,
  });

  // ==========================================================
  // PEŁNE IMIĘ I NAZWISKO
  // ==========================================================

  String get fullName => '$firstName $lastName';

  // ==========================================================
  // CZY ZAWODNIK MOŻE ZAGRAĆ
  // ==========================================================

  bool get canPlayMatch {
    if (clubId == null) {
      return false;
    }

    // Zbyt duże zmęczenie uniemożliwia grę.
    return fatigue < 95;
  }

  // ==========================================================
  // PRZELICZENIE OVERALL NA PODSTAWIE UMIEJĘTNOŚCI
  // ==========================================================

  void refreshOverall() {
    switch (position) {
      case PlayerPosition.goalkeeper:
        overall = (
          (physical * 0.35) +
          (passing * 0.25) +
          (pace * 0.20) +
          (dribbling * 0.20)
        ).round();
        break;

      case PlayerPosition.defender:
        overall = (
          (defending * 0.40) +
          (physical * 0.25) +
          (passing * 0.20) +
          (pace * 0.15)
        ).round();
        break;

      case PlayerPosition.midfielder:
        overall = (
          (passing * 0.30) +
          (dribbling * 0.25) +
          (defending * 0.20) +
          (physical * 0.15) +
          (pace * 0.10)
        ).round();
        break;

      case PlayerPosition.winger:
        overall = (
          (pace * 0.30) +
          (dribbling * 0.30) +
          (shooting * 0.20) +
          (passing * 0.20)
        ).round();
        break;

      case PlayerPosition.striker:
        overall = (
          (shooting * 0.40) +
          (pace * 0.20) +
          (dribbling * 0.20) +
          (physical * 0.20)
        ).round();
        break;
    }

    overall = overall.clamp(1, 99).toInt();
  }

  // ==========================================================
  // DECYZJA TRENERA O STATUSIE MECZOWYM
  // ==========================================================

  void updateMatchStatus() {
    if (clubId == null) {
      inMatchSquad = false;
      isStarter = false;
      isRegularStarter = false;
      squadStatus = 'Bez klubu';
      return;
    }

    double score = overall.toDouble();

    if (form >= 80) {
      score += 5;
    } else if (form < 45) {
      score -= 6;
    }

    if (fitness < 50) {
      score -= 10;
    }

    if (managerRelationship >= 75) {
      score += 4;
    } else if (managerRelationship < 30) {
      score -= 8;
    }

    if (!canPlayMatch) {
      inMatchSquad = false;
      isStarter = false;
      isRegularStarter = false;
      squadStatus = 'Kontuzja / zbyt duże zmęczenie';
      return;
    }

    if (score >= 78) {
      inMatchSquad = true;
      isStarter = true;
      isRegularStarter = true;
      squadStatus = 'Podstawowy skład';
    } else if (score >= 62) {
      inMatchSquad = true;
      isStarter = false;
      isRegularStarter = false;
      squadStatus = 'Rezerwowy';
    } else {
      inMatchSquad = false;
      isStarter = false;
      isRegularStarter = false;
      squadStatus = 'Poza kadrą meczową';
    }
  }

  // ==========================================================
  // NAGRODA ZAUFANIA PO DOBRYM TRENINGU
  // ==========================================================

  void rewardTrainingTrust() {
    managerRelationship = (managerRelationship + 1).clamp(0, 100).toInt();
  }

  // ==========================================================
  // DODANIE WYSTĘPU / GOLA / ASYSTY DO STATYSTYK KARIERY
  // ==========================================================

  void addCareerAppearance({
    required int minutes,
    required bool started,
    required double rating,
  }) {
    careerAppearances++;

    matchStats.addAppearance(
      playedMinutes: minutes,
      started: started,
      rating: rating,
    );
  }

  void addCareerGoal() {
    careerGoals++;
    matchStats.addGoal();
  }

  void addCareerAssist() {
    careerAssists++;
    matchStats.addAssist();
  }

  factory PlayerCareer.fromJson(Map<String, dynamic> j) {
    final player = PlayerCareer(
    id: j['id'] ?? 'career_player_001', firstName: j['firstName'] ?? 'Player', lastName: j['lastName'] ?? 'Career',
    nationality: j['nationality'] ?? 'Polska', age: j['age'] ?? 18, height: j['height'] ?? 180,
    position: PlayerPosition.values.firstWhere((e) => e.name == j['position'], orElse: () => PlayerPosition.striker),
    overall: j['overall'] ?? 60, potential: j['potential'] ?? 85, pace: j['pace'] ?? 60,
    shooting: j['shooting'] ?? 60, passing: j['passing'] ?? 60, dribbling: j['dribbling'] ?? 60,
    defending: j['defending'] ?? 40, physical: j['physical'] ?? 60, clubId: j['clubId'], shirtNumber: j['shirtNumber'] ?? 10,
    fatigue: j['fatigue'] ?? 0, fitness: j['fitness'] ?? 100, form: j['form'] ?? 70, morale: j['morale'] ?? 70,
    happiness: j['happiness'] ?? 70, managerRelationship: j['managerRelationship'] ?? 50, teamRelationship: j['teamRelationship'] ?? 50,
    agentId: j['agentId'], agentInfluence: j['agentInfluence'] ?? 50, transferRequest: j['transferRequest'] ?? false,
    fame: j['fame'] ?? 0, reputation: j['reputation'] ?? 50, fanSupport: j['fanSupport'] ?? 35,
    mediaPressure: j['mediaPressure'] ?? 0, marketability: j['marketability'] ?? 0, transferPull: j['transferPull'] ?? 0,
    sponsorInterest: j['sponsorInterest'] ?? 0, sponsorTier: j['sponsorTier'] ?? 0, sponsorIncome: j['sponsorIncome'] ?? 0,
    agentAttention: j['agentAttention'] ?? 0, interviewInvites: j['interviewInvites'] ?? 0, mediaAppearances: j['mediaAppearances'] ?? 0,
    shirtDemand: j['shirtDemand'] ?? 0, coachPressure: j['coachPressure'] ?? 0, fanMoments: j['fanMoments'] ?? 0,
    clubInterestLevel: j['clubInterestLevel'] ?? 0, marketingValue: j['marketingValue'] ?? 0, commercialEvents: j['commercialEvents'] ?? 0,
    internationalCaps: j['internationalCaps'] ?? 0, internationalGoals: j['internationalGoals'] ?? 0,
    internationalAssists: j['internationalAssists'] ?? 0, nationalCallUps: j['nationalCallUps'] ?? 0,
    lastNationalCallUpYear: j['lastNationalCallUpYear'] ?? 0, wageExpectation: j['wageExpectation'] ?? 10,
    appearanceBonus: j['appearanceBonus'] ?? 0, goalBonus: j['goalBonus'] ?? 0, assistBonus: j['assistBonus'] ?? 0,
    trophyBonus: j['trophyBonus'] ?? 0, releaseClause: (j['releaseClause'] ?? 0).toDouble(),
    contractYearsRemaining: j['contractYearsRemaining'] ?? 1, inMatchSquad: j['inMatchSquad'] ?? false,
    isStarter: j['isStarter'] ?? false, isRegularStarter: j['isRegularStarter'] ?? false,
    squadStatus: j['squadStatus'] ?? 'Bez klubu', careerAppearances: j['careerAppearances'] ?? 0,
    careerGoals: j['careerGoals'] ?? 0, careerAssists: j['careerAssists'] ?? 0,
    );
    final stats = j['matchStats'];
    if (stats is Map) {
      player.matchStats.loadFromJson(Map<String, dynamic>.from(stats));
    }
    return player;
  }

}
