import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/club.dart';
import 'package:fpg/models/player.dart';
import 'package:fpg/simulation/world_engine.dart';
import 'package:fpg/simulation/world_integrity_validator.dart';

Player player(String id, String clubId, {int age = 22}) => Player(
  id: id, name: 'Player $id', age: age,
  position: PlayerPosition.midfielder, overall: 65, potential: 75,
  pace: 65, shooting: 60, passing: 65, dribbling: 65,
  defending: 55, physical: 65, clubId: clubId,
);

Club club(String id) => Club(id: id, name: 'Club $id', overall: 65);

void main() {
  test('P0.7 detects duplicate IDs and cross-club roster corruption', () {
    final clubs = [club('a'), club('b')];
    final players = [player('p', 'a'), player('p', 'b')];
    clubs[0].addPlayer('p');
    clubs[1].addPlayer('p');

    final report = WorldIntegrityValidator.validate(clubs: clubs, players: players);
    expect(report.isValid, isFalse);
    expect(report.errors, contains(startsWith('DUPLICATE_PLAYER_ID')));
    expect(report.errors, contains(startsWith('PLAYER_IN_MULTIPLE_ROSTERS')));
  });

  test('WorldEngine roster sync keeps each player in exactly one owned roster', () {
    final clubs = [club('a'), club('b')];
    final players = [player('p1', 'a'), player('p2', 'b')];
    final world = WorldEngine(clubs: clubs, players: players, leagues: const [], random: Random(7));

    final report = world.validateWorldIntegrity();
    expect(report.isValid, isTrue, reason: report.errors.join('\n'));
    expect(clubs[0].playerIds, ['p1']);
    expect(clubs[1].playerIds, ['p2']);
  });

  test('loan parent must remain a real club and loan duration must be positive', () {
    final clubs = [club('parent'), club('loan')];
    final p = player('p', 'loan');
    p.loanFromClubId = 'parent';
    p.loanUntilDay = 10;
    final valid = WorldIntegrityValidator.validate(clubs: clubs, players: [p]);
    expect(valid.isValid, isTrue, reason: valid.errors.join('\n'));

    p.loanFromClubId = 'missing';
    final invalid = WorldIntegrityValidator.validate(clubs: clubs, players: [p]);
    expect(invalid.errors, contains(startsWith('LOAN_WITH_UNKNOWN_PARENT')));
  });
}
