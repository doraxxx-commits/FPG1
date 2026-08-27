import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';
import '../models/negotiation.dart';
import 'transfer_interest_engine.dart';
import 'agent_engine.dart';

/// Wieloetapowe negocjacje. Każda próba zmienia stan rynku zamiast natychmiast
/// wykonywać transfer.
class NegotiationEngine {
  final Random _random;
  final Map<String, Negotiation> active = {};
  NegotiationEngine({Random? random}) : _random = random ?? Random();

  List<String> process({
    required List<Club> clubs,
    required List<Player> players,
    required TransferInterestEngine interestEngine,
    required bool transferWindow,
    required AgentEngine agentEngine,
  }) {
    if (!transferWindow) return [];
    final logs = <String>[];
    final entries = interestEngine.interests.values.where((i) => i.stage == 'serious').toList();
    for (final interest in entries.take(max(1, clubs.length ~/ 10))) {
      final buyer = clubs.firstWhereOrNull((c) => c.id == interest.clubId);
      final player = players.firstWhereOrNull((p) => p.id == interest.playerId);
      final seller = player == null ? null : clubs.firstWhereOrNull((c) => c.id == player.clubId);
      if (buyer == null || seller == null || player == null) continue;
      final id = '${buyer.id}::${seller.id}::${player.id}';
      // Transfer może być negocjowany dopiero, gdy zawodnik jest świadomy
      // zainteresowania i nie odrzucił go.
      if (!interest.playerAware || interest.playerDecision == 'rejected') continue;
      final agent = player.agentId == null ? null : agentEngine.agentById(player.agentId!);
      final n = active.putIfAbsent(id, () {
        final demanded = max((player.value * (1.15 + seller.reputation / 500)).round(), 200000);
        return Negotiation(
          id: id, buyerClubId: buyer.id, sellerClubId: seller.id, playerId: player.id,
          offeredFee: max(100000, (player.value * .85).round()),
          demandedFee: demanded + (interest.offerQuality >= 80 ? (player.value * .05).round() : 0),
          offeredWage: player.weeklyWage.round(),

          demandedWage: (player.weeklyWage * (1.12 + (agent?.wageDemand ?? 10) / 1000)).round(),
        );
      });
      n.round++;
      // V18.6: agent quality modifies the seller's patience and wage target.
      if (agent != null && interest.offerQuality >= 75) {
        n.demandedWage = max(n.demandedWage, (player.weeklyWage * 1.05).round());
      }
      final gap = n.demandedFee - n.offeredFee;
      final wageGap = n.demandedWage - n.offeredWage;
      final wageAccepted = wageGap <= max(1000, (n.demandedWage * .08).round());
      if (gap <= max(100000, (n.demandedFee * .08).round()) && buyer.budget >= n.demandedFee && wageAccepted) {
        if (_random.nextDouble() < .72) {
          buyer.budget -= n.demandedFee;
          seller.budget += n.demandedFee;
          player.clubId = buyer.id;
          player.contractYearsRemaining = 3;
          player.releaseClause = player.value * 2.5;
          n.stage = 'accepted';
          interest.stage = 'offer';
          logs.add('NEGOCJACJA ZAKOŃCZONA: ${player.name} → ${buyer.name}');
          active.remove(id);
          continue;
        }
      }
      if (n.round >= 5 || n.patience <= 0) {
        n.stage = 'rejected';
        interest.stage = 'cooling';
        active.remove(id);
        continue;
      }
      // Kontroferta: sprzedający schodzi powoli, kupujący podnosi propozycję.
      n.offeredFee += max(50000, gap ~/ 3);
      n.demandedFee -= max(25000, gap ~/ 5);
      n.offeredWage += max(500, (n.demandedWage - n.offeredWage) ~/ 3);
      if (agent?.aggressiveInNegotiations == true) n.demandedFee += max(10000, gap ~/ 20);
      n.patience--;
      n.stage = 'counter';
      logs.add('KONTROFERTA: ${seller.name} ↔ ${buyer.name} za ${player.name}');
    }
    return logs;
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) { for (final x in this) { if (test(x)) return x; } return null; }
}
