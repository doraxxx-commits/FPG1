import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/game_engine.dart';
import '../core/fpg_theme.dart';
import 'league_table_screen.dart';
import 'lifestyle_screen.dart';
import 'manager_screen.dart';
import 'match_screen.dart';
import 'news_screen.dart';
import 'player_development_screen.dart';
import 'player_profile_screen.dart';
import 'team_screen.dart';
import 'training_screen.dart';
import 'transfers_screen.dart';
import 'career_decision_center_screen.dart';
import 'career_storylines_screen.dart';
import 'relationship_web_screen.dart';
import 'relationship_actions_screen.dart';
import 'relationship_events_screen.dart';
import 'world_snapshot_screen.dart';
import 'season_overview_screen.dart';

class CareerHomeScreen extends StatefulWidget {
  final GameEngine engine;
  const CareerHomeScreen({super.key, required this.engine});
  @override State<CareerHomeScreen> createState() => _CareerHomeScreenState();
}

class _CareerHomeScreenState extends State<CareerHomeScreen> {
  GameEngine get engine => widget.engine;
  int tab = 0;

  void open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final player = engine.careerPlayer;
    if (player == null || player.contract == null) {
      return const Scaffold(body: Center(child: Text('Brak aktywnej kariery.')));
    }
    final contract = player.contract!;
    final clubMatches = engine.clubs.where((c) => c.id == player.clubId).toList();
    if (clubMatches.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Nie znaleziono klubu zawodnika.')),
      );
    }
    final club = clubMatches.first;

    final pages = [
      _dashboard(player, contract, club),
      _worldHub(),
      _careerHub(),
      _profile(player, club),
    ];

    return Scaffold(
      backgroundColor: FPGTheme.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: FPGTheme.accent, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.sports_soccer, color: Colors.black, size: 20)),
          const SizedBox(width: 10),
          const Text('FPG'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: () async {
            HapticFeedback.lightImpact();
            final ok = await engine.saveWorld();
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Gra zapisana' : 'Błąd zapisu')));
          }),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          if (i != tab) HapticFeedback.selectionClick();
          setState(() => tab = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Start'),
          NavigationDestination(icon: Icon(Icons.public_outlined), selectedIcon: Icon(Icons.public), label: 'Świat'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Kariera'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _dashboard(dynamic player, dynamic contract, dynamic club) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    _hero(player, club),
    const SizedBox(height: 12),
    _careerStatusStrip(player, club),
    const SizedBox(height: 18),
    _section('NAJBLIŻSZY MECZ'),
    _matchCard(club),
    const SizedBox(height: 12),
    _continueDayCard(),
    const SizedBox(height: 18),
    _section('FORMA I STATUS'),
    Row(children: [Expanded(child: _metric('FORMA', '${player.form}', Icons.trending_up)), const SizedBox(width: 10), Expanded(child: _metric('KONDYCJA', '${player.fitness}', Icons.bolt)), const SizedBox(width: 10), Expanded(child: _metric('MORALE', '${player.morale}', Icons.mood))]),
    const SizedBox(height: 18),
    _section('DZISIAJ'),
    _todayActionBanner(),
    _actionTile(Icons.fitness_center, 'Trening', engine.dailyCareerActionConsumed ? 'Dzisiejsza akcja została już wykonana' : 'Popraw rozwój i walcz o skład', engine.dailyCareerActionConsumed ? null : () => open(TrainingScreen(engine: engine))),
    _actionTile(Icons.newspaper_outlined, 'FPG News', 'Co dzieje się w świecie futbolu', () => open(NewsScreen(engine: engine))),
    _actionTile(Icons.hub_outlined, 'Centrum decyzji', 'Transfery, kontrakty, media i sponsorzy', () => open(CareerDecisionCenterScreen(engine: engine))),
  ]);


  Widget _careerStatusStrip(dynamic player, dynamic club) {
    final season = engine.currentSeason;
    final next = engine.nextCareerFixture;
    final matchText = next == null
        ? 'Brak kolejnego meczu'
        : engine.careerHasMatchToday
            ? 'Mecz dzisiaj'
            : 'Najbliższy mecz za ${_daysUntil(next)} dni';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: FPGDecor.glowCard(),
      child: Row(children: [
        const Icon(Icons.calendar_month_rounded, size: 18, color: FPGTheme.accent),
        const SizedBox(width: 10),
        Expanded(child: Text('SEZON $season  •  $matchText', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70))),
        Text('DZIŚ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: FPGTheme.accent.withOpacity(.9))),
      ]),
    );
  }

  int _daysUntil(dynamic fixture) {
    try {
      final today = DateTime(engine.gameState.year, engine.gameState.month, engine.gameState.day).difference(DateTime(engine.gameState.year, 1, 1)).inDays;
      final targetDate = DateTime(fixture.year, fixture.month, fixture.day);
      final todayDate = DateTime(engine.gameState.year, engine.gameState.month, engine.gameState.day);
      return targetDate.difference(DateTime(todayDate.year, todayDate.month, todayDate.day)).inDays.clamp(0, 999);
    } catch (_) {
      return 0;
    }
  }

  Widget _todayActionBanner() {
    final consumed = engine.dailyCareerActionConsumed;
    final label = engine.dailyCareerAction == 'training'
        ? 'TRENING WYKONANY'
        : engine.dailyCareerAction == 'match'
            ? 'MECZ ROZEGRANY'
            : 'WYBIERZ AKCJĘ DNIA';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(consumed ? Icons.check_circle : Icons.today, color: FPGTheme.accent),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
          if (consumed) const Text('GOTOWE', style: TextStyle(color: FPGTheme.muted, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _worldHub() => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    _title('Świat futbolu', 'Świat działa również bez Ciebie.'),
    _worldCard(Icons.newspaper, 'Wiadomości', 'Transfery, trenerzy, kryzysy i wydarzenia', () => open(NewsScreen(engine: engine))),
    _worldCard(Icons.swap_horiz, 'Transfery', 'Rynek zawodników i ruchy klubów', () => open(TransfersScreen(engine: engine))),
    _worldCard(Icons.leaderboard, 'Tabele', 'Formy lig i walka o awans', () => open(LeagueTableScreen(engine: engine))),
    _worldCard(Icons.groups, 'Klub', 'Kadra, relacje i atmosfera', () => open(TeamScreen(engine: engine))),
    _worldCard(Icons.manage_accounts, 'Trener', 'Zaufanie, decyzje i hierarchia', () => open(ManagerScreen(engine: engine))),
    _worldCard(Icons.monitor_heart_outlined, 'World Snapshot — DEV', 'Stan świata, aktywność AI, kadry i historia wydarzeń', () => open(WorldSnapshotScreen(engine: engine))),
  ]);

  Widget _careerHub() => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    _title('Kariera', 'Decyzje, które zmieniają Twoją ścieżkę.'),
    _worldCard(Icons.sports_soccer, 'Mecz', 'Rozegraj kolejkę i wpływaj na wynik', () => open(MatchScreen(engine: engine))),
    _worldCard(Icons.emoji_events_outlined, 'Sezon', 'Tabela, cel klubu i postęp sezonu', () => open(SeasonOverviewScreen(engine: engine))),
    _worldCard(Icons.fitness_center, 'Trening', 'Rozwijaj atrybuty i potencjał', () => open(TrainingScreen(engine: engine))),
    _worldCard(Icons.auto_graph, 'Rozwój', 'OVR, potencjał i progres', () => open(PlayerDevelopmentScreen(engine: engine))),
    _worldCard(Icons.favorite, 'Życie', 'Relacje i decyzje poza boiskiem', () => open(LifestyleScreen(engine: engine))),
    _worldCard(Icons.swap_horiz, 'Transfery', 'Zainteresowanie klubów i negocjacje', () => open(TransfersScreen(engine: engine))),
    _worldCard(Icons.hub_outlined, 'Centrum decyzji', 'Wszystkie ważne decyzje kariery w jednym miejscu', () => open(CareerDecisionCenterScreen(engine: engine))),
    _worldCard(Icons.auto_stories_outlined, 'Historie kariery', 'Wielostopniowe wydarzenia i ich zakończenia', () => open(CareerStorylinesScreen(engine: engine))),
    _worldCard(Icons.hub_outlined, 'Sieć relacji', 'Agent, trener, klub, kibice i media', () => open(RelationshipWebScreen(engine: engine))),
    _worldCard(Icons.bolt_outlined, 'Akcje relacji', 'Wykorzystaj zaufanie i odblokowane możliwości', () => open(RelationshipActionsScreen(engine: engine))),
    _worldCard(Icons.forum_outlined, 'Wydarzenia relacji', 'Rozmowy, telefony i sytuacje wymagające decyzji', () => open(RelationshipEventsScreen(engine: engine))),
  ]);

  Widget _profile(dynamic player, dynamic club) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    _hero(player, club),
    const SizedBox(height: 16),
    _section('STATYSTYKI KARIERY'),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
      _row('Występy', '${player.careerAppearances}'),
      _row('Gole', '${player.careerGoals}'),
      _row('Asysty', '${player.careerAssists}'),
      _row('Wartość', '${(player.contract?.marketValue ?? 0).toStringAsFixed(0)} zł'),
    ]))),
    const SizedBox(height: 16),
    _worldCard(Icons.person, 'Pełny profil', 'Atrybuty, kontrakt i historia zawodnika', () => open(PlayerProfileScreen(engine: engine))),
  ]);

  Widget _hero(dynamic player, dynamic club) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18212B),
            Color(0xFF0E1218),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.name,
                      style: const TextStyle(color: FPGTheme.muted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_position(player.position)} • ${player.age} lat',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: FPGTheme.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${player.overall}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _mini('FORMA', '${player.form}')),
              const SizedBox(width: 8),
              Expanded(child: _mini('MORALE', '${player.morale}')),
              const SizedBox(width: 8),
              Expanded(
                child: _mini(
                  'NR',
                  '#${player.contract?.squadNumber ?? '-'}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _matchCard(dynamic club) {
    final fixture = engine.nextCareerFixture;
    if (fixture == null) {
      return Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: const [
        Icon(Icons.event_available, color: FPGTheme.accent), SizedBox(width: 12),
        Expanded(child: Text('Brak kolejnych spotkań w terminarzu.', style: TextStyle(fontWeight: FontWeight.w700))),
      ])));
    }
    final isHome = fixture.homeClubId == club.id;
    final opponentId = isHome ? fixture.awayClubId : fixture.homeClubId;
    final opponent = engine.clubs.firstWhere((c) => c.id == opponentId, orElse: () => club);
    final today = engine.careerHasMatchToday;
    final date = '${fixture.day.toString().padLeft(2, '0')}.${fixture.month.toString().padLeft(2, '0')}';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: today ? () => open(MatchScreen(engine: engine)) : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: FPGTheme.accent.withOpacity(.14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.sports_soccer, color: FPGTheme.accent)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(today ? 'DZISIAJ' : 'NASTĘPNY MECZ • $date', style: const TextStyle(color: FPGTheme.muted, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('${isHome ? 'DOM' : 'WYJAZD'} • ${opponent.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(today ? 'Rozegraj mecz' : 'Mecz pojawi się w centrum dnia', style: const TextStyle(color: Colors.white60)),
            ])),
            Icon(today ? Icons.play_arrow_rounded : Icons.lock_clock, size: 22, color: today ? FPGTheme.accent : Colors.white38),
          ]),
        ),
      ),
    );
  }

  Widget _continueDayCard() => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticFeedback.mediumImpact();
        engine.advanceSimulationDay();
        if (mounted) setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.fast_forward_rounded, color: FPGTheme.accent)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('KONTYNUUJ DZIEŃ', style: TextStyle(fontWeight: FontWeight.w900)),
            SizedBox(height: 3),
            Text('Przejdź do kolejnego dnia kariery', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ])),
          const Icon(Icons.arrow_forward_ios, size: 14, color: FPGTheme.accent),
        ]),
      ),
    ),
  );

  Widget _metric(String label, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 18, color: FPGTheme.accent), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: FPGTheme.muted, fontSize: 10, fontWeight: FontWeight.w700))])));
  Widget _mini(String label, String value) => Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity( .055), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: FPGTheme.muted, fontSize: 9))]));
  Widget _section(String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: const TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: Colors.white70)));
  Widget _title(String t, String sub) => Padding(padding: const EdgeInsets.only(bottom: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(sub, style: const TextStyle(color: FPGTheme.muted))]));
  Widget _worldCard(IconData icon, String title, String sub, VoidCallback? onTap) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: FPGTheme.accent.withOpacity(.10), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: FPGTheme.accent)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub, style: const TextStyle(color: FPGTheme.muted)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap == null ? null : () { HapticFeedback.selectionClick(); onTap(); },
    ),
  );
  Widget _actionTile(IconData icon, String title, String sub, VoidCallback? onTap) => _worldCard(icon, title, sub, onTap);
  Widget _row(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: const TextStyle(color: FPGTheme.muted)), Text(b, style: const TextStyle(fontWeight: FontWeight.w800))]));
  String _position(dynamic p) => p.toString().split('.').last.toUpperCase();
}
