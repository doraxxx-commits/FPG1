import '../models/player.dart';
import '../models/player_relationships.dart';
import '../models/relationship_action.dart';
import '../models/world_event.dart';
import 'relationship_web_engine.dart';

/// V19.6 — Relationship Actions.
/// Strong relationships unlock explicit, contextual actions. Actions are
/// limited by cooldowns so the player cannot farm relationship stats every day.
class RelationshipActionsEngine {
  final Map<String, Map<String, int>> _lastUsed = {};

  List<RelationshipAction> availableActions({required Player p, required PlayerRelationships r, required int absoluteDay}) {
    final actions = <RelationshipAction>[];
    void add(RelationshipAction a, int value) {
      if (value < a.minValue) return;
      final last = _lastUsed[p.id]?[a.id];
      if (last != null && absoluteDay - last < a.cooldownDays) return;
      actions.add(a);
    }

    add(const RelationshipAction(id:'coach_talk', relationship:'coach', title:'Rozmowa z trenerem', description:'Poproś o jasne określenie swojej roli i planu na najbliższe tygodnie.', icon:'coach', minValue:55, cooldownDays:7), r.coach);
    add(const RelationshipAction(id:'coach_role', relationship:'coach', title:'Poproś o większą rolę', description:'Wykorzystaj zaufanie trenera i dobrą formę, aby walczyć o miejsce w podstawowym składzie.', icon:'role', minValue:78, cooldownDays:14), r.coach);
    add(const RelationshipAction(id:'agent_plan', relationship:'agent', title:'Plan kariery z agentem', description:'Agent przygotuje plan rynku: pozostanie, nowy kontrakt albo transfer.', icon:'agent', minValue:60, cooldownDays:14), r.agent);
    add(const RelationshipAction(id:'agent_target', relationship:'agent', title:'Poproś o konkretny klub', description:'Agent zacznie aktywnie sondować jeden z dostępnych kierunków transferowych.', icon:'target', minValue:82, cooldownDays:21), r.agent);
    add(const RelationshipAction(id:'club_extension', relationship:'club', title:'Rozmowa o przyszłości', description:'Dobra relacja pozwala otworzyć rozmowę o przedłużeniu kontraktu i większej roli.', icon:'club', minValue:78, cooldownDays:21), r.club);
    add(const RelationshipAction(id:'club_support', relationship:'club', title:'Poproś klub o wsparcie', description:'Poproś klub o publiczne wsparcie w trudnym okresie medialnym.', icon:'shield', minValue:82, cooldownDays:18), r.club);
    add(const RelationshipAction(id:'fans_campaign', relationship:'fans', title:'Uruchom kampanię kibiców', description:'Silne wsparcie trybun może zwiększyć presję na pozytywne decyzje klubu.', icon:'fans', minValue:80, cooldownDays:21), r.fans);
    add(const RelationshipAction(id:'media_exclusive', relationship:'media', title:'Ekskluzywny wywiad', description:'Wykorzystaj dobrą relację z mediami do kontrolowania narracji wokół swojej kariery.', icon:'media', minValue:78, cooldownDays:14), r.media);
    add(const RelationshipAction(id:'media_reset', relationship:'media', title:'Kontrolowany reset medialny', description:'Poproś media o ograniczenie presji i skup się na boisku.', icon:'quiet', minValue:65, cooldownDays:14), r.media);
    return actions;
  }

  RelationshipActionResult execute({
    required Player p,
    required RelationshipWebEngine relationshipWeb,
    required String actionId,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    final r = relationshipWeb.forPlayer(p);
    final action = availableActions(p: p, r: r, absoluteDay: absoluteDay).where((a) => a.id == actionId).firstOrNull;
    if (action == null) {
      return const RelationshipActionResult(actionId:'invalid', title:'Akcja niedostępna', description:'Ta możliwość jest obecnie niedostępna albo jest jeszcze na cooldownie.', success:false);
    }
    _lastUsed.putIfAbsent(p.id, () => {})[action.id] = absoluteDay;

    switch (action.id) {
      case 'coach_talk':
        p.managerRelationship = (p.managerRelationship + 4).clamp(0,100).toInt();
        p.happiness = (p.happiness + 3).clamp(0,100).toInt();
        relationshipWeb.applyDecision(p:p, decision:'talk_club', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
      case 'coach_role':
        p.managerRelationship = (p.managerRelationship + 7).clamp(0,100).toInt();
        p.happiness = (p.happiness + 5).clamp(0,100).toInt();
        p.squadStatus = 'rotation';
        relationshipWeb.applyDecision(p:p, decision:'demand_role', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
      case 'agent_plan':
        p.agentAttention = (p.agentAttention + 8).clamp(0,100).toInt();
        p.transferPull = (p.transferPull + 3).clamp(0,100).toInt();
        relationshipWeb.applyDecision(p:p, decision:'welcome_interest', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
      case 'agent_target':
        p.agentAttention = (p.agentAttention + 12).clamp(0,100).toInt();
        p.transferPull = (p.transferPull + 7).clamp(0,100).toInt();
        p.clubInterestLevel = (p.clubInterestLevel + 8).clamp(0,100).toInt();
        relationshipWeb.applyDecision(p:p, decision:'meet_interested_club', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
      case 'club_extension':
        p.happiness = (p.happiness + 6).clamp(0,100).toInt();
        p.wageExpectation = p.wageExpectation <= 0 ? (p.weeklyWage * 1.05).round() : p.wageExpectation;
        relationshipWeb.applyDecision(p:p, decision:'commit_club', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
      case 'club_support':
        p.mediaPressure = (p.mediaPressure - 12).clamp(0,100).toInt();
        p.happiness = (p.happiness + 4).clamp(0,100).toInt();
        relationshipWeb.applyDecision(p:p, decision:'reconcile', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
      case 'fans_campaign':
        p.fanSupport = (p.fanSupport + 8).clamp(0,100).toInt();
        p.mediaPressure = (p.mediaPressure - 5).clamp(0,100).toInt();
        relationshipWeb.applyDecision(p:p, decision:'answer_on_pitch', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
      case 'media_exclusive':
        p.mediaAppearances += 1;
        p.interviewInvites += 1;
        p.fame = (p.fame + 4).clamp(0,100).toInt();
        p.marketability = (p.marketability + 3).clamp(0,100).toInt();
        p.mediaPressure = (p.mediaPressure + 5).clamp(0,100).toInt();
        relationshipWeb.applyDecision(p:p, decision:'use_fame', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
      case 'media_reset':
        p.mediaPressure = (p.mediaPressure - 15).clamp(0,100).toInt();
        p.mediaAppearances += 1;
        relationshipWeb.applyDecision(p:p, decision:'limit_media', absoluteDay:absoluteDay, year:year, month:month, day:day);
        break;
    }

    return RelationshipActionResult(
      actionId: action.id,
      title: action.title,
      description: _description(action.id),
    );
  }

  String _description(String id) => switch (id) {
    'coach_talk' => 'Trener docenił bezpośrednią rozmowę. Zawodnik ma teraz jaśniejszy obraz swojej roli.',
    'coach_role' => 'Zawodnik wykorzystał zaufanie trenera i otworzył sobie drogę do większej liczby minut.',
    'agent_plan' => 'Agent przygotowuje plan dalszej kariery i zaczyna aktywniej monitorować rynek.',
    'agent_target' => 'Agent rozpoczyna rozmowy z wybranymi klubami. Zainteresowanie rynkowe rośnie.',
    'club_extension' => 'Klub jest gotowy rozmawiać o przyszłości zawodnika na korzystniejszych warunkach.',
    'club_support' => 'Klub publicznie wsparł zawodnika, ograniczając część presji medialnej.',
    'fans_campaign' => 'Kibice rozpoczęli kampanię wsparcia. Zawodnik odzyskał część kontroli nad narracją.',
    'media_exclusive' => 'Ekskluzywny wywiad zwiększył rozpoznawalność, ale również zainteresowanie mediów.',
    'media_reset' => 'Zawodnik ograniczył ekspozycję medialną i może skupić się na boisku.',
    _ => 'Decyzja została wykonana.',
  };

  Map<String,dynamic> toJson() => {'lastUsed': _lastUsed.map((k,v) => MapEntry(k, Map<String,dynamic>.from(v)))};

  void restoreFromJson(Map<String,dynamic>? json) {
    _lastUsed.clear();
    final raw = json?['lastUsed'];
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is Map) {
          _lastUsed[e.key.toString()] = {for (final x in (e.value as Map).entries) x.key.toString(): _int(x.value)};
        }
      }
    }
  }

  static int _int(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}
