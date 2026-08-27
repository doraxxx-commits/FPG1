import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../core/training_engine.dart';

/// P2.2-C — development hub.
///
/// This screen is intentionally connected to the real GameEngine training
/// transaction. It does not mutate PlayerCareer directly, so the same daily
/// action rules used by Career Home are respected here as well.
class PlayerDevelopmentScreen extends StatefulWidget {
  final GameEngine engine;

  const PlayerDevelopmentScreen({
    super.key,
    required this.engine,
  });

  @override
  State<PlayerDevelopmentScreen> createState() => _PlayerDevelopmentScreenState();
}

class _PlayerDevelopmentScreenState extends State<PlayerDevelopmentScreen> {
  String? message;
  TrainingResult? lastResult;
  int? previousOverall;

  GameEngine get engine => widget.engine;

  void train(TrainingType type) {
    final player = engine.careerPlayer;
    if (player == null) return;

    final beforeOverall = player.overall;
    try {
      final result = engine.trainPlayer(type);
      if (!mounted) return;
      setState(() {
        previousOverall = beforeOverall;
        lastResult = result;
        message = '${result.name}: +${result.primaryGain} głównego rozwoju. '
            'Zmęczenie +${result.fatigue}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = engine.careerPlayer;

    if (player == null) {
      return const Scaffold(
        body: Center(child: Text('Brak danych zawodnika.')),
      );
    }

    final gap = (player.potential - player.overall).clamp(0, 99);
    final potentialProgress = player.potential == 0
        ? 0.0
        : (player.overall / player.potential).clamp(0.0, 1.0);
    final canTrain = !engine.dailyCareerActionConsumed &&
        !engine.careerHasMatchToday &&
        player.fatigue < 90;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      appBar: AppBar(
        title: const Text('ROZWÓJ ZAWODNIKA'),
        backgroundColor: const Color(0xFF080A0F),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _developmentHeader(player, gap, potentialProgress),
            const SizedBox(height: 16),
            _statusCard(player, canTrain),
            if (lastResult != null) ...[
              const SizedBox(height: 12),
              _resultCard(player),
            ],
            if (message != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    message!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            const Text(
              'ATRYBUTY',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _attributeBar('TEMPO (PAC)', player.pace),
            _attributeBar('STRZAŁY (SHO)', player.shooting),
            _attributeBar('PODANIA (PAS)', player.passing),
            _attributeBar('DRYBLING (DRI)', player.dribbling),
            _attributeBar('OBRONA (DEF)', player.defending),
            _attributeBar('FIZYCZNOŚĆ (PHY)', player.physical),
            const SizedBox(height: 22),
            const Text(
              'TRENING DZIŚ',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              canTrain
                  ? 'Wybierz jeden trening. To zużyje dzisiejszą akcję kariery.'
                  : engine.careerHasMatchToday
                      ? 'Dzisiaj masz mecz — trening jest niedostępny.'
                      : engine.dailyCareerActionConsumed
                          ? 'Dzisiejsza akcja została już wykorzystana.'
                          : 'Regeneruj się przed kolejnym ciężkim treningiem.',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 10),
            _trainingButton('TEMPO', 'PAC + pobocznie PHY', TrainingType.pace, canTrain),
            _trainingButton('STRZAŁY', 'SHO + pobocznie PHY', TrainingType.shooting, canTrain),
            _trainingButton('PODANIA', 'PAS + pobocznie DRI', TrainingType.passing, canTrain),
            _trainingButton('DRYBLING', 'DRI + pobocznie PAC', TrainingType.dribbling, canTrain),
            _trainingButton('OBRONA', 'DEF + pobocznie PHY', TrainingType.defending, canTrain),
            _trainingButton('FIZYCZNY', 'PHY + pobocznie PAC', TrainingType.physical, canTrain),
            _trainingButton('BALANS', 'Mały progres we wszystkich atrybutach', TrainingType.balanced, canTrain),
            const SizedBox(height: 22),
            const Text(
              'PERKI KARIERY',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _perkTile('🔥 Snajper', '+5% do celności wykończenia', player.overall >= 70, 'OVR 70+'),
            _perkTile('⚡ Sprinter', 'Mniejsze zmęczenie kontratakiem', player.pace >= 75, 'PAC 75+'),
            _perkTile('🧊 Clutch Player', 'Bonus w końcówkach spotkań', player.overall >= 80, 'OVR 80+'),
            _perkTile('🧠 Lider Szatni', 'Wpływ na morale zespołu', player.overall >= 85, 'OVR 85+'),
          ],
        ),
      ),
    );
  }

  Widget _developmentHeader(dynamic player, int gap, double progress) {
    final ovrDelta = previousOverall == null ? 0 : player.overall - previousOverall!;
    return Card(
      color: const Color(0xFF1E2638),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statColumn('OVR', '${player.overall}', Colors.greenAccent),
                const Spacer(),
                _statColumn('POTENCJAŁ', '${player.potential}', Colors.blueAccent),
                const Spacer(),
                _statColumn('WIEK', '${player.age}', Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DROGA DO POTENCJAŁU', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('$gap OVR do celu', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 7),
            LinearProgressIndicator(value: progress, minHeight: 9),
            if (ovrDelta != 0) ...[
              const SizedBox(height: 8),
              Text(
                ovrDelta > 0 ? '↑ OVR +$ovrDelta po ostatnim treningu' : 'OVR $ovrDelta',
                style: TextStyle(color: ovrDelta > 0 ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusCard(dynamic player, bool canTrain) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: _smallStatus('FORMA', player.form)),
            Expanded(child: _smallStatus('FITNESS', player.fitness)),
            Expanded(child: _smallStatus('FATIGUE', player.fatigue)),
            Expanded(child: _smallStatus('TRENER', player.managerRelationship)),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(dynamic player) {
    final result = lastResult!;
    final before = previousOverall ?? player.overall;
    return Card(
      color: const Color(0xFF18231D),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Expanded(child: Text('${result.name} • OVR $before → ${player.overall}')),
            Text('+${result.primaryGain}', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _smallStatus(String label, int value) => Column(
        children: [
          Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
        ],
      );

  Widget _statColumn(String label, String value, Color color) => Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: color)),
        ],
      );

  Widget _attributeBar(String name, int val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(name, style: const TextStyle(color: Colors.white70)),
              Text('$val', style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 5),
            LinearProgressIndicator(value: (val.clamp(0, 99)) / 99.0, minHeight: 7),
          ],
        ),
      );

  Widget _trainingButton(String title, String subtitle, TrainingType type, bool enabled) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          enabled: enabled,
          leading: const Icon(Icons.fitness_center),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: Icon(enabled ? Icons.arrow_forward_ios : Icons.lock_outline, size: 16),
          onTap: enabled ? () => train(type) : null,
        ),
      );

  Widget _perkTile(String title, String subtitle, bool unlocked, String condition) => Card(
        color: unlocked ? const Color(0xFF1E2638) : Colors.white.withOpacity(0.03),
        child: ListTile(
          leading: Icon(unlocked ? Icons.verified : Icons.lock, color: unlocked ? Colors.greenAccent : Colors.white30),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: unlocked ? Colors.white : Colors.white38)),
          subtitle: Text(unlocked ? subtitle : 'Zablokowano: $condition', style: TextStyle(color: unlocked ? Colors.white70 : Colors.white30)),
        ),
      );
}
