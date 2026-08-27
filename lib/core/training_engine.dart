import 'dart:math';

import '../models/player_career.dart';

enum TrainingType {
  pace,
  shooting,
  passing,
  dribbling,
  defending,
  physical,
  balanced,
}

class TrainingResult {
  final String name;
  final String description;

  final int primaryGain;
  final int secondaryGain;

  final int fatigue;

  TrainingResult({
    required this.name,
    required this.description,
    required this.primaryGain,
    required this.secondaryGain,
    required this.fatigue,
  });
}

class TrainingEngine {
  final Random _random = Random();

  TrainingResult train(
    PlayerCareer player,
    TrainingType type,
  ) {
    final primaryGain = _calculateGain(
      player,
      type,
    );

    final secondaryGain =
        max(0, primaryGain ~/ 2);

    final fatigue = _calculateFatigue(
      player,
      type,
    );

    switch (type) {
      case TrainingType.pace:
        player.pace = _increaseStat(
          player.pace,
          primaryGain,
        );

        player.physical = _increaseStat(
          player.physical,
          secondaryGain,
        );

        return TrainingResult(
          name: 'SZYBKOŚĆ',
          description:
              'Trening szybkości i dynamiki.',
          primaryGain: primaryGain,
          secondaryGain: secondaryGain,
          fatigue: fatigue,
        );

      case TrainingType.shooting:
        player.shooting = _increaseStat(
          player.shooting,
          primaryGain,
        );

        player.physical = _increaseStat(
          player.physical,
          secondaryGain,
        );

        return TrainingResult(
          name: 'WYKOŃCZENIE',
          description:
              'Trening strzałów i wykończenia akcji.',
          primaryGain: primaryGain,
          secondaryGain: secondaryGain,
          fatigue: fatigue,
        );

      case TrainingType.passing:
        player.passing = _increaseStat(
          player.passing,
          primaryGain,
        );

        player.dribbling = _increaseStat(
          player.dribbling,
          secondaryGain,
        );

        return TrainingResult(
          name: 'PODANIA',
          description:
              'Trening podań, wizji i rozegrania.',
          primaryGain: primaryGain,
          secondaryGain: secondaryGain,
          fatigue: fatigue,
        );

      case TrainingType.dribbling:
        player.dribbling = _increaseStat(
          player.dribbling,
          primaryGain,
        );

        player.pace = _increaseStat(
          player.pace,
          secondaryGain,
        );

        return TrainingResult(
          name: 'DRYBLING',
          description:
              'Trening techniki i prowadzenia piłki.',
          primaryGain: primaryGain,
          secondaryGain: secondaryGain,
          fatigue: fatigue,
        );

      case TrainingType.defending:
        player.defending = _increaseStat(
          player.defending,
          primaryGain,
        );

        player.physical = _increaseStat(
          player.physical,
          secondaryGain,
        );

        return TrainingResult(
          name: 'OBRONA',
          description:
              'Trening odbioru i ustawienia.',
          primaryGain: primaryGain,
          secondaryGain: secondaryGain,
          fatigue: fatigue,
        );

      case TrainingType.physical:
        player.physical = _increaseStat(
          player.physical,
          primaryGain,
        );

        player.pace = _increaseStat(
          player.pace,
          secondaryGain,
        );

        return TrainingResult(
          name: 'FIZYCZNOŚĆ',
          description:
              'Trening siły, kondycji i wytrzymałości.',
          primaryGain: primaryGain,
          secondaryGain: secondaryGain,
          fatigue: fatigue,
        );

      case TrainingType.balanced:
        player.pace = _increaseStat(
          player.pace,
          secondaryGain,
        );

        player.shooting = _increaseStat(
          player.shooting,
          secondaryGain,
        );

        player.passing = _increaseStat(
          player.passing,
          secondaryGain,
        );

        player.dribbling = _increaseStat(
          player.dribbling,
          secondaryGain,
        );

        player.defending = _increaseStat(
          player.defending,
          secondaryGain,
        );

        player.physical = _increaseStat(
          player.physical,
          secondaryGain,
        );

        return TrainingResult(
          name: 'TRENING OGÓLNY',
          description:
              'Wszechstronny trening całego zawodnika.',
          primaryGain: secondaryGain,
          secondaryGain: secondaryGain,
          fatigue: fatigue,
        );
    }
  }

  int _calculateGain(
    PlayerCareer player,
    TrainingType type,
  ) {
    final current = _getRelevantStat(
      player,
      type,
    );

    final potential = player.potential;

    if (current >= potential) {
      return 0;
    }

    final difference = potential - current;

    int base;

    if (player.age <= 19) {
      base = 2;
    } else if (player.age <= 22) {
      base = 1;
    } else {
      base = 1;
    }

    if (difference <= 5) {
      base = 1;
    }

    final randomBonus =
        _random.nextInt(100) < 20 ? 1 : 0;

    return min(
      base + randomBonus,
      difference,
    );
  }

  int _calculateFatigue(
    PlayerCareer player,
    TrainingType type,
  ) {
    switch (type) {
      case TrainingType.physical:
        return 12;

      case TrainingType.pace:
        return 10;

      case TrainingType.shooting:
        return 7;

      case TrainingType.passing:
        return 6;

      case TrainingType.dribbling:
        return 8;

      case TrainingType.defending:
        return 8;

      case TrainingType.balanced:
        return 9;
    }
  }

  int _getRelevantStat(
    PlayerCareer player,
    TrainingType type,
  ) {
    switch (type) {
      case TrainingType.pace:
        return player.pace;

      case TrainingType.shooting:
        return player.shooting;

      case TrainingType.passing:
        return player.passing;

      case TrainingType.dribbling:
        return player.dribbling;

      case TrainingType.defending:
        return player.defending;

      case TrainingType.physical:
        return player.physical;

      case TrainingType.balanced:
        return player.overall;
    }
  }

  int _increaseStat(
    int value,
    int amount,
  ) {
    return min(
      99,
      value + amount,
    );
  }
}
