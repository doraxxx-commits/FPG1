import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

/// Analizuje potrzeby kadrowe klubu. TransferEngine korzysta z tego zamiast
/// wykonywać przypadkowe transfery.
class ClubAIEngine {
  final Random _random;
  ClubAIEngine({Random? random}) : _random = random ?? Random();

  PlayerPosition? biggestNeed(Club club, List<Player> players) {
    final squad = players.where((p) => p.clubId == club.id).toList();
    final counts = <PlayerPosition, int>{
      for (final pos in PlayerPosition.values) pos: squad.where((p) => p.position == pos).length,
    };

    final minimums = <PlayerPosition, int>{
      PlayerPosition.goalkeeper: 2,
      PlayerPosition.defender: 5,
      PlayerPosition.midfielder: 5,
      PlayerPosition.winger: 3,
      PlayerPosition.striker: 2,
    };

    final needs = PlayerPosition.values.where((p) => (counts[p] ?? 0) < minimums[p]!).toList();
    if (needs.isNotEmpty) return needs[_random.nextInt(needs.length)];

    // Tożsamość trenera zmienia priorytety. Nie jest to bonus do OVR, tylko
    // preferencja AI, dzięki której dwa kluby o podobnej sile mogą budować
    // zupełnie inne kadry.
    final stylePriority = switch (club.managerStyle) {
      'youth' => PlayerPosition.values.firstWhere(
          (p) => squad.where((x) => x.position == p && x.age <= 23).isEmpty,
          orElse: () => PlayerPosition.midfielder),
      'stars' => PlayerPosition.values.reduce((a, b) =>
          _average(squad, a) < _average(squad, b) ? a : b),
      'physical' => PlayerPosition.defender,
      'possession' => PlayerPosition.midfielder,
      'counter' => PlayerPosition.winger,
      _ => null,
    };
    if (stylePriority != null) return stylePriority;

    // Jeżeli kadra jest pełna, szukamy najsłabszej pozycji.
    return PlayerPosition.values.reduce((a, b) => _average(squad, a) < _average(squad, b) ? a : b);
  }

  double _average(List<Player> squad, PlayerPosition position) {
    final list = squad.where((p) => p.position == position).toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (sum, p) => sum + p.overall) / list.length;
  }
}
