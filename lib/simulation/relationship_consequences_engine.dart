import 'dart:math';
import '../models/player.dart';
import '../models/world_event.dart';
import 'relationship_web_engine.dart';

/// V19.5 — Relationship Consequences.
/// Turns relationship levels into concrete career opportunities, protections,
/// conflicts and escalation. Cooldowns prevent spam and are persisted.
class RelationshipConsequencesEngine {
  final Random _random;
  final Map<String, Map<String, int>> _lastTriggered = {};

  RelationshipConsequencesEngine({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processDay({
    required List<Player> players,
    required RelationshipWebEngine relationshipWeb,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    final events = <WorldEvent>[];
    for (final p in players) {
      final r = relationshipWeb.forPlayer(p);

      // Strong coach relationship + good form can unlock a bigger role.
      if (r.coach >= 82 && p.form >= 72 && p.consecutiveBenchDays == 0 &&
          _trigger(p.id, 'coach_support', absoluteDay, 14, 28)) {
        p.managerRelationship = (p.managerRelationship + 5).clamp(0, 100).toInt();
        p.happiness = (p.happiness + 4).clamp(0, 100).toInt();
        events.add(_event(year, month, day, 'relationship_coach_support', p,
          'Trener daje zawodnikowi większą rolę',
          'Dobra relacja z trenerem i wysoka forma otworzyły nowe możliwości w zespole ${p.clubId}.', 4));
      }

      // Bad coach relationship + prolonged benching creates a concrete conflict.
      if (r.coach <= 24 && p.consecutiveBenchDays >= 7 &&
          _trigger(p.id, 'coach_conflict', absoluteDay, 10, 24)) {
        p.happiness = (p.happiness - 6).clamp(0, 100).toInt();
        p.managerRelationship = (p.managerRelationship - 6).clamp(0, 100).toInt();
        events.add(_event(year, month, day, 'relationship_coach_conflict', p,
          'Trener i zawodnik coraz dalej od porozumienia',
          '${p.name} zaczyna domagać się wyjaśnień w sprawie swojej roli w zespole.', 4));
      }

      // Strong agent + transfer pull unlocks active representation.
      if (r.agent >= 80 && p.transferPull >= 55 &&
          _trigger(p.id, 'agent_market_push', absoluteDay, 21, 30)) {
        p.fame = (p.fame + 2).clamp(0, 100).toInt();
        p.transferPull = (p.transferPull + 4).clamp(0, 100).toInt();
        events.add(_event(year, month, day, 'relationship_agent_push', p,
          'Agent zaczyna aktywnie pracować nad przyszłością zawodnika',
          'Agent ${p.name} wykorzystuje rosnące zainteresowanie rynku, aby otworzyć nowe możliwości.', 3));
      }

      // Very strong club relationship can protect a player during a bad spell.
      if (r.club >= 82 && p.form <= 42 &&
          _trigger(p.id, 'club_protection', absoluteDay, 18, 32)) {
        p.happiness = (p.happiness + 3).clamp(0, 100).toInt();
        p.mediaPressure = (p.mediaPressure - 5).clamp(0, 100).toInt();
        events.add(_event(year, month, day, 'relationship_club_protection', p,
          'Klub staje za zawodnikiem',
          'Mimo słabszej formy klub publicznie okazuje ${p.name} zaufanie i ogranicza presję.', 3));
      }

      // Fans can soften media criticism.
      if (r.fans >= 84 && p.form <= 48 && p.mediaPressure >= 55 &&
          _trigger(p.id, 'fans_protection', absoluteDay, 14, 35)) {
        p.fanSupport = (p.fanSupport + 3).clamp(0, 100).toInt();
        p.mediaPressure = (p.mediaPressure - 7).clamp(0, 100).toInt();
        events.add(_event(year, month, day, 'relationship_fans_protection', p,
          'Kibice stają po stronie zawodnika',
          'Trybuny okazują ${p.name} wsparcie mimo ostatnich słabszych występów.', 3));
      }

      // Strong media relationship increases reach, but also raises pressure.
      if (r.media >= 88 && p.fame >= 65 &&
          _trigger(p.id, 'media_amplification', absoluteDay, 21, 26)) {
        p.fame = (p.fame + 3).clamp(0, 100).toInt();
        p.marketability = (p.marketability + 2).clamp(0, 100).toInt();
        p.mediaPressure = (p.mediaPressure + 4).clamp(0, 100).toInt();
        events.add(_event(year, month, day, 'relationship_media_amplification', p,
          'Media wynoszą zawodnika na wyższy poziom',
          '${p.name} jest coraz częściej obecny w najważniejszych materiałach piłkarskich.', 3));
      }

      // Low club + low coach + contract nearing expiry can create an ultimatum.
      if (r.club <= 22 && r.coach <= 28 && p.contractYearsRemaining <= 1 &&
          _trigger(p.id, 'club_ultimatum', absoluteDay, 21, 22)) {
        p.transferRequest = true;
        p.happiness = (p.happiness - 5).clamp(0, 100).toInt();
        events.add(_event(year, month, day, 'relationship_club_ultimatum', p,
          'Relacja z klubem wchodzi w fazę krytyczną',
          'Połączenie konfliktu z trenerem i niepewnej przyszłości kontraktowej sprawia, że ${p.name} zaczyna rozważać odejście.', 5));
      }
    }
    return events;
  }

  bool _trigger(String playerId, String key, int day, int cooldown, int percent) {
    final map = _lastTriggered.putIfAbsent(playerId, () => {});
    final last = map[key];
    if (last != null && day - last < cooldown) return false;
    if (_random.nextInt(100) >= percent) return false;
    map[key] = day;
    return true;
  }

  WorldEvent _event(int y, int m, int d, String type, Player p, String title, String desc, int importance) =>
      WorldEvent(year: y, month: m, day: d, type: type, title: title, description: desc,
        playerId: p.id, clubId: p.clubId, importance: importance);

  Map<String, dynamic> toJson() => {
    'lastTriggered': {
      for (final e in _lastTriggered.entries) e.key: Map<String, dynamic>.from(e.value),
    },
  };

  void restoreFromJson(Map<String, dynamic>? json) {
    _lastTriggered.clear();
    final raw = json?['lastTriggered'];
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is Map) {
          _lastTriggered[e.key.toString()] = {
            for (final x in (e.value as Map).entries)
              x.key.toString(): x.value is int ? x.value as int : int.tryParse('${x.value}') ?? 0,
          };
        }
      }
    }
  }
}
