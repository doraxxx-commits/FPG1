import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/player.dart';
import 'package:fpg/simulation/development_engine.dart';

Player makePlayer() => Player(
  id: 'prospect', name: 'Prospect', age: 19,
  position: PlayerPosition.striker, overall: 79, potential: 80,
  pace: 78, shooting: 84, passing: 55, dribbling: 76,
  defending: 25, physical: 72, clubId: null,
);

void main() {
  test('season development never overshoots hidden potential', () {
    final player = makePlayer();
    final engine = DevelopmentEngine(random: Random(7));

    for (var season = 0; season < 10; season++) {
      engine.processSeason([player]);
      expect(player.overall, lessThanOrEqualTo(player.potential));
      expect(player.overall, inInclusiveRange(1, 99));
    }
  });
}
