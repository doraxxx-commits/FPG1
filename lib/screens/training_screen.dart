import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../core/training_engine.dart';

class TrainingScreen extends StatefulWidget {
  final GameEngine engine;

  const TrainingScreen({
    super.key,
    required this.engine,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  String? message;

  void train(TrainingType type) {
    try {
      final result = widget.engine.trainPlayer(type);

      setState(() {
        message =
            'Trening wykonany!\n'
            'Zmęczenie: +${result.fatigue}';
      });
    } catch (e) {
      setState(() {
        message = e.toString().replaceFirst(
          'Bad state: ',
          '',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.engine.careerPlayer;

    if (player == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('TRENING'),
        ),
        body: const Center(
          child: Text(
            'Najpierw utwórz zawodnika.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),

      appBar: AppBar(
        title: const Text('TRENING'),
        backgroundColor: const Color(0xFF080A0F),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [

            // ==================================================
            // ZAWODNIK
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),

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

                    const SizedBox(height: 8),

                    Text(
                      'OVR ${player.overall}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'FORMA: ${player.form}',
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'KONDYCJA: ${player.fitness}',
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'ZMĘCZENIE: ${player.fatigue}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'WYBIERZ TRENING',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // TRENINGI
            // ==================================================

            _trainingButton(
              title: 'TEMPO',
              subtitle: 'Rozwój szybkości',
              type: TrainingType.pace,
            ),

            _trainingButton(
              title: 'STRZAŁY',
              subtitle: 'Rozwój wykończenia',
              type: TrainingType.shooting,
            ),

            _trainingButton(
              title: 'PODANIA',
              subtitle: 'Rozwój podań',
              type: TrainingType.passing,
            ),

            _trainingButton(
              title: 'DRYBLING',
              subtitle: 'Rozwój dryblingu',
              type: TrainingType.dribbling,
            ),

            _trainingButton(
              title: 'OBRONA',
              subtitle: 'Rozwój defensywy',
              type: TrainingType.defending,
            ),

            _trainingButton(
              title: 'FIZYCZNY',
              subtitle: 'Rozwój siły i fizyczności',
              type: TrainingType.physical,
            ),

            const SizedBox(height: 20),

            // ==================================================
            // KOMUNIKAT
            // ==================================================

            if (message != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    message!,
                    style: const TextStyle(
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

  Widget _trainingButton({
    required String title,
    required String subtitle,
    required TrainingType type,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          subtitle,
        ),

        trailing: const Icon(
          Icons.fitness_center,
        ),

        onTap: () {
          train(type);
        },
      ),
    );
  }
}
