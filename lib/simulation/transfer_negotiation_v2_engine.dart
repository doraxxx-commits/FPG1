import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/transfer_negotiation.dart';
import '../models/transfer_interest.dart';
import 'agent_engine.dart';

/// V18.8 — Transfer Negotiation 2.0.
///
/// Transfer przestaje być pojedynczą transakcją. Najpierw klub kupujący
/// negocjuje z właścicielem karty zawodnika, a równolegle zawodnik i agent
/// oceniają pensję, rolę, bonus i klauzulę.
class TransferNegotiationV2Engine {
  final Random _random;
  final Map<String, TransferNegotiation> active = {};

  TransferNegotiationV2Engine({Random? random}) : _random = random ?? Random();

  /// V18.9 — decyzje zawodnika gracza. Nie kończą negocjacji natychmiast;
  /// ustawiają stanowisko, które klub/agent rozpatrzą przy kolejnym ticku świata.
  bool playerDecision(String negotiationId, String decision) {
    final n = active[negotiationId];
    if (n == null) return false;
    if (!{'accept', 'negotiate', 'reject'}.contains(decision)) return false;
    n.playerDecision = decision == 'accept' ? 'accepted' : decision == 'reject' ? 'rejected' : 'negotiating';
    if (decision == 'reject') {
      n.playerPatience = 0;
      n.stage = 'rejected';
    } else if (decision == 'negotiate') {
      n.offeredWage += max(250, (n.demandedWage - n.offeredWage) ~/ 2);
      n.offeredSigningBonus += max(250, (n.demandedSigningBonus - n.offeredSigningBonus) ~/ 2);
      n.offeredRoleScore = min(n.demandedRoleScore, n.offeredRoleScore + 8);
      n.stage = 'player_counter';
    } else {
      n.stage = 'player_accepted';
    }
    return true;
  }

  List<TransferNegotiation> activeForPlayer(String playerId) =>
      active.values.where((n) => n.playerId == playerId).toList();

  List<String> process({
    required List<Club> clubs,
    required List<Player> players,
    required Map<String, TransferInterest> interests,
    required bool transferWindow,
    required AgentEngine agentEngine,
  }) {
    if (!transferWindow) return [];
    final logs = <String>[];
    final serious = interests.values.where((i) =>
      i.stage == 'serious' || i.stage == 'offer' || i.stage == 'negotiation').toList();

    for (final interest in serious.take(max(1, clubs.length ~/ 8))) {
      final buyer = _findClub(clubs, interest.clubId);
      final player = _findPlayer(players, interest.playerId);
      final seller = player == null ? null : _findClub(clubs, player.clubId);
      if (buyer == null || seller == null || player == null || buyer.id == seller.id) continue;
      if (!interest.playerAware || interest.playerDecision == 'rejected') continue;

      final id = '${buyer.id}::${seller.id}::${player.id}';
      final agent = player.agentId == null ? null : agentEngine.agentById(player.agentId!);
      final n = active.putIfAbsent(id, () => _open(id, buyer, seller, player, interest, agent));
      interest.stage = 'negotiation';

      // Ręczne odrzucenie przez zawodnika natychmiast zamyka rozmowę.
      if (n.playerDecision == 'rejected') {
        interest.stage = 'rejected';
        n.stage = 'rejected';
        logs.add('ZAWODNIK ODRZUCIŁ OFERTĘ: ${player.name} — ${buyer.name}');
        active.remove(id);
        continue;
      }

      n.round++;

      final sellerGap = n.demandedFee - n.offeredFee;
      final wageGap = n.demandedWage - n.offeredWage;
      final roleGap = n.demandedRoleScore - n.offeredRoleScore;
      final affordable = buyer.budget >= n.demandedFee + n.demandedSigningBonus;
      final feeClose = sellerGap <= max(100000, (n.demandedFee * .07).round());
      final wageClose = wageGap <= max(500, (n.demandedWage * .07).round());
      final roleClose = roleGap <= 12;

      final playerApproved = n.playerDecision == 'accepted';
      final autoApproval = n.playerDecision == 'pending' && _random.nextDouble() < .20;
      if (affordable && feeClose && wageClose && roleClose && (playerApproved || autoApproval) && _random.nextDouble() < _acceptanceChance(buyer, seller, player, agent)) {
        final completed = _completeTransfer(buyer, seller, player, n);
        if (!completed) {
          n.stage = 'rejected';
          interest.stage = 'cooling';
          logs.add('TRANSFER ODRZUCONY FINANSOWO: ${player.name} — ${buyer.name}');
          active.remove(id);
          continue;
        }
        interest.stage = 'offer';
        n.stage = 'accepted';
        logs.add('TRANSFER UZGODNIONY: ${player.name} → ${buyer.name} (€${n.demandedFee})');
        active.remove(id);
        continue;
      }

      if (n.round >= 7 || n.buyerPatience <= 0 || n.sellerPatience <= 0 || n.playerPatience <= 0) {
        n.stage = 'rejected';
        interest.stage = 'cooling';
        logs.add('NEGOCJACJE TRANSFEROWE UPADŁY: ${player.name} — ${buyer.name}');
        active.remove(id);
        continue;
      }

      _counterOffer(n, buyer, seller, player, agent);
      n.patience--;
      logs.add(_counterLog(n, player, buyer, seller));
    }
    return logs;
  }

  TransferNegotiation _open(String id, Club buyer, Club seller, Player p,
      TransferInterest interest, dynamic agent) {
    final fee = max((p.value * (1.12 + seller.reputation / 600)).round(), 200000);
    final wageBase = max(p.weeklyWage.round(), 500);
    final famePremium = p.fame >= 70 ? .12 : p.fame >= 45 ? .06 : 0.0;
    final agentPremium = agent == null ? 0.0 : agent.wageDemand / 1200;
    final demandedWage = (wageBase * (1.10 + famePremium + agentPremium)).round();
    final desiredRole = p.fame >= 75 || p.overall >= buyer.overall + 2 ? 85 : p.overall >= buyer.minimumSigningOverall ? 65 : 45;
    final roleOffer = buyer.overall >= seller.overall + 4 ? 75 : 55;
    return TransferNegotiation(
      id: id,
      buyerClubId: buyer.id,
      sellerClubId: seller.id,
      playerId: p.id,
      offeredFee: max(150000, (fee * .84).round()),
      demandedFee: fee + (interest.offerQuality >= 80 ? (p.value * .06).round() : 0),
      offeredWage: max(wageBase, (wageBase * .96).round()),
      demandedWage: demandedWage,
      offeredYears: p.age >= 30 ? 2 : 3,
      demandedYears: p.age >= 30 ? 2 : 4,
      offeredSigningBonus: (wageBase * 2).round(),
      demandedSigningBonus: (demandedWage * 5).round(),
      offeredReleaseClause: p.value * 2.2,
      demandedReleaseClause: p.value * (2.4 + p.fame / 250),
      offeredRoleScore: roleOffer,
      demandedRoleScore: desiredRole,
    );
  }

  void _counterOffer(TransferNegotiation n, Club buyer, Club seller, Player p, dynamic agent) {
    final feeGap = n.demandedFee - n.offeredFee;
    n.offeredFee += max(50000, (feeGap / 3).round());
    n.demandedFee -= max(25000, (feeGap / 5).round());

    final wageGap = n.demandedWage - n.offeredWage;
    n.offeredWage += max(250, (wageGap / 3).round());
    n.demandedWage -= max(100, (wageGap / 6).round());

    final bonusGap = n.demandedSigningBonus - n.offeredSigningBonus;
    n.offeredSigningBonus += max(100, (bonusGap / 3).round());

    n.offeredRoleScore = min(n.demandedRoleScore, n.offeredRoleScore + 6);
    if (n.demandedYears > n.offeredYears && p.age < 31) n.offeredYears++;

    if (agent?.aggressiveInNegotiations == true) {
      n.demandedWage += max(100, (n.demandedWage * .015).round());
      n.playerPatience--;
    }

    if (buyer.financialHealth < 35) n.buyerPatience--;
    if (seller.financialHealth < 35) n.sellerPatience--;
    if (p.transferRequest) n.sellerPatience = max(1, n.sellerPatience - 1);

    n.stage = n.demandedFee > n.offeredFee ? 'seller_counter' : 'player_counter';
  }

  String _counterLog(TransferNegotiation n, Player p, Club buyer, Club seller) {
    if (n.stage == 'seller_counter') {
      return 'KONTROFERTA KLUBU: ${seller.name} ↔ ${buyer.name} za ${p.name} (€${n.demandedFee})';
    }
    return 'KONTROFERTA ZAWODNIKA: ${p.name} żąda €${n.demandedWage}/tydz. od ${buyer.name}';
  }

  double _acceptanceChance(Club buyer, Club seller, Player p, dynamic agent) {
    var chance = .62;
    if (p.transferRequest) chance += .12;
    if (p.squadStatus == 'outOfSquad') chance += .10;
    if (seller.financialHealth < 35) chance += .10;
    if (buyer.reputation > seller.reputation) chance += .05;
    if (agent?.negotiationSkill != null) chance += agent.negotiationSkill / 1000;
    return chance.clamp(.25, .92);
  }

  bool _completeTransfer(Club buyer, Club seller, Player p, TransferNegotiation n) {
    final totalFee = n.demandedFee + n.demandedSigningBonus;
    final annualWageCost = max(1, n.demandedWage) * 52;
    final reserve = max(250000, (buyer.budget * 0.20).round());
    if (buyer.budget - totalFee - annualWageCost < reserve) return false;

    buyer.budget -= totalFee;
    seller.budget += n.demandedFee;
    p.clubId = buyer.id;
    p.contractYearsRemaining = n.demandedYears;
    p.weeklyWage = n.demandedWage.toDouble();
    p.wageExpectation = n.demandedWage;
    p.releaseClause = n.demandedReleaseClause;
    p.contractRole = n.demandedRoleScore >= 80 ? 'important' : n.demandedRoleScore >= 60 ? 'rotation' : 'squad';
    p.appearanceBonus = max(p.appearanceBonus, (n.demandedWage * .15).round());
    p.goalBonus = max(p.goalBonus, (n.demandedWage * .30).round());
    p.happiness = min(100, p.happiness + 10);
    p.transferRequest = false;
    p.consecutiveBenchDays = 0;
    p.squadStatus = 'reserves';
    return true;
  }

  Club? _findClub(List<Club> clubs, String? id) => id == null ? null : clubs.where((c) => c.id == id).firstOrNull;
  Player? _findPlayer(List<Player> players, String id) => players.where((p) => p.id == id).firstOrNull;

  Map<String, dynamic> toJson() => {'active': active.map((k, v) => MapEntry(k, v.toJson()))};

  void restoreFromJson(Map<String, dynamic>? json) {
    active.clear();
    if (json == null || json['active'] is! Map) return;
    for (final entry in (json['active'] as Map).entries) {
      if (entry.value is Map) {
        final n = TransferNegotiation.fromJson(Map<String, dynamic>.from(entry.value));
        if (n.id.isNotEmpty) active[entry.key.toString()] = n;
      }
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
