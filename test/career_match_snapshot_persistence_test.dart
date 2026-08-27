import 'package:flutter_test/flutter_test.dart';

void main() {
  test('career match snapshot contains every transient field required for SAVE/LOAD', () {
    final snapshot = <String, dynamic>{
      'today': true,
      'appeared': true,
      'started': true,
      'minutes': 87,
      'goals': 2,
      'assists': 1,
      'rating': 8.4,
      'homeGoals': 3,
      'awayGoals': 1,
      'clubId': 'pol_ek_club_1',
      'clubIsHome': true,
    };
    expect(snapshot.keys, containsAll([
      'today','appeared','started','minutes','goals','assists','rating',
      'homeGoals','awayGoals','clubId','clubIsHome',
    ]));
    expect(snapshot['minutes'], 87);
    expect(snapshot['goals'], 2);
    expect(snapshot['assists'], 1);
    expect(snapshot['rating'], 8.4);
  });
}
