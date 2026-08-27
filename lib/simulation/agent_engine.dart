import 'dart:math';
import '../models/agent.dart';
import '../models/player.dart';

/// Zarządza portfelami agentów i ich wpływem na rynek.
/// V18.6: agent nie tylko istnieje przy zawodniku — aktywnie steruje siłą
/// negocjacji, tempem zainteresowania i jakością potencjalnych ofert.
class AgentEngine {
  final Random _random;
  final List<Agent> agents = [];
  final Map<String, List<String>> clients = {};

  AgentEngine({Random? random}) : _random = random ?? Random();

  void ensureAgents(List<Player> players) {
    for (final player in players) {
      if (player.agentId != null) {
        _attach(player.agentId!, player.id);
        final existing = agentById(player.agentId!);
        if (existing != null) player.agentInfluence = existing.marketInfluence;
        continue;
      }
      final chance = player.overall >= 72 ? .85 : player.potential >= 82 ? .72 : .28;
      if (_random.nextDouble() > chance) continue;
      final agent = _createAgent(player);
      player.agentId = agent.id;
      player.agentInfluence = agent.marketInfluence;
      _attach(agent.id, player.id);
    }
  }

  /// V18.6: agent reaguje na rosnącą sławę klienta i jego sytuację sportową.
  /// Nie generuje transferu sam z siebie; buduje przewagę negocjacyjną.
  void processMarketInfluence(List<Player> players, int absoluteDay) {
    for (final player in players) {
      final id = player.agentId;
      if (id == null) continue;
      final agent = agentById(id);
      if (agent == null) continue;

      var target = agent.marketInfluence;
      if (player.fame >= 70) target += 4;
      if (player.reputation >= 75) target += 3;
      if (player.transferRequest) target += 2;
      if (player.consecutiveBenchDays >= 21) target += 3;
      if (player.form >= 80) target += 2;
      if (player.age <= 23 && player.potential >= 82) target += 2;

      if (target > agent.marketInfluence && _random.nextDouble() < .35) {
        agent.marketInfluence = min(95, agent.marketInfluence + 1);
      } else if (target < agent.marketInfluence && _random.nextDouble() < .12) {
        agent.marketInfluence = max(20, agent.marketInfluence - 1);
      }
      player.agentInfluence = agent.marketInfluence;

      if (absoluteDay % 14 == 0 && player.fame >= 60) {
        agent.reputation = min(95, agent.reputation + 1);
      }
    }
  }

  Agent _createAgent(Player player) {
    final index = agents.length + 1;
    final agent = Agent(
      id: 'agent_$index',
      name: '${_first[_random.nextInt(_first.length)]} ${_last[_random.nextInt(_last.length)]}',
      reputation: (45 + player.overall ~/ 3 + _random.nextInt(20)).clamp(30, 95).toInt(),
      negotiationSkill: (45 + player.potential ~/ 4 + _random.nextInt(20)).clamp(30, 95).toInt(),
      marketInfluence: (35 + player.overall ~/ 3 + _random.nextInt(25)).clamp(25, 95).toInt(),
      loyalty: (35 + _random.nextInt(60)).clamp(20, 95),
      wageDemand: 5 + _random.nextInt(20),
      aggressiveInNegotiations: _random.nextDouble() < .35,
    );
    agents.add(agent);
    clients[agent.id] = [];
    return agent;
  }

  Agent? agentById(String id) {
    for (final agent in agents) {
      if (agent.id == id) return agent;
    }
    return null;
  }

  void changeAgent(Player player, Agent newAgent) {
    if (player.agentId == newAgent.id) return;
    if (player.agentId != null) clients[player.agentId!]?.remove(player.id);
    player.agentId = newAgent.id;
    player.agentInfluence = newAgent.marketInfluence;
    _attach(newAgent.id, player.id);
  }

  Agent? findBestAlternative(Player player) {
    if (agents.isEmpty) return null;
    final candidates = agents.where((a) => a.id != player.agentId).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final ascore = a.reputation + a.negotiationSkill + a.marketInfluence + a.loyalty;
      final bscore = b.reputation + b.negotiationSkill + b.marketInfluence + b.loyalty;
      return bscore.compareTo(ascore);
    });
    return candidates.first;
  }

  void processClientGrowth(List<Player> players) {
    for (final agent in agents) {
      final clientIds = clients[agent.id] ?? const <String>[];
      final activeClients = players.where((p) => clientIds.contains(p.id)).length;
      if (activeClients >= 5) agent.marketInfluence = min(95, agent.marketInfluence + 1);
      if (activeClients == 0) agent.reputation = max(20, agent.reputation - 1);
    }
  }

  void _attach(String agentId, String playerId) {
    clients.putIfAbsent(agentId, () => <String>[]);
    if (!clients[agentId]!.contains(playerId)) clients[agentId]!.add(playerId);
  }

  Map<String, dynamic> toJson() => {
    'agents': agents.map((a) => {
      'id': a.id, 'name': a.name, 'reputation': a.reputation,
      'negotiationSkill': a.negotiationSkill, 'marketInfluence': a.marketInfluence,
      'loyalty': a.loyalty, 'wageDemand': a.wageDemand,
      'aggressiveInNegotiations': a.aggressiveInNegotiations,
    }).toList(),
    'clients': clients.map((k, v) => MapEntry(k, List<String>.from(v))),
  };

  void restoreFromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    agents.clear();
    clients.clear();
    final rawAgents = json['agents'];
    if (rawAgents is List) {
      for (final raw in rawAgents) {
        if (raw is! Map) continue;
        agents.add(Agent(
          id: raw['id'] ?? '', name: raw['name'] ?? 'Agent',
          reputation: raw['reputation'] ?? 50, negotiationSkill: raw['negotiationSkill'] ?? 50,
          marketInfluence: raw['marketInfluence'] ?? 50, loyalty: raw['loyalty'] ?? 50,
          wageDemand: raw['wageDemand'] ?? 10,
          aggressiveInNegotiations: raw['aggressiveInNegotiations'] ?? false,
        ));
      }
    }
    final rawClients = json['clients'];
    if (rawClients is Map) {
      for (final entry in rawClients.entries) {
        clients[entry.key.toString()] = entry.value is List
            ? entry.value.map((e) => e.toString()).toList()
            : <String>[];
      }
    }
  }

  static const _first = ['Marco', 'Luca', 'Adrian', 'Daniel', 'Michał', 'Thomas', 'Victor', 'Alex'];
  static const _last = ['Rossi', 'Silva', 'Kowalski', 'Weber', 'Costa', 'Müller', 'Nowak', 'Santos'];
}
