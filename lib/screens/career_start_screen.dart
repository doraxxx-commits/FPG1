import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import 'career_home_screen.dart';

class CareerStartScreen extends StatelessWidget {
  final GameEngine engine;

  const CareerStartScreen({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final player = engine.careerPlayer;

    if (player == null ||
        player.contract == null ||
        player.clubId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Nie znaleziono danych kariery.',
          ),
        ),
      );
    }

    final clubMatches = engine.clubs.where((club) => club.id == player.clubId).toList();
    if (clubMatches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Nie znaleziono klubu zawodnika.')));
    }
    final club = clubMatches.first;

    final contract = player.contract!;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),

      appBar: AppBar(
        title: const Text('POCZĄTEK KARIERY'),
        backgroundColor: const Color(0xFF080A0F),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            const Text(
              'WITAMY W PROFESJONALNEJ PIŁCE',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${player.firstName} ${player.lastName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'TWÓJ KLUB',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      club.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'OVR klubu: ${club.overall}',
                    ),

                    Text(
                      'Status: ${contract.squadStatus}',
                    ),

                    Text(
                      'Numer: #${contract.squadNumber}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'KONTRAKT',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Pozostało: '
                      '${contract.yearsRemaining} lata',
                    ),

                    Text(
                      'Pensja: '
                      '${contract.weeklySalary.toStringAsFixed(0)} / tydzień',
                    ),

                    Text(
                      'Wartość: '
                      '${contract.marketValue.toStringAsFixed(0)}',
                    ),

                    Text(
                      'Zaufanie trenera: '
                      '${contract.managerTrust}/100',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                onPressed: () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => CareerHomeScreen(
        engine: engine,
      ),
    ),
  );
},

                child: const Text(
                  'ROZPOCZNIJ KARIERĘ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
