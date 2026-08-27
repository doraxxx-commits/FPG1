import 'dart:math';
import '../models/player.dart';
import '../models/player_relationships.dart';
import '../models/relationship_event.dart';
import '../models/world_event.dart';
import 'relationship_web_engine.dart';

/// V19.7 — Interactive relationship scenes. Actions and world thresholds can
/// open a scene with multiple responses; the selected response feeds back into
/// the same relationship graph and player stats.
class RelationshipEventsEngine {
  final Random _random;
  final List<RelationshipEvent> pending = [];
  final Map<String,int> _lastGenerated = {};
  int _serial = 0;
  final Map<String, Map<String, dynamic>> _chains = {};
  RelationshipEventsEngine({Random? random}):_random=random??Random();

  List<RelationshipEvent> processDay({required List<Player> players, required RelationshipWebEngine web, required int absoluteDay}) {
    final out=<RelationshipEvent>[];
    for(final p in players) {
      if(p.id.isEmpty || pending.any((e)=>e.playerId==p.id && !e.resolved)) continue;
      final r=web.forPlayer(p);
      RelationshipEvent? e;
      final chain = _chains[p.id];
      if (chain != null && (chain['dueDay'] as int? ?? 999999) <= absoluteDay && chain['active'] == true) {
        e = _nextChainScene(p, chain, absoluteDay);
      }
      if(e == null && ((_lastGenerated[p.id]??-9999)+5<=absoluteDay) && r.coach<=25 && p.consecutiveBenchDays>=5) {
        e=_scene(p,'coach_crisis','coach','Trener chce wyjaśnić Twoją rolę','Po kolejnych meczach na ławce trener prosi Cię na rozmowę. Możesz zażądać większej roli albo pokazać cierpliwość.',absoluteDay,[
          const RelationshipEventChoice(id:'fight_role',title:'Walcz o miejsce',description:'Postaw sprawę jasno i poproś o konkretną szansę.',tone:'bold'),
          const RelationshipEventChoice(id:'trust_coach',title:'Zaufaj trenerowi',description:'Zaakceptuj plan i skup się na treningach.',tone:'calm'),
          const RelationshipEventChoice(id:'call_agent',title:'Skonsultuj to z agentem',description:'Nie eskalujesz rozmowy, ale uruchamiasz wsparcie agenta.',tone:'agent'),
        ]);
      } else if(e == null && ((_lastGenerated[p.id]??-9999)+5<=absoluteDay) && r.agent>=82 && p.transferPull>=65) {
        e=_scene(p,'agent_call','agent','Telefon od agenta','Agent ma pierwszy konkretny sygnał z rynku. Pyta, czy może rozpocząć rozmowy.',absoluteDay,[
          const RelationshipEventChoice(id:'open_market',title:'Otwórz rynek',description:'Pozwól agentowi aktywnie szukać klubu.',tone:'bold'),
          const RelationshipEventChoice(id:'listen_only',title:'Tylko zbierz informacje',description:'Agent może sondować rynek, ale bez deklaracji odejścia.',tone:'calm'),
          const RelationshipEventChoice(id:'stay_focus',title:'Zostań przy obecnym klubie',description:'Zamknij temat transferu na ten moment.',tone:'loyal'),
        ]);
      } else if(e == null && ((_lastGenerated[p.id]??-9999)+5<=absoluteDay) && r.club<=25 && p.contractYearsRemaining<=1) {
        e=_scene(p,'club_future','club','Spotkanie z dyrektorem sportowym','Klub chce wiedzieć, czy widzisz swoją przyszłość tutaj. Twoja odpowiedź wpłynie na dalsze rozmowy.',absoluteDay,[
          const RelationshipEventChoice(id:'commit',title:'Chcę zostać',description:'Deklarujesz lojalność i otwierasz drogę do negocjacji.',tone:'loyal'),
          const RelationshipEventChoice(id:'conditions',title:'Zostanę na moich warunkach',description:'Chcesz konkretnej roli i warunków.',tone:'bold'),
          const RelationshipEventChoice(id:'leave',title:'Jestem otwarty na odejście',description:'Klub dostaje jasny sygnał, że trzeba rozważyć transfer.',tone:'exit'),
        ]);
      } else if(e == null && ((_lastGenerated[p.id]??-9999)+5<=absoluteDay) && r.media>=88 && p.mediaPressure>=78) {
        e=_scene(p,'media_interview','media','Media chcą Twojej odpowiedzi','Po ostatnich wydarzeniach dziennikarze czekają na Twoje stanowisko. Jedno zdanie może zmienić narrację.',absoluteDay,[
          const RelationshipEventChoice(id:'speak',title:'Powiedz wprost, co myślisz',description:'Ryzykujesz większą presję, ale kontrolujesz narrację.',tone:'bold'),
          const RelationshipEventChoice(id:'neutral',title:'Odpowiedz dyplomatycznie',description:'Nie dajesz mediom paliwa do konfliktu.',tone:'calm'),
          const RelationshipEventChoice(id:'no_comment',title:'Bez komentarza',description:'Chronisz prywatność i skupiasz się na boisku.',tone:'quiet'),
        ]);
      }
      if(e!=null){ pending.add(e); _lastGenerated[p.id]=absoluteDay; out.add(e); }
    }
    return out;
  }

  RelationshipEvent? createFromAction({required Player p, required String actionId, required int absoluteDay}) {
    if(pending.any((e)=>e.playerId==p.id&&!e.resolved)) return null;
    final data=<String,Map<String,dynamic>>{
      'coach_talk': {'target':'coach','title':'Trener chce ustalić plan','description':'Po rozmowie trener daje Ci wybór: zaakceptować plan, walczyć o rolę albo poprosić o dodatkowy czas.'},
      'agent_plan': {'target':'agent','title':'Agent proponuje plan kariery','description':'Agent przygotował trzy ścieżki. Możesz zostać, obserwować rynek albo rozpocząć konkretne rozmowy.'},
      'club_support': {'target':'club','title':'Klub proponuje publiczne wsparcie','description':'Dyrektor pyta, czy klub ma mocniej stanąć po Twojej stronie w mediach.'},
      'media_exclusive': {'target':'media','title':'Wywiad na wyłączność','description':'Redakcja daje Ci pełną przestrzeń. Możesz podkręcić narrację, uspokoić sytuację albo odmówić.'},
    };
    final d=data[actionId]; if(d==null)return null;
    final e=_scene(p,'action_$actionId','${d['target']}','${d['title']}','${d['description']}',absoluteDay,[
      const RelationshipEventChoice(id:'accept',title:'Skorzystaj z okazji',description:'Podejmujesz współpracę i bierzesz inicjatywę.',tone:'bold'),
      const RelationshipEventChoice(id:'balanced',title:'Zagraj ostrożnie',description:'Wybierasz bezpieczną wersję i ograniczasz ryzyko.',tone:'calm'),
      const RelationshipEventChoice(id:'decline',title:'Odmów',description:'Nie chcesz teraz eskalować sytuacji.',tone:'quiet'),
    ]);
    pending.add(e); _lastGenerated[p.id]=absoluteDay; return e;
  }

  RelationshipEventChoice? choice(String eventId,String choiceId)=>pending.where((e)=>e.id==eventId).firstOrNull?.choices.where((c)=>c.id==choiceId).firstOrNull;

  WorldEvent? resolve({required RelationshipEvent event, required String choiceId, required Player p, required RelationshipWebEngine web, required int absoluteDay, required int year, required int month, required int day}) {
    if(event.resolved)return null;
    final c=choice(event.id,choiceId); if(c==null)return null;
    event.resolved=true; event.chosenId=choiceId;
    final delta=<String,int>{};
    if (event.chainId != null) {
      _chains[p.id] = {
        'id': event.chainId, 'target': event.target, 'stage': event.stage + 1,
        'lastChoice': choiceId, 'dueDay': absoluteDay + 2, 'active': event.stage < 3,
      };
    }
    switch(event.target){
      case 'coach':
        if(choiceId=='accept_role'){p.happiness=(p.happiness+5).clamp(0,100).toInt();delta.addAll({'coach':8,'club':3});} else if(choiceId=='demand_role') {p.managerRelationship=(p.managerRelationship+3).clamp(0,100).toInt();p.happiness=(p.happiness+1).clamp(0,100).toInt();delta.addAll({'coach':-2,'club':-2});} else if(choiceId=='ask_agent') {p.agentAttention=(p.agentAttention+7).clamp(0,100).toInt();delta.addAll({'agent':6,'coach':-2});} else if(choiceId=='fight_role'){p.managerRelationship=(p.managerRelationship+5).clamp(0,100).toInt();p.happiness=(p.happiness+3).clamp(0,100).toInt();delta.addAll({'coach':4,'club':-2});}
        else if(choiceId=='trust_coach'){p.managerRelationship=(p.managerRelationship+8).clamp(0,100).toInt();p.happiness=(p.happiness+4).clamp(0,100).toInt();delta['coach']=7;}
        else {p.agentAttention=(p.agentAttention+6).clamp(0,100).toInt();delta.addAll({'agent':5,'coach':-1});}
        break;
      case 'agent':
        if(choiceId=='pursue'){p.transferPull=(p.transferPull+8).clamp(0,100).toInt();p.clubInterestLevel=(p.clubInterestLevel+7).clamp(0,100).toInt();delta.addAll({'agent':8,'media':4});} else if(choiceId=='wait'){delta.addAll({'agent':2,'media':-1});} else if(choiceId=='close'){p.transferPull=(p.transferPull-4).clamp(0,100).toInt();delta.addAll({'agent':-4,'club':5});} else if(choiceId=='open_market'){p.transferPull=(p.transferPull+10).clamp(0,100).toInt();p.clubInterestLevel=(p.clubInterestLevel+8).clamp(0,100).toInt();delta.addAll({'agent':8,'club':-4,'media':4});}
        else if(choiceId=='listen_only'){p.agentAttention=(p.agentAttention+4).clamp(0,100).toInt();delta.addAll({'agent':4,'media':2});}
        else {p.transferPull=(p.transferPull-3).clamp(0,100).toInt();delta.addAll({'club':6,'agent':-3});}
        break;
      case 'club':
        if(choiceId=='stay'){p.transferRequest=false;p.happiness=(p.happiness+5).clamp(0,100).toInt();delta.addAll({'club':9,'fans':4});} else if(choiceId=='terms'){p.wageExpectation=(p.weeklyWage*1.08).round();delta.addAll({'club':-2,'agent':4});} else if(choiceId=='exit'){p.transferRequest=true;delta.addAll({'club':-10,'agent':7,'media':5,'fans':-2});} else if(choiceId=='commit'){p.happiness=(p.happiness+6).clamp(0,100).toInt();delta.addAll({'club':10,'fans':5,'agent':-2});}
        else if(choiceId=='conditions'){p.wageExpectation=(p.weeklyWage*1.08).round();delta.addAll({'club':-2,'agent':4});}
        else {p.transferRequest=true;delta.addAll({'club':-12,'agent':8,'media':6,'fans':-3});}
        break;
      case 'media':
        if(choiceId=='clarify'){p.mediaPressure=(p.mediaPressure-6).clamp(0,100).toInt();delta.addAll({'media':4,'fans':2});} else if(choiceId=='double_down'){p.fame=(p.fame+4).clamp(0,100).toInt();p.mediaPressure=(p.mediaPressure+7).clamp(0,100).toInt();delta.addAll({'media':8,'fans':1});} else if(choiceId=='withdraw'){p.mediaPressure=(p.mediaPressure-10).clamp(0,100).toInt();delta.addAll({'media':-8,'fans':-1});} else if(choiceId=='speak'){p.fame=(p.fame+5).clamp(0,100).toInt();p.mediaPressure=(p.mediaPressure+8).clamp(0,100).toInt();delta.addAll({'media':8,'fans':2});}
        else if(choiceId=='neutral'){p.mediaPressure=(p.mediaPressure-2).clamp(0,100).toInt();delta['media']=2;}
        else {p.mediaPressure=(p.mediaPressure-10).clamp(0,100).toInt();delta.addAll({'media':-10,'fans':-1});}
        break;
    }
    delta.forEach((k,v)=>web.applyDecision(p:p,decision:_decisionFor(k,v),absoluteDay:absoluteDay,year:year,month:month,day:day));
    return WorldEvent(year:year,month:month,day:day,type:'relationship_scene',title:'${event.title} • ${c.title}',description:'${p.name}: ${c.description}',playerId:p.id,clubId:p.clubId,importance:4);
  }

  RelationshipEvent _nextChainScene(Player p, Map<String,dynamic> chain, int day) {
    final target='${chain['target']??'club'}';
    final stage=(chain['stage'] as int?)??2;
    final last='${chain['lastChoice']??''}';
    List<RelationshipEventChoice> choices;
    String title;
    String description;
    if (target=='coach') {
      title = stage==2 ? 'Trener wraca z odpowiedzią' : 'Decydująca rozmowa z trenerem';
      description = stage==2 ? 'Twoja poprzednia decyzja wpłynęła na plan. Trener proponuje konkretną rolę.' : 'Nadszedł moment, by ustalić, czy zostajesz w walce o skład.';
      choices = [
        const RelationshipEventChoice(id:'accept_role',title:'Przyjmij plan',description:'Akceptujesz rolę i walczysz o minuty.',tone:'calm'),
        const RelationshipEventChoice(id:'demand_role',title:'Zażądaj większej roli',description:'Stawiasz wyższe wymagania.',tone:'bold'),
        const RelationshipEventChoice(id:'ask_agent',title:'Poproś agenta o pomoc',description:'Nie chcesz prowadzić tej rozmowy sam.',tone:'agent'),
      ];
    } else if (target=='agent') {
      title = stage==2 ? 'Agent wraca z rynku' : 'Agent ma konkretną propozycję';
      description = last=='open_market' ? 'Pojawił się klub gotowy wejść w rozmowy.' : 'Agent zebrał informacje i chce ustalić następny krok.';
      choices = [
        const RelationshipEventChoice(id:'pursue',title:'Rozpocznij rozmowy',description:'Pozwalasz agentowi przejść do konkretów.',tone:'bold'),
        const RelationshipEventChoice(id:'wait',title:'Poczekaj',description:'Nie chcesz podejmować decyzji pod presją.',tone:'calm'),
        const RelationshipEventChoice(id:'close',title:'Zamknij temat',description:'Na razie zostajesz w klubie.',tone:'loyal'),
      ];
    } else if (target=='club') {
      title = stage==2 ? 'Klub odpowiada na Twoje stanowisko' : 'Dyrektor sportowy wraca do rozmowy';
      description = last=='leave' ? 'Klub chce ustalić, czy transfer jest jedynym rozwiązaniem.' : 'Klub przedstawia warunki dalszej współpracy.';
      choices = [
        const RelationshipEventChoice(id:'stay',title:'Zostań',description:'Potwierdzasz chęć kontynuowania kariery tutaj.',tone:'loyal'),
        const RelationshipEventChoice(id:'terms',title:'Postaw warunki',description:'Chcesz konkretnej roli i warunków.',tone:'bold'),
        const RelationshipEventChoice(id:'exit',title:'Podtrzymaj decyzję o odejściu',description:'Nie wycofujesz transfer request.',tone:'exit'),
      ];
    } else {
      title = stage==2 ? 'Druga fala medialna' : 'Media chcą domknięcia historii';
      description = 'Twoja poprzednia wypowiedź wywołała reakcję. Teraz możesz zakończyć temat albo go eskalować.';
      choices = [
        const RelationshipEventChoice(id:'clarify',title:'Doprecyzuj',description:'Uspokajasz sytuację i zamykasz temat.',tone:'calm'),
        const RelationshipEventChoice(id:'double_down',title:'Podtrzymaj stanowisko',description:'Bronisz swojej poprzedniej wypowiedzi.',tone:'bold'),
        const RelationshipEventChoice(id:'withdraw',title:'Wycofaj się z rozmów',description:'Nie chcesz dalej komentować.',tone:'quiet'),
      ];
    }
    return _scene(p,'chain_${chain['id']}_${stage}','${target}',title,description,day,choices,chainId:'${chain['id']}',stage:stage);
  }

  String _decisionFor(String k,int v){if(k=='agent'&&v>0)return 'welcome_interest';if(k=='club'&&v<0)return 'request_transfer';if(k=='club'&&v>0)return 'commit_club';if(k=='media'&&v<0)return 'limit_media';if(k=='media'&&v>0)return 'public_statement';if(k=='fans')return 'answer_on_pitch';return 'talk_club';}
  RelationshipEvent _scene(Player p,String id,String target,String title,String description,int day,List<RelationshipEventChoice> choices,{String? chainId,int stage=1})=>RelationshipEvent(id:'${id}_${p.id}_${day}_${_serial++}',playerId:p.id,target:target,title:title,description:description,createdAbsoluteDay:day,choices:choices,chainId:chainId ?? '${target}_${p.id}_${day}_${_serial}',stage:stage);
  Map<String,dynamic> toJson()=>{'serial':_serial,'pending':pending.map((e)=>e.toJson()).toList(),'lastGenerated':_lastGenerated,'chains':_chains};
  void restoreFromJson(Map<String,dynamic>? j){pending.clear();_lastGenerated.clear();_chains.clear();_serial=(j?['serial'] as int?)??0;final raw=j?['pending'];if(raw is List){for(final x in raw){if(x is Map)pending.add(RelationshipEvent.fromJson(Map<String,dynamic>.from(x)));}}final chains=j?['chains']; if(chains is Map){for(final e in chains.entries){if(e.value is Map)_chains[e.key.toString()]=Map<String,dynamic>.from(e.value);}} final lg=j?['lastGenerated'];if(lg is Map){for(final e in lg.entries){_lastGenerated[e.key.toString()]=e.value is int?e.value:int.tryParse('${e.value}')??0;}}}
}
