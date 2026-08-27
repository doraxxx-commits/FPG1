import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../models/club.dart';

class CareerScreen extends StatefulWidget {
  final GameEngine engine;

  const CareerScreen({
    super.key,
    required this.engine,
  });

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  GameEngine get engine => widget.engine;

  @override
  Widget build(BuildContext context) {
    final player = engine.careerPlayer;

    if (player == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF080A0F),
        appBar: AppBar(
          title: const Text('KARIERA'),
        ),
        body: const Center(
          child: Text(
            'Brak aktywnego zawodnika.',
          ),
        ),
      );
    }

    Club? playerClub;

    if (player.clubId != null) {
      try {
        playerClub = engine.clubs.firstWhere(
          (club) => club.id == player.clubId,
        );
      } catch (_) {
        playerClub = null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),

      appBar: AppBar(
        title: const Text('KARIERA'),
        backgroundColor: const Color(0xFF080A0F),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },

          child: ListView(
            padding: const EdgeInsets.all(16),

            children: [
              // ==================================================
              // ZAWODNIK
              // ==================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Row(
                    children: [
                      Container(
                        width: 82,
                        height: 82,

                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius:
                              BorderRadius.circular(18),
                        ),

                        child: Center(
                          child: Text(
                            '${player.overall}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Text(
                              player.fullName,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              '${_positionName(player.position)}'
                              ' • ${player.age} lat',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              playerClub?.name ??
                                  'Brak klubu',
                              style: const TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // FORMA / KONDYCJA / ZMĘCZENIE
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      title: 'FORMA',
                      value: player.form,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _statCard(
                      title: 'KONDYCJA',
                      value: player.fitness,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _statCard(
                      title: 'ZMĘCZENIE',
                      value: player.fatigue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==================================================
              // STATYSTYKI
              // ==================================================

              const Text(
                'STATYSTYKI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    children: [
                      _statRow(
                        'Występy',
                        player.careerAppearances
                            .toString(),
                      ),

                      _statRow(
                        'Gole',
                        player.careerGoals.toString(),
                      ),

                      _statRow(
                        'Asysty',
                        player.careerAssists.toString(),
                      ),

                      _statRow(
                        'OVR',
                        player.overall.toString(),
                      ),

                      _statRow(
                        'Potencjał',
                        player.potential.toString(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // KONTRAKT
              // ==================================================

              const Text(
                'KONTRAKT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: player.contract == null
                      ? const Text(
                          'Brak kontraktu.',
                        )
                      : Column(
                          children: [
                            _statRow(
                              'Klub',
                              playerClub?.name ??
                                  'Nieznany',
                            ),

                            _statRow(
                              'Numer',
                              player.contract!
                                  .squadNumber
                                  .toString(),
                            ),

                            _statRow(
                              'Pensja',
                              '${player.contract!.weeklySalary.toStringAsFixed(0)} zł / tydz.',
                            ),

                            _statRow(
                              'Wartość',
                              _formatMoney(
                                player.contract!
                                    .marketValue,
                              ),
                            ),

                            _statRow(
                              'Kontrakt',
                              '${player.contract!.yearsRemaining} lata',
                            ),

                            _statRow(
                              'Zaufanie trenera',
                              '${player.contract!.managerTrust}/100',
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // AKCJE
              // ==================================================

              const Text(
                'KARIERA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _actionButton(
                icon: Icons.fitness_center,
                title: 'TRENING',
                subtitle:
                    'Rozwijaj swoje umiejętności',
                onTap: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ekran treningu dodamy w kolejnym kroku.',
                      ),
                    ),
                  );
                },
              ),

              _actionButton(
                icon: Icons.sports_soccer,
                title: 'MECZE',
                subtitle:
                    'Sprawdź swoje występy',
                onTap: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Centrum meczowe dodamy później.',
                      ),
                    ),
                  );
                },
              ),

              _actionButton(
                icon: Icons.bar_chart,
                title: 'STATYSTYKI',
                subtitle:
                    'Zobacz szczegółowe statystyki',
                onTap: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Panel statystyk dodamy później.',
                      ),
                    ),
                  );
                },
              ),

              _actionButton(
                icon: Icons.swap_horiz,
                title: 'TRANSFERY',
                subtitle:
                    'Oferty innych klubów',
                onTap: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Rynek transferowy dodamy później.',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // DATA
              // ==================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        'DATA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        engine.currentDate,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KARTA STATYSTYKI
  // ============================================================

  Widget _statCard({
    required String title,
    required int value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),

        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIERSZ STATYSTYKI
  // ============================================================

  Widget _statRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRZYCISK AKCJI
  // ============================================================

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,

          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius:
                BorderRadius.circular(12),
          ),

          child: Icon(icon),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),

        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // POZYCJA
  // ============================================================

  String _positionName(dynamic position) {
    final name = position.toString().split('.').last;

    switch (name) {
      case 'goalkeeper':
        return 'BR';

      case 'defender':
        return 'OB';

      case 'midfielder':
        return 'POM';

      case 'winger':
        return 'SKR';

      case 'striker':
        return 'NAP';

      default:
        return name.toUpperCase();
    }
  }

  // ============================================================
  // PIENIĄDZE
  // ============================================================

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} mln zł';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} tys. zł';
    }

    return '${value.toStringAsFixed(0)} zł';
  }
}
