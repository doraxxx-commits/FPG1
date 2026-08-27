import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

/// Kontroluje emerytury i regenerację świata. Maksymalny wiek zawodnika AI
/// to 50 lat.
class RetirementEngine {
  final Random _random;
  RetirementEngine({Random? random}) : _random = random ?? Random();

  List<Player> processSeason({required List<Player> players, required List<Club> clubs}) {
    final retired = <Player>[];
    for (final player in players) {
      if (player.age < 30) continue;
      var chance = 0.0;
      if (player.age >= 50) {
        chance = 1.0;
      } else if (player.age >= 45) {
        chance = 0.45;
      } else if (player.age >= 40) {
        chance = 0.22;
      } else if (player.age >= 36) {
        chance = player.overall >= 82 ? 0.05 : 0.12;
      } else if (player.age >= 32) {
        chance = player.overall < 60 ? 0.08 : 0.015;
      }
      if (_random.nextDouble() < chance) retired.add(player);
    }

    // V11.1: retirement only identifies the retired players.
    // WorldEngine removes them and lets the youth scouting pipeline replenish
    // the ecosystem instead of creating a synthetic regen for each retiree.
    return retired;
  }
}
