import 'dart:math';

import '../models/player.dart';
import '../models/club.dart';

/// Rozwój zawodników całego świata.
///
/// Rozwój jest zależny od wieku, potencjału, formy, kondycji, morale i
/// potencjału pozostającego do wykorzystania. Dzięki temu młodzi zawodnicy
/// rozwijają się, ale nie każdy automatycznie staje się gwiazdą.
class DevelopmentEngine {
  final Random _random;

  DevelopmentEngine({Random? random}) : _random = random ?? Random();

  /// Small daily training stimulus for the living-world simulation.
  /// It is intentionally much weaker than the end-of-season development pass:
  /// daily work nudges attributes, while seasons create the visible OVR jumps.
  void processDay(List<Player> players, List<Club> clubs) {
    final clubsById = {for (final club in clubs) club.id: club};

    for (final player in players) {
      if (player.injured || player.age < 16 || player.age >= 35) continue;
      if (player.fatigue >= 82 || player.fitness <= 35) continue;

      final club = player.clubId == null ? null : clubsById[player.clubId];
      final environment = 0.70
          + ((club?.academyQuality ?? 50) / 100.0) * 0.15
          + (player.morale / 100.0) * 0.10
          + (player.form / 100.0) * 0.05;
      final ageFactor = player.age <= 20
          ? 1.35
          : player.age <= 24
              ? 1.15
              : player.age <= 28
                  ? 0.85
                  : 0.55;

      // Most days produce no permanent attribute point. This prevents the
      // daily loop from making players grow unrealistically fast.
      final chance = (0.018 * environment * ageFactor).clamp(0.004, 0.035);
      if (_random.nextDouble() > chance) continue;

      final gain = player.age <= 23 && player.overall < player.potential ? 1 : 0;
      if (gain == 0) continue;

      _raiseAttributes(player, gain);
      player.fatigue = min(100, player.fatigue + 2);
      _refreshOverall(player);
      _refreshMarketValue(player);
    }
  }

  void processSeason(List<Player> players, {List<Club>? clubs}) {
    final clubsById = {for (final club in clubs ?? const <Club>[]) club.id: club};
    for (final player in players) {
      if (player.age <= 16 || player.age >= 34) continue;

      final gap = player.potential - player.overall;
      if (gap > 0) {
        final ageFactor = _growthAgeFactor(player.age);
        final club = player.clubId == null ? null : clubsById[player.clubId];
        final dna = club == null ? 0.0 : _dnaFit(player, club);
        final minutesFactor = player.age <= 23 ? min(1.15, 0.80 + player.minutesPlayed / 9000.0) : 1.0;
        final personality = (player.personality.professionalism + player.personality.discipline) / 200.0;
        final environment =
            (0.55 + (player.form / 100.0) * 0.15 + (player.morale / 100.0) * 0.10 + dna * 0.10 + personality * 0.10) * minutesFactor;
        final noise = 0.85 + _random.nextDouble() * 0.30;
        final amount = (gap * ageFactor * environment * noise).round();
        final growth = amount.clamp(0, min(5, gap)).toInt();
        if (growth > 0) _raiseAttributes(player, growth);
      } else if (player.age >= 28) {
        _applyLateCareerDecline(player);
      }

      _refreshOverall(player);
      _refreshMarketValue(player);
    }
  }

  double _dnaFit(Player player, Club club) {
    final target = switch (player.position) {
      PlayerPosition.goalkeeper => (club.academyTactical + club.academyPhysical) / 2,
      PlayerPosition.defender => (club.academyTactical * .6 + club.academyPhysical * .4),
      PlayerPosition.midfielder => (club.academyTechnical * .35 + club.academyCreative * .35 + club.academyTactical * .30),
      PlayerPosition.winger => (club.academyCreative * .5 + club.academyTechnical * .3 + club.academyPhysical * .2),
      PlayerPosition.striker => (club.academyCreative * .35 + club.academyTechnical * .35 + club.academyPhysical * .3),
    };
    return (target / 100.0).clamp(.35, 1.05);
  }

  double _growthAgeFactor(int age) {
    if (age <= 20) return 0.18;
    if (age <= 23) return 0.14;
    if (age <= 26) return 0.09;
    return 0.04;
  }

  void _raiseAttributes(Player p, int amount) {
    switch (p.position) {
      case PlayerPosition.goalkeeper:
        p.physical = min(99, p.physical + amount);
        p.passing = min(99, p.passing + max(1, amount - 1));
        break;
      case PlayerPosition.defender:
        p.defending = min(99, p.defending + amount);
        p.physical = min(99, p.physical + max(1, amount - 1));
        p.passing = min(99, p.passing + max(1, amount ~/ 2));
        break;
      case PlayerPosition.midfielder:
        p.passing = min(99, p.passing + amount);
        p.dribbling = min(99, p.dribbling + max(1, amount - 1));
        break;
      case PlayerPosition.winger:
        p.pace = min(99, p.pace + amount);
        p.dribbling = min(99, p.dribbling + amount);
        break;
      case PlayerPosition.striker:
        p.shooting = min(99, p.shooting + amount);
        p.physical = min(99, p.physical + max(1, amount ~/ 2));
        break;
    }
  }

  void _applyLateCareerDecline(Player p) {
    final agePressure = (p.age - 27) * 0.18;
    final formPressure = p.form < 60 ? 0.6 : 0.0;
    final declineChance = ((agePressure + formPressure) / 100).clamp(0.01, 0.12);
    if (_random.nextDouble() > declineChance) return;

    final decline = p.age >= 33 ? 2 : 1;
    p.pace = max(25, p.pace - decline);
    p.physical = max(25, p.physical - decline);
    if (p.age >= 35 && _random.nextBool()) {
      p.dribbling = max(20, p.dribbling - 1);
    }
  }

  void _refreshOverall(Player p) {
    double value;
    switch (p.position) {
      case PlayerPosition.goalkeeper:
        value = p.physical * .35 + p.passing * .25 + p.pace * .20 + p.dribbling * .20;
        break;
      case PlayerPosition.defender:
        value = p.defending * .40 + p.physical * .25 + p.passing * .20 + p.pace * .15;
        break;
      case PlayerPosition.midfielder:
        value = p.passing * .30 + p.dribbling * .25 + p.defending * .20 + p.physical * .15 + p.pace * .10;
        break;
      case PlayerPosition.winger:
        value = p.pace * .30 + p.dribbling * .30 + p.shooting * .20 + p.passing * .20;
        break;
      case PlayerPosition.striker:
        value = p.shooting * .40 + p.pace * .20 + p.dribbling * .20 + p.physical * .20;
        break;
    }
    p.overall = value.round().clamp(1, 99).toInt();
    // Potential is the long-term ceiling used by the world generator and
    // development model. Prevent a single attribute spike from overshooting
    // the hidden potential rating. This keeps long-run OVR distributions
    // stable across many seasons.
    if (p.potential > 0 && p.overall > p.potential) {
      p.overall = p.potential;
    }
  }

  void _refreshMarketValue(Player p) {
    final ageMultiplier = p.age <= 23
        ? 1.25
        : p.age <= 28
            ? 1.10
            : p.age <= 32
                ? 0.85
                : 0.55;
    final potentialMultiplier = 1.0 + max(0, p.potential - p.overall) / 150.0;
    p.value = max(50000.0, p.overall * p.overall * 1800 * ageMultiplier * potentialMultiplier);
    p.weeklyWage = max(150.0, p.overall * p.overall * 0.65);
  }
}
