import 'dart:math';
import '../models/player.dart';
import '../models/player_relationships.dart';
import '../models/world_event.dart';

/// V19.4 — Relationship Web.
/// Keeps five persistent relationships around every world player and lets
/// career decisions alter them instead of only changing isolated stats.
class RelationshipWebEngine {
  final Random _random;
  final Map<String, PlayerRelationships> _relations = {};

  RelationshipWebEngine({Random? random}) : _random = random ?? Random();

  PlayerRelationships forPlayer(Player p) {
    return _relations.putIfAbsent(p.id, () => PlayerRelationships(
      playerId: p.id,
      agent: p.agentInfluence.clamp(0, 100).toInt(),
      coach: p.managerRelationship.clamp(0, 100),
      club: ((p.managerRelationship + p.happiness) / 2).round().clamp(0, 100),
      fans: p.fanSupport.clamp(0, 100),
      media: (50 + p.mediaPressure ~/ 3).clamp(0, 100),
    ));
  }

  List<WorldEvent> processDay({
    required List<Player> players,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    final events = <WorldEvent>[];
    for (final p in players) {
      final r = forPlayer(p);
      if (r.lastUpdatedAbsoluteDay == absoluteDay) continue;
      r.lastUpdatedAbsoluteDay = absoluteDay;

      // Slow natural drift: relationships move toward the current football reality.
      final coachTarget = (p.managerRelationship + (p.form - 50) ~/ 4).clamp(0, 100).toInt();
      final clubTarget = ((p.happiness + p.managerRelationship) / 2).round().clamp(0, 100).toInt();
      final fanTarget = p.fanSupport.clamp(0, 100).toInt();
      final mediaTarget = (50 + p.mediaPressure ~/ 2).clamp(0, 100).toInt();
      _nudge(r, 'coach', coachTarget);
      _nudge(r, 'club', clubTarget);
      _nudge(r, 'fans', fanTarget);
      _nudge(r, 'media', mediaTarget);
      _nudge(r, 'agent', p.agentInfluence.clamp(0, 100).toInt());

      // Relationship thresholds create consequences, but are intentionally rare.
      if (r.coach <= 20 && p.consecutiveBenchDays >= 7 && _random.nextInt(100) < 18) {
        events.add(_event(year, month, day, 'relationship_coach_crisis', p,
          'Relacja z trenerem jest na granicy', '${p.name} od dawna nie może przebić się do składu. Narasta napięcie między zawodnikiem a trenerem.', 4));
      }
      if (r.club <= 20 && p.contractYearsRemaining <= 1 && _random.nextInt(100) < 16) {
        events.add(_event(year, month, day, 'relationship_club_crisis', p,
          'Relacja z klubem gwałtownie się pogarsza', 'Rozmowy o przyszłości ${p.name} stają się coraz trudniejsze.', 4));
      }
      if (r.media >= 85 && p.mediaPressure >= 80 && _random.nextInt(100) < 12) {
        events.add(_event(year, month, day, 'relationship_media_boom', p,
          'Media coraz mocniej interesują się zawodnikiem', '${p.name} stał się ważną postacią medialną. Każda kolejna decyzja może mieć większy rezonans.', 3));
      }
    }
    return events;
  }

  /// Applies a career decision to the relationship graph.
  List<WorldEvent> applyDecision({
    required Player p,
    required String decision,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    final r = forPlayer(p);
    final deltas = <String, int>{};
    switch (decision) {
      case 'talk_club': deltas.addAll({'club': 8, 'coach': 3}); break;
      case 'back_agent': deltas.addAll({'agent': 8, 'club': -8, 'media': 4}); break;
      case 'stay_silent': deltas.addAll({'club': 2, 'media': -4}); break;
      case 'demand_role': deltas.addAll({'coach': -7, 'club': -3, 'agent': 4}); break;
      case 'accept_compromise': deltas.addAll({'club': 10, 'coach': 5, 'agent': -3}); break;
      case 'request_transfer': deltas.addAll({'club': -14, 'agent': 10, 'fans': -4, 'media': 8}); break;
      case 'ultimatum': deltas.addAll({'club': -15, 'agent': 8, 'media': 10}); break;
      case 'reconcile': deltas.addAll({'club': 14, 'coach': 7, 'fans': 5, 'agent': -3}); break;
      case 'welcome_interest': deltas.addAll({'agent': 7, 'media': 4}); break;
      case 'public_statement': deltas.addAll({'media': 12, 'fans': -5, 'club': -10, 'agent': 8}); break;
      case 'commit_club': deltas.addAll({'club': 10, 'fans': 7, 'media': -4, 'agent': -4}); break;
      case 'meet_interested_club': deltas.addAll({'agent': 8, 'club': -4, 'media': 5}); break;
      case 'slow_down': deltas.addAll({'club': 3, 'media': -6}); break;
      case 'force_exit': deltas.addAll({'club': -18, 'agent': 12, 'fans': -8, 'media': 12}); break;
      case 'accept_move': deltas.addAll({'agent': 6, 'club': -2, 'media': 5}); break;
      case 'use_fame': deltas.addAll({'media': 8, 'fans': 6, 'agent': 3}); break;
      case 'limit_media': deltas.addAll({'media': -12, 'fans': -2}); break;
      case 'answer_critics': deltas.addAll({'media': 8, 'fans': 3}); break;
      case 'answer_on_pitch': deltas.addAll({'coach': 5, 'fans': 8, 'media': 5}); break;
      case 'protect_privacy': deltas.addAll({'media': -10, 'fans': 1}); break;
      default: break;
    }
    final events = <WorldEvent>[];
    deltas.forEach((target, delta) {
      _change(r, target, delta, absoluteDay, 'Decyzja: $decision');
    });
    if (deltas.isNotEmpty) {
      events.add(_event(year, month, day, 'relationship_change', p,
        'Relacje reagują na decyzję', '${p.name}: decyzja „$decision” zmieniła jego relacje z otoczeniem.', 3));
    }
    return events;
  }

  Map<String, dynamic> toJson() => {
    'relations': {for (final e in _relations.entries) e.key: e.value.toJson()},
  };

  void restoreFromJson(Map<String, dynamic>? json) {
    _relations.clear();
    final raw = json?['relations'];
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is Map) _relations[e.key.toString()] = PlayerRelationships.fromJson(Map<String, dynamic>.from(e.value));
      }
    }
  }

  void _nudge(PlayerRelationships r, String target, int desired) {
    final current = _get(r, target);
    if (current == desired) return;
    _set(r, target, current + (desired - current).sign);
  }

  void _change(PlayerRelationships r, String target, int delta, int day, String reason) {
    _set(r, target, _get(r, target) + delta);
    r.history.add(RelationshipLog(absoluteDay: day, target: target, delta: delta, reason: reason));
    if (r.history.length > 80) r.history.removeRange(0, r.history.length - 80);
  }

  int _get(PlayerRelationships r, String t) {
    switch (t) {
      case 'agent': return r.agent;
      case 'coach': return r.coach;
      case 'club': return r.club;
      case 'fans': return r.fans;
      default: return r.media;
    }
  }
  void _set(PlayerRelationships r, String t, int v) {
    final x = v.clamp(0, 100).toInt();
    switch (t) { case 'agent': r.agent = x; break; case 'coach': r.coach = x; break; case 'club': r.club = x; break; case 'fans': r.fans = x; break; default: r.media = x; }
  }

  WorldEvent _event(int y,int m,int d,String type,Player p,String title,String desc,int importance) => WorldEvent(year:y,month:m,day:d,type:type,title:title,description:desc,playerId:p.id,clubId:p.clubId,importance:importance);
}
