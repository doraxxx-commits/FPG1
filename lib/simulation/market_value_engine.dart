import 'dart:math';

import '../models/player.dart';
import '../models/player_career.dart';

/// V26 — dynamic football market valuation.
///
/// OVR is the anchor, but the market also prices what a player is actually
/// doing: minutes, appearances, starts, production, form, age, potential,
/// reputation and commercial pull. Production is position-aware so a defender
/// is not punished like a striker for scoring fewer goals.
class MarketValueEngine {
  double valueForWorldPlayer(Player p) {
    final base = _ovrBase(p.overall);
    final age = _ageFactor(p.age);
    final potential = 1.0 + ((p.potential - p.overall).clamp(0, 25) / 120.0);
    final playingTime = _playingTimeFactor(p.appearances, p.minutesPlayed, p.starts);
    final production = _productionFactor(p);
    final form = 0.88 + (p.form.clamp(0, 100) / 100.0) * 0.24;
    final reputation = 0.92 + (p.reputation.clamp(0, 100) / 100.0) * 0.16;
    final commercial = 0.96 + ((p.marketability + p.fame).clamp(0, 200) / 200.0) * 0.12;
    final contract = _contractFactor(p.contractYearsRemaining);

    return max(50000, base * age * potential * playingTime * production * form * reputation * commercial * contract);
  }

  double valueForCareerPlayer(PlayerCareer p) {
    final base = _ovrBase(p.overall);
    final age = _ageFactor(p.age);
    final potential = 1.0 + ((p.potential - p.overall).clamp(0, 25) / 120.0);
    final playingTime = _playingTimeFactor(
      p.matchStats.appearances,
      p.matchStats.minutes,
      p.matchStats.starts,
    );
    final production = _careerProductionFactor(p);
    final form = 0.88 + (p.form.clamp(0, 100) / 100.0) * 0.24;
    final reputation = 0.92 + (p.reputation.clamp(0, 100) / 100.0) * 0.16;
    final commercial = 0.96 + ((p.marketability + p.fame).clamp(0, 200) / 200.0) * 0.12;
    final contract = _contractFactor(p.contractYearsRemaining);

    return max(50000, base * age * potential * playingTime * production * form * reputation * commercial * contract);
  }

  void refreshWorldPlayer(Player p) {
    p.value = valueForWorldPlayer(p);
  }

  void refreshCareerPlayer(PlayerCareer p) {
    final value = valueForCareerPlayer(p);
    p.contract?.updateMarketValue(value);
  }

  double _ovrBase(int overall) {
    // Realistyczna krzywa rynku: OVR jest kotwicą, ale nie liniową.
    // Punkty referencyjne są kalibrowane do europejskiego rynku i łączone
    // logarytmicznie, dzięki czemu 90 OVR jest wielokrotnie droższy od 70.
    const anchors = <int, double>{
      40: 250000,
      50: 600000,
      60: 2000000,
      65: 4000000,
      70: 8000000,
      75: 15000000,
      80: 30000000,
      85: 55000000,
      90: 100000000,
      95: 160000000,
      99: 220000000,
    };

    final o = overall.clamp(40, 99);
    if (anchors.containsKey(o)) return anchors[o]!;

    final lower = anchors.keys.where((k) => k < o).reduce(max);
    final upper = anchors.keys.where((k) => k > o).reduce(min);
    final t = (o - lower) / (upper - lower);
    final a = log(anchors[lower]!);
    final b = log(anchors[upper]!);
    return exp(a + (b - a) * t);
  }

  double _ageFactor(int age) {
    if (age <= 20) return 1.12;
    if (age <= 23) return 1.18;
    if (age <= 26) return 1.10;
    if (age <= 29) return 1.00;
    if (age <= 31) return 0.88;
    if (age <= 33) return 0.72;
    if (age <= 35) return 0.55;
    return 0.38;
  }

  double _playingTimeFactor(int appearances, int minutes, int starts) {
    if (appearances <= 0 || minutes <= 0) return 0.72;
    final minutesPerAppearance = minutes / appearances;
    final regularity = (appearances / 25.0).clamp(0.0, 1.0);
    final minutesQuality = (minutesPerAppearance / 75.0).clamp(0.35, 1.10);
    final starterShare = (starts / appearances).clamp(0.0, 1.0);
    return (0.78 + regularity * 0.18 + minutesQuality * 0.12 + starterShare * 0.10).clamp(0.72, 1.16);
  }

  double _productionFactor(Player p) {
    final apps = max(1, p.appearances);
    final per90 = 90 / max(1, p.minutesPlayed);
    final goals90 = p.goals * per90;
    final assists90 = p.assists * per90;
    final output = switch (p.position) {
      PlayerPosition.striker => goals90 * 0.20 + assists90 * 0.08,
      PlayerPosition.winger => goals90 * 0.12 + assists90 * 0.12,
      PlayerPosition.midfielder => goals90 * 0.07 + assists90 * 0.14,
      PlayerPosition.defender => goals90 * 0.03 + assists90 * 0.05,
      PlayerPosition.goalkeeper => 0.0,
    };
    final sampleTrust = (apps / 20.0).clamp(0.0, 1.0);
    return (0.90 + output.clamp(-0.15, 0.55) * sampleTrust).clamp(0.82, 1.38);
  }

  double _careerProductionFactor(PlayerCareer p) {
    final apps = max(1, p.matchStats.appearances);
    final minutes = max(1, p.matchStats.minutes);
    final per90 = 90 / minutes;
    final goals90 = p.matchStats.goals * per90;
    final assists90 = p.matchStats.assists * per90;
    final output = switch (p.position) {
      PlayerPosition.striker => goals90 * 0.20 + assists90 * 0.08,
      PlayerPosition.winger => goals90 * 0.12 + assists90 * 0.12,
      PlayerPosition.midfielder => goals90 * 0.07 + assists90 * 0.14,
      PlayerPosition.defender => goals90 * 0.03 + assists90 * 0.05,
      PlayerPosition.goalkeeper => 0.0,
    };
    final sampleTrust = (apps / 20.0).clamp(0.0, 1.0);
    return (0.90 + output.clamp(-0.15, 0.55) * sampleTrust).clamp(0.82, 1.38);
  }

  double _contractFactor(int years) {
    if (years <= 0) return 0.82;
    if (years == 1) return 0.90;
    if (years == 2) return 0.98;
    if (years == 3) return 1.02;
    return 1.05;
  }
}
