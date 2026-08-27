import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/models/club.dart';
import 'package:fpg/models/player.dart';
import 'package:fpg/simulation/transfer_engine.dart';

void main() {
  test('transfer market keeps an operating reserve', () {
    final buyer = Club(id: 'b', name: 'Buyer', country: 'PL', leagueId: 'l', overall: 70, budget: 300000);
    final seller = Club(id: 's', name: 'Seller', country: 'PL', leagueId: 'l', overall: 70, budget: 300000);
    final player = Player(
      id: 'p', name: 'Player', age: 22, position: PlayerPosition.striker,
      overall: 70, potential: 80, value: 250000, weeklyWage: 5000, clubId: seller.id,
    );
    final beforeBuyer = buyer.budget;
    TransferEngine(random: Random(1)).processWindow(
      clubs: [buyer, seller], players: [player], summer: true, winter: false, absoluteDay: 10,
    );
    expect(buyer.budget, lessThanOrEqualTo(beforeBuyer));
    expect(buyer.budget, greaterThanOrEqualTo(0));
  });
}
