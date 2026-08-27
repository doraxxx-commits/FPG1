import 'package:flutter/material.dart';
import '../core/game_engine.dart';

class ManagerScreen extends StatefulWidget {
  final GameEngine engine;

  const ManagerScreen({
    super.key,
    required this.engine,
  });

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  void _interactWithManager(String actionType) {
    final player = widget.engine.careerPlayer;
    if (player == null || player.contract == null) return;

    final contract = player.contract!;
    String responseMessage = '';

    setState(() {
      switch (actionType) {
        case 'MORE_MINUTES':
          if (contract.managerTrust >= 60) {
            contract.managerTrust = (contract.managerTrust + 2).clamp(0, 100).toInt();
            responseMessage = 'Trener: "Widzę Twoje zaangażowanie. Dostaniesz swoją szansę w najbliższym meczu."';
          } else {
            contract.managerTrust = (contract.managerTrust - 5).clamp(0, 100).toInt();
            responseMessage = 'Trener: "Na minuty trzeba sobie zasłużyć na treningach. Pracuj ciężej."';
          }
          break;

        case 'PRAISE_TACTICS':
          contract.managerTrust = (contract.managerTrust + 4).clamp(0, 100).toInt();
          responseMessage = 'Trener: "Doceniam, że rozumiesz nasz plan na mecz. Takich zawodników potrzebuję."';
          break;

        case 'REQUEST_TRANSFER':
          contract.managerTrust = (contract.managerTrust - 15).clamp(0, 100).toInt();
          responseMessage = 'Trener: "Skoro nie chcesz tu być, ułatwię ci odejście. Trafiasz na listę transferową."';
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(responseMessage),
        backgroundColor: const Color(0xFF1E2638),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.engine.careerPlayer;

    if (player == null || player.contract == null) {
      return const Scaffold(
        body: Center(child: Text('Brak aktywnych danych kariery.')),
      );
    }

    final contract = player.contract!;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      appBar: AppBar(
        title: const Text('Gabinet Trenera'),
        backgroundColor: const Color(0xFF080A0F),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // STATUS ZAUFANIA
            Card(
              color: const Color(0xFF131722),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, size: 30, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Główny Szkoleniowiec',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Status w składzie: ${contract.squadStatus}',
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Poziom Zaufania:'),
                        Text(
                          '${contract.managerTrust} / 100',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: contract.managerTrust >= 70
                                ? Colors.greenAccent
                                : (contract.managerTrust >= 40 ? Colors.orangeAccent : Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: contract.managerTrust / 100.0,
                      backgroundColor: Colors.white10,
                      color: contract.managerTrust >= 70
                          ? Colors.greenAccent
                          : (contract.managerTrust >= 40 ? Colors.orangeAccent : Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'ROZMOWA Z TRENEREM',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _actionTile(
              icon: Icons.sports_soccer,
              title: 'Poproś o więcej minut na boisku',
              subtitle: 'Wymaga zaufania min. 60+',
              onTap: () => _interactWithManager('MORE_MINUTES'),
            ),
            _actionTile(
              icon: Icons.thumb_up,
              title: 'Pochwal taktykę przed meczem',
              subtitle: 'Zwiększa relację z trenerem (+4 trust)',
              onTap: () => _interactWithManager('PRAISE_TACTICS'),
            ),
            _actionTile(
              icon: Icons.exit_to_app,
              title: 'Poproś o wpisanie na listę transferową',
              subtitle: 'Znacząco obniża relacje z trenerem (-15 trust)',
              onTap: () => _interactWithManager('REQUEST_TRANSFER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E2638),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.greenAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
