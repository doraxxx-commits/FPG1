import 'dart:math';

import '../models/club.dart';
import '../models/rivalry.dart';

/// Buduje trwałe rywalizacje. Derby zaczynają się od bliskości sportowej,
/// wspólnej ligi i historii, a później intensywność może rosnąć.
class RivalryEngine {
  final Random _random;
  final Map<String, Rivalry> rivalries = {};

  RivalryEngine({Random? random}) : _random = random ?? Random();

  void initialize(List<Club> clubs) {
    final grouped = <String, List<Club>>{};
    for (final club in clubs) {
      grouped.putIfAbsent('${club.country}:${club.leagueId}', () => []).add(club);
    }
    for (final group in grouped.values) {
      for (var i = 0; i < group.length; i++) {
        for (var j = i + 1; j < group.length; j++) {
          final a = group[i];
          final b = group[j];
          final gap = (a.overall - b.overall).abs();
          final seed = 25 + max(0, 20 - gap) + (a.reputation + b.reputation) ~/ 20;
          if (_random.nextDouble() < .35 || gap <= 4) {
            final id = _id(a.id, b.id);
            rivalries.putIfAbsent(id, () => Rivalry(
              id: id,
              clubAId: a.id,
              clubBId: b.id,
              intensity: seed.clamp(20, 90).toInt(),
            ));
          }
        }
      }
    }
  }

  void processSeason(List<Club> clubs) {
    initialize(clubs);
    for (final rivalry in rivalries.values) {
      final a = clubs.firstWhereOrNull((c) => c.id == rivalry.clubAId);
      final b = clubs.firstWhereOrNull((c) => c.id == rivalry.clubBId);
      if (a == null || b == null) continue;
      final gap = (a.overall - b.overall).abs();
      if (gap <= 5) {
        rivalry.intensity = min(100, rivalry.intensity + 2);
      } else {
        rivalry.intensity = max(15, rivalry.intensity - 1);
      }
    }
  }


  int intensityBetween(String clubAId, String clubBId) {
    final id = _id(clubAId, clubBId);
    return rivalries[id]?.intensity ?? 0;
  }

  bool isDerby(String clubAId, String clubBId) => intensityBetween(clubAId, clubBId) >= 60;

  String _id(String a, String b) => a.compareTo(b) < 0 ? '$a::$b' : '$b::$a';
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
