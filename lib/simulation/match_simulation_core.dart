import 'dart:math';

/// Wspólny, UI-niezależny rdzeń symulacji meczu.
/// GlobalMatchEngine i MatchEngine korzystają z tych samych zasad wyliczania
/// siły zespołu i oczekiwanych goli; różnią się tylko warstwą danych oraz prezentacją.
class MatchSimulationTeamInput {
  final double playerAverage;
  final double formAverage;
  final double fitnessAverage;
  final double moraleAverage;
  final int clubOverall;
  final int financialHealth;
  final int reputation;
  final int tacticalIdentity;
  final int managerQuality;



  const MatchSimulationTeamInput({
    required this.playerAverage,
    required this.formAverage,
    required this.fitnessAverage,
    required this.moraleAverage,
    required this.clubOverall,
    required this.financialHealth,
    required this.reputation,
    this.tacticalIdentity = 50,
    this.managerQuality = 50,
  });
}

class MatchSimulationCoreResult {
  final int homeGoals;
  final int awayGoals;
  final double homeStrength;
  final double awayStrength;
  final double homeXg;
  final double awayXg;

  const MatchSimulationCoreResult({
    required this.homeGoals,
    required this.awayGoals,
    required this.homeStrength,
    required this.awayStrength,
    required this.homeXg,
    required this.awayXg,
  });
}

class MatchSimulationCore {
  final Random random;

  MatchSimulationCore({Random? random}) : random = random ?? Random();

  MatchSimulationCoreResult simulate({
    required MatchSimulationTeamInput home,
    required MatchSimulationTeamInput away,
    int rivalryIntensity = 0,
  }) {
    var homeStrength = _strength(home, homeAdvantage: true);
    var awayStrength = _strength(away, homeAdvantage: false);

    // V13: wynik nie opiera się już prawie wyłącznie na OVR. Forma, morale,
    // kondycja, finanse i reputacja tworzą kontekst meczu, a przewaga nie daje
    // automatycznie wysokiego wyniku.
    final volatility = 1.0 + rivalryIntensity.clamp(0, 100) / 220.0;
    homeStrength += (random.nextDouble() - .5) * 3.0 * volatility;
    awayStrength += (random.nextDouble() - .5) * 3.0 * volatility;

    if (rivalryIntensity >= 60) {
      final chaos = rivalryIntensity * .06;
      homeStrength += (random.nextDouble() - .5) * chaos;
      awayStrength += (random.nextDouble() - .5) * chaos;
    }

    final homeXg = _expectedGoals(homeStrength, awayStrength, true);
    final awayXg = _expectedGoals(homeStrength, awayStrength, false);

    return MatchSimulationCoreResult(
      homeGoals: _poissonLikeGoals(homeXg),
      awayGoals: _poissonLikeGoals(awayXg),
      homeStrength: homeStrength,
      awayStrength: awayStrength,
      homeXg: homeXg,
      awayXg: awayXg,
    );
  }

  double _strength(MatchSimulationTeamInput team, {required bool homeAdvantage}) {
    var strength = team.playerAverage * .64 +
        team.clubOverall * .20 +
        team.formAverage * .08 +
        team.fitnessAverage * .04 +
        team.moraleAverage * .02;
    // Tactical identity and manager quality alter how reliably a club converts
    // its raw squad strength into chances.
    strength += (team.tacticalIdentity - 50) * .035;
    strength += (team.managerQuality - 50) * .025;
    strength += team.financialHealth * .012;
    strength += team.reputation * .008;
    if (homeAdvantage) strength += 2.5;
    return strength;
  }

  double _expectedGoals(double home, double away, bool isHome) {
    final diff = isHome ? home - away : away - home;
    final base = isHome ? 1.36 : 1.08;
    // Spłaszczamy wpływ dużej różnicy siły. Dzięki temu słabszy klub może
    // wygrać 1:0, ale faworyt nadal jest wyraźnym faworytem.
    final strengthImpact = tanh(diff / 22.0) * .72;
    final fatigueNoise = (random.nextDouble() - .5) * .18;
    return (base + strengthImpact + fatigueNoise).clamp(.18, 3.35);
  }

  double tanh(double x) {
    final e = exp(2 * x);
    return (e - 1) / (e + 1); 
  }

  int _poissonLikeGoals(double lambda) {
    final chance = random.nextDouble();
    var cumulative = exp(-lambda);
    if (chance <= cumulative) return 0;
    var probability = cumulative;
    for (var k = 1; k <= 8; k++) {
      probability *= lambda / k;
      cumulative += probability;
      if (chance <= cumulative) return k;
    }
    return 8;
  }
}
