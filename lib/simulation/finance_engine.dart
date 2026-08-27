import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

/// Finanse klubów AI. Ma być lekkie i deterministyczne, ale wystarczająco
/// mocne, aby pieniądze wpływały na decyzje transferowe.
class FinanceEngine {
  void processWeekly(List<Club> clubs, List<Player> players) {
    for (final club in clubs) {
      final squad = players.where((p) => p.clubId == club.id).toList();
      final wageBill = squad.fold<double>(0, (sum, p) => sum + p.weeklyWage);
      final revenue = 12000 + club.reputation * 650.0 + club.overall * 900.0;
      final operatingCost = max(10000.0, wageBill * 1.20 + club.overall * 120.0);

      club.budget = max(0, club.budget + (revenue - operatingCost).round());
      final pressure = operatingCost <= 0 ? 0.0 : (wageBill / operatingCost);

      if (club.budget < operatingCost * 3 || pressure > 0.70) {
        club.financialHealth = max(5, club.financialHealth - 1);
      } else if (club.budget > operatingCost * 10) {
        club.financialHealth = min(100, club.financialHealth + 1);
      }
    }
  }

  void processSeason(List<Club> clubs) {
    for (final club in clubs) {
      final prize = 150000 + club.overall * 20000 + club.reputation * 5000;
      club.budget = max(0, club.budget + prize);
      if (club.financialHealth < 35) {
        club.boardPressure = min(100, club.boardPressure + 5);
      } else if (club.financialHealth > 80) {
        club.boardPressure = max(20, club.boardPressure - 2);
      }
    }
  }
}
