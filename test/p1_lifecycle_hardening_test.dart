import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/club.dart';
import 'package:fpg/models/player.dart';
import 'package:fpg/simulation/contract_engine.dart';
import 'package:fpg/simulation/transfer_engine.dart';
import 'package:fpg/simulation/world_integrity_validator.dart';

Player makePlayer(String id, String? clubId, {PlayerPosition position = PlayerPosition.striker, int overall = 70, int contractYears = 1}) => Player(
  id: id, name: id, age: 24, position: position, overall: overall, potential: overall + 10,
  pace: overall, shooting: overall, passing: overall, dribbling: overall,
  defending: overall - 5, physical: overall, clubId: clubId,
  contractYearsRemaining: contractYears,
);

Club makeClub(String id, {int overall = 70}) => Club(id: id, name: id, overall: overall);

void main() {
  test('contract engine ignores orphaned club ids instead of mutating another club policy', () {
    final clubs = [makeClub('A')];
    final orphan = makePlayer('P', 'MISSING', contractYears: 1);
    ContractEngine(random: Random(1)).processSeason(clubs, [orphan]);
    expect(orphan.contractYearsRemaining, 1);
    expect(orphan.clubId, 'MISSING');
  });

  test('free-agent signing requires a matching position', () {
    final buyer = makeClub('BUYER');
    final freeDefender = makePlayer('D', null, position: PlayerPosition.defender, contractYears: 0);
    final players = [freeDefender];
    final logs = TransferEngine(random: Random(2)).processWindow(
      clubs: [buyer], players: players, summer: true, winter: false, absoluteDay: 365,
    );
    expect(freeDefender.clubId, isNull);
    expect(logs, isEmpty);
  });

  test('validator rejects impossible loan and free-agent states', () {
    final clubs = [makeClub('A'), makeClub('B')];
    final loanSameClub = makePlayer('L', 'A');
    loanSameClub.loanFromClubId = 'A';
    loanSameClub.loanUntilDay = 100;
    final badFreeAgent = makePlayer('F', 'B');
    badFreeAgent.squadStatus = 'freeAgent';
    final report = WorldIntegrityValidator.validate(clubs: clubs, players: [loanSameClub, badFreeAgent]);
    expect(report.errors, contains(startsWith('LOAN_PARENT_EQUALS_CURRENT_CLUB')));
    expect(report.errors, contains(startsWith('FREE_AGENT_WITH_CLUB')));
  });
}
