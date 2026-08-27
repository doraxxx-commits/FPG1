import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../simulation/season_overview_engine.dart';

class SeasonOverviewScreen extends StatelessWidget {
  final GameEngine engine;
  const SeasonOverviewScreen({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final overview = SeasonOverviewEngine().build(engine);
    final club = engine.careerClub;
    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      appBar: AppBar(title: const Text('Sezon'), backgroundColor: const Color(0xFF080A0F)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(overview, club?.name ?? 'Brak klubu'),
          const SizedBox(height: 14),
          _card('CEL ZARZĄDU', overview.objective, Icons.flag_rounded),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('POSTĘP SEZONU', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: overview.seasonProgress, minHeight: 8),
                const SizedBox(height: 10),
                Text('${overview.completedMatches} rozegranych • ${overview.remainingMatches} pozostało', style: const TextStyle(color: Colors.white60)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                _row('Pozycja', overview.position == 0 ? '—' : '${overview.position}. / ${overview.clubCount}'),
                _row('Punkty', '${overview.standing.points}'),
                _row('Bilans', '${overview.standing.wins}-${overview.standing.draws}-${overview.standing.losses}'),
                _row('Bramki', '${overview.standing.goalsFor}:${overview.standing.goalsAgainst}'),
                _row('Różnica', '${overview.standing.goalDifference >= 0 ? '+' : ''}${overview.standing.goalDifference}'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Icon(overview.objectiveMet ? Icons.check_circle : Icons.trending_up, color: overview.objectiveMet ? Colors.greenAccent : Colors.white70),
                const SizedBox(width: 12),
                Expanded(child: Text(overview.objectiveMet ? 'Cel jest obecnie realizowany.' : 'Cel jest jeszcze poza zasięgiem — sezon trwa.', style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(SeasonOverview o, String club) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF18212B), Color(0xFF0E1218)])),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${o.season}/${o.season + 1}', style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(club, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      Row(children: [
        Text(o.position == 0 ? '—' : '${o.position}.', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
        const SizedBox(width: 12),
        const Text('miejsce w lidze', style: TextStyle(color: Colors.white60)),
      ]),
    ]),
  );

  Widget _card(String title, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(icon, color: Colors.white70), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))]))])));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white54)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]));
}
