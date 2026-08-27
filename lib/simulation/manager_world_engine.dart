import 'dart:math';
import '../models/club.dart';
import '../models/manager_candidate.dart';

/// Trenerzy tworzą własny rynek pracy: mają styl, jakość, reputację i koszt.
class ManagerWorldEngine {
  final Random random;
  final List<ManagerCandidate> candidates = [];

  ManagerWorldEngine({Random? random}) : random = random ?? Random() {
    _seedCandidates();
  }

  static const styles = <String>['balanced', 'youth', 'stars', 'possession', 'counter', 'physical'];

  void _seedCandidates() {
    const names = ['Marco Bellini', 'Jonas Weber', 'Pawel Nowak', 'Diego Santos', 'Lars Holm', 'Adrian Costa', 'Milan Kovac', 'Thomas Berger', 'Nicolas Moreau', 'Mateusz Zielinski'];
    for (var i = 0; i < names.length; i++) {
      candidates.add(ManagerCandidate(
        id: 'manager_candidate_$i',
        name: names[i],
        preferredStyle: styles[i % styles.length],
        quality: 58 + (i * 3) % 34,
        reputation: 45 + (i * 5) % 45,
        youthDevelopment: 45 + (i * 7) % 50,
        tacticalIdentity: 45 + (i * 9) % 45,
        wageDemand: 20 + i * 4,
      ));
    }
  }

  void processDay(List<Club> clubs) {
    for (final club in clubs) {
      club.managerTenureDays++;
      final momentum = club.winsStreak - club.lossesStreak;
      if (momentum >= 3) {
        club.boardConfidence = min(100, club.boardConfidence + 1);
      } else if (momentum <= -3) {
        club.boardConfidence = max(0, club.boardConfidence - 1);
      }

      final crisis = club.lossesStreak >= 5 || club.financialHealth < 20 || club.boardConfidence < 25;
      final successful = club.winsStreak >= 5 && club.stability >= 65;
      final sackChance = crisis
          ? (0.004 + club.boardPressure / 850)
          : (successful ? 0.0001 : 0.00035);

      if (random.nextDouble() < sackChance && club.managerTenureDays > 90) {
        changeManager(club);
      }
    }
  }

  void changeManager(Club club) {
    // Zwolniony trener wraca na rynek pracy, jeśli był kandydatem.
    final old = candidates.where((c) => c.id == club.managerId).firstOrNull;
    if (old != null) old.employed = false;

    final budgetMillions = max(10, club.budget ~/ 1000000);
    final affordable = candidates.where((c) => !c.employed && c.wageDemand <= budgetMillions).toList();
    final pool = affordable.isEmpty ? candidates.where((c) => !c.employed).toList() : affordable;

    if (pool.isEmpty) {
      club.managerId = 'generated_manager_${random.nextInt(100000)}';
      club.managerName = 'Manager ${random.nextInt(900) + 100}';
      club.managerStyle = styles[random.nextInt(styles.length)];
      club.managerQuality = (club.managerQuality + random.nextInt(21) - 10).clamp(30, 95).toInt();
      club.managerReputation = (club.managerReputation + random.nextInt(17) - 8).clamp(20, 95).toInt();
      club.tacticalIdentity = (club.tacticalIdentity + random.nextInt(25) - 12).clamp(20, 95).toInt();
    } else {
      pool.sort((a, b) {
        final aFit = a.quality + a.reputation + a.youthDevelopment * (club.youthFocus / 100) + (a.preferredStyle == club.managerStyle ? 8 : 0);
        final bFit = b.quality + b.reputation + b.youthDevelopment * (club.youthFocus / 100) + (b.preferredStyle == club.managerStyle ? 8 : 0);
        return bFit.compareTo(aFit);
      });
      final candidate = pool.first;
      candidate.employed = true;
      club.managerId = candidate.id;
      club.managerName = candidate.name;
      club.managerStyle = candidate.preferredStyle;
      club.managerQuality = candidate.quality;
      club.managerReputation = candidate.reputation;
      club.tacticalIdentity = candidate.tacticalIdentity;
    }
    club.managerTenureDays = 0;
    club.seasonsManaged++;
    club.boardConfidence = 55;
    club.stability = max(15, club.stability - 3);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
