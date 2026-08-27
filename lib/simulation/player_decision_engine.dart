import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';
import '../models/transfer_interest.dart';
import 'agent_engine.dart';
import '../models/agent.dart';


/// Podejmuje autonomiczne decyzje zawodników wobec zainteresowania transferowego.
/// Zawodnik nie jest biernym obiektem rynku: ocenia minuty, rolę, pensję,
/// reputację klubu i wpływ agenta.
class PlayerDecisionEngine {
  final Random _random;
  PlayerDecisionEngine({Random? random}) : _random = random ?? Random();

  List<String> processDay({
    required List<Club> clubs,
    required List<Player> players,
    required Map<String, TransferInterest> interests,
    required AgentEngine agentEngine,
    required int absoluteDay,
  }) {
    final logs = <String>[];
    for (final interest in interests.values) {
      if (interest.stage != 'serious' && interest.stage != 'offer' && interest.stage != 'negotiation') continue;
      final player = players.where((p) => p.id == interest.playerId).firstOrNull;
      final buyer = clubs.where((c) => c.id == interest.clubId).firstOrNull;
      if (player == null || buyer == null || player.clubId == buyer.id) continue;
      final seller = clubs.where((c) => c.id == player.clubId).firstOrNull;
      if (seller == null) continue;

      final agent = player.agentId == null ? null : agentEngine.agentById(player.agentId!);
      final score = _decisionScore(player, buyer, agent);
      if (!interest.playerAware) {
        // Zawodnik potrzebuje czasu, aby dowiedzieć się o zainteresowaniu.
        final awarenessChance = (0.18 + interest.score / 250 + (agent?.marketInfluence ?? 0) / 500).clamp(.15, .65);
        if (_random.nextDouble() > awarenessChance) continue;
        interest.playerAware = true;
        interest.awarenessDay = absoluteDay;
        logs.add('INFORMACJA DLA ZAWODNIKA: ${player.name} dowiedział się o zainteresowaniu ${buyer.name}.');
      }

      if (interest.playerDecision == 'pending') {
        if (score >= 70 && _random.nextDouble() < .12) {
          interest.playerDecision = 'wants_transfer';
          player.transferRequest = true;
          player.morale = max(20, player.morale - 2);
          logs.add('ŻĄDANIE TRANSFERU: ${player.name} chce rozważyć przejście do ${buyer.name}.');
        } else if (score <= 35 && _random.nextDouble() < .10) {
          interest.playerDecision = 'rejected';
          interest.stage = 'cooling';
          logs.add('ODRZUCONA OFERTA: ${player.name} nie jest zainteresowany ${buyer.name}.');
        }
      }

      // Agent może przyspieszyć eskalację, jeśli zawodnik jest niedoceniany.
      if (agent != null && player.consecutiveBenchDays >= 21 && agent.negotiationSkill >= 70 && interest.score >= 70) {
        player.transferRequest = true;
        interest.playerDecision = 'wants_transfer';
      }
    }
    return logs;
  }

  double _decisionScore(Player p, Club buyer, Agent? agent) {
    var score = 45.0;
    score += (buyer.reputation - 50) * .18;
    // V11.1C: młody zawodnik ocenia ofertę także przez własne preferencje.
    score += (buyer.overall - p.preferences.preferredClubLevel) * .10;
    score += p.preferences.foreignMoveWillingness * .06;
    score += p.preferences.minutesExpectation * .08;
    score += p.preferences.wagePriority * .05;
    score += (buyer.overall - p.overall) * 1.5;
    score += p.transferRequest ? 12 : 0;
    score += p.consecutiveBenchDays >= 14 ? 15 : 0;
    score += p.squadStatus == 'outOfSquad' ? 12 : 0;
    score += buyer.preferredMinAge <= p.age && p.age <= buyer.preferredMaxAge ? 5 : -3;
    score += (agent?.loyalty ?? 50) * .08;
    score += p.personality.ambition * .05;
    score += p.personality.loyalty * .03;
    score += p.personality.adaptability * .02;
    score -= p.morale < 40 ? 5 : 0;
    return score.clamp(0, 100);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
