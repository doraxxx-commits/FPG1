import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../core/fpg_theme.dart';

class RelationshipWebScreen extends StatefulWidget {
  final GameEngine engine;
  const RelationshipWebScreen({super.key, required this.engine});
  @override State<RelationshipWebScreen> createState() => _RelationshipWebScreenState();
}

class _RelationshipWebScreenState extends State<RelationshipWebScreen> {
  GameEngine get engine => widget.engine;
  dynamic get player => engine.careerPlayer == null ? null : engine.players.where((p) => p.id == engine.careerPlayer!.id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final p = player;
    if (p == null) return const Scaffold(body: Center(child: Text('Brak aktywnej kariery.')));
    final r = engine.worldEngine.relationshipWebEngine.forPlayer(p);
    return Scaffold(
      backgroundColor: FPGTheme.bg,
      appBar: AppBar(title: const Text('Relationship Web')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _hero(r), const SizedBox(height: 16),
        _card('AGENT', Icons.business_center_outlined, r.agent, 'Siła zaufania i współpracy z agentem.'),
        _card('TRENER', Icons.sports, r.coach, 'Zaufanie trenera, rola w składzie i codzienna komunikacja.'),
        _card('KLUB', Icons.stadium_outlined, r.club, 'Relacja z klubem, zarządem i otoczeniem zawodnika.'),
        _card('KIBICE', Icons.groups_outlined, r.fans, 'Wsparcie trybun i tolerancja na słabsze momenty.'),
        _card('MEDIA', Icons.newspaper_outlined, r.media, 'Relacja z mediami i siła narracji wokół zawodnika.'),
        const SizedBox(height: 18),
        const Text('OSTATNIE ZMIANY', style: TextStyle(color: FPGTheme.muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        if (r.history.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Brak zmian. Relacje będą rozwijać się wraz z karierą.'))),
        ...r.history.reversed.take(10).map((h) => Card(child: ListTile(
          leading: Icon(h.delta >= 0 ? Icons.trending_up : Icons.trending_down, color: h.delta >= 0 ? FPGTheme.accent : Colors.redAccent),
          title: Text('${h.target.toUpperCase()}  ${h.delta > 0 ? '+' : ''}${h.delta}', style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(h.reason),
        ))),
      ]),
    );
  }

  Widget _hero(dynamic r) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors:[Color(0xFF18212B),Color(0xFF0E1218)]),borderRadius: BorderRadius.circular(24)),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RELATIONSHIP WEB', style: TextStyle(color:FPGTheme.muted,fontSize:11,fontWeight:FontWeight.w900,letterSpacing:1.3)),
      SizedBox(height:7), Text('Twoja kariera to sieć relacji.', style: TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
      SizedBox(height:6), Text('Decyzje budują sojusze, konflikty i reputację.', style: TextStyle(color:Colors.white70)),
    ]),
  );

  Widget _card(String title, IconData icon, int value, String description) => Card(
    margin: const EdgeInsets.only(bottom:10),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
      Row(children:[Icon(icon,color:FPGTheme.accent),const SizedBox(width:10),Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),const Spacer(),Text('$value/100',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))]),
      const SizedBox(height:8), Text(description,style:const TextStyle(color:Colors.white70)),
      const SizedBox(height:10), ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:value/100.0,minHeight:8,backgroundColor:Colors.white10)),
    ])),
  );
}
