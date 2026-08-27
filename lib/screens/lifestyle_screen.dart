import 'package:flutter/material.dart';
import '../core/game_engine.dart';

class LifestyleScreen extends StatefulWidget {
  final GameEngine engine;

  const LifestyleScreen({
    super.key,
    required this.engine,
  });

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  int _relationshipStatus = 65; // Relacja z dziewczyną (0-100)

  void _triggerActivity(String type) {
    final player = widget.engine.careerPlayer;
    if (player == null) return;

    String message = '';
    setState(() {
      switch (type) {
        case 'DATE':
          _relationshipStatus = (_relationshipStatus + 12).clamp(0, 100).toInt();
          player.morale = (player.morale + 8).clamp(0, 100).toInt();
          player.fatigue = (player.fatigue + 5).clamp(0, 100).toInt();
          message = 'Spędziłeś miły wieczór z partnerką. Morale +8, Zmęczenie +5.';
          break;

        case 'REST':
          player.fatigue = (player.fatigue - 20).clamp(0, 100).toInt();
          player.fitness = (player.fitness + 10).clamp(0, 100).toInt();
          message = 'Zostałeś w domu i odpocząłeś przed meczem. Zmęczenie -20.';
          break;

        case 'PARTY':
          _relationshipStatus = (_relationshipStatus - 10).clamp(0, 100).toInt();
          player.morale = (player.morale + 15).clamp(0, 100).toInt();
          player.fatigue = (player.fatigue + 25).clamp(0, 100).toInt();
          message = 'Impreza na mieście! Morale +15, ale Zmęczenie +25 i spadek relacji.';
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E2638),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.engine.careerPlayer;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      appBar: AppBar(
        title: const Text('Życie i Obozowisko'),
        backgroundColor: const Color(0xFF080A0F),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KARTA RELACJI
            Card(
              color: const Color(0xFF131722),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.pinkAccent, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Życie Osobiste & Partnerka',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jakość Relacji:'),
                        Text(
                          '$_relationshipStatus / 100',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _relationshipStatus / 100.0,
                      backgroundColor: Colors.white10,
                      color: Colors.pinkAccent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'AKTYWNOŚCI POZA BOISKIEM',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _activityTile(
              icon: Icons.restaurant,
              title: 'Wyjście na kolację z partnerką',
              subtitle: 'Podnosi relacje oraz morale, lekko zwiększa zmęczenie',
              onTap: () => _triggerActivity('DATE'),
            ),
            _activityTile(
              icon: Icons.hotel,
              title: 'Regeneracja w domu',
              subtitle: 'Znacząco obniża zmęczenie przed meczem',
              onTap: () => _triggerActivity('REST'),
            ),
            _activityTile(
              icon: Icons.nightlife,
              title: 'Wycisnąć noc na mieście z przyjaciółmi',
              subtitle: 'Ogromny skok morale, ale wysokie zmęczenie i spadek relacji',
              onTap: () => _triggerActivity('PARTY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E2638),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.pinkAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
