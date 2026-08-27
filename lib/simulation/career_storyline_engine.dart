import 'dart:math';
import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';
import '../models/career_storyline.dart';
import '../models/career_storyline_choice.dart';

/// V19.2 — Career Storylines.
/// Turns isolated career consequences into persistent multi-stage stories.
class CareerStorylineEngine {
  final Random _random;
  final List<CareerStoryline> active = [];
  final List<CareerStoryline> completed = [];
  final Map<String, int> _cooldowns = {};

  CareerStorylineEngine({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processDay({
    required List<Player> players,
    required List<Club> clubs,
    required int year,
    required int month,
    required int day,
    required int absoluteDay,
  }) {
    final events = <WorldEvent>[];
    for (final p in players) {
      final club = p.clubId == null ? null : clubs.where((c) => c.id == p.clubId).firstOrNull;
      if (club == null) continue;
      final stories = active.where((s) => s.playerId == p.id && !s.completed).toList();
      for (final s in stories) {
        if (_cooldown(s.id, absoluteDay, 2)) continue;
        switch (s.type) {
          case 'contract_crisis':
            if (s.stage == 0 && p.contractYearsRemaining <= 1 && p.happiness <= 35) {
              s.stage = 1; s.lastUpdatedAbsoluteDay = absoluteDay;
              events.add(_event(year, month, day, 'story_contract_escalation', p,
                'Historia: konflikt kontraktowy eskaluje', '${p.name} i ${club.name} nadal nie znaleźli wspólnego języka. Agent domaga się jasnego planu.', club.id, 4));
            } else if (s.stage == 1 && p.transferRequest) {
              s.stage = 2; s.lastUpdatedAbsoluteDay = absoluteDay;
              events.add(_event(year, month, day, 'story_contract_ultimatum', p,
                'Historia: pojawia się ultimatum', 'Po braku porozumienia ${p.name} rozważa odejście. Klub musi zdecydować, czy spełnić oczekiwania, czy przygotować się na transfer.', club.id, 5));
            }
            break;
          case 'transfer_saga':
            if (s.stage == 0 && p.mediaPressure >= 55 && p.transferRequest) {
              s.stage = 1; s.lastUpdatedAbsoluteDay = absoluteDay;
              events.add(_event(year, month, day, 'story_transfer_escalation', p,
                'Historia transferowa nabiera tempa', 'Temat przyszłości ${p.name} przestaje być pojedynczą plotką. Media i agent naciskają na rozwiązanie sytuacji.', club.id, 4));
            } else if (s.stage == 1 && p.clubInterestLevel >= 80) {
              s.stage = 2; s.lastUpdatedAbsoluteDay = absoluteDay;
              events.add(_event(year, month, day, 'story_transfer_offer', p,
                'Historia: na stole pojawia się konkretna opcja', 'Zainteresowanie ${p.name} jest już na tyle duże, że klub może otrzymać konkretną ofertę.', club.id, 5));
            }
            break;
          case 'media_spotlight':
            if (s.stage == 0 && p.fame >= 75 && p.form >= 70) {
              s.stage = 1; s.lastUpdatedAbsoluteDay = absoluteDay;
              events.add(_event(year, month, day, 'story_media_spotlight', p,
                'Historia: zawodnik trafia pod lupę', '${p.name} staje się jednym z najczęściej komentowanych zawodników. Każdy kolejny występ ma większe znaczenie.', club.id, 3));
            } else if (s.stage == 1 && p.mediaPressure >= 88) {
              s.stage = 2; s.lastUpdatedAbsoluteDay = absoluteDay;
              p.happiness = max(10, p.happiness - 3);
              events.add(_event(year, month, day, 'story_media_backlash', p,
                'Historia: sława zaczyna kosztować', 'Rosnąca popularność przynosi zainteresowanie, ale również presję. ${p.name} musi nauczyć się zarządzać oczekiwaniami.', club.id, 4));
            }
            break;
        }
      }

      // Seed stories from persistent conditions. No daily spam: one story per type.
      if (p.contractYearsRemaining <= 1 && p.happiness <= 35 && !_hasActive(p.id, 'contract_crisis') && _readyStart('${p.id}:contract', absoluteDay, 21)) {
        final s = start(type: 'contract_crisis', title: 'Konflikt kontraktowy', player: p, absoluteDay: absoluteDay);
        events.add(_event(year, month, day, 'story_started', p, 'Nowa historia kariery: ${s.title}', 'Wokół ${p.name} rozpoczyna się wieloetapowa historia. Jej kolejne etapy zależą od decyzji i wydarzeń świata.', club.id, 3));
      }
      if (p.transferRequest && p.mediaPressure >= 55 && !_hasActive(p.id, 'transfer_saga') && _readyStart('${p.id}:transfer', absoluteDay, 14)) {
        final s = start(type: 'transfer_saga', title: 'Saga transferowa', player: p, absoluteDay: absoluteDay);
        events.add(_event(year, month, day, 'story_started', p, 'Nowa historia kariery: ${s.title}', 'Przyszłość ${p.name} zaczyna tworzyć wieloetapową sagę transferową.', club.id, 3));
      }
      if (p.fame >= 75 && p.form >= 70 && !_hasActive(p.id, 'media_spotlight') && _readyStart('${p.id}:media', absoluteDay, 30)) {
        final s = start(type: 'media_spotlight', title: 'Życie pod lupą mediów', player: p, absoluteDay: absoluteDay);
        events.add(_event(year, month, day, 'story_started', p, 'Nowa historia kariery: ${s.title}', 'Rosnąca popularność ${p.name} rozpoczyna historię, w której każdy kolejny występ może zmienić jego pozycję medialną.', club.id, 2));
      }
    }
    return events;
  }

  List<WorldEvent> decisionTrigger({required String category, required String decision, required Player player, required int absoluteDay, required int year, required int month, required int day, Club? club}) {
    final events = <WorldEvent>[];
    if (category == 'contract' && decision == 'reject' && player.contractYearsRemaining <= 1) {
      if (!_hasActive(player.id, 'contract_crisis')) { start(type: 'contract_crisis', title: 'Konflikt kontraktowy', player: player, absoluteDay: absoluteDay); events.add(_event(year,month,day,'story_started',player,'Historia: Konflikt kontraktowy','Odrzucona oferta uruchamia wieloetapową historię przyszłości zawodnika.',club?.id,3)); }
    }
    if (category == 'transfer' && (decision == 'negotiate' || decision == 'accept')) {
      if (!_hasActive(player.id, 'transfer_saga')) { start(type: 'transfer_saga', title: 'Saga transferowa', player: player, absoluteDay: absoluteDay); events.add(_event(year,month,day,'story_started',player,'Historia: Saga transferowa','Decyzja transferowa uruchamia historię z kolejnymi etapami negocjacji i presji.',club?.id,3)); }
    }
    if (category == 'interview' && decision == 'accept' && player.fame >= 60) {
      if (!_hasActive(player.id, 'media_spotlight')) { start(type: 'media_spotlight', title: 'Życie pod lupą mediów', player: player, absoluteDay: absoluteDay); events.add(_event(year,month,day,'story_started',player,'Historia: Życie pod lupą mediów','Wywiad uruchamia wieloetapową historię medialną zawodnika.',club?.id,2)); }
    }
    return events;
  }


  /// V19.3: choices are generated from the current story stage and player state.
  List<CareerStorylineChoice> choicesFor(CareerStoryline s, Player p) {
    if (s.completed) return const [];
    switch (s.type) {
      case 'contract_crisis':
        if (s.stage == 0) return const [
          CareerStorylineChoice(id: 'talk_club', title: 'Porozmawiaj z klubem', description: 'Spróbuj uspokoić sytuację bez publicznej wojny.', tone: 'positive'),
          CareerStorylineChoice(id: 'back_agent', title: 'Poprzyj agenta', description: 'Twarde stanowisko zwiększy nacisk, ale może pogorszyć relację.', tone: 'hard'),
          CareerStorylineChoice(id: 'stay_silent', title: 'Milcz', description: 'Nie dolewaj oliwy do ognia i poczekaj na rozwój sytuacji.', tone: 'neutral'),
        ];
        if (s.stage == 1) return const [
          CareerStorylineChoice(id: 'demand_role', title: 'Zażądaj większej roli', description: 'Postaw warunek sportowy przed dalszymi rozmowami.', tone: 'hard'),
          CareerStorylineChoice(id: 'accept_compromise', title: 'Szukaj kompromisu', description: 'Zmniejsz oczekiwania, aby utrzymać dobre relacje.', tone: 'positive'),
          CareerStorylineChoice(id: 'request_transfer', title: 'Poproś o transfer', description: 'Przenieś konflikt na rynek transferowy.', tone: 'danger'),
        ];
        return const [
          CareerStorylineChoice(id: 'ultimatum', title: 'Postaw ultimatum', description: 'Ostatnia próba wymuszenia konkretnej decyzji.', tone: 'danger'),
          CareerStorylineChoice(id: 'reconcile', title: 'Zakończ konflikt', description: 'Spróbuj zamknąć sprawę i odbudować relację.', tone: 'positive'),
        ];
      case 'transfer_saga':
        if (s.stage == 0) return const [
          CareerStorylineChoice(id: 'welcome_interest', title: 'Pozwól działać agentowi', description: 'Agent może rozwijać zainteresowanie innych klubów.', tone: 'positive'),
          CareerStorylineChoice(id: 'public_statement', title: 'Powiedz, że chcesz odejść', description: 'Publiczne stanowisko przyspieszy sagę, ale zwiększy presję.', tone: 'hard'),
          CareerStorylineChoice(id: 'commit_club', title: 'Zostań przy klubie', description: 'Daj obecnemu klubowi sygnał, że transfer nie jest priorytetem.', tone: 'positive'),
        ];
        if (s.stage == 1) return const [
          CareerStorylineChoice(id: 'meet_interested_club', title: 'Rozpocznij rozmowy', description: 'Zwiększ szansę na konkretną ofertę i warunki osobiste.', tone: 'positive'),
          CareerStorylineChoice(id: 'slow_down', title: 'Spowolnij negocjacje', description: 'Ogranicz presję i poczekaj na lepszą opcję.', tone: 'neutral'),
          CareerStorylineChoice(id: 'force_exit', title: 'Wymuś odejście', description: 'Mocny ruch zwiększy szansę transferu, ale pogorszy relacje.', tone: 'danger'),
        ];
        return const [
          CareerStorylineChoice(id: 'accept_move', title: 'Postaw na transfer', description: 'Daj agentowi zielone światło do finalizacji ruchu.', tone: 'positive'),
          CareerStorylineChoice(id: 'wait_better', title: 'Czekaj na lepszy klub', description: 'Ryzykujesz utratę obecnej oferty.', tone: 'hard'),
          CareerStorylineChoice(id: 'stay', title: 'Zostań', description: 'Kończysz sagę i próbujesz odbudować pozycję w klubie.', tone: 'neutral'),
        ];
      case 'media_spotlight':
        if (s.stage == 0) return const [
          CareerStorylineChoice(id: 'embrace_spotlight', title: 'Wykorzystaj sławę', description: 'Więcej mediów, większa marka i większa presja.', tone: 'hard'),
          CareerStorylineChoice(id: 'selective_media', title: 'Wybierz tylko ważne media', description: 'Buduj markę bez niepotrzebnego szumu.', tone: 'positive'),
          CareerStorylineChoice(id: 'privacy', title: 'Chroń prywatność', description: 'Ogranicz ekspozycję i obniż presję.', tone: 'neutral'),
        ];
        if (s.stage == 1) return const [
          CareerStorylineChoice(id: 'answer_critics', title: 'Odpowiedz krytykom', description: 'Publicznie broń swojej pozycji.', tone: 'hard'),
          CareerStorylineChoice(id: 'focus_pitch', title: 'Odpowiedz na boisku', description: 'Skup się na treningu i wynikach.', tone: 'positive'),
          CareerStorylineChoice(id: 'step_back', title: 'Wycofaj się z mediów', description: 'Zmniejsz presję kosztem części rozpoznawalności.', tone: 'neutral'),
        ];
        return const [
          CareerStorylineChoice(id: 'own_narrative', title: 'Przejmij narrację', description: 'Wykorzystaj popularność do budowania własnej marki.', tone: 'positive'),
          CareerStorylineChoice(id: 'reset', title: 'Zrób reset medialny', description: 'Ogranicz ekspozycję i odzyskaj spokój.', tone: 'neutral'),
        ];
      default:
        return const [CareerStorylineChoice(id: 'silence', title: 'Zachowaj spokój', description: 'Nie eskaluj sytuacji.')];
    }
  }

  /// Applies a contextual choice. Returns true when the choice was accepted.
  bool choose(CareerStoryline s, String choiceId, Player p, {required int absoluteDay}) {
    if (!active.contains(s) || s.completed) return false;
    final available = choicesFor(s, p);
    if (!available.any((c) => c.id == choiceId)) return false;
    switch (choiceId) {
      case 'talk_club': case 'accept_compromise': case 'reconcile': case 'commit_club': case 'stay': case 'focus_pitch': case 'selective_media':
        p.happiness = min(100, p.happiness + 5); p.mediaPressure = max(0, p.mediaPressure - 3);
        break;
      case 'back_agent': case 'demand_role': case 'public_statement': case 'answer_critics': case 'embrace_spotlight':
        p.mediaPressure = min(100, p.mediaPressure + 8); p.reputation = max(0, p.reputation - 2);
        break;
      case 'stay_silent': case 'slow_down': case 'privacy': case 'step_back': case 'reset':
        p.mediaPressure = max(0, p.mediaPressure - 8); p.happiness = min(100, p.happiness + 2);
        break;
      case 'request_transfer': case 'ultimatum': case 'force_exit':
        p.transferRequest = true; p.mediaPressure = min(100, p.mediaPressure + 10); break;
      case 'welcome_interest': case 'meet_interested_club': case 'accept_move': case 'own_narrative':
        p.clubInterestLevel = min(100, p.clubInterestLevel + 8); p.fame = min(100, p.fame + 2); break;
      case 'wait_better':
        p.clubInterestLevel = min(100, p.clubInterestLevel + 3); p.mediaPressure = min(100, p.mediaPressure + 4); break;
    }
    s.lastUpdatedAbsoluteDay = absoluteDay;
    // A contextual choice normally advances one stage. Final-stage choices resolve the story.
    if (s.stage >= 2 || choiceId == 'stay' || choiceId == 'reconcile' || choiceId == 'reset') {
      active.remove(s); s.completed = true; s.outcome = choiceId; completed.add(s);
      if (completed.length > 100) completed.removeRange(0, completed.length - 100);
    } else {
      s.stage += 1;
    }
    return true;
  }

  CareerStoryline start({required String type, required String title, required Player player, required int absoluteDay}) {
    final s = CareerStoryline(id: '${type}_${player.id}_$absoluteDay', playerId: player.id, type: type, title: title, stage: 0, startedAbsoluteDay: absoluteDay, lastUpdatedAbsoluteDay: absoluteDay);
    active.add(s);
    return s;
  }

  bool resolve(String storylineId, String outcome, Player player) {
    final index = active.indexWhere((s) => s.id == storylineId && s.playerId == player.id);
    if (index < 0) return false;
    final s = active.removeAt(index);
    s.completed = true; s.outcome = outcome;
    completed.add(s);
    if (outcome == 'reconcile') player.happiness = min(100, player.happiness + 6);
    if (outcome == 'leave') player.transferRequest = true;
    if (outcome == 'silence') player.mediaPressure = max(0, player.mediaPressure - 8);
    if (completed.length > 100) completed.removeRange(0, completed.length - 100);
    return true;
  }

  bool _hasActive(String playerId, String type) => active.any((s) => s.playerId == playerId && s.type == type && !s.completed);
  bool _readyStart(String key, int day, int cooldown) { final until = _cooldowns[key]; if (until != null && until > day) return false; _cooldowns[key] = day + cooldown; return true; }
  bool _cooldown(String id, int day, int days) { final until = _cooldowns['tick:$id']; if (until != null && until > day) return true; _cooldowns['tick:$id'] = day + days; return false; }

  Map<String, dynamic> toJson() => {'active': active.map((s) => s.toJson()).toList(), 'completed': completed.map((s) => s.toJson()).toList(), 'cooldowns': _cooldowns};
  void restoreFromJson(Map<String, dynamic>? json) {
    active.clear(); completed.clear(); _cooldowns.clear();
    if (json == null) return;
    if (json['active'] is List) for (final x in json['active']) if (x is Map) active.add(CareerStoryline.fromJson(Map<String,dynamic>.from(x)));
    if (json['completed'] is List) for (final x in json['completed']) if (x is Map) completed.add(CareerStoryline.fromJson(Map<String,dynamic>.from(x)));
    if (json['cooldowns'] is Map) for (final e in (json['cooldowns'] as Map).entries) _cooldowns[e.key.toString()] = e.value is int ? e.value : int.tryParse('${e.value}') ?? 0;
  }

  WorldEvent _event(int y,int m,int d,String type,Player p,String title,String desc,String? clubId,int importance) => WorldEvent(year:y,month:m,day:d,type:type,title:title,description:desc,clubId:clubId,playerId:p.id,importance:importance);
}
