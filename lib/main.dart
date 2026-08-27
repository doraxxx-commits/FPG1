import 'package:flutter/material.dart';

import 'core/game_engine.dart';
import 'core/fpg_theme.dart';
import 'models/player.dart';
import 'screens/create_player_screen.dart';
import 'screens/training_screen.dart';
import 'screens/player_profile_screen.dart';
import 'screens/club_selection_screen.dart';
import 'screens/career_home_screen.dart';

void main() {
  runApp(const FPGApp());
}

class FPGApp extends StatelessWidget {
  const FPGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FPG - Football Player Game',
      theme: FPGTheme.dark(),
      home: const FPGHomePage(),
    );
  }
}

class FPGHomePage extends StatefulWidget {
  const FPGHomePage({super.key});

  @override
  State<FPGHomePage> createState() => _FPGHomePageState();
}

class _FPGHomePageState extends State<FPGHomePage> {
  final GameEngine engine = GameEngine();

  // ============================================================
  // CZAS GRY
  // ============================================================

  void nextDay() {
    try {
      engine.advanceSimulationDay();
      if (!mounted) return;
      setState(() {});
    } catch (error, stack) {
      // Open-beta safety boundary: a faulty optional subsystem must not
      // terminate the Flutter process. The simulation error is logged and
      // the current screen remains usable.
      debugPrint('FPG simulation error: $error');
      debugPrint('$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się wykonać tego dnia. Stan gry pozostał otwarty.')),
      );
      setState(() {});
    }
  }

  // ============================================================
  // NOWA KARIERA
  // ============================================================

  void openCreatePlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlayerScreen(
          engine: engine,
        ),
      ),
    ).then((_) {
      setState(() {});

      // NAPRAWA: wcześniej po stworzeniu zawodnika appka po prostu
      // wracała na ten ekran, a wybór klubu (i cała reszta gry:
      // tabela ligi, drużyna, trener, transfery, newsy, mecze...)
      // nigdy nie był wywoływany — te ekrany istniały w kodzie,
      // ale nic do nich nie prowadziło.
      if (engine.careerPlayer != null &&
          engine.careerPlayer!.clubId == null) {
        openClubSelection();
      }
    });
  }

  // ============================================================
  // WYBÓR KLUBU
  // ============================================================

  void openClubSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubSelectionScreen(
          engine: engine,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  // ============================================================
  // GŁÓWNY HUB KARIERY (tabela ligi, drużyna, trener, transfery,
  // newsy, styl życia, mecze, rozwój zawodnika)
  // ============================================================

  void openCareerHome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareerHomeScreen(
          engine: engine,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  // ============================================================
  // TRENING
  // ============================================================

  void openTraining() {
    if (engine.careerPlayer == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingScreen(
          engine: engine,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final table = engine.leagueEngine.table;
    final player = engine.careerPlayer;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'FPG',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF080A0F),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            // ==================================================
            // LOGO
            // ==================================================

            const Text(
              'FPG',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'FOOTBALL PLAYER GAME',
              style: TextStyle(
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // INFORMACJE O SEZONIE
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'SEZON ${engine.currentSeason}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      engine.currentDate,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: nextDay,

                        child: const Text(
                          'NASTĘPNY DZIEŃ',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // NOWA KARIERA
            // ==================================================

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: openCreatePlayer,

                icon: const Icon(
                  Icons.person_add,
                ),

                label: const Text(
                  'NOWA KARIERA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // KARIERA — prowadzi do CareerHomeScreen, czyli huba
            // ze wszystkimi ekranami gry (tabela, drużyna, trener,
            // transfery, newsy, styl życia, mecze, rozwój).
            // Jeśli zawodnik nie ma jeszcze klubu, prowadzi do
            // wyboru klubu.
            // ==================================================

            if (engine.careerPlayer != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: engine.careerPlayer!.clubId == null
                      ? openClubSelection
                      : openCareerHome,
                  icon: const Icon(Icons.stadium),
                  label: Text(
                    engine.careerPlayer!.clubId == null
                        ? 'WYBIERZ KLUB'
                        : 'KONTYNUUJ KARIERĘ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: engine.careerPlayer == null
        ? null
        : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerProfileScreen(
                  engine: engine,
                ),
              ),
            );
          },
    child: const Text(
      'PROFIL ZAWODNIKA',
    ),
  ),
),
            const SizedBox(height: 12),

SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: engine.careerPlayer == null
        ? null
        : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrainingScreen(
                  engine: engine,
                ),
              ),
            );
          },
    child: const Text(
      'TRENING',
    ),
  ),
),

            // ==================================================
            // INFORMACJE O ZAWODNIKU
            // ==================================================

            if (player != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        player.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '${player.position.name.toUpperCase()}  •  '
                        'Wiek ${player.age}',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _playerInfo(
                              'OVR',
                              '${player.overall}',
                            ),
                          ),

                          Expanded(
                            child: _playerInfo(
                              'POT',
                              '${player.potential}',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _playerInfo(
                              'FITNESS',
                              '${player.fitness}',
                            ),
                          ),

                          Expanded(
                            child: _playerInfo(
                              'FORMA',
                              '${player.form}',
                            ),
                          ),

                          Expanded(
                            child: _playerInfo(
                              'ZMĘCZENIE',
                              '${player.fatigue}',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'PACE ${player.pace}  •  '
                        'SHO ${player.shooting}',
                      ),

                      Text(
                        'PAS ${player.passing}  •  '
                        'DRI ${player.dribbling}',
                      ),

                      Text(
                        'DEF ${player.defending}  •  '
                        'PHY ${player.physical}',
                      ),
                    ],
                  ),
                ),
              ),

            // ==================================================
            // TRENING
            // ==================================================

            if (player != null) ...[
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: openTraining,

                  icon: const Icon(
                    Icons.fitness_center,
                  ),

                  label: const Text(
                    'TRENING',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ==================================================
            // DZISIEJSZE MECZE
            // ==================================================

            const Text(
              'DZISIAJ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (engine.todayFixtures.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),

                  child: Text(
                    'Brak meczów zaplanowanych na dzisiaj.',
                  ),
                ),
              ),

            ...engine.todayFixtures.map((fixture) {
              final homeMatches = engine.clubs.where((club) => club.id == fixture.homeClubId).toList();
              final awayMatches = engine.clubs.where((club) => club.id == fixture.awayClubId).toList();
              if (homeMatches.isEmpty || awayMatches.isEmpty) {
                return const SizedBox.shrink();
              }
              final home = homeMatches.first;
              final away = awayMatches.first;

              return Card(
                child: ListTile(
                  title: Text(
                    '${home.name}  '
                    '${fixture.homeGoals ?? '-'} : '
                    '${fixture.awayGoals ?? '-'}  '
                    '${away.name}',
                  ),

                  subtitle: Text(
                    fixture.played
                        ? 'Mecz zakończony'
                        : 'Mecz zaplanowany',
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ==================================================
            // NASTĘPNE MECZE
            // ==================================================

            const Text(
              'NASTĘPNE MECZE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...engine.upcomingFixtures
                .take(5)
                .map((fixture) {
              final homeMatches = engine.clubs.where((club) => club.id == fixture.homeClubId).toList();
              final awayMatches = engine.clubs.where((club) => club.id == fixture.awayClubId).toList();
              if (homeMatches.isEmpty || awayMatches.isEmpty) {
                return const SizedBox.shrink();
              }
              final home = homeMatches.first;
              final away = awayMatches.first;

              return Card(
                child: ListTile(
                  title: Text(
                    '${home.name} vs ${away.name}',
                  ),

                  subtitle: Text(
                    '${fixture.day.toString().padLeft(2, '0')}.'
                    '${fixture.month.toString().padLeft(2, '0')}.'
                    '${fixture.year}',
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ==================================================
            // TABELA EKSTRAKLASY
            // ==================================================

            const Text(
              'EKSTRAKLASA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...List.generate(
              table.length,
              (index) {
                final standing =
                    table[index];

                final clubMatches = engine.clubs.where((club) => club.id == standing.clubId).toList();
                if (clubMatches.isEmpty) {
                  return const SizedBox.shrink();
                }
                final club = clubMatches.first;

                return Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 30,

                      child: Text(
                        '${index + 1}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    title: Text(
                      club.name,
                    ),

                    subtitle: Text(
                      'OVR ${club.overall}  •  '
                      '${standing.played} meczów',
                    ),

                    trailing: Text(
                      '${standing.points} pkt',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAŁY WIDGET INFORMACJI O ZAWODNIKU
  // ============================================================

  Widget _playerInfo(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
