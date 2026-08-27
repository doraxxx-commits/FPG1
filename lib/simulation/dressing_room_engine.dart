import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';

/// Hierarchia szatni i konflikty. Konflikt buduje napięcie, a przy wysokim
/// napięciu może prowadzić do żądania transferu, spadku morale i interwencji trenera.
class DressingRoomEngine {
  final Random _random;
  final Map<String, int> leadership = {};
  final Map<String, int> tension = {};

  DressingRoomEngine({Random? random}) : _random = random ?? Random();

  List<String> processDay({required List<Club> clubs, required List<Player> players}) {
    final logs = <String>[];
    for (final club in clubs) {
      final squad = players.where((p) => p.clubId == club.id).toList();
      if (squad.length < 3) continue;
      squad.sort((a, b) => _leadershipScore(b).compareTo(_leadershipScore(a)));
      final captain = squad.first;
      leadership[club.id] = _leadershipScore(captain);

      final unhappy = squad.where((p) => p.consecutiveBenchDays >= 20 || p.morale <= 40 || p.transferRequest).toList();
      if (unhappy.isNotEmpty && _random.nextDouble() < .015) {
        final player = unhappy[_random.nextInt(unhappy.length)];
        tension[club.id] = min(100, (tension[club.id] ?? 0) + 8);
        player.morale = max(15, player.morale - 3);
        player.managerRelationship = max(10, player.managerRelationship - 2);
        logs.add('NAPIĘCIE W SZATNI: ${club.name} — ${player.name}');
      }

      final clubTension = tension[club.id] ?? 0;
      if (clubTension >= 45) {
        final candidates = squad.where((p) => p.consecutiveBenchDays >= 15 || p.morale <= 45).toList();
        if (candidates.isNotEmpty && _random.nextDouble() < .01) {
          final player = candidates[_random.nextInt(candidates.length)];
          player.transferRequest = true;
          player.happiness = max(15, player.happiness - 6);
          logs.add('ŻĄDANIE TRANSFERU: ${player.name} — ${club.name}');
        }
      }
      if (clubTension >= 70) {
        final leader = squad.reduce((a, b) => _leadershipScore(a) >= _leadershipScore(b) ? a : b);
        leader.morale = min(100, leader.morale + 1);
        club.stability = max(10, club.stability - 1);
        club.boardConfidence = max(10, club.boardConfidence - 1);
      }
      if (clubTension > 0) {
        tension[club.id] = max(0, clubTension - 1);
      }
    }
    return logs;
  }

  int _leadershipScore(Player p) => p.age * 2 + p.overall + p.managerRelationship ~/ 2 + p.morale ~/ 4;
}
