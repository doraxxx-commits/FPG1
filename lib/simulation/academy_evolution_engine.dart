import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

/// V11.1D: academy history becomes a feedback loop.
/// Successful graduates improve academy reputation and slowly shape the DNA;
/// failures and lack of pathways can weaken it. Changes are intentionally slow.
class AcademyEvolutionEngine {
  final Random _random;
  AcademyEvolutionEngine({Random? random}) : _random = random ?? Random();

  List<String> processSeason({required List<Club> clubs, required List<Player> players}) {
    final events = <String>[];
    for (final club in clubs) {
      final academyPlayers = players.where((p) => p.clubId == club.id).toList();
      final graduates = academyPlayers.where((p) =>
          p.hasProfessionalContract || p.debutDay > 0 || p.careerStage == 'firstTeam' || p.careerStage == 'loan').toList();
      final debutants = academyPlayers.where((p) => p.debutDay > 0 && p.age <= 23).length;
      final highImpact = academyPlayers.where((p) => p.age <= 26 && p.overall >= 75).length;
      final youthMinutes = academyPlayers.where((p) => p.age <= 23).fold<int>(0, (sum, p) => sum + p.minutesPlayed);

      var delta = 0;
      if (debutants > 0) delta += min(4, debutants);
      if (highImpact > 0) delta += min(4, highImpact);
      if (youthMinutes >= 1800) delta += 2;
      if (graduates.isEmpty && club.youthFocus >= 65) delta -= 1;
      if (club.stability < 35) delta -= 1;
      delta += _random.nextInt(3) - 1;

      final oldRep = club.academyReputation;
      club.academyReputation = (oldRep + delta).clamp(15, 95).toInt();
      _evolveDna(club, academyPlayers);

      // Reputation feeds back very gently into the headline academy quality.
      final target = ((club.academyReputation * .45) + (club.academyTechnical + club.academyCreative + club.academyTactical) / 6).round();
      if (target > club.academyQuality) club.academyQuality = min(100, club.academyQuality + 1);
      if (target < club.academyQuality) club.academyQuality = max(25, club.academyQuality - 1);

      if (delta >= 3) events.add('${club.name}: reputacja akademii rośnie (${club.academyReputation}).');
      else if (delta <= -2) events.add('${club.name}: akademia traci część reputacji (${club.academyReputation}).');
    }
    return events;
  }

  void _evolveDna(Club club, List<Player> players) {
    final young = players.where((p) => p.age <= 23).toList();
    if (young.isEmpty) return;
    final technical = young.fold<double>(0, (s, p) => s + p.passing + p.dribbling) / (young.length * 2);
    final physical = young.fold<double>(0, (s, p) => s + p.physical + p.pace) / (young.length * 2);
    final creative = young.fold<double>(0, (s, p) => s + p.dribbling + p.passing + p.shooting) / (young.length * 3);
    final tactical = young.fold<double>(0, (s, p) => s + p.defending + p.passing) / (young.length * 2);
    club.academyTechnical = _nudge(club.academyTechnical, technical.round(), 1);
    club.academyPhysical = _nudge(club.academyPhysical, physical.round(), 1);
    club.academyCreative = _nudge(club.academyCreative, creative.round(), 1);
    club.academyTactical = _nudge(club.academyTactical, tactical.round(), 1);
    if (young.where((p) => p.nationality == club.country).length * 2 >= young.length) {
      club.academyLocal = min(100, club.academyLocal + 1);
    }
  }

  int _nudge(int current, int target, int step) {
    if (target > current) return min(100, current + step);
    if (target < current) return max(1, current - step);
    return current;
  }
}
