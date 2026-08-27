import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';

/// Generuje nowe pokolenia zawodników zależnie od jakości akademii,
/// kraju, reputacji klubu i nacisku na młodzież.
class AcademyEngine {
  final Random _random;
  AcademyEngine({Random? random}) : _random = random ?? Random();

  List<Player> generateSeasonTalents({
    required List<Club> clubs,
    required List<Player> players,
    required int seasonYear,
  }) {
    final generated = <Player>[];
    for (final club in clubs) {
      final baseChance = 0.22 + (club.academyQuality / 100) * 0.58;
      if (_random.nextDouble() > baseChance) continue;

      final count = club.academyQuality >= 85 && _random.nextDouble() < .35 ? 2 : 1;
      for (var i = 0; i < count; i++) {
        final player = _generate(club, seasonYear, players.length + generated.length);
        generated.add(player);
      }
    }
    players.addAll(generated);
    return generated;
  }

  Player _generate(Club club, int seasonYear, int index) {
    final countryFactor = _countryFactor(club.country);
    final academyFactor = club.academyQuality * .20;
    final youthFactor = club.youthFocus * .12;
    final reputationFactor = club.reputation * .06;
    final seed = (45 + countryFactor + academyFactor + youthFactor + reputationFactor + _random.nextInt(16)).round().clamp(45, 76).toInt();
    final potential = (seed + 10 + (club.academyQuality / 5).round() + _random.nextInt(13)).clamp(seed + 5, 96).toInt();
    final position = PlayerPosition.values[_random.nextInt(PlayerPosition.values.length)];
    final id = 'academy_${seasonYear}_${club.id}_${index}_${_random.nextInt(1000000)}';
    return Player(
      id: id,
      name: '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}',
      age: 16 + _random.nextInt(4),
      position: position,
      nationality: club.country,
      overall: seed,
      potential: potential,
      pace: _stat(seed),
      shooting: _stat(seed),
      passing: _stat(seed),
      dribbling: _stat(seed),
      defending: _stat(seed),
      physical: _stat(seed),
      value: seed * seed * 950.0,
      weeklyWage: max(120, seed * 85.0),
      clubId: club.id,
      contractYearsRemaining: 3,
      squadStatus: 'academy',
      morale: 75,
      managerRelationship: 55,
    );
  }

  int _countryFactor(String country) {
    const strengths = {
      'Anglia': 10, 'Hiszpania': 10, 'Niemcy': 9, 'Włochy': 9,
      'Francja': 10, 'Brazylia': 10, 'Argentyna': 9, 'Portugalia': 9,
      'Holandia': 8, 'Belgia': 8, 'Polska': 6,
    };
    return strengths[country] ?? 4;
  }

  int _stat(int seed) => (seed - 8 + _random.nextInt(17)).clamp(1, 99);

  static const _firstNames = ['Mateo', 'Kacper', 'Szymon', 'Nico', 'Lucas', 'Julian', 'Marco', 'Leo', 'Jakub', 'Filip', 'Jan', 'Gabriel', 'Oskar', 'Milan'];
  static const _lastNames = ['Nowak', 'Rossi', 'Silva', 'Müller', 'Kowalski', 'Garcia', 'Weber', 'Wiśniewski', 'Zieliński', 'Dubois', 'Martins', 'Wójcik'];
}
