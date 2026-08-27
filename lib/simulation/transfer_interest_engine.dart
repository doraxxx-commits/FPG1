import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';
import '../models/transfer_interest.dart';
import 'agent_engine.dart';

/// Buduje pamięć zainteresowania klubów zawodnikami.
/// V18.6: fame/reputation/marketing i agent wpływają na jakość zainteresowania,
/// etap oraz potencjalną jakość oferty.
class TransferInterestEngine {
  final Random _random;
  final Map<String, TransferInterest> interests = {};

  TransferInterestEngine({Random? random}) : _random = random ?? Random();

  void processDay({
    required List<Club> clubs,
    required List<Player> players,
    required int absoluteDay,
    AgentEngine? agentEngine,
  }) {
    final candidates = players.where((p) => p.clubId != null && !p.injured).toList();
    for (final buyer in clubs) {
      final pool = candidates.where((p) => p.clubId != buyer.id && _fits(buyer, p)).toList();
      pool.sort((a, b) => _score(buyer, b, agentEngine).compareTo(_score(buyer, a, agentEngine)));
      for (final player in pool.take(2)) {
        final score = _score(buyer, player, agentEngine);
        if (score < 62 || _random.nextDouble() > .035) continue;
        final id = '${buyer.id}::${player.id}';
        final agent = player.agentId == null || agentEngine == null ? null : agentEngine.agentById(player.agentId!);
        final fit = _clubFit(buyer, player);
        final offerQuality = _offerQuality(buyer, player, agent, score);
        final agentBoost = agent == null ? 0 : ((agent.marketInfluence * .12) + (agent.reputation * .06)).round();
        final interest = interests.putIfAbsent(id, () => TransferInterest(
          id: id, clubId: buyer.id, playerId: player.id, score: score.round(), lastContactDay: absoluteDay,
        ));
        interest.clubFit = fit;
        interest.agentInfluence = agent?.marketInfluence ?? 0;
        interest.agentBacked = agent != null && agent.marketInfluence >= 60 && player.fame >= 55;
        interest.offerQuality = offerQuality;
        interest.score = max(1, min(100, ((interest.score * .72) + (score * .18) + agentBoost * .10).round()));
        interest.daysActive++;
        interest.lastContactDay = absoluteDay;
        if (interest.score >= 82) {
          interest.stage = 'serious';
        } else if (interest.score >= 74 && interest.daysActive >= 3) {
          interest.stage = 'serious';
        }
      }
    }
    interests.removeWhere((_, i) => absoluteDay - i.lastContactDay > 120);
  }

  bool _fits(Club c, Player p) => p.overall >= c.minimumSigningOverall - 10 &&
      p.age >= c.preferredMinAge - 3 && p.age <= c.preferredMaxAge + 4;

  double _score(Club c, Player p, AgentEngine? agentEngine) {
    final age = ((c.preferredMinAge + c.preferredMaxAge) / 2 - p.age).abs();
    final potential = max(0, p.potential - p.overall) * c.youthFocus / 100;
    final youthBonus = p.age <= 21 ? c.youthFocus * .10 : 0;
    final personalityFit = (p.personality.ambition + p.personality.adaptability) * .04;
    final minutes = p.consecutiveBenchDays >= 14 ? 8 : 0;
    final role = p.squadStatus == 'outOfSquad' ? 10 : p.squadStatus == 'reserves' ? 5 : 0;
    final fameBonus = p.fame * .18;
    final reputationBonus = (p.reputation - 50) * .11;
    final marketBonus = p.marketability * .08;
    final agent = p.agentId == null || agentEngine == null ? null : agentEngine.agentById(p.agentId!);
    final agentBonus = agent == null ? 0 : agent.marketInfluence * .10 + agent.reputation * .04;
    final demandBonus = p.transferRequest ? 4 : 0;
    return p.overall * 1.45 + potential * 1.4 + p.form * .18 + minutes + role + youthBonus + personalityFit +
        fameBonus + reputationBonus + marketBonus + agentBonus + demandBonus - age * 2;
  }

  int _clubFit(Club c, Player p) {
    var fit = 50;
    fit += ((c.overall - p.overall) / 2).round();
    if (p.age >= c.preferredMinAge && p.age <= c.preferredMaxAge) fit += 15;
    if (p.age <= 23) fit += (c.youthFocus / 5).round();
    if (p.fame >= 65 && c.reputation >= 65) fit += 8;
    return fit.clamp(0, 100);
  }

  int _offerQuality(Club buyer, Player p, dynamic agent, double score) {
    var quality = score * .65 + buyer.reputation * .15 + p.marketability * .10;
    if (agent != null) quality += agent.negotiationSkill * .06 + agent.marketInfluence * .04;
    return quality.round().clamp(1, 100);
  }

  /// Player-initiated transfer request. Creates a small, visible shortlist
  /// of realistic buyers instead of waiting for a random AI approach.
  List<TransferInterest> requestTransfer({
    required List<Club> clubs,
    required dynamic player,
    required int absoluteDay,
    AgentEngine? agentEngine,
  }) {
    if (player.clubId == null || player.injured) return const [];
    final buyers = clubs.where((c) => c.id != player.clubId && _fits(c, player)).toList();
    buyers.sort((a, b) => _score(b, player, agentEngine).compareTo(_score(a, player, agentEngine)));
    player.transferRequest = true;
    final created = <TransferInterest>[];
    for (final buyer in buyers.take(3)) {
      final score = max(70, min(100, _score(buyer, player, agentEngine).round() + 12));
      final id = '${buyer.id}::${player.id}';
      final existing = interests[id];
      final interest = existing ?? TransferInterest(
        id: id, clubId: buyer.id, playerId: player.id, score: score,
        lastContactDay: absoluteDay,
      );
      interest.score = score;
      interest.stage = 'serious';
      interest.playerAware = true;
      interest.awarenessDay = absoluteDay;
      interest.playerDecision = 'wants_transfer';
      interest.clubFit = _clubFit(buyer, player);
      interest.offerQuality = _offerQuality(buyer, player,
          player.agentId == null || agentEngine == null ? null : agentEngine.agentById(player.agentId!), score.toDouble());
      interest.lastContactDay = absoluteDay;
      interests[id] = interest;
      created.add(interest);
    }
    return created;
  }

  Map<String, dynamic> toJson() => {
    'interests': interests.map((k, v) => MapEntry(k, v.toJson())),
  };

  void restoreFromJson(Map<String, dynamic>? json) {
    interests.clear();
    if (json == null || json['interests'] is! Map) return;
    final raw = json['interests'] as Map;
    for (final entry in raw.entries) {
      if (entry.value is Map) {
        final interest = TransferInterest.fromJson(Map<String, dynamic>.from(entry.value));
        if (interest.id.isNotEmpty) interests[entry.key.toString()] = interest;
      }
    }
  }
}
