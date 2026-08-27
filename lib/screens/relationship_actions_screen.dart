import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../core/fpg_theme.dart';
import '../models/relationship_action.dart';
import '../models/world_event.dart';
import 'relationship_events_screen.dart';

class RelationshipActionsScreen extends StatefulWidget {
  final GameEngine engine;
  const RelationshipActionsScreen({super.key, required this.engine});
  @override State<RelationshipActionsScreen> createState() => _RelationshipActionsScreenState();
}

class _RelationshipActionsScreenState extends State<RelationshipActionsScreen> {
  GameEngine get engine => widget.engine;

  dynamic get player {
    final career = engine.careerPlayer;
    if (career == null) return null;
    for (final p in engine.players) {
      if (p.id == career.id) return p;
    }
    return null;
  }

  int get absoluteDay => DateTime(engine.gameState.year, engine.gameState.month, engine.gameState.day)
      .difference(DateTime(2026, 1, 1)).inDays;

  @override
  Widget build(BuildContext context) {
    final p = player;
    if (p == null) return const Scaffold(body: Center(child: Text('Brak aktywnej kariery.')));
    final web = engine.worldEngine.relationshipWebEngine;
    final r = web.forPlayer(p);
    final actions = engine.worldEngine.relationshipActionsEngine.availableActions(
      p: p, r: r, absoluteDay: absoluteDay,
    );

    return Scaffold(
      backgroundColor: FPGTheme.bg,
      appBar: AppBar(title: const Text('Relacje • Akcje')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _hero(r, actions.length),
        const SizedBox(height: 18),
        if (actions.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: const [
            Icon(Icons.hourglass_empty, size: 38, color: FPGTheme.muted),
            SizedBox(height: 10),
            Text('Brak dostępnych akcji', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('Wzmocnij relacje albo poczekaj na zakończenie cooldownów.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
          ]))),
        ...actions.map((a) => _actionCard(context, p, a)),
      ]),
    );
  }

  Widget _hero(dynamic r, int count) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF241A36), Color(0xFF0E1218)]),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('RELATIONSHIP ACTIONS', style: TextStyle(color: FPGTheme.muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
      const SizedBox(height: 7),
      const Text('Relacje otwierają możliwości.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('$count dostępnych akcji • Agent ${r.agent} • Trener ${r.coach} • Klub ${r.club} • Kibice ${r.fans} • Media ${r.media}', style: const TextStyle(color: Colors.white70)),
    ]),
  );

  Widget _actionCard(BuildContext context, dynamic p, RelationshipAction a) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _execute(context, p, a),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: FPGTheme.accent.withOpacity( .12), borderRadius: BorderRadius.circular(14)), child: Icon(_icon(a.icon), color: FPGTheme.accent)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 5),
          Text(a.description, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 7),
          Text('${a.relationship.toUpperCase()} • MIN. ${a.minValue}', style: const TextStyle(color: FPGTheme.muted, fontSize: 10, fontWeight: FontWeight.w800)),
        ])),
        const Icon(Icons.arrow_forward_ios, size: 15, color: FPGTheme.accent),
      ])),
    ),
  );

  Future<void> _execute(BuildContext context, dynamic p, RelationshipAction a) async {
    final now = engine.gameState;
    final absolute = DateTime(now.year, now.month, now.day).difference(DateTime(2026, 1, 1)).inDays;
    final result = engine.worldEngine.relationshipActionsEngine.execute(
      p: p,
      relationshipWeb: engine.worldEngine.relationshipWebEngine,
      actionId: a.id,
      absoluteDay: absolute,
      year: now.year,
      month: now.month,
      day: now.day,
    );
    if (result.success) {
      // Keep the action visible to the same News/World pipeline without
      // advancing the calendar a second time.
      final e = WorldEvent(
        year: now.year,
        month: now.month,
        day: now.day,
        type: 'relationship_action',
        title: result.title,
        description: result.description,
        playerId: p.id,
        clubId: p.clubId,
        importance: 3,
      );
      engine.worldEngine.lastDayEvents.add(e);
      engine.worldEngine.worldEventHistory.add(e);
      engine.worldEngine.worldEventEngine.absorbExternalEvents([e]);
      final scene = engine.worldEngine.relationshipEventsEngine.createFromAction(p: p, actionId: a.id, absoluteDay: absolute);
      if (scene != null && context.mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => RelationshipEventsScreen(engine: engine)));
      }
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.description)));
  }

  IconData _icon(String icon) => switch (icon) {
    'coach' => Icons.sports,
    'role' => Icons.star_outline,
    'agent' => Icons.business_center_outlined,
    'target' => Icons.gps_fixed,
    'club' => Icons.stadium_outlined,
    'shield' => Icons.shield_outlined,
    'fans' => Icons.groups_outlined,
    'media' => Icons.newspaper_outlined,
    'quiet' => Icons.volume_off_outlined,
    _ => Icons.hub_outlined,
  };
}
