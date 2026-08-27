import '../models/club.dart';
import '../models/player.dart';
import '../models/player_career.dart';

/// Most pomiędzy karierą użytkownika a tym samym światem, w którym działają
/// zawodnicy AI. Dzięki temu zawodnik gracza nie jest osobnym "wyjątkiem".
class CareerWorldBridge {
  Player? _projection;
  String? _lastClubId;

  Player? get projection => _projection;

  void attach({required PlayerCareer career, required List<Player> worldPlayers, required List<Club> clubs}) {
    final existing = worldPlayers.where((p) => p.id == career.id).firstOrNull;
    if (existing != null) {
      _projection = existing;
    } else {
      _projection = _toWorldPlayer(career);
      worldPlayers.add(_projection!);
    }
    _lastClubId = _projection!.clubId;
    _syncRoster(worldPlayers: worldPlayers, clubs: clubs);
  }

  void pushCareerState(PlayerCareer career) {
    final p = _projection;
    if (p == null) return;
    p.name = career.fullName;
    p.age = career.age;
    p.nationality = career.nationality;
    p.overall = career.overall;
    p.potential = career.potential;
    p.pace = career.pace;
    p.shooting = career.shooting;
    p.passing = career.passing;
    p.dribbling = career.dribbling;
    p.defending = career.defending;
    p.physical = career.physical;
    p.clubId = career.clubId;
    p.agentId = career.agentId;
    p.agentInfluence = career.agentInfluence;
    p.transferRequest = career.transferRequest;
    p.happiness = career.happiness;
    p.fame = career.fame; p.reputation = career.reputation; p.fanSupport = career.fanSupport;
    p.mediaPressure = career.mediaPressure; p.marketability = career.marketability; p.transferPull = career.transferPull;
    p.sponsorInterest = career.sponsorInterest; p.sponsorTier = career.sponsorTier; p.sponsorIncome = career.sponsorIncome;
    p.agentAttention = career.agentAttention; p.interviewInvites = career.interviewInvites; p.mediaAppearances = career.mediaAppearances;
    p.shirtDemand = career.shirtDemand; p.coachPressure = career.coachPressure; p.fanMoments = career.fanMoments;
    p.clubInterestLevel = career.clubInterestLevel; p.marketingValue = career.marketingValue; p.commercialEvents = career.commercialEvents;
    p.morale = career.morale;
    p.managerRelationship = career.managerRelationship;
    p.fatigue = career.fatigue;
    p.fitness = career.fitness;
    p.form = career.form;
    p.contractYearsRemaining = career.contract?.yearsRemaining ?? career.contractYearsRemaining;
    p.releaseClause = career.contract?.marketValue != null && career.releaseClause > 0
        ? career.releaseClause
        : career.releaseClause;
    p.weeklyWage = career.contract?.weeklySalary ?? p.weeklyWage;
    p.hasProfessionalContract = career.contract?.isActive ?? p.hasProfessionalContract;
    p.contractRole = career.contract?.squadStatus ?? p.contractRole;
    p.wageExpectation = career.wageExpectation;
    p.appearanceBonus = career.appearanceBonus;
    p.goalBonus = career.goalBonus;
    p.assistBonus = career.assistBonus;
    p.trophyBonus = career.trophyBonus;
    p.appearances = career.matchStats.appearances;
    p.starts = career.matchStats.starts;
    p.minutesPlayed = career.matchStats.minutes;
    p.goals = career.matchStats.goals;
    p.assists = career.matchStats.assists;
  }

  void pullWorldState(PlayerCareer career, {required List<Player> worldPlayers, required List<Club> clubs}) {
    final p = worldPlayers.where((x) => x.id == career.id).firstOrNull ?? _projection;
    if (p == null) return;
    // World simulation is authoritative for mutable football state.
    // Keep the career projection fully synchronized so development, aging,
    // fatigue/form and market changes made by WorldEngine are not lost when
    // control returns to the player's career layer.
    career.age = p.age;
    career.overall = p.overall;
    career.potential = p.potential;
    career.pace = p.pace;
    career.shooting = p.shooting;
    career.passing = p.passing;
    career.dribbling = p.dribbling;
    career.defending = p.defending;
    career.physical = p.physical;
    career.clubId = p.clubId;
    career.fitness = p.fitness;
    career.form = p.form;
    career.fatigue = p.fatigue;
    career.contractYearsRemaining = p.contractYearsRemaining;
    career.releaseClause = p.releaseClause;
    if (career.contract != null) {
      career.contract!.yearsRemaining = p.contractYearsRemaining;
      career.contract!.updateMarketValue(p.value);
      career.contract!.squadStatus = p.squadStatus;
      career.contract!.managerTrust = p.managerRelationship;
      career.contract!.updateSalary(p.weeklyWage);
    }
    career.agentId = p.agentId;
    career.agentInfluence = p.agentInfluence;
    career.transferRequest = p.transferRequest;
    career.happiness = p.happiness;
    career.fame = p.fame; career.reputation = p.reputation; career.fanSupport = p.fanSupport;
    career.mediaPressure = p.mediaPressure; career.marketability = p.marketability; career.transferPull = p.transferPull;
    career.sponsorInterest = p.sponsorInterest; career.sponsorTier = p.sponsorTier; career.sponsorIncome = p.sponsorIncome;
    career.agentAttention = p.agentAttention; career.interviewInvites = p.interviewInvites; career.mediaAppearances = p.mediaAppearances;
    career.shirtDemand = p.shirtDemand; career.coachPressure = p.coachPressure; career.fanMoments = p.fanMoments;
    career.clubInterestLevel = p.clubInterestLevel; career.marketingValue = p.marketingValue; career.commercialEvents = p.commercialEvents;
    career.morale = p.morale;
    career.managerRelationship = p.managerRelationship;
    career.internationalCaps = p.internationalCaps;
    career.internationalGoals = p.internationalGoals;
    career.internationalAssists = p.internationalAssists;
    career.nationalCallUps = p.nationalCallUps;
    career.lastNationalCallUpYear = p.lastNationalCallUpYear;
    career.wageExpectation = p.wageExpectation;
    career.appearanceBonus = p.appearanceBonus;
    career.goalBonus = p.goalBonus;
    career.assistBonus = p.assistBonus;
    career.trophyBonus = p.trophyBonus;
    _syncRoster(worldPlayers: worldPlayers, clubs: clubs);
  }

  void _syncRoster({required List<Player> worldPlayers, required List<Club> clubs}) {
    final p = _projection;
    if (p == null) return;
    if (_lastClubId != null && _lastClubId != p.clubId) {
      clubs.where((c) => c.id == _lastClubId).forEach((c) => c.removePlayer(p.id));
    }
    for (final club in clubs) {
      club.removePlayer(p.id);
    }
    if (p.clubId != null) {
      clubs.where((c) => c.id == p.clubId).forEach((c) => c.addPlayer(p.id));
    }
    _lastClubId = p.clubId;
  }

  Player _toWorldPlayer(PlayerCareer c) => Player(
    id: c.id,
    name: c.fullName,
    age: c.age,
    position: c.position,
    nationality: c.nationality,
    overall: c.overall,
    potential: c.potential,
    pace: c.pace,
    shooting: c.shooting,
    passing: c.passing,
    dribbling: c.dribbling,
    defending: c.defending,
    physical: c.physical,
    value: 0,
    weeklyWage: 0,
    clubId: c.clubId,
    agentId: c.agentId,
    agentInfluence: c.agentInfluence,
    transferRequest: c.transferRequest,
    happiness: c.happiness, fame: c.fame, reputation: c.reputation, fanSupport: c.fanSupport,
    mediaPressure: c.mediaPressure, marketability: c.marketability, transferPull: c.transferPull,
    sponsorInterest: c.sponsorInterest, sponsorTier: c.sponsorTier, sponsorIncome: c.sponsorIncome,
    agentAttention: c.agentAttention, interviewInvites: c.interviewInvites, mediaAppearances: c.mediaAppearances,
    shirtDemand: c.shirtDemand, coachPressure: c.coachPressure, fanMoments: c.fanMoments,
    clubInterestLevel: c.clubInterestLevel, marketingValue: c.marketingValue, commercialEvents: c.commercialEvents,
    internationalCaps: c.internationalCaps,
    internationalGoals: c.internationalGoals,
    internationalAssists: c.internationalAssists,
    nationalCallUps: c.nationalCallUps,
    lastNationalCallUpYear: c.lastNationalCallUpYear,
    wageExpectation: c.wageExpectation,
    appearanceBonus: c.appearanceBonus,
    goalBonus: c.goalBonus,
    assistBonus: c.assistBonus,
    trophyBonus: c.trophyBonus,
    releaseClause: c.releaseClause,
    contractYearsRemaining: c.contractYearsRemaining,
    fatigue: c.fatigue,
    fitness: c.fitness,
    form: c.form,
    morale: c.morale,
    managerRelationship: c.managerRelationship,
  );
}
