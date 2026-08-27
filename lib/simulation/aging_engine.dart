import 'dart:math';
import '../models/player.dart';
import '../models/club.dart';

class AgingEngine {
  static final Random _rnd = Random();

  static const List<String> _firstNames = [
    'Mateo', 'Kacper', 'Szymon', 'Nico', 'Lucas', 'Julian', 'Marco', 'Leo', 'Jakub', 'Filip', 'Jan', 'Gabriel'
  ];

  static const List<String> _lastNames = [
    'Nowak', 'Rossi', 'Silva', 'Müller', 'Kowalski', 'Garcia', 'Weber', 'Wiśniewski', 'Zieliński', 'Dubois', 'Martins'
  ];

  static void processEndOfSeason({
    required List<Player> allPlayers,
    required List<Club> allClubs,
  }) {
    final List<Player> retiredPlayers = [];

    for (final player in allPlayers) {
      player.age += 1;

      if (player.age <= 26 && player.overall < player.potential) {
        final gap = player.potential - player.overall;
        final growth = (gap * (0.15 + _rnd.nextDouble() * 0.15)).round().clamp(1, 4).toInt();
        
        player.pace = (player.pace + growth).clamp(1, 99).toInt();
        player.shooting = (player.shooting + growth).clamp(1, 99).toInt();
        player.passing = (player.passing + growth).clamp(1, 99).toInt();
        player.dribbling = (player.dribbling + growth).clamp(1, 99).toInt();
      }

      if (player.age >= 31) {
        final ovrFactor = (100 - player.overall) / 100.0;
        final ageFactor = (player.age - 30) * 0.3;
        final totalDecline = ((ageFactor * ovrFactor) + (_rnd.nextDouble() * 0.5)).round().clamp(0, 3).toInt();

        if (totalDecline > 0) {
          player.pace = (player.pace - totalDecline).clamp(35, 99).toInt();
          player.physical = (player.physical - totalDecline).clamp(35, 99).toInt();
          player.fatigue = (player.fatigue + totalDecline).clamp(0, 100).toInt();
        }
      }

      if (player.age >= 32) {
        bool shouldRetire = false;

        if (player.age >= 48) {
          shouldRetire = true;
        } else if (player.age >= 40) {
          shouldRetire = _rnd.nextDouble() < 0.40;
        } else if (player.age >= 36) {
          final isGK = player.position == PlayerPosition.goalkeeper;
          final isStar = player.overall >= 82;
          final baseChance = (isGK || isStar) ? 0.08 : 0.20;
          shouldRetire = _rnd.nextDouble() < baseChance;
        } else if (player.age >= 32) {
          if (player.overall < 60) {
            shouldRetire = _rnd.nextDouble() < 0.10;
          }
        }

        if (shouldRetire) {
          retiredPlayers.add(player);
        }
      }
    }

    for (final retired in retiredPlayers) {
      allPlayers.remove(retired);
      final regen = _generateRegen(retired.clubId, retired.position);
      allPlayers.add(regen);
    }
  }

  static Player _generateRegen(String? clubId, PlayerPosition position) {
    final fName = _firstNames[_rnd.nextInt(_firstNames.length)];
    final lName = _lastNames[_rnd.nextInt(_lastNames.length)];
    final baseStat = 58 + _rnd.nextInt(14);

    return Player(
      id: 'regen_${DateTime.now().millisecondsSinceEpoch}_${_rnd.nextInt(9999)}',
      name: '$fName $lName',
      age: 17 + _rnd.nextInt(3),
      position: position,
      overall: baseStat,
      potential: baseStat + 12 + _rnd.nextInt(10),
      pace: (baseStat + _rnd.nextInt(8) - 4).clamp(1, 99),
      shooting: (baseStat + _rnd.nextInt(8) - 4).clamp(1, 99),
      passing: (baseStat + _rnd.nextInt(8) - 4).clamp(1, 99),
      dribbling: (baseStat + _rnd.nextInt(8) - 4).clamp(1, 99),
      defending: (baseStat + _rnd.nextInt(8) - 4).clamp(1, 99),
      physical: (baseStat + _rnd.nextInt(8) - 4).clamp(1, 99),
      value: (baseStat * 18000).toDouble(),
      weeklyWage: (baseStat * 140).toDouble(),
      clubId: clubId,
    );
  }
}
