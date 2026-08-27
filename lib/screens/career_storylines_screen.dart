import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../core/fpg_theme.dart';
import '../models/career_storyline.dart';
import '../models/career_storyline_choice.dart';

class CareerStorylinesScreen extends StatefulWidget {
  final GameEngine engine;
  const CareerStorylinesScreen({super.key, required this.engine});
  @override State<CareerStorylinesScreen> createState() => _CareerStorylinesScreenState();
}

class _CareerStorylinesScreenState extends State<CareerStorylinesScreen> {
  GameEngine get engine => widget.engine;
  dynamic get player => engine.careerPlayer == null ? null : engine.players.where((p) => p.id == engine.careerPlayer!.id).firstOrNull;

  String stageText(CareerStoryline s) {
    switch (s.type) {
      case 'contract_crisis': return ['Napięcie', 'Eskalacja', 'Ultimatum'][s.stage.clamp(0, 2)];
      case 'transfer_saga': return ['Zainteresowanie', 'Presja', 'Konkretna oferta'][s.stage.clamp(0, 2)];
      case 'media_spotlight': return ['Rozpoznawalność', 'Pod lupą', 'Koszt sławy'][s.stage.clamp(0, 2)];
      default: return 'Etap ${s.stage + 1}';
    }
  }

  Future<void> choose(CareerStoryline s) async {
    final p = player;
    if (p == null) return;
    final choices = engine.worldEngine.careerStorylineEngine.choicesFor(s, p);
    final selected = await showModalBottomSheet<CareerStorylineChoice>(
      context: context,
      backgroundColor: FPGTheme.bg,
      isScrollControlled: true,
      builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 12), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DECYZJA', style: TextStyle(color: FPGTheme.muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 6), Text(s.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 14),
        ...choices.map((c) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(c.description)), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.pop(context, c))),),
      ]))),
    );
    if (selected == null) return;
    final absoluteDay = engine.worldEngine.absoluteDayForDate(engine.state.year, engine.state.month, engine.state.day);
    final ok = engine.worldEngine.careerStorylineEngine.choose(s, selected.id, p, absoluteDay: absoluteDay);
    if (!ok) return;
    final relationshipEvents = engine.worldEngine.relationshipWebEngine.applyDecision(
      p: p, decision: selected.id, absoluteDay: absoluteDay,
      year: engine.state.year, month: engine.state.month, day: engine.state.day,
    );
    engine.worldEngine.lastDayEvents.addAll(relationshipEvents);
    engine.worldEngine.worldEventHistory.addAll(relationshipEvents);
    engine.worldEngine.worldEventEngine.absorbExternalEvents(relationshipEvents);
    final event = engine.worldEngine.worldEventForPlayer(type: 'career_story_choice', title: 'Decyzja w historii kariery', description: '${p.name}: ${s.title} → ${selected.title}', playerId: p.id, importance: selected.tone == 'danger' ? 5 : 3);
    engine.worldEngine.lastDayEvents.add(event); engine.worldEngine.worldEventHistory.add(event); engine.worldEngine.worldEventEngine.absorbExternalEvents([event]);
    setState(() {});
  }

  @override Widget build(BuildContext context) {
    final p = player;
    if (p == null) return const Scaffold(body: Center(child: Text('Brak aktywnej kariery.')));
    final active = engine.worldEngine.careerStorylineEngine.active.where((s) => s.playerId == p.id && !s.completed).toList();
    final done = engine.worldEngine.careerStorylineEngine.completed.where((s) => s.playerId == p.id).toList().reversed.toList();
    return Scaffold(
      backgroundColor: FPGTheme.bg,
      appBar: AppBar(title: const Text('Historie kariery')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _hero(active.length),
        const SizedBox(height: 18),
        if (active.isEmpty) _empty(),
        ...active.map(_activeCard),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 12), const Text('ZAKOŃCZONE HISTORIE', style: TextStyle(color: FPGTheme.muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const SizedBox(height: 8),
          ...done.take(8).map(_completedCard),
        ],
      ]),
    );
  }

  Widget _hero(int count) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors:[Color(0xFF18212B),Color(0xFF0E1218)]),borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[const Text('CAREER STORIES',style:TextStyle(color:FPGTheme.muted,fontSize:11,fontWeight:FontWeight.w900,letterSpacing:1.3)),const SizedBox(height:7),const Text('Twoja kariera ma pamięć i wybór.',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text('$count aktywnych historii • wybory zmieniają kolejne etapy',style:const TextStyle(color:Colors.white70))]));
  Widget _empty() => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: const [Icon(Icons.auto_stories_outlined,size:42,color:FPGTheme.accent),SizedBox(height:10),Text('BRAK AKTYWNYCH HISTORII',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:5),Text('Świat obserwuje Twoją karierę. Kolejne wydarzenia mogą rozpocząć nową historię.',textAlign:TextAlign.center,style:TextStyle(color:FPGTheme.muted))])));
  Widget _activeCard(CareerStoryline s) => Card(margin: const EdgeInsets.only(bottom:12), child: Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.auto_stories,color:FPGTheme.accent),const SizedBox(width:10),Expanded(child:Text(s.title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))),Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:FPGTheme.accent.withOpacity(.12),borderRadius:BorderRadius.circular(9)),child:Text(stageText(s),style:const TextStyle(color:FPGTheme.accent,fontSize:10,fontWeight:FontWeight.w900)))]),const SizedBox(height:10),Text(_description(s),style:const TextStyle(color:Colors.white70)),const SizedBox(height:12),Text('Etap ${s.stage + 1} • decyzje zależą od aktualnej sytuacji zawodnika',style:const TextStyle(color:FPGTheme.muted,fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:12),SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>choose(s),icon:const Icon(Icons.forum_outlined),label:const Text('PODEJMIJ DECYZJĘ'),style:OutlinedButton.styleFrom(backgroundColor:FPGTheme.accent,foregroundColor:Colors.black)))])));
  String _description(CareerStoryline s) { if(s.type=='contract_crisis') return 'Kontrakt, relacja z klubem i oczekiwania agenta tworzą historię, która może zakończyć się nową umową albo transferem.'; if(s.type=='transfer_saga') return 'Zainteresowanie rynku rośnie etapami. Kolejna oferta, presja mediów i decyzje agenta mogą zmienić przyszłość zawodnika.'; return 'Popularność rośnie, ale każdy kolejny występ zwiększa oczekiwania. Możesz ograniczyć medialny szum albo dalej budować markę.'; }
  Widget _completedCard(CareerStoryline s) => Card(child:ListTile(leading:const Icon(Icons.history,color:FPGTheme.muted),title:Text(s.title),subtitle:Text('Zakończenie: ${s.outcome ?? '—'}')));
}
