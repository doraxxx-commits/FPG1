import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/core/game_engine.dart';

void main() {
  test('career hub exposes a real next fixture without mutating state', () {
    final engine = GameEngine();
    expect(engine.nextCareerFixture, isNull);
    expect(engine.careerHasMatchToday, isFalse);
  });
}
