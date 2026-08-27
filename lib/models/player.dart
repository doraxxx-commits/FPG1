import 'player_personality.dart';
import 'player_preferences.dart';

enum PlayerPosition {
  goalkeeper,
  defender,
  midfielder,
  winger,
  striker,
}

class Player {
  final String id;
  String name;
  int age;
  final PlayerPosition position;
  String nationality;
  int overall;
  int potential;

  // V11.1B: osobowość i preferencje są częścią ścieżki kariery młodego zawodnika.
  final PlayerPersonality personality;
  final PlayerPreferences preferences;
  bool hasProfessionalContract;
  int debutDay;
  int firstContractYear;
  String careerStage;

  int pace;
  int shooting;
  int passing;
  int dribbling;
  int defending;
  int physical;

  double value;
  double weeklyWage;
  String? clubId;

  // World Simulation 4.0: agent zawodnika i jego wpływ na rynek.
  String? agentId;
  int agentInfluence;
  bool transferRequest;
  int happiness;

  // V18.4 public profile and market memory.
  int fame;
  int reputation;
  int fanSupport;
  int mediaPressure;
  int marketability;
  int transferPull;

  // V18.5 career consequences.
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

  // Historia reprezentacyjna zawodnika. Jest niezależna od statystyk klubowych.
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
  double loanFeeExpectation;
  int guaranteedMinutesExpectation;
  double buyoutClauseExpectation;

  // Światowe kontrakty i wypożyczenia. Dla zawodników AI są lekkim
  // odpowiednikiem PlayerContract z kariery gracza.
  int contractYearsRemaining;
  double releaseClause;
  String contractRole;
  String? loanFromClubId;
  int loanUntilDay;

  int fatigue;
  int fitness;
  int form;
  int morale;

  // Pamięć AI trenera — dzięki tym polom decyzje nie są całkowicie losowe.
  int managerRelationship;
  String squadStatus;
  int consecutiveBenchDays;
  int consecutiveUnusedDays;
  int appearances;
  int starts;
  int minutesPlayed;
  int goals;
  int assists;
  int lastMatchDay;
  int lastTrainingDay;
  bool injured;
  int injuryDaysRemaining;

  Player({
    required this.id,
    required this.name,
    required this.age,
    required this.position,
    this.nationality = 'Polska',
    required this.overall,
    required this.potential,
    PlayerPersonality? personality,
    PlayerPreferences? preferences,
    this.hasProfessionalContract = false,
    this.debutDay = 0,
    this.firstContractYear = 0,
    this.careerStage = 'academy',
    this.pace = 60,
    this.shooting = 60,
    this.passing = 60,
    this.dribbling = 60,
    this.defending = 50,
    this.physical = 60,
    this.value = 0,
    this.weeklyWage = 0,
    this.clubId,
    this.agentId,
    this.agentInfluence = 50,
    this.transferRequest = false,
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
    this.loanFeeExpectation = 0,
    this.guaranteedMinutesExpectation = 0,
    this.buyoutClauseExpectation = 0,
    this.contractYearsRemaining = 1,
    this.releaseClause = 0,
    this.contractRole = 'rotation',
    this.loanFromClubId,
    this.loanUntilDay = 0,
    this.fatigue = 0,
    this.fitness = 100,
    this.form = 70,
    this.morale = 70,
    this.managerRelationship = 50,
    this.squadStatus = 'reserves',
    this.consecutiveBenchDays = 0,
    this.consecutiveUnusedDays = 0,
    this.appearances = 0,
    this.starts = 0,
    this.minutesPlayed = 0,
    this.goals = 0,
    this.assists = 0,
    this.lastMatchDay = 0,
    this.lastTrainingDay = 0,
    this.injured = false,
    this.injuryDaysRemaining = 0,
  }) : personality = personality ?? PlayerPersonality(),
       preferences = preferences ?? PlayerPreferences();

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'age': age, 'position': position.name,
    'nationality': nationality, 'overall': overall, 'potential': potential,
    'personality': personality.toJson(), 'preferences': preferences.toJson(), 'hasProfessionalContract': hasProfessionalContract, 'debutDay': debutDay, 'firstContractYear': firstContractYear, 'careerStage': careerStage,
    'pace': pace, 'shooting': shooting, 'passing': passing,
    'dribbling': dribbling, 'defending': defending, 'physical': physical,
    'value': value, 'weeklyWage': weeklyWage, 'clubId': clubId,
    'agentId': agentId, 'agentInfluence': agentInfluence,
    'transferRequest': transferRequest, 'happiness': happiness,
    'fame': fame, 'reputation': reputation, 'fanSupport': fanSupport,
    'mediaPressure': mediaPressure, 'marketability': marketability, 'transferPull': transferPull,
    'sponsorInterest': sponsorInterest, 'sponsorTier': sponsorTier, 'sponsorIncome': sponsorIncome,
    'agentAttention': agentAttention, 'interviewInvites': interviewInvites, 'mediaAppearances': mediaAppearances,
    'shirtDemand': shirtDemand, 'coachPressure': coachPressure, 'fanMoments': fanMoments,
    'clubInterestLevel': clubInterestLevel, 'marketingValue': marketingValue, 'commercialEvents': commercialEvents,
    'internationalCaps': internationalCaps, 'internationalGoals': internationalGoals,
    'internationalAssists': internationalAssists, 'nationalCallUps': nationalCallUps,
    'lastNationalCallUpYear': lastNationalCallUpYear, 'wageExpectation': wageExpectation,
    'appearanceBonus': appearanceBonus, 'goalBonus': goalBonus, 'assistBonus': assistBonus,
    'trophyBonus': trophyBonus, 'loanFeeExpectation': loanFeeExpectation,
    'guaranteedMinutesExpectation': guaranteedMinutesExpectation,
    'buyoutClauseExpectation': buyoutClauseExpectation,
    'contractYearsRemaining': contractYearsRemaining, 'releaseClause': releaseClause,
    'contractRole': contractRole, 'loanFromClubId': loanFromClubId, 'loanUntilDay': loanUntilDay,
    'fatigue': fatigue, 'fitness': fitness, 'form': form, 'morale': morale,
    'managerRelationship': managerRelationship, 'squadStatus': squadStatus,
    'consecutiveBenchDays': consecutiveBenchDays, 'consecutiveUnusedDays': consecutiveUnusedDays,
    'appearances': appearances, 'starts': starts, 'minutesPlayed': minutesPlayed,
    'goals': goals, 'assists': assists, 'lastMatchDay': lastMatchDay,
    'lastTrainingDay': lastTrainingDay, 'injured': injured, 'injuryDaysRemaining': injuryDaysRemaining,
  };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
    id: j['id'] as String, name: j['name'] as String, age: j['age'] as int,
    position: PlayerPosition.values.firstWhere((e) => e.name == j['position'], orElse: () => PlayerPosition.midfielder),
    nationality: j['nationality'] ?? 'Polska', overall: j['overall'] ?? 50, potential: j['potential'] ?? 60,
    personality: PlayerPersonality.fromJson(j['personality'] is Map ? Map<String, dynamic>.from(j['personality']) : null),
    preferences: PlayerPreferences.fromJson(j['preferences'] is Map ? Map<String, dynamic>.from(j['preferences']) : null),
    hasProfessionalContract: j['hasProfessionalContract'] ?? false, debutDay: j['debutDay'] ?? 0, firstContractYear: j['firstContractYear'] ?? 0, careerStage: j['careerStage'] ?? 'academy',
    pace: j['pace'] ?? 50, shooting: j['shooting'] ?? 50, passing: j['passing'] ?? 50,
    dribbling: j['dribbling'] ?? 50, defending: j['defending'] ?? 50, physical: j['physical'] ?? 50,
    value: (j['value'] ?? 0).toDouble(), weeklyWage: (j['weeklyWage'] ?? 0).toDouble(), clubId: j['clubId'],
    agentId: j['agentId'], agentInfluence: j['agentInfluence'] ?? 50, transferRequest: j['transferRequest'] ?? false,
    happiness: j['happiness'] ?? 70, fame: j['fame'] ?? 0, reputation: j['reputation'] ?? 50,
    fanSupport: j['fanSupport'] ?? 35, mediaPressure: j['mediaPressure'] ?? 0, marketability: j['marketability'] ?? 0, transferPull: j['transferPull'] ?? 0,
    sponsorInterest: j['sponsorInterest'] ?? 0, sponsorTier: j['sponsorTier'] ?? 0, sponsorIncome: j['sponsorIncome'] ?? 0,
    agentAttention: j['agentAttention'] ?? 0, interviewInvites: j['interviewInvites'] ?? 0, mediaAppearances: j['mediaAppearances'] ?? 0,
    shirtDemand: j['shirtDemand'] ?? 0, coachPressure: j['coachPressure'] ?? 0, fanMoments: j['fanMoments'] ?? 0,
    clubInterestLevel: j['clubInterestLevel'] ?? 0, marketingValue: j['marketingValue'] ?? 0, commercialEvents: j['commercialEvents'] ?? 0,
    internationalCaps: j['internationalCaps'] ?? 0,
    internationalGoals: j['internationalGoals'] ?? 0, internationalAssists: j['internationalAssists'] ?? 0,
    nationalCallUps: j['nationalCallUps'] ?? 0, lastNationalCallUpYear: j['lastNationalCallUpYear'] ?? 0,
    wageExpectation: j['wageExpectation'] ?? 10, appearanceBonus: j['appearanceBonus'] ?? 0,
    goalBonus: j['goalBonus'] ?? 0, assistBonus: j['assistBonus'] ?? 0, trophyBonus: j['trophyBonus'] ?? 0,
    loanFeeExpectation: (j['loanFeeExpectation'] ?? 0).toDouble(), guaranteedMinutesExpectation: j['guaranteedMinutesExpectation'] ?? 0,
    buyoutClauseExpectation: (j['buyoutClauseExpectation'] ?? 0).toDouble(), contractYearsRemaining: j['contractYearsRemaining'] ?? 1,
    releaseClause: (j['releaseClause'] ?? 0).toDouble(), contractRole: j['contractRole'] ?? 'rotation',
    loanFromClubId: j['loanFromClubId'], loanUntilDay: j['loanUntilDay'] ?? 0, fatigue: j['fatigue'] ?? 0,
    fitness: j['fitness'] ?? 100, form: j['form'] ?? 70, morale: j['morale'] ?? 70,
    managerRelationship: j['managerRelationship'] ?? 50, squadStatus: j['squadStatus'] ?? 'reserves',
    consecutiveBenchDays: j['consecutiveBenchDays'] ?? 0, consecutiveUnusedDays: j['consecutiveUnusedDays'] ?? 0,
    appearances: j['appearances'] ?? 0, starts: j['starts'] ?? 0, minutesPlayed: j['minutesPlayed'] ?? 0,
    goals: j['goals'] ?? 0, assists: j['assists'] ?? 0, lastMatchDay: j['lastMatchDay'] ?? 0,
    lastTrainingDay: j['lastTrainingDay'] ?? 0, injured: j['injured'] ?? false, injuryDaysRemaining: j['injuryDaysRemaining'] ?? 0,
  );

}
