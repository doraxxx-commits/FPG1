import 'package:flutter/material.dart';

import '../core/fpg_theme.dart';
import '../core/game_engine.dart';
import '../models/player.dart';

/// V26 — developer-facing snapshot of the autonomous football world.
/// It is intentionally compact: the goal is to answer "czy świat żyje?"
/// without inventing another simulation layer.
class WorldSnapshotScreen extends StatefulWidget {
  final GameEngine engine;

  const WorldSnapshotScreen({super.key, required this.engine});

  @override
  State<WorldSnapshotScreen> createState() => _WorldSnapshotScreenState();
}

class _WorldSnapshotScreenState extends State<WorldSnapshotScreen> {
  GameEngine get engine => widget.engine;
  bool running = false;
  String auditMessage = 'Nie wykonano jeszcze testu długiej symulacji.';

  @override
  Widget build(BuildContext context) {
    final world = engine.worldEngine;
    final players = [...engine.players]
      ..sort((a, b) => b.value.compareTo(a.value));
    final scorers = [...engine.players]
      ..sort((a, b) => b.goals.compareTo(a.goals));
    final clubsWithManagers = engine.clubs.where((c) => c.managerName.isNotEmpty).length;
    final rosterLinks = engine.clubs.fold<int>(0, (sum, c) => sum + c.playerIds.length);
    final realRosterLinks = engine.players.where((p) {
      if (p.clubId == null) return false;
      return engine.clubs.any((c) => c.id == p.clubId && c.playerIds.contains(p.id));
    }).length;
    final rosterHealth = engine.players.isEmpty ? 0 : (realRosterLinks / engine.players.length * 100).round();
    final eventCount = world.worldEventHistory.length;
    final managerVariety = engine.clubs.map((c) => c.managerName).toSet().length;
    final score = _livingScore(
      rosterHealth: rosterHealth,
      managers: clubsWithManagers,
      events: eventCount,
      managerVariety: managerVariety,
      players: engine.players.length,
    );

    return Scaffold(
      backgroundColor: FPGTheme.bg,
      appBar: AppBar(title: const Text('WORLD SNAPSHOT — DEV')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(score, world.lastDaySummary),
          const SizedBox(height: 14),
          _section('ZDROWIE ŚWIATA'),
          _metricGrid([
            _metric('Kluby', '${engine.clubs.length}'),
            _metric('Zawodnicy', '${engine.players.length}'),
            _metric('Trenerzy', '$clubsWithManagers'),
            _metric('Historia', '$eventCount'),
            _metric('Spójność kadr', '$rosterHealth%'),
            _metric('Powiązania kadrowe', '$rosterLinks'),
          ]),
          const SizedBox(height: 14),
          _section('TEST ŻYJĄCEGO ŚWIATA — DEV'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auditMessage, style: const TextStyle(color: FPGTheme.muted)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _auditButton(context, 30, 'SYMULUJ 30 DNI'),
                      _auditButton(context, 90, 'SYMULUJ 90 DNI'),
                      _auditButton(context, 180, 'SYMULUJ 180 DNI'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Test nie rozgrywa meczu kariery gracza. Symuluje wyłącznie autonomiczny świat AI.', style: TextStyle(fontSize: 11, color: FPGTheme.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _section('OSTATNI TICK'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Mecze AI', '${world.lastDaySummary['matches'] ?? 0}'),
                  _row('Gole', '${world.lastDaySummary['goals'] ?? 0}'),
                  _row('Wydarzenia', '${world.lastDaySummary['events'] ?? 0}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _section('NAJWIĘKSZE WARTOŚCI'),
          ...players.take(5).map((p) => _playerRow(p, money: true)),
          const SizedBox(height: 14),
          _section('NAJLEPSI STRZELCY'),
          ...scorers.where((p) => p.goals > 0).take(5).map((p) => _playerRow(p)),
          const SizedBox(height: 14),
          _section('OSTATNIE WYDARZENIA ŚWIATA'),
          if (world.worldEventHistory.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Brak zapisanych wydarzeń.')))
          else
            ...world.worldEventHistory.reversed.take(12).map((e) => Card(
              child: ListTile(
                dense: true,
                leading: Icon(_iconFor(e.type)),
                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${e.day.toString().padLeft(2, '0')}.${e.month.toString().padLeft(2, '0')}.${e.year} • ${e.description}'),
              ),
            )),
        ],
      ),
    );
  }

  int _livingScore({required int rosterHealth, required int managers, required int events, required int managerVariety, required int players}) {
    final roster = rosterHealth.clamp(0, 100) * 0.35;
    final manager = players == 0 ? 0 : (managers / engine.clubs.length * 100).clamp(0, 100) * 0.15;
    final history = (events / 150.0).clamp(0, 1) * 100 * 0.20;
    final variety = engine.clubs.isEmpty ? 0 : (managerVariety / engine.clubs.length * 100).clamp(0, 100) * 0.15;
    final activity = ((engine.worldEngine.lastDaySummary['matches'] ?? 0) > 0 ? 15 : 0);
    return (roster + manager + history + variety + activity).round().clamp(0, 100);
  }

  Future<void> _runAudit(BuildContext context, int days) async {
    if (running) return;
    setState(() { running = true; auditMessage = 'Symuluję $days dni świata AI…'; });
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final beforeEvents = engine.worldEngine.worldEventHistory.length;
    final beforeTransfers = engine.worldEngine.worldEventHistory.where((e) => e.type == 'transfer').length;
    final beforeManagers = engine.worldEngine.worldEventHistory.where((e) => e.type == 'manager_change').length;
    final beforeTop = [...engine.players]..sort((a,b) => b.value.compareTo(a.value));
    final beforeValue = beforeTop.isEmpty ? 0 : beforeTop.first.value;

    engine.simulateWorldOnlyDays(days);

    final afterEvents = engine.worldEngine.worldEventHistory.length;
    final afterTransfers = engine.worldEngine.worldEventHistory.where((e) => e.type == 'transfer').length;
    final afterManagers = engine.worldEngine.worldEventHistory.where((e) => e.type == 'manager_change').length;
    final afterTop = [...engine.players]..sort((a,b) => b.value.compareTo(a.value));
    final afterValue = afterTop.isEmpty ? 0 : afterTop.first.value;
    final eventDelta = (afterEvents - beforeEvents).clamp(0, 999999);
    final transferDelta = (afterTransfers - beforeTransfers).clamp(0, 999999);
    final managerDelta = (afterManagers - beforeManagers).clamp(0, 999999);
    final valueDelta = afterValue - beforeValue;

    if (!mounted) return;
    setState(() {
      running = false;
      auditMessage = '+$days dni • +$eventDelta wydarzeń • +$transferDelta transferów • +$managerDelta zmian trenerów • lider rynku ${valueDelta >= 0 ? '+' : ''}${_money(valueDelta.toDouble())}';
    });
  }

  Widget _auditButton(BuildContext context, int days, String label) => FilledButton.tonal(
    onPressed: running ? null : () => _runAudit(context, days),
    child: Text(running ? '…' : label),
  );

  Widget _hero(int score, Map<String, int> summary) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(color: FPGTheme.accent, borderRadius: BorderRadius.circular(22)),
            child: Center(child: Text('$score', style: const TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('LIVING WORLD SCORE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(score >= 75 ? 'Świat wygląda aktywnie.' : score >= 50 ? 'Świat działa, ale wymaga dalszego spinania.' : 'Za mało realnej aktywności świata.', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Ostatni tick: ${summary['matches'] ?? 0} meczów • ${summary['events'] ?? 0} wydarzeń', style: const TextStyle(color: FPGTheme.muted)),
          ])),
        ],
      ),
    ),
  );

  Widget _metricGrid(List<Widget> items) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 2.25,
    children: items,
  );

  Widget _metric(String label, String value) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(color: FPGTheme.muted, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))])));

  Widget _playerRow(Player p, {bool money = false}) => Card(child: ListTile(title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${p.position.name} • OVR ${p.overall} • ${p.appearances} wyst. • ${p.goals} g • ${p.assists} a'), trailing: Text(money ? _money(p.value) : '${p.goals}', style: const TextStyle(fontWeight: FontWeight.w900, color: FPGTheme.accent))));

  Widget _row(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Text(a)), Text(b, style: const TextStyle(fontWeight: FontWeight.w800))]));

  Widget _section(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: FPGTheme.muted)));

  String _money(double value) {
    if (value >= 1000000) return '€${(value / 1000000).toStringAsFixed(1)}m';
    return '€${(value / 1000).toStringAsFixed(0)}k';
  }

  IconData _iconFor(String type) {
    if (type.contains('transfer')) return Icons.swap_horiz;
    if (type.contains('manager')) return Icons.manage_accounts;
    if (type.contains('contract')) return Icons.description;
    if (type.contains('match')) return Icons.sports_soccer;
    if (type.contains('relationship')) return Icons.people;
    return Icons.public;
  }
}
