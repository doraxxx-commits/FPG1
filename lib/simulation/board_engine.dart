import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';

/// Warstwa zarządu klubu. Zarząd wyznacza cele, ocenia trenera i reaguje na
/// wyniki, finanse oraz niezadowolenie kibiców.
class BoardEngine {
  final Random _random;
  BoardEngine({Random? random}) : _random = random ?? Random();

  List<String> processDay({required List<Club> clubs, required List<Player> players}) {
    final logs = <String>[];
    for (final club in clubs) {
      final squad = players.where((p) => p.clubId == club.id).toList();
      final squadAverage = squad.isEmpty
          ? club.overall
          : squad.map((p) => p.overall).reduce((a, b) => a + b) / squad.length;

      var target = club.overall;
      if (club.boardPressure >= 80) target += 2;
      if (club.reputation >= 80) target += 1;
      if (club.financialHealth < 30) target -= 3;
      target = target.clamp(40, 95).toInt();

      final resultPressure = club.lossesStreak >= 4 ? 8 : club.winsStreak >= 4 ? -4 : 0;
      final performanceGap = target - squadAverage;
      final delta = (performanceGap / 12).round() + resultPressure ~/ 4;
      club.boardConfidence = (club.boardConfidence - delta).clamp(5, 100).toInt();

      if (club.boardConfidence <= 20 && club.managerTenureDays > 60) {
        if (_random.nextDouble() < 0.025 + club.boardPressure / 5000) {
          club.boardConfidence = 55;
          club.managerQuality = (club.managerQuality + _random.nextInt(15) - 7).clamp(30, 95).toInt();
          club.managerReputation = (club.managerReputation + _random.nextInt(11) - 5).clamp(20, 95).toInt();
          club.managerTenureDays = 0;
          logs.add('ZARZĄD: ${club.name} zmienił trenera po utracie zaufania.');
        }
      }

      if (club.financialHealth < 20 && club.budget > 0) {
        club.transferActivity = max(15, club.transferActivity - 1);
      }
    }
    return logs;
  }
}
