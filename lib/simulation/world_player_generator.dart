import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/youth_prospect.dart';
import '../models/player_personality.dart';
import '../models/player_preferences.dart';

/// Generates real `Player` objects for the autonomous football world.
///
/// This is intentionally separate from the career-player creator: generated
/// players are persistent members of the global world and therefore survive
/// saves, transfers, development and retirement just like every other AI
/// player.
class WorldPlayerGenerator {
  final Random random;

  WorldPlayerGenerator({Random? random}) : random = random ?? Random();

  /// Materialises a discovered prospect into the persistent Player model.
  /// The hidden potential is copied only into Player.potential; the scouting
  /// estimate is intentionally not stored as the truth.
  Player fromProspect({
    required int year,
    required Club club,
    required YouthProspect prospect,
  }) {
    final base = prospect.rawTalent;
    final stats = _statsFor(prospect.position, base);
    return Player(
      id: prospect.id,
      name: prospect.name,
      age: prospect.age,
      position: prospect.position,
      nationality: prospect.nationality,
      overall: base,
      potential: prospect.hiddenPotential,
      personality: PlayerPersonality(
        professionalism: prospect.professionalism,
        ambition: prospect.ambition,
        loyalty: prospect.loyalty,
        adaptability: prospect.adaptability,
        discipline: ((prospect.professionalism + prospect.adaptability) / 2).round(),
      ),
      preferences: PlayerPreferences(
        minutesExpectation: (45 + prospect.ambition ~/ 3).clamp(45, 90),
        preferredClubLevel: (prospect.rawTalent + prospect.ambition ~/ 4).clamp(35, 95),
        foreignMoveWillingness: (100 - prospect.localAffinity + prospect.adaptability ~/ 2).clamp(10, 95),
        wagePriority: (35 + prospect.ambition ~/ 4).clamp(35, 90),
        loyaltyToCurrentClub: prospect.loyalty,
        preferredRole: prospect.rawTalent >= 65 ? 'firstTeam' : 'development',
      ),
      pace: stats[0],
      shooting: stats[1],
      passing: stats[2],
      dribbling: stats[3],
      defending: stats[4],
      physical: stats[5],
      value: _marketValue(base, prospect.hiddenPotential, prospect.age),
      weeklyWage: max(100, base * 95.0),
      clubId: club.id,
      contractYearsRemaining: 3,
      contractRole: 'academy',
      squadStatus: 'academy',
      morale: 72,
      form: 65,
      fitness: 100,
    );
  }

  Player generate({
    required int year,
    required Club club,
    PlayerPosition? position,
    int? age,
  }) {
    final selectedPosition = position ?? _position();
    final playerAge = age ?? (16 + random.nextInt(4));

    // Strong academies produce better floor/potential, while weaker clubs
    // still have a chance to discover an exceptional prospect.
    final academyBase = 42 + (club.overall * 0.22).round();
    final floor = (academyBase - 8 + random.nextInt(17)).clamp(40, 72).toInt();
    final potentialBoost = 12 + random.nextInt(24);
    final potential = (floor + potentialBoost + (club.overall >= 80 ? 3 : 0))
        .clamp(floor, 95);

    final stats = _statsFor(selectedPosition, floor);
    final id = 'academy_${year}_${club.id}_${random.nextInt(1 << 30)}';

    return Player(
      id: id,
      name: '${_firstNames[random.nextInt(_firstNames.length)]} ${_lastNames[random.nextInt(_lastNames.length)]}',
      age: playerAge,
      position: selectedPosition,
      nationality: _nationalityForClub(club),
      overall: floor,
      potential: potential,
      pace: stats[0],
      shooting: stats[1],
      passing: stats[2],
      dribbling: stats[3],
      defending: stats[4],
      physical: stats[5],
      value: _marketValue(floor, potential, playerAge),
      weeklyWage: max(100, floor * 95.0),
      clubId: club.id,
      contractYearsRemaining: 3,
      contractRole: 'academy',
      squadStatus: 'academy',
      morale: 72,
      form: 65,
      fitness: 100,
    );
  }

  /// Builds a full first-team squad (~20 players) for a club that has no
  /// (or too few) players yet. Unlike [generate], which produces young
  /// academy prospects, this spreads ages across a realistic senior squad
  /// so a club can actually field 11 players plus bench in the 2D match.
  List<Player> generateFirstTeamSquad({
    required int year,
    required Club club,
    int targetSize = 20,
  }) {
    const positionPlan = <PlayerPosition, int>{
      PlayerPosition.goalkeeper: 3,
      PlayerPosition.defender: 7,
      PlayerPosition.midfielder: 6,
      PlayerPosition.winger: 2,
      PlayerPosition.striker: 2,
    };
    final result = <Player>[];
    var slot = 0;
    for (final entry in positionPlan.entries) {
      for (var i = 0; i < entry.value && result.length < targetSize; i++) {
        // Senior squads span ~18-33, weighted toward a 21-29 prime.
        final age = 18 + random.nextInt(16);
        final id = 'squad_${year}_${club.id}_${slot++}_${random.nextInt(1 << 30)}';
        result.add(
          _seniorPlayer(id: id, year: year, club: club, position: entry.key, age: age),
        );
      }
    }
    return result;
  }

  Player _seniorPlayer({
    required String id,
    required int year,
    required Club club,
    required PlayerPosition position,
    required int age,
  }) {
    // Senior first-teamers sit close to the club's overall rating, not the
    // lower academy-prospect floor used by [generate].
    final base = (club.overall - 6 + random.nextInt(13)).clamp(45, 90).toInt();
    final potential = age <= 23
        ? (base + random.nextInt(14)).clamp(base, 95).toInt()
        : base;
    final stats = _statsFor(position, base);
    return Player(
      id: id,
      name: '${_firstNames[random.nextInt(_firstNames.length)]} ${_lastNames[random.nextInt(_lastNames.length)]}',
      age: age,
      position: position,
      nationality: _nationalityForClub(club),
      overall: base,
      potential: potential,
      pace: stats[0],
      shooting: stats[1],
      passing: stats[2],
      dribbling: stats[3],
      defending: stats[4],
      physical: stats[5],
      value: _marketValue(base, potential, age),
      weeklyWage: max(300, base * 140.0),
      clubId: club.id,
      contractYearsRemaining: 1 + random.nextInt(4),
      contractRole: 'firstTeam',
      squadStatus: 'firstTeam',
      morale: 65 + random.nextInt(20),
      form: 55 + random.nextInt(25),
      fitness: 90 + random.nextInt(11),
    );
  }

  /// Creates a small annual academy intake. It does not replace the
  /// retirement system; it gives clubs a sustainable source of new people.
  List<Player> generateSeasonIntake({
    required int year,
    required Club club,
    required int currentSquadSize,
  }) {
    var count = 0;

    if (currentSquadSize < 18) {
      count = 2;
    } else if (currentSquadSize < 22) {
      count = 1 + (random.nextDouble() < 0.35 ? 1 : 0);
    } else if (random.nextDouble() < 0.18) {
      // Even deep squads occasionally promote one academy player.
      count = 1;
    }

    final result = <Player>[];
    final usedPositions = <PlayerPosition>{};
    for (var i = 0; i < count; i++) {
      PlayerPosition? preferred;
      if (i == 0 && random.nextDouble() < 0.55) {
        preferred = _positionNeedingDepth(club, currentSquadSize);
      }
      preferred ??= _position(exclude: usedPositions);
      usedPositions.add(preferred);
      result.add(generate(year: year, club: club, position: preferred));
    }
    return result;
  }

  PlayerPosition _position({Set<PlayerPosition>? exclude}) {
    final positions = PlayerPosition.values
        .where((p) => !(exclude?.contains(p) ?? false))
        .toList();
    return positions[random.nextInt(positions.length)];
  }

  PlayerPosition _positionNeedingDepth(Club club, int currentSquadSize) {
    // Without inventing a separate squad-needs model, distribute academy
    // intakes across the five football positions. ClubAI will later make the
    // strategic decision about buying instead of promoting.
    final weights = <PlayerPosition, int>{
      PlayerPosition.goalkeeper: 1,
      PlayerPosition.defender: 3,
      PlayerPosition.midfielder: 3,
      PlayerPosition.winger: 2,
      PlayerPosition.striker: 2,
    };
    final total = weights.values.fold<int>(0, (a, b) => a + b);
    var roll = random.nextInt(total);
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return PlayerPosition.midfielder;
  }

  List<int> _statsFor(PlayerPosition position, int base) {
    int stat(int bonus) => (base + bonus + random.nextInt(13) - 6).clamp(1, 99).toInt();
    switch (position) {
      case PlayerPosition.goalkeeper:
        return [stat(-3), stat(-2), stat(2), stat(-3), stat(4), stat(2)];
      case PlayerPosition.defender:
        return [stat(0), stat(-2), stat(2), stat(-1), stat(6), stat(4)];
      case PlayerPosition.midfielder:
        return [stat(1), stat(1), stat(5), stat(3), stat(2), stat(1)];
      case PlayerPosition.winger:
        return [stat(6), stat(3), stat(1), stat(5), stat(-3), stat(0)];
      case PlayerPosition.striker:
        return [stat(3), stat(7), stat(0), stat(3), stat(-4), stat(2)];
    }
  }

  double _marketValue(int overall, int potential, int age) {
    final ageMultiplier = age <= 19 ? 1.25 : 1.0;
    final potentialMultiplier = 1.0 + ((potential - overall).clamp(0, 30) / 60);
    return max(25000, pow(overall / 45, 4) * 70000 * ageMultiplier * potentialMultiplier).toDouble();
  }

  String _nationalityForClub(Club club) {
    // Current data does not expose a country on every club in a consistent
    // way, so use a broad football nationality pool. Transfers can later
    // modify nationality distribution through scouting/recruitment systems.
    return _nations[random.nextInt(_nations.length)];
  }

  static const _firstNames = [
    'Mateo', 'Kacper', 'Szymon', 'Nico', 'Lucas', 'Julian', 'Marco', 'Leo',
    'Jakub', 'Filip', 'Jan', 'Gabriel', 'Adrian', 'Milan', 'Noah', 'Oskar',
  ];
  static const _lastNames = [
    'Nowak', 'Rossi', 'Silva', 'Müller', 'Kowalski', 'Garcia', 'Weber',
    'Wiśniewski', 'Zieliński', 'Dubois', 'Martins', 'Kovac', 'Santos',
  ];
  static const _nations = [
    'Polska', 'Niemcy', 'Hiszpania', 'Włochy', 'Francja', 'Brazylia',
    'Argentyna', 'Chorwacja', 'Portugalia', 'Holandia', 'Anglia',
  ];
}
