import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/core/game_engine.dart';

void main() {
  test('career projection and world player share the same career id', () {
    final engine = GameEngine();
    engine.createPlayer(
      firstName: 'Test',
      lastName: 'Player',
      nationality: 'Polska',
      age: 18,
      height: 180,
      position: engine.players.first.position,
      pace: 60,
      shooting: 60,
      passing: 60,
      dribbling: 60,
      defending: 40,
      physical: 60,
    );

    expect(engine.careerPlayer, isNotNull);
    expect(engine.careerWorldBridge.projection, isNotNull);
    expect(engine.careerPlayer!.id, engine.careerWorldBridge.projection!.id);
  });
}
