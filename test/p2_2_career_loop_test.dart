import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/core/game_engine.dart';
import 'package:fpg/core/training_engine.dart';
import 'package:fpg/models/player.dart';

void main() {
  test('career day allows one meaningful training action and then requires next day', () {
    final engine = GameEngine();
    engine.createPlayer(
      firstName: 'Test', lastName: 'Player', nationality: 'POL', age: 18, height: 180,
      position: PlayerPosition.midfielder, pace: 70, shooting: 65, passing: 72,
      dribbling: 70, defending: 50, physical: 68,
    );
    // A newly created career has no club yet, but training is still a valid
    // daily career action. The guard itself is what this test targets.
    engine.trainPlayer(TrainingType.passing);
    expect(engine.dailyCareerActionConsumed, isTrue);
    expect(engine.dailyCareerAction, 'training');
    expect(() => engine.trainPlayer(TrainingType.pace), throwsStateError);
  });
}
