import 'package:flutter/material.dart';
import '../core/game_engine.dart';

class LeagueTableScreen extends StatelessWidget {
  final GameEngine engine;

  const LeagueTableScreen({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    // Pobranie aktualnej ligi gracza
    //
    // NAPRAWA: `engine.leagueEngine.standings` to Map<String, Standing>,
    // a ten ekran próbował go indeksować jak listę (`standings[index]`)
    // i odwoływał się do pola `clubName`, którego Standing w ogóle nie ma.
    // `.table` zwraca już posortowaną listę Standing.
    final player = engine.careerPlayer;
    final standings = engine.leagueEngine.table;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      appBar: AppBar(
        title: const Text('Tabela Ligowa'),
        backgroundColor: const Color(0xFF080A0F),
      ),
      body: SafeArea(
        child: standings.isEmpty
            ? const Center(
                child: Text(
                  'Brak danych o tabeli ligowej.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: standings.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Nagłówek tabeli
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2638),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Klub', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 35, child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 35, child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 40, child: Text('PKT', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                        ],
                      ),
                    );
                  }

                  final item = standings[index - 1];
                  final isPlayerClub = player != null && item.clubId == player.clubId;

                  final clubMatches = engine.clubs.where((c) => c.id == item.clubId).toList();
                  final clubName = clubMatches.isEmpty ? 'Nieznany klub' : clubMatches.first.name;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isPlayerClub
                          ? Colors.green.withOpacity( 0.15)
                          : (index % 2 == 0 ? Colors.white.withOpacity( 0.02) : Colors.transparent),
                      border: const Border(
                        bottom: BorderSide(color: Colors.white12, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontWeight: isPlayerClub ? FontWeight.bold : FontWeight.normal,
                              color: isPlayerClub ? Colors.greenAccent : Colors.white70,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            clubName,
                            style: TextStyle(
                              fontWeight: isPlayerClub ? FontWeight.bold : FontWeight.normal,
                               color: isPlayerClub ? Colors.white : Colors.white.withOpacity(0.9),

                            ),
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: Text(
                            '${item.played}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: Text(
                            '${item.goalsFor}:${item.goalsAgainst}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${item.points}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
