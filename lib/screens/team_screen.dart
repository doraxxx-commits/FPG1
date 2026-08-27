import 'package:flutter/material.dart';
import '../core/game_engine.dart';

class TeamScreen extends StatefulWidget {
  final GameEngine engine;

  const TeamScreen({
    super.key,
    required this.engine,
  });

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  int _lockerRoomChemistry = 72; // Zgranie w szatni (0-100)

  void _teamBuilding(String action) {
    final player = widget.engine.careerPlayer;
    if (player == null) return;

    String msg = '';
    setState(() {
      if (action == 'BBQ') {
        _lockerRoomChemistry = (_lockerRoomChemistry + 8).clamp(0, 100).toInt();
        player.morale = (player.morale + 5).clamp(0, 100).toInt();
        player.fatigue = (player.fatigue + 4).clamp(0, 100).toInt();
        msg = 'Zorganizowałeś wspólnego grilla dla drużyny! Zgranie +8, Morale +5.';
      } else if (action == 'TALK') {
        _lockerRoomChemistry = (_lockerRoomChemistry + 4).clamp(0, 100).toInt();
        msg = 'Motywacyjna mowa w szatni przed meczem podniosła duch zespołu! (+4 Zgrania)';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1E2638),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.engine.careerPlayer;
    final clubName = widget.engine.clubs
        .firstWhere((c) => c.id == player?.clubId, orElse: () => widget.engine.clubs.first)
        .name;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      appBar: AppBar(
        title: const Text('Relacje z Drużyną'),
        backgroundColor: const Color(0xFF080A0F),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KARTA ZGRANIA SZATNI
            Card(
              color: const Color(0xFF131722),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Szatnia: $clubName',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Zgranie i Atmosfera:'),
                        Text(
                          '$_lockerRoomChemistry / 100',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _lockerRoomChemistry / 100.0,
                      backgroundColor: Colors.white10,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'INTEGRACJA Z DRUŻYNĄ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _teamTile(
              icon: Icons.sports_bar,
              title: 'Wspólny grill / wyjście integracyjne',
              subtitle: 'Podnosi zgranie szatni i morale zespołu (+8 Zgrania)',
              onTap: () => _teamBuilding('BBQ'),
            ),
            _teamTile(
              icon: Icons.campaign,
              title: 'Mowa motywacyjna w szatni',
              subtitle: 'Buduje Twoją pozycję jako lidera zespołu (+4 Zgrania)',
              onTap: () => _teamBuilding('TALK'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E2638),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
