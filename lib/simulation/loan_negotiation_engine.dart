import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';
import '../models/loan_negotiation.dart';

class LoanNegotiationEngine {
  final Random _random;
  final Map<String, LoanNegotiation> active = {};
  LoanNegotiationEngine({Random? random}) : _random = random ?? Random();

  List<String> process({required List<Club> clubs, required List<Player> players, required bool transferWindow, int absoluteDay = 0}) {
    if (!transferWindow) return [];
    final logs = <String>[];
    final candidates = players.where((p) => p.clubId != null && (p.squadStatus == 'reserves' || p.squadStatus == 'outOfSquad' || p.consecutiveBenchDays >= 14) && p.age <= 24).toList();
    for (final player in candidates.take(max(1, clubs.length ~/ 8))) {
      final parent = clubs.firstWhereOrNull((c) => c.id == player.clubId);
      if (parent == null) continue;
      final destination = clubs.firstWhereOrNull((c) => c.id != parent.id && c.overall >= player.overall - 12 && c.overall <= player.overall + 4 && c.financialHealth > 30);
      if (destination == null) continue;
      final id = '${parent.id}::${destination.id}::${player.id}';
      final n = active.putIfAbsent(id, () => LoanNegotiation(
        id: id,
        parentClubId: parent.id,
        destinationClubId: destination.id,
        playerId: player.id,
        loanFee: max(25000, (player.value * .03).round()),
        wageShare: .55,
        guaranteedMinutes: 900,
        buyoutClause: player.value * 1.8,
      ));
      n.round++;
      if (n.round >= 2 && _random.nextDouble() < .45) {
        if (destination.budget >= n.loanFee && destination.overall <= player.overall + 6) {
          destination.budget -= n.loanFee;
          parent.budget += n.loanFee;
          player.loanFromClubId = parent.id;
          player.clubId = destination.id;
          // Loan duration is absolute in the world clock.
          player.loanUntilDay = absoluteDay + 180;

          player.happiness = min(100, player.happiness + 8);
          n.stage = 'accepted';
          active.remove(id);
          logs.add('WYPOŻYCZENIE: ${player.name} → ${destination.name} (gwarantowane minuty: ${n.guaranteedMinutes})');
          continue;
        }
      }
      if (n.round >= 4) {
        n.stage = 'rejected';
        active.remove(id);
      } else {
        n.loanFee = (n.loanFee * 1.08).round();
        n.guaranteedMinutes = min(1600, n.guaranteedMinutes + 150);
        n.stage = 'counter';
      }
    }
    return logs;
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) { for (final x in this) { if (test(x)) return x; } return null; }
}
