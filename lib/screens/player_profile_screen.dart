import 'package:flutter/material.dart';

import '../core/game_engine.dart';

class PlayerProfileScreen extends StatelessWidget {
  final GameEngine engine;

  const PlayerProfileScreen({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final player = engine.careerPlayer;

    if (player == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PROFIL ZAWODNIKA'),
        ),
        body: const Center(
          child: Text(
            'Brak utworzonego zawodnika.',
          ),
        ),
      );
    }

    final club = player.clubId == null
        ? null
        : engine.clubs.where((club) => club.id == player.clubId).isEmpty
            ? null
            : engine.clubs.firstWhere((club) => club.id == player.clubId);

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),

      appBar: AppBar(
        title: const Text('PROFIL ZAWODNIKA'),
        backgroundColor: const Color(0xFF080A0F),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [

            // ==================================================
            // NAGŁÓWEK
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [

                    CircleAvatar(
                      radius: 42,
                      child: Text(
                        player.overall.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      player.fullName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      player.position.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      club?.name ?? 'BRAK KLUBU',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PODSTAWOWE INFORMACJE
            // ==================================================

            _sectionTitle('INFORMACJE'),

            _infoCard([
              _infoRow('Narodowość', player.nationality),
              _infoRow('Wiek', '${player.age} lat'),
              _infoRow('Wzrost', '${player.height} cm'),
              _infoRow(
                'Pozycja',
                player.position.name.toUpperCase(),
              ),
              _infoRow(
                'Numer',
                player.shirtNumber.toString(),
              ),
              _infoRow(
                'OVR',
                player.overall.toString(),
              ),
              _infoRow(
                'Potencjał',
                player.potential.toString(),
              ),
            ]),

            const SizedBox(height: 16),

            // ==================================================
            // UMIEJĘTNOŚCI
            // ==================================================

            _sectionTitle('UMIEJĘTNOŚCI'),

            _statsCard([
              _statRow('PACE', player.pace),
              _statRow('SHOOTING', player.shooting),
              _statRow('PASSING', player.passing),
              _statRow('DRIBBLING', player.dribbling),
              _statRow('DEFENDING', player.defending),
              _statRow('PHYSICAL', player.physical),
            ]),

            const SizedBox(height: 16),

            // ==================================================
            // FORMA
            // ==================================================

            _sectionTitle('STAN ZAWODNIKA'),

            _statsCard([
              _statRow('FORMA', player.form),
              _statRow('KONDYCJA', player.fitness),
              _statRow(
                'ZMĘCZENIE',
                player.fatigue,
              ),
              _statRow(
                'MORALE',
                player.morale,
              ),
              _statRow(
                'SZCZĘŚCIE',
                player.happiness,
              ),
              _statRow(
                'TRENER',
                player.managerRelationship,
              ),
              _statRow(
                'DRUŻYNA',
                player.teamRelationship,
              ),
            ]),

            const SizedBox(height: 16),

            // ==================================================
            // KONTRAKT
            // ==================================================

            _sectionTitle('KONTRAKT'),

            _infoCard([
              _infoRow(
                'Klub',
                club?.name ?? 'Brak klubu',
              ),
              _infoRow(
                'Pensja',
                player.contract == null
                    ? '-'
                    : '${player.contract!.weeklySalary.toStringAsFixed(0)} / tydz.',
              ),
              _infoRow(
                'Wartość',
                player.contract == null
                    ? '-'
                    : '${player.contract!.marketValue.toStringAsFixed(0)}',
              ),
              _infoRow(
                'Lata kontraktu',
                player.contract == null
                    ? '-'
                    : player.contract!.yearsRemaining.toString(),
              ),
            ]),

            const SizedBox(height: 16),

            // ==================================================
            // KARIERA
            // ==================================================

            _sectionTitle('KARIERA'),

            _infoCard([
              _infoRow(
                'Występy',
                player.careerAppearances.toString(),
              ),
              _infoRow(
                'Gole',
                player.careerGoals.toString(),
              ),
              _infoRow(
                'Asysty',
                player.careerAssists.toString(),
              ),
            ]),

            const SizedBox(height: 16),

            // ==================================================
            // STATYSTYKI MECZOWE
            // ==================================================

            _sectionTitle('STATYSTYKI MECZOWE'),

            _infoCard([
              _infoRow(
                'Występy',
                player.matchStats.appearances.toString(),
              ),
              _infoRow(
                'Mecze od początku',
                player.matchStats.starts.toString(),
              ),
              _infoRow(
                'Wejścia z ławki',
                player.matchStats.substituteAppearances.toString(),
              ),
              _infoRow(
                'Minuty',
                player.matchStats.minutes.toString(),
              ),
              _infoRow(
                'Gole',
                player.matchStats.goals.toString(),
              ),
              _infoRow(
                'Asysty',
                player.matchStats.assists.toString(),
              ),
              _infoRow(
                'Żółte kartki',
                player.matchStats.yellowCards.toString(),
              ),
              _infoRow(
                'Czerwone kartki',
                player.matchStats.redCards.toString(),
              ),
              _infoRow(
                'Strzały',
                player.matchStats.shots.toString(),
              ),
              _infoRow(
                'Strzały celne',
                player.matchStats.shotsOnTarget.toString(),
              ),
              _infoRow(
                'Kluczowe podania',
                player.matchStats.keyPasses.toString(),
              ),
              _infoRow(
                'Udane dryblingi',
                player.matchStats.successfulDribbles.toString(),
              ),
              _infoRow(
                'Średnia ocena',
                player.matchStats.averageRating
                    .toStringAsFixed(2),
              ),
            ]),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TYTUŁ SEKCJI
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),

      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // KARTA INFORMACJI
  // ============================================================

  Widget _infoCard(
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  // ============================================================
  // WIERSZ INFORMACJI
  // ============================================================

  Widget _infoRow(
    String label,
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
            label,
            style: const TextStyle(
              color: Colors.white54,
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATYSTYKA
  // ============================================================

  Widget _statsCard(
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _statRow(
    String label,
    int value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: Row(
        children: [

          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 35,
            child: Text(
              value.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
