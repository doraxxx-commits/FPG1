import 'dart:math';
import '../models/player.dart';
import '../models/world_event.dart';
import 'relationship_web_engine.dart';

/// V19.9 — Career Consequence Engine 2.0.
/// Bridges a player's actual match performance with the relationship/career
/// world. It deliberately runs after the match so the next squad decision can
/// react to what happened on the pitch.
class CareerConsequenceEngineV2 {
  final Random _random;
  final Map<String, int> _lastProcessedDay = {};

  CareerConsequenceEngineV2({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processMatch({
    required Player player,
    required RelationshipWebEngine relationshipWeb,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
    required int homeGoals,
    required int awayGoals,
    required bool playerClubIsHome,
    required bool appeared,
    required bool started,
    required int minutes,
    required double rating,
    required int goals,
    required int assists,
  }) {
    if (_lastProcessedDay[player.id] == absoluteDay) return const [];
    _lastProcessedDay[player.id] = absoluteDay;

    final teamGoals = playerClubIsHome ? homeGoals : awayGoals;
    final opponentGoals = playerClubIsHome ? awayGoals : homeGoals;
    final won = teamGoals > opponentGoals;
    final draw = teamGoals == opponentGoals;
    final events = <WorldEvent>[];

    // No appearance still matters: a player can react to being left out.
    if (!appeared || minutes <= 0) {
      player.happiness = (player.happiness - 1).clamp(0, 100).toInt();
      player.managerRelationship = (player.managerRelationship - 1).clamp(0, 100).toInt();
      relationshipWeb.applyDecision(
        p: player,
        decision: 'demand_role',
        absoluteDay: absoluteDay,
        year: year,
        month: month,
        day: day,
      );
      events.add(_event(year, month, day, 'career_match_unused', player,
          'Bez minut po meczu',
          '${player.name} nie pojawił się na boisku. Brak minut może wpłynąć na jego relację z trenerem przed kolejnym spotkaniem.', 2));
      return events;
    }

    final excellent = rating >= 8.0;
    final good = rating >= 7.2;
    final poor = rating < 5.8;

    if (excellent) {
      player.managerRelationship = (player.managerRelationship + 5).clamp(0, 100).toInt();
      player.happiness = (player.happiness + 4).clamp(0, 100).toInt();
      player.fanSupport = (player.fanSupport + 3).clamp(0, 100).toInt();
      player.fame = (player.fame + 1).clamp(0, 100).toInt();
      player.coachPressure = (player.coachPressure - 4).clamp(0, 100).toInt();
      relationshipWeb.applyDecision(p: player, decision: 'answer_on_pitch', absoluteDay: absoluteDay, year: year, month: month, day: day);
      events.add(_event(year, month, day, 'career_match_breakthrough', player,
          'Występ, który zmienia narrację',
          '${player.name} zanotował świetny występ (${rating.toStringAsFixed(1)}). Trener, kibice i media zaczynają patrzeć na niego inaczej.', 4));
    } else if (good) {
      player.managerRelationship = (player.managerRelationship + 2).clamp(0, 100).toInt();
      player.happiness = (player.happiness + 2).clamp(0, 100).toInt();
      player.fanSupport = (player.fanSupport + 1).clamp(0, 100).toInt();
      relationshipWeb.applyDecision(p: player, decision: 'answer_on_pitch', absoluteDay: absoluteDay, year: year, month: month, day: day);
    } else if (poor) {
      player.managerRelationship = (player.managerRelationship - 4).clamp(0, 100).toInt();
      player.happiness = (player.happiness - 2).clamp(0, 100).toInt();
      player.coachPressure = (player.coachPressure + 5).clamp(0, 100).toInt();
      relationshipWeb.applyDecision(p: player, decision: 'demand_role', absoluteDay: absoluteDay, year: year, month: month, day: day);
      events.add(_event(year, month, day, 'career_match_setback', player,
          'Słabszy występ zwiększa presję',
          '${player.name} zakończył mecz z oceną ${rating.toStringAsFixed(1)}. Trener może ostrożniej podejść do jego roli w następnym spotkaniu.', 3));
    }

    // Result-specific feedback is intentionally smaller than performance.
    if (won) {
      player.happiness = (player.happiness + 2).clamp(0, 100).toInt();
      player.fanSupport = (player.fanSupport + 2).clamp(0, 100).toInt();
    } else if (!draw) {
      player.happiness = (player.happiness - 1).clamp(0, 100).toInt();
      if (poor) player.mediaPressure = (player.mediaPressure + 2).clamp(0, 100).toInt();
    }

    if (goals > 0) {
      player.fame = (player.fame + min(3, goals)).clamp(0, 100).toInt();
      player.fanSupport = (player.fanSupport + min(5, goals * 2)).clamp(0, 100).toInt();
      player.marketingValue = (player.marketingValue + min(4, goals * 2)).clamp(0, 100).toInt();
      events.add(_event(year, month, day, 'career_match_goal_impact', player,
          'Gol zmienia sytuację zawodnika',
          '${player.name} zdobył ${goals == 1 ? 'gola' : 'gole'} i dodatkowo podbił zainteresowanie kibiców oraz rynku.', 3));
    }

    if (assists > 0) {
      player.reputation = (player.reputation + min(2, assists)).clamp(0, 100).toInt();
    }

    if (won && excellent && player.managerRelationship >= 75) {
      events.add(_event(year, month, day, 'career_match_role_upgrade', player,
          'Trener zaczyna ufać zawodnikowi',
          'Świetny występ i dobry wynik zwiększają szanse ${player.name} na utrzymanie podstawowej roli w kolejnym meczu.', 4));
    }

    if (!won && poor && player.managerRelationship <= 35) {
      player.managerRelationship = (player.managerRelationship - 3).clamp(0, 100).toInt();
      events.add(_event(year, month, day, 'career_match_role_risk', player,
          'Ryzyko utraty miejsca w składzie',
          'Po słabym występie i niekorzystnym wyniku relacja z trenerem jest napięta. Kolejny wybór składu może być trudniejszy.', 4));
    }

    return events;
  }

  Map<String, dynamic> toJson() => {'lastProcessedDay': Map<String, int>.from(_lastProcessedDay)};

  void restoreFromJson(Map<String, dynamic>? json) {
    _lastProcessedDay.clear();
    final raw = json?['lastProcessedDay'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final v = e.value is num ? (e.value as num).toInt() : int.tryParse('${e.value}');
        if (v != null) _lastProcessedDay[e.key.toString()] = v;
      }
    }
  }

  WorldEvent _event(int y, int m, int d, String type, Player p, String title, String description, int importance) => WorldEvent(
    year: y, month: m, day: d, type: type, title: title, description: description,
    playerId: p.id, clubId: p.clubId, importance: importance,
  );
}
