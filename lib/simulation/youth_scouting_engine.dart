import 'dart:math';

import '../models/academy_profile.dart';
import '../models/club.dart';
import '../models/player.dart';
import '../models/youth_prospect.dart';

/// V11.1 youth pipeline: clubs discover prospects instead of directly
/// rolling complete players. The returned prospect is deliberately richer
/// than the eventual Player, so future stages can add contracts, agents and
/// debut events without changing the scouting layer.
class YouthScoutingEngine {
  final Random _random;

  YouthScoutingEngine({Random? random}) : _random = random ?? Random();

  List<YouthProspect> discover({
    required int year,
    required Club club,
    required List<Player> players,
    int? requestedCount,
  }) {
    final profile = AcademyProfile.fromClub(
      academyQuality: club.academyQuality,
      youthFocus: club.youthFocus,
      reputation: club.reputation,
      stability: club.stability,
    );

    final count = requestedCount ?? _intakeCount(club, players, profile);
    if (count <= 0) return const [];

    final result = <YouthProspect>[];
    final usedPositions = <PlayerPosition>{};
    for (var i = 0; i < count; i++) {
      final position = _neededPosition(club, players, exclude: usedPositions);
      usedPositions.add(position);
      result.add(_createProspect(year, club, profile, position, i));
    }
    return result;
  }

  int _intakeCount(Club club, List<Player> players, AcademyProfile profile) {
    final size = players.where((p) => p.clubId == club.id).length;
    if (size < 18) return 2;
    if (size < 22) return _random.nextDouble() < .70 ? 2 : 1;
    if (club.youthFocus >= 75 && _random.nextDouble() < .55) return 1;
    return _random.nextDouble() < profile.promotionRate / 500 ? 1 : 0;
  }

  PlayerPosition _neededPosition(
    Club club,
    List<Player> players, {
    Set<PlayerPosition>? exclude,
  }) {
    final counts = <PlayerPosition, int>{
      for (final p in PlayerPosition.values) p: 0,
    };
    for (final player in players.where((p) => p.clubId == club.id)) {
      counts[player.position] = (counts[player.position] ?? 0) + 1;
    }

    final weights = <PlayerPosition, int>{};
    for (final position in PlayerPosition.values) {
      final desired = switch (position) {
        PlayerPosition.goalkeeper => 3,
        PlayerPosition.defender => 7,
        PlayerPosition.midfielder => 7,
        PlayerPosition.winger => 4,
        PlayerPosition.striker => 4,
      };
      final shortage = max(1, desired - (counts[position] ?? 0));
      weights[position] = shortage * shortage;
    }

    final available = weights.entries.where((e) => !(exclude?.contains(e.key) ?? false)).toList();
    final pool = available.isEmpty ? weights.entries.toList() : available;
    final total = pool.fold<int>(0, (sum, e) => sum + e.value);
    var roll = _random.nextInt(max(1, total));
    for (final entry in pool) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return PlayerPosition.midfielder;
  }

  YouthProspect _createProspect(
    int year,
    Club club,
    AcademyProfile profile,
    PlayerPosition position,
    int index,
  ) {
    final region = _regionFor(club.country);
    final local = _localAffinity(club.country, profile);
    final dnaBonus = (_positionDna(club, position) - 50) * .12;
    final reputationBonus = (club.academyReputation - 50) * .08;
    final rawTalent = (38 +
            profile.quality * .20 +
            profile.scoutingNetwork * .10 +
            club.reputation * .05 +
            dnaBonus + reputationBonus +
            _random.nextInt(23))
        .round()
        .clamp(40, 78).toInt();
    final hiddenPotential = (rawTalent +
            8 +
            profile.developmentQuality ~/ 8 +
            _random.nextInt(17))
        .clamp(rawTalent + 5, 96).toInt();
    final error = max(3, 14 - profile.scoutingNetwork ~/ 9);
    final minEstimate = max(rawTalent, hiddenPotential - error - _random.nextInt(4));
    final maxEstimate = min(99, hiddenPotential + _random.nextInt(error + 1));
    final confidence = (45 + profile.scoutingNetwork ~/ 2 + _random.nextInt(21)).clamp(40, 98).toInt();

    return YouthProspect(
      id: 'prospect_${year}_${club.id}_${index}_${_random.nextInt(1 << 30)}',
      name: '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}',
      birthYear: year - (15 + _random.nextInt(3)),
      age: 15 + _random.nextInt(3),
      position: position,
      nationality: _nationalityForClub(club.country),
      region: region,
      rawTalent: rawTalent,
      hiddenPotential: hiddenPotential,
      scoutingEstimateMin: minEstimate,
      scoutingEstimateMax: maxEstimate,
      scoutingConfidence: confidence,
      professionalism: (45 + _random.nextInt(51)).clamp(1, 99).toInt(),
      ambition: (40 + _random.nextInt(56)).clamp(1, 99).toInt(),
      loyalty: (40 + local ~/ 2 + _random.nextInt(31)).clamp(1, 99).toInt(),
      adaptability: (45 + _random.nextInt(51)).clamp(1, 99).toInt(),
      localAffinity: local,
      scoutingPath: _scoutingPath(profile, local),
      clubId: club.id,
    );
  }

  int _positionDna(Club club, PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper: return (club.academyTactical * .5 + club.academyPhysical * .5).round();
      case PlayerPosition.defender: return (club.academyTactical * .6 + club.academyPhysical * .4).round();
      case PlayerPosition.midfielder: return (club.academyTechnical * .35 + club.academyCreative * .35 + club.academyTactical * .30).round();
      case PlayerPosition.winger: return (club.academyCreative * .5 + club.academyTechnical * .3 + club.academyPhysical * .2).round();
      case PlayerPosition.striker: return (club.academyCreative * .35 + club.academyTechnical * .35 + club.academyPhysical * .3).round();
    }
  }

  int _localAffinity(String country, AcademyProfile profile) =>
      (profile.localFocus + _random.nextInt(31) - 15).clamp(25, 100).toInt();

  String _scoutingPath(AcademyProfile profile, int localAffinity) {
    if (localAffinity >= 75) return 'regional';
    if (profile.internationalFocus >= 70) return 'international';
    return 'national';
  }

  String _regionFor(String country) {
    const regions = {
      'Polska': 'Polska',
      'Niemcy': 'Niemcy',
      'Hiszpania': 'Hiszpania',
      'Włochy': 'Włochy',
      'Francja': 'Francja',
      'Brazylia': 'Brazylia',
      'Argentyna': 'Argentyna',
      'Chorwacja': 'Bałkany',
      'Portugalia': 'Portugalia',
      'Holandia': 'Beneluks',
      'Anglia': 'Anglia',
    };
    return regions[country] ?? country;
  }

  String _nationalityForClub(String country) {
    final related = <String, List<String>>{
      'Polska': ['Polska', 'Polska', 'Polska', 'Ukraina', 'Czechy'],
      'Portugalia': ['Portugalia', 'Portugalia', 'Brazylia', 'Angola'],
      'Hiszpania': ['Hiszpania', 'Hiszpania', 'Maroko', 'Argentyna'],
      'Francja': ['Francja', 'Francja', 'Senegal', 'Algieria'],
      'Niemcy': ['Niemcy', 'Niemcy', 'Turcja', 'Polska'],
      'Holandia': ['Holandia', 'Holandia', 'Surinam', 'Belgia'],
      'Anglia': ['Anglia', 'Anglia', 'Nigeria', 'Irlandia'],
      'Włochy': ['Włochy', 'Włochy', 'Albania', 'Argentyna'],
      'Brazylia': ['Brazylia', 'Brazylia', 'Brazylia', 'Urugwaj'],
      'Argentyna': ['Argentyna', 'Argentyna', 'Argentyna', 'Urugwaj'],
      'Chorwacja': ['Chorwacja', 'Chorwacja', 'Bośnia', 'Serbia'],
    };
    final pool = related[country] ?? [country];
    return pool[_random.nextInt(pool.length)];
  }

  static const _firstNames = [
    'Mateo', 'Kacper', 'Szymon', 'Nico', 'Lucas', 'Julian', 'Marco', 'Leo',
    'Jakub', 'Filip', 'Jan', 'Gabriel', 'Adrian', 'Milan', 'Noah', 'Oskar',
  ];
  static const _lastNames = [
    'Nowak', 'Rossi', 'Silva', 'Müller', 'Kowalski', 'Garcia', 'Weber',
    'Wiśniewski', 'Zieliński', 'Dubois', 'Martins', 'Kovac', 'Santos',
  ];
}
