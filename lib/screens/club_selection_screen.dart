import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../models/club.dart';
import 'career_start_screen.dart';

class ClubSelectionScreen extends StatelessWidget {
  final GameEngine engine;

  const ClubSelectionScreen({
    super.key,
    required this.engine,
  });

  List<Club> getAvailableClubs() {
    final clubs = engine.leagueClubs.toList();

    clubs.sort(
      (a, b) => a.overall.compareTo(b.overall),
    );

    if (clubs.length <= 4) {
      return clubs;
    }

    // Na razie wybieramy cztery kluby
    // odpowiednie do rozpoczęcia kariery.
    final middle = clubs.length ~/ 2;

    final start = (middle - 2).clamp(
      0,
      clubs.length - 4,
    ).toInt();

    return clubs.sublist(
      start,
      start + 4,
    );
  }

  String clubDescription(Club club) {
    if (club.overall >= 75) {
      return 'Silny klub • trudna walka o skład';
    }

    if (club.overall >= 70) {
      return 'Dobry klub • konkurencja o miejsce';
    }

    if (club.overall >= 65) {
      return 'Średni klub • realna szansa na grę';
    }

    return 'Słabszy klub • duża szansa na minuty';
  }

  void selectClub(
  BuildContext context,
  Club club,
) {
  engine.assignPlayerToClub(club.id);

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => CareerStartScreen(
        engine: engine,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final clubs = getAvailableClubs();

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),

      appBar: AppBar(
        title: const Text('WYBÓR KLUBU'),
        backgroundColor: const Color(0xFF080A0F),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            const Text(
              'WYBIERZ SWÓJ PIERWSZY KLUB',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'To będzie pierwszy krok Twojej profesjonalnej kariery.',
              style: TextStyle(
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 24),

            ...clubs.map(
              (club) {
                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),

                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),

                    onTap: () {
                      selectClub(
                        context,
                        club,
                      );
                    },

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  club.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),

                              Text(
                                'OVR ${club.overall}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            clubDescription(club),
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Budżet klubu: '
                            '${club.budget}',
                            style: const TextStyle(
                              color: Colors.white54,
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,

                            child: ElevatedButton(
                              onPressed: () {
                                selectClub(
                                  context,
                                  club,
                                );
                              },

                              child: const Text(
                                'WYBIERAM TEN KLUB',
                              ),
                            ),
                          ),
                        ],
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
}
