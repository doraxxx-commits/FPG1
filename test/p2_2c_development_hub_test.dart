import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/core/game_engine.dart';
import 'package:fpg/core/training_engine.dart';
import 'package:fpg/models/player.dart';

void main() {
  test('development training uses the daily career action and changes attributes', () {
    final engine = GameEngine();
    engine.createPlayer(
      firstName: 'Test',
      lastName: 'Player',
      nationality: 'Polska',
      age: 18,
      height: 180,
      position: PlayerPosition.striker,
      pace: 60,
      shooting: 65,
      passing: 55,
      dribbling: 60,
      defending: 30,
      physical: 60,
    );

    final before = engine.careerPlayer!.shooting;
    engine.trainPlayer(TrainingType.shooting);

    expect(engine.dailyCareerActionConsumed, isTrue);
    expect(engine.dailyCareerAction, 'training');
    expect(engine.careerPlayer!.shooting, greaterThanOrEqualTo(before));

    expect(
      () => engine.trainPlayer(TrainingType.passing),
      throwsStateError,
    );
  });
}
