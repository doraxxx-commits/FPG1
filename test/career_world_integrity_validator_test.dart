import 'package:flutter_test/flutter_test.dart';

import 'package:fpg/models/club.dart';
import 'package:fpg/models/player.dart';
import 'package:fpg/models/player_career.dart';
import 'package:fpg/simulation/career_world_integrity_validator.dart';

void main() {
  test('career projection must keep mutable football state synchronized', () {
    final career = PlayerCareer(
      id: 'career_1', firstName: 'A', lastName: 'B', nationality: 'PL',
      age: 20, height: 180, position: PlayerPosition.striker,
      overall: 70, potential: 85, pace: 75, shooting: 72, passing: 55,
      dribbling: 68, defending: 30, physical: 65, clubId: 'c1',
    );
    final projection = Player(
      id: 'career_1', name: 'A B', age: 20, position: PlayerPosition.striker,
      nationality: 'PL', overall: 70, potential: 85, pace: 75, shooting: 72,
      passing: 55, dribbling: 68, defending: 30, physical: 65, value: 1,
      weeklyWage: 1000, clubId: 'c1', fitness: 100, form: 70, fatigue: 0,
    );
    final club = Club(id: 'c1', name: 'Test', leagueId: 'l1', overall: 70, reputation: 70, budget: 1000000);
    expect(const CareerWorldIntegrityValidator().isValid(
      career: career, projection: projection, clubs: [club]), isTrue);

    projection.overall = 71;
    expect(const CareerWorldIntegrityValidator().isValid(
      career: career, projection: projection, clubs: [club]), isFalse);
  });
}
