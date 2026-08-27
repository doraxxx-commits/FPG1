import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';
import 'agent_engine.dart';
import 'transfer_interest_engine.dart';
import 'negotiation_engine.dart';
import 'transfer_negotiation_v2_engine.dart';
import 'dressing_room_engine.dart';
import 'national_team_engine.dart';
import 'reputation_engine.dart';
import 'rivalry_engine.dart';
import 'player_decision_engine.dart';
import 'loan_negotiation_engine.dart';
import 'contract_negotiation_engine.dart';
import 'board_engine.dart';

/// Warstwa World Simulation 4.0. Nie zastępuje istniejących silników —
/// łączy nowe mechanizmy społeczne i pokoleniowe z obecnym światem.
class WorldSimulation4Engine {
  final Random _random;
  late final ReputationEngine reputationEngine;
  late final RivalryEngine rivalryEngine;
  late final AgentEngine agentEngine;
  late final TransferInterestEngine transferInterestEngine;
  late final NegotiationEngine negotiationEngine;
  late final TransferNegotiationV2Engine transferNegotiationV2Engine;
  late final DressingRoomEngine dressingRoomEngine;
  late final NationalTeamEngine nationalTeamEngine;
  late final PlayerDecisionEngine playerDecisionEngine;
  late final LoanNegotiationEngine loanNegotiationEngine;
  late final ContractNegotiationEngine contractNegotiationEngine;
  late final BoardEngine boardEngine;
  final List<WorldEvent> recentEvents = [];
  final Map<String, String> _announcedInterestStages = {};

  WorldSimulation4Engine({Random? random}) : _random = random ?? Random() {
    reputationEngine = ReputationEngine();
    rivalryEngine = RivalryEngine(random: _random);
    agentEngine = AgentEngine(random: _random);
    transferInterestEngine = TransferInterestEngine(random: _random);
    negotiationEngine = NegotiationEngine(random: _random);
    transferNegotiationV2Engine = TransferNegotiationV2Engine(random: _random);
    dressingRoomEngine = DressingRoomEngine(random: _random);
    nationalTeamEngine = NationalTeamEngine(random: _random);
    playerDecisionEngine = PlayerDecisionEngine(random: _random);
    loanNegotiationEngine = LoanNegotiationEngine(random: _random);
    contractNegotiationEngine = ContractNegotiationEngine(random: _random);
    boardEngine = BoardEngine(random: _random);
  }

  WorldEvent worldEventForPlayer({required String type, required String title, required String description, required String playerId, int importance = 1}) => WorldEvent(
    year: 0, month: 0, day: 0, type: type, title: title, description: description, playerId: playerId, importance: importance,
  );

  List<String> processDay({required List<Club> clubs, required List<Player> players, int absoluteDay = 0, int year = 0, int month = 0, int day = 0, bool transferWindow = false}) {
    agentEngine.ensureAgents(players);
    agentEngine.processClientGrowth(players);
    agentEngine.processMarketInfluence(players, absoluteDay);
    nationalTeamEngine.ensureTeams(clubs);
    reputationEngine.processDay(clubs: clubs, players: players);
    final logs = <String>[];
    logs.addAll(boardEngine.processDay(clubs: clubs, players: players));
    transferInterestEngine.processDay(
      clubs: clubs, players: players, absoluteDay: absoluteDay, agentEngine: agentEngine,
    );

    // V11.1C: zainteresowanie dużego klubu staje się częścią historii świata,
    // ale tylko przy awansie etapu, żeby nie spamować newsów każdego dnia.
    for (final interest in transferInterestEngine.interests.values) {
      if (interest.stage != 'serious' && interest.stage != 'offer' && interest.stage != 'negotiation') continue;
      final key = interest.id;
      final previous = _announcedInterestStages[key];
      if (previous == interest.stage) continue;
      _announcedInterestStages[key] = interest.stage;
      final player = players.where((p) => p.id == interest.playerId).firstOrNull;
      final buyer = clubs.where((c) => c.id == interest.clubId).firstOrNull;
      if (player == null || buyer == null) continue;
      recentEvents.add(WorldEvent(
        year: year,
        month: month,
        day: day,
        type: 'transfer_interest',
        title: 'Rośnie zainteresowanie młodym zawodnikiem',
        description: '${buyer.name} coraz poważniej obserwuje ${player.name}. Etap: ${interest.stage}.',
        clubId: buyer.id,
        playerId: player.id,
        importance: interest.stage == 'negotiation' ? 4 : 3,
      ));
    }

    logs.addAll(playerDecisionEngine.processDay(
      clubs: clubs,
      players: players,
      interests: transferInterestEngine.interests,
      agentEngine: agentEngine,
      absoluteDay: absoluteDay,
    ));
    logs.addAll(dressingRoomEngine.processDay(clubs: clubs, players: players));
    logs.addAll(loanNegotiationEngine.process(
      clubs: clubs, players: players, transferWindow: transferWindow, absoluteDay: absoluteDay,
    ));
    // V18.8 zastępuje stare negocjacje jednym spójnym procesem:
    // kupujący ↔ sprzedający ↔ zawodnik/agent.
    logs.addAll(transferNegotiationV2Engine.process(
      clubs: clubs,
      players: players,
      interests: transferInterestEngine.interests,
      transferWindow: transferWindow,
      agentEngine: agentEngine,
    ));
    logs.addAll(contractNegotiationEngine.process(
      clubs: clubs,
      players: players,
      agentEngine: agentEngine,
    ));
    for (final log in logs) {
      recentEvents.add(WorldEvent(
        year: year, month: month, day: day, type: log.startsWith('NAPIĘCIE') ? 'dressing_room' : 'transfer_negotiation',
        title: log.split(':').first, description: log, importance: 2,
      ));
    }
    if (recentEvents.length > 300) recentEvents.removeRange(0, recentEvents.length - 300);
    return logs;
  }

  Map<String, dynamic> toJson() => {
    'agents': agentEngine.toJson(),
    'transferInterest': transferInterestEngine.toJson(),
    'announcedInterestStages': Map<String, String>.from(_announcedInterestStages),
    'transferNegotiationV2': transferNegotiationV2Engine.toJson(),
  };

  void restoreFromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    agentEngine.restoreFromJson(
      json['agents'] is Map ? Map<String, dynamic>.from(json['agents']) : null,
    );
    transferInterestEngine.restoreFromJson(
      json['transferInterest'] is Map ? Map<String, dynamic>.from(json['transferInterest']) : null,
    );
    transferNegotiationV2Engine.restoreFromJson(
      json['transferNegotiationV2'] is Map ? Map<String, dynamic>.from(json['transferNegotiationV2']) : null,
    );
    _announcedInterestStages.clear();
    final rawStages = json['announcedInterestStages'];
    if (rawStages is Map) {
      for (final entry in rawStages.entries) {
        _announcedInterestStages[entry.key.toString()] = entry.value.toString();
      }
    }
  }

  List<Player> processSeason({
    required List<Club> clubs,
    required List<Player> players,
    required int seasonYear,
  }) {
    rivalryEngine.processSeason(clubs);
    agentEngine.ensureAgents(players);
    nationalTeamEngine.processSeason(clubs: clubs, players: players, seasonYear: seasonYear);
    reputationEngine.processDay(clubs: clubs, players: players);
    return const [];
  }
}
