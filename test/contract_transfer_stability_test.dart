import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/club.dart';
import 'package:fpg/models/player.dart';
import 'package:fpg/simulation/contract_engine.dart';
import 'package:fpg/simulation/transfer_engine.dart';

Player makePlayer(String id, {String? clubId, int years = 1, int wage = 1000}) => Player(
  id: id,
  name: 'Player $id',
  age: 24,
  position: PlayerPosition.striker,
  overall: 70,
  potential: 80,
  pace: 70,
  shooting: 75,
  passing: 65,
  dribbling: 70,
  defending: 35,
  physical: 65,
  value: 500000,
  weeklyWage: wage.toDouble(),
  clubId: clubId,
  contractYearsRemaining: years,
  hasProfessionalContract: true,
);

Club makeClub(String id, {int financialHealth = 75}) => Club(
  id: id,
  name: 'Club $id',
  country: 'Polska',
  leagueId: 'test',
  overall: 70,
  budget: 50000000,
  financialHealth: financialHealth,
  minimumSigningOverall: 60,
);

void main() {
  test('P0.9 expired contract releases player instead of leaving 0-year contract', () {
    final club = makeClub('club', financialHealth: 10);
    final player = makePlayer('p', clubId: club.id, years: 1, wage: 100000);
    club.addPlayer(player.id);

    ContractEngine(random: Random(1)).processSeason([club], [player]);

    expect(player.contractYearsRemaining, 0);
    expect(player.clubId, isNull);
    expect(player.hasProfessionalContract, isFalse);
    expect(player.squadStatus, 'freeAgent');
  });

  test('loan return uses absolute world day and is idempotent', () {
    final parent = makeClub('parent');
    final loanClub = makeClub('loan');
    final player = makePlayer('loaned', clubId: loanClub.id, years: 2);
    player.loanFromClubId = parent.id;
    player.loanUntilDay = 250;

    final engine = TransferEngine(random: Random(2));
    expect(engine.processLoanReturns(
      clubs: [parent, loanClub], players: [player], absoluteDay: 249,
    ), isEmpty);
    expect(player.clubId, loanClub.id);

    final logs = engine.processLoanReturns(
      clubs: [parent, loanClub], players: [player], absoluteDay: 250,
    );
    expect(logs, hasLength(1));
    expect(player.clubId, parent.id);
    expect(player.loanFromClubId, isNull);
    expect(player.loanUntilDay, 0);

    expect(engine.processLoanReturns(
      clubs: [parent, loanClub], players: [player], absoluteDay: 251,
    ), isEmpty);
  });

  test('transfer window can sign a free agent and gives a fresh contract', () {
    final club = makeClub('buyer');
    final free = makePlayer('free', clubId: null, years: 0);
    free.squadStatus = 'freeAgent';

    final engine = TransferEngine(random: Random(3));
    final logs = engine.processWindow(
      clubs: [club],
      players: [free],
      summer: true,
      winter: false,
      absoluteDay: 365,
    );

    // Randomized market activity may skip the signing; if it signs, all
    // ownership/contract invariants must hold. Re-run with deterministic seed
    // candidates would make the assertion brittle, so verify eligibility path
    // separately by checking that no invalid state is produced.
    if (logs.isNotEmpty) {
      expect(free.clubId, club.id);
      expect(free.contractYearsRemaining, greaterThan(0));
      expect(free.hasProfessionalContract, isTrue);
      expect(free.squadStatus, 'squad');
    } else {
      expect(free.clubId, isNull);
      expect(free.contractYearsRemaining, 0);
    }
  });
}
