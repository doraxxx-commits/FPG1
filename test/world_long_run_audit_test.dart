import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/club.dart';
import 'package:fpg/models/league.dart';
import 'package:fpg/models/player.dart';
import 'package:fpg/simulation/world_engine.dart';
import 'package:fpg/simulation/world_long_run_audit.dart';
import 'package:fpg/simulation/world_player_generator.dart';

void main() {
  test('P1.2 five-season lifecycle keeps player graph and squad depth healthy', () {
    final leagues = [
      League(id: 'top', name: 'Top', country: 'Testland', level: 1),
      League(id: 'second', name: 'Second', country: 'Testland', level: 2),
    ];
    final clubs = <Club>[];
    for (var i = 0; i < 8; i++) {
      clubs.add(Club(
        id: 'club_$i',
        name: 'Club $i',
        country: 'Testland',
        leagueId: i < 4 ? 'top' : 'second',
        overall: 62 + (i % 5),
        budget: 8000000,
        reputation: 55,
        financialHealth: 75,
        youthFocus: 70,
        transferActivity: 45,
      ));
    }

    final generator = WorldPlayerGenerator(random: Random(123));
    final players = <Player>[];
    for (final club in clubs) {
      players.addAll(generator.generateFirstTeamSquad(
        year: 2026,
        club: club,
        targetSize: 20,
      ));
    }

    final world = WorldEngine(
      clubs: clubs,
      players: players,
      leagues: leagues,
      seasonStartYear: 2026,
      random: Random(456),
    );

    final snapshots = <WorldLongRunAuditSnapshot>[];
    for (var season = 2026; season < 2036; season++) {
      world.processEndOfSeason(nextSeasonStartYear: season + 1);
      final snapshot = WorldLongRunAudit.snapshot(
        seasonYear: season + 1,
        clubs: clubs,
        players: players,
      );
      WorldLongRunAudit.assertHealthy(snapshot);
      snapshots.add(snapshot);
    }

    expect(snapshots, hasLength(10));
    expect(snapshots.every((s) => s.clubCount == 8), isTrue);
    expect(snapshots.every((s) => s.playerCount >= 8 * 18), isTrue);
    expect(snapshots.every((s) => s.minSeniorSquad >= 18), isTrue);
    expect(snapshots.every((s) => s.duplicatePlayerIds == 0), isTrue);
    expect(snapshots.every((s) => s.unknownClubAssignments == 0), isTrue);
    expect(snapshots.every((s) => s.potentialBreaches == 0), isTrue);
    expect(snapshots.every((s) => s.maxOverall <= 99), isTrue);
    expect(snapshots.every((s) => s.averageOverall >= 45 && s.averageOverall <= 90), isTrue);
  });
}
