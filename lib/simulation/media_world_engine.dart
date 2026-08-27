import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';

/// V18.3: Media World.
///
/// Media is a persistent interpretation layer over real world events. It does
/// not invent an unrelated universe: headlines, rumours and follow-ups are
/// derived from the same events produced by the autonomous world.
class MediaStory {
  final String id;
  final String type;
  String title;
  String body;
  String source;
  int credibility;
  int heat;
  int stage;
  final String? clubId;
  final String? playerId;
  int year;
  int month;
  int day;

  MediaStory({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.source,
    required this.credibility,
    required this.heat,
    required this.stage,
    this.clubId,
    this.playerId,
    required this.year,
    required this.month,
    required this.day,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'source': source,
        'credibility': credibility,
        'heat': heat,
        'stage': stage,
        'clubId': clubId,
        'playerId': playerId,
        'year': year,
        'month': month,
        'day': day,
      };

  factory MediaStory.fromJson(Map<String, dynamic> j) => MediaStory(
        id: '${j['id'] ?? ''}',
        type: '${j['type'] ?? 'news'}',
        title: '${j['title'] ?? 'Wiadomość'}',
        body: '${j['body'] ?? ''}',
        source: '${j['source'] ?? 'FPG Media'}',
        credibility: (j['credibility'] as num?)?.toInt() ?? 60,
        heat: (j['heat'] as num?)?.toInt() ?? 30,
        stage: (j['stage'] as num?)?.toInt() ?? 1,
        clubId: j['clubId']?.toString(),
        playerId: j['playerId']?.toString(),
        year: (j['year'] as num?)?.toInt() ?? 2026,
        month: (j['month'] as num?)?.toInt() ?? 1,
        day: (j['day'] as num?)?.toInt() ?? 1,
      );
}

class MediaWorldEngine {
  final Random _random;
  final List<MediaStory> stories = [];
  final Map<String, int> _lastStoryDay = {};

  MediaWorldEngine({Random? random}) : _random = random ?? Random();

  List<MediaStory> processDay({
    required List<WorldEvent> events,
    required List<Club> clubs,
    required List<Player> players,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    final generated = <MediaStory>[];

    final important = events
        .where((e) => e.importance >= 2)
        .toList()
      ..sort((a, b) => b.importance.compareTo(a.importance));

    for (final event in important.take(8)) {
      final key = '${event.type}:${event.clubId ?? ''}:${event.playerId ?? ''}';
      final last = _lastStoryDay[key];

      if (last != null && absoluteDay - last < 2) continue;
      _lastStoryDay[key] = absoluteDay;

      final story = _fromEvent(event, clubs, players, year, month, day);
      if (story == null) continue;
      stories.add(story);
      generated.add(story);
    }

    // A transfer request becomes a rumour only after it has persisted for a
    // while. This prevents every unhappy player from generating daily spam.
    for (final player in players.where((p) => p.transferRequest && p.clubId != null).take(6)) {
      final club = clubs.where((c) => c.id == player.clubId).firstOrNull;
      if (club == null) continue;
      final key = 'rumour:${player.id}';
      final last = _lastStoryDay[key];
      if (last != null && absoluteDay - last < 7) continue;
      if (player.consecutiveBenchDays < 7 && player.morale > 40) continue;

      _lastStoryDay[key] = absoluteDay;
      final story = MediaStory(
        id: 'media_${absoluteDay}_${player.id}_${_random.nextInt(9999)}',
        type: 'rumour',
        title: 'Niepewność wokół ${player.name}',
        body: 'Wokół ${player.name} i ${club.name} narasta temat przyszłości zawodnika. Źródła sugerują, że sytuacja może wpłynąć na rynek transferowy.',
        source: 'FPG Insider',
        credibility: 58 + _random.nextInt(20),
        heat: 45 + _random.nextInt(25),
        stage: 1,
        clubId: club.id,
        playerId: player.id,
        year: year,
        month: month,
        day: day,
      );
      stories.add(story);
      generated.add(story);
    }

    _advanceStories(absoluteDay);
    if (stories.length > 150) {
      stories.removeRange(0, stories.length - 150);
    }

    return generated;
  }

  MediaStory? _fromEvent(
    WorldEvent event,
    List<Club> clubs,
    List<Player> players,
    int year,
    int month,
    int day,
  ) {
    final club = event.clubId == null
        ? null
        : clubs.where((c) => c.id == event.clubId).firstOrNull;
    final player = event.playerId == null
        ? null
        : players.where((p) => p.id == event.playerId).firstOrNull;

    String title = event.title;
    String body = event.description;
    String source = 'FPG News';
    String type = 'news';
    int credibility = 82;
    int heat = min(95, 25 + event.importance * 14);
    int stage = 1;

    switch (event.type) {
      case 'transfer':
        type = 'transfer';
        source = 'Transfer Desk';
        credibility = 90;
        heat += 15;
        break;
      case 'manager_change':
        type = 'breaking';
        source = 'Football Desk';
        credibility = 96;
        heat = 85;
        break;
      case 'social_dressing_room':
      case 'social_manager':
        type = 'insider';
        source = 'FPG Insider';
        credibility = 64;
        heat = 62;
        stage = 2;
        break;
      case 'social_fans':
        type = 'fan_pressure';
        source = 'Stadium Report';
        credibility = 78;
        heat = 58;
        break;
      case 'finance':
        type = 'finance';
        source = 'Business of Football';
        credibility = 88;
        heat = 48;
        break;
      case 'match':
        type = 'match';
        source = 'FPG Match Centre';
        credibility = 99;
        heat = event.importance >= 2 ? 60 : 35;
        break;
    }

    if (club != null && event.type == 'match' && club.lossesStreak >= 3) {
      title = '${club.name} pod presją po kolejnej wpadce';
      body = '${event.description} Seria wyników zwiększa zainteresowanie sytuacją trenera i zarządu.';
      type = 'analysis';
      source = 'FPG Football Desk';
      credibility = 86;
      heat = 72;
    }

    if (player != null && event.type.contains('social')) {
      body = '${event.description} Media zaczynają obserwować sytuację ${player.name} bliżej.';
    }

    return MediaStory(
      id: 'media_${year}_${month}_${day}_${event.type}_${_random.nextInt(999999)}',
      type: type,
      title: title,
      body: body,
      source: source,
      credibility: credibility,
      heat: heat.clamp(0, 100),
      stage: stage,
      clubId: event.clubId,
      playerId: event.playerId,
      year: year,
      month: month,
      day: day,
    );
  }

  void _advanceStories(int absoluteDay) {
    for (final story in stories) {
      if (absoluteDay - _toAbsoluteDay(story) >= 1) {
        story.heat = max(0, story.heat - 5);
      }
      if (story.heat >= 70 && story.stage < 3 && absoluteDay - _toAbsoluteDay(story) >= 2) {
        story.stage++;
      }
    }
  }

  int _toAbsoluteDay(MediaStory story) {
    var total = 0;
    for (var y = 1; y < story.year; y++) {
      total += (y % 400 == 0 || (y % 4 == 0 && y % 100 != 0)) ? 366 : 365;
    }
    const monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    for (var m = 1; m < story.month; m++) {
      total += monthDays[m - 1];
      if (m == 2 && (story.year % 400 == 0 || (story.year % 4 == 0 && story.year % 100 != 0))) total++;
    }
    return total + story.day;
  }

  List<MediaStory> forClub(String? clubId) => stories
      .where((s) => clubId == null || s.clubId == clubId)
      .toList()
      .reversed
      .toList();

  List<MediaStory> get latest => stories.reversed.toList();

  Map<String, dynamic> toJson() => {
        'stories': stories.map((s) => s.toJson()).toList(),
        'lastStoryDay': _lastStoryDay,
      };

  void restoreFromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    stories.clear();
    _lastStoryDay.clear();
    final rawStories = json['stories'];
    if (rawStories is List) {
      for (final raw in rawStories) {
        if (raw is Map) stories.add(MediaStory.fromJson(Map<String, dynamic>.from(raw)));
      }
    }
    final rawLast = json['lastStoryDay'];
    if (rawLast is Map) {
      for (final e in rawLast.entries) {
        final value = e.value is num ? (e.value as num).toInt() : int.tryParse('${e.value}');
        if (value != null) _lastStoryDay[e.key.toString()] = value;
      }
    }
    if (stories.length > 150) stories.removeRange(0, stories.length - 150);
  }
}
