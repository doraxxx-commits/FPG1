import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/club.dart';
import '../lib/models/player_career.dart';
import '../lib/models/player.dart';
import '../lib/simulation/match_engine.dart';

void main() {
  test('MatchEngine produces coherent team stats and selects a positional XI', () {
    final club = Club(id: 'a', name: 'A', overall: 80);
    final away = Club(id: 'b', name: 'B', overall: 75);
    final players = List.generate(18, (i) => PlayerCareer(
      id: 'p$i', firstName: 'P', lastName: '$i', nationality: 'PL', age: 20, height: 180,
      position: i == 0 ? PlayerPosition.striker : PlayerPosition.defender,
      overall: i == 0 ? 90 : 60, potential: 90, pace: 70, shooting: i == 0 ? 90 : 50,
      passing: 60, dribbling: 60, defending: 60, physical: 60, clubId: 'a',
    ));
    final engine = MatchEngine(random: Random(42));
    final result = engine.simulate(home: club, away: away, homePlayers: players, awayPlayers: players);

    expect(result.homeShots, greaterThanOrEqualTo(result.homeGoals + 3));
    expect(result.awayShots, greaterThanOrEqualTo(result.awayGoals + 3));
    expect(result.homeShotsOnTarget, lessThanOrEqualTo(result.homeShots));
    expect(result.awayShotsOnTarget, lessThanOrEqualTo(result.awayShots));
    expect(result.possessionHome, inInclusiveRange(30, 70));
    expect(result.playerPerformances, isNotEmpty);
    expect(result.playerPerformances.where((p) => p.started).length, 11);
  });

  test('MatchEngine prefers quality within each position and excludes unavailable players', () {
  final club = Club(id: 'home', name: 'Home', overall: 75);
  final away = Club(id: 'away', name: 'Away', overall: 75);
  final players = <PlayerCareer>[
    PlayerCareer(id: 'gk', firstName: 'GK', lastName: '1', nationality: 'PL', age: 24, height: 190, position: PlayerPosition.goalkeeper, overall: 80, potential: 85, pace: 50, shooting: 20, passing: 60, dribbling: 30, defending: 70, physical: 70, clubId: 'home'),
    ...List.generate(5, (i) => PlayerCareer(id: 'd$i', firstName: 'D', lastName: '$i', nationality: 'PL', age: 24, height: 180, position: PlayerPosition.defender, overall: i == 4 ? 88 : 60 + i, potential: 90, pace: 60, shooting: 40, passing: 60, dribbling: 40, defending: 70, physical: 70, clubId: 'home')),
    ...List.generate(4, (i) => PlayerCareer(id: 'm$i', firstName: 'M', lastName: '$i', nationality: 'PL', age: 24, height: 180, position: PlayerPosition.midfielder, overall: 65 + i, potential: 90, pace: 60, shooting: 55, passing: 70, dribbling: 65, defending: 50, physical: 65, clubId: 'home')),
    ...List.generate(3, (i) => PlayerCareer(id: 'w$i', firstName: 'W', lastName: '$i', nationality: 'PL', age: 24, height: 180, position: PlayerPosition.winger, overall: 66 + i, potential: 90, pace: 75, shooting: 60, passing: 65, dribbling: 75, defending: 35, physical: 60, clubId: 'home')),
    PlayerCareer(id: 'st', firstName: 'ST', lastName: '1', nationality: 'PL', age: 24, height: 185, position: PlayerPosition.striker, overall: 82, potential: 90, pace: 75, shooting: 85, passing: 55, dribbling: 70, defending: 25, physical: 75, clubId: 'home'),
  ];
  final unavailable = players.firstWhere((p) => p.id == 'd0');
  unavailable.fitness = 10;

  final result = MatchEngine(random: Random(7)).simulate(home: club, away: away, homePlayers: players);
  final started = result.playerPerformances.where((p) => p.started).map((p) => p.playerId).toSet();

  expect(started.length, 11);
  expect(started, contains('gk'));
  expect(started, contains('d4'));
  expect(started, contains('st'));
    expect(started, isNot(contains('d0')));
  });
}
