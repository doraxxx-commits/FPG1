import 'dart:math';

import '../models/player.dart';

/// Prosty, ale stanowy silnik kontuzji. Nie losuje kontuzji każdego dnia:
/// ryzyko wynika z wieku, zmęczenia, kondycji i obciążenia meczowego.
class InjuryEngine {
  final Random _random;

  InjuryEngine({Random? random}) : _random = random ?? Random();

  void processDay(List<Player> players) {
    for (final player in players) {
      if (player.injured) {
        player.injuryDaysRemaining--;
        player.fatigue = max(0, player.fatigue - 2);
        player.fitness = min(75, player.fitness + 1);
        if (player.injuryDaysRemaining <= 0) {
          player.injured = false;
          player.injuryDaysRemaining = 0;
          player.morale = max(35, min(100, player.morale + 3));
        }
        continue;
      }

      var risk = 0.0007;
      if (player.fatigue > 60) risk += (player.fatigue - 60) * 0.00025;
      if (player.fatigue > 85) risk += 0.006;
      if (player.fitness < 55) risk += 0.0025;
      if (player.age >= 30) risk += (player.age - 29) * 0.00015;
      if (player.minutesPlayed > 2500) risk += 0.001;

      if (_random.nextDouble() < risk) {
        player.injured = true;
        player.injuryDaysRemaining = _injuryLength(player);
        player.squadStatus = 'injured';
        player.fitness = max(20, player.fitness - 12);
        player.morale = max(25, player.morale - 4);
      }
    }
  }

  int _injuryLength(Player p) {
    final roll = _random.nextDouble();
    if (roll < 0.55) return 4 + _random.nextInt(11); // 4–14 dni
    if (roll < 0.85) return 15 + _random.nextInt(31); // 15–45
    if (roll < 0.97) return 46 + _random.nextInt(45); // 46–90
    return 91 + _random.nextInt(91); // poważna kontuzja
  }
}
