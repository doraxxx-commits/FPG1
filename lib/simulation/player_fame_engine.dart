import 'dart:math';
import '../models/player.dart';
import '../models/world_event.dart';
import 'media_world_engine.dart';

/// V18.4: Player Fame & Reputation.
/// Fame is persistent social/market memory, not another OVR.
class PlayerFameEngine {
  final Random _random;
  PlayerFameEngine({Random? random}) : _random = random ?? Random();

  void processDay({required List<Player> players, required List<WorldEvent> events, required List<MediaStory> mediaStories, required int absoluteDay}) {
    for (final player in players) {
      _ensureBaseline(player);
      final before = player.fame;
      for (final event in events.where((e) => e.playerId == player.id)) {
        _applyEvent(player, event);
      }
      for (final story in mediaStories.where((s) => s.playerId == player.id)) {
        _applyStory(player, story);
      }
      if (player.appearances > 0) {
        if (player.form >= 80) player.fame++;
        if (player.form <= 45) player.fame--;
      }
      if (player.internationalCaps > 0 && player.lastMatchDay == absoluteDay) player.fame++;

      if (player.fame > 50 && player.form < 55) player.fame--;
      if (player.fame < 50 && player.form > 75) player.fame++;
      player.mediaPressure = max(0, player.mediaPressure - 3);

      final target = ((player.fame * .65) + (player.form * .15) + (player.morale * .10) + (player.overall * .10)).round();
      final delta = target - player.reputation;
      if (delta > 0) player.reputation++;
      if (delta < 0) player.reputation--;

      player.fame = player.fame.clamp(0, 100).toInt();
      player.reputation = player.reputation.clamp(1, 100).toInt();
      player.fanSupport = player.fanSupport.clamp(0, 100).toInt();
      player.mediaPressure = player.mediaPressure.clamp(0, 100).toInt();
      player.marketability = _marketability(player);
      player.transferPull = _transferPull(player);
      if ((before - player.fame).abs() > 12) {
        player.fame = (before + (player.fame - before).sign * 12).clamp(0, 100).toInt();
      }
    }
  }

  void _ensureBaseline(Player p) {
    if (p.fame == 0 && p.reputation == 50 && p.marketability == 0) {
      p.fame = (p.overall - 35).clamp(5, 45).toInt();
      p.reputation = (p.overall - 10).clamp(20, 70).toInt();
      p.fanSupport = (p.overall - 20).clamp(15, 60).toInt();
      p.marketability = _marketability(p);
    }
  }

  void _applyEvent(Player p, WorldEvent event) {
    final importance = event.importance.clamp(1, 5).toInt();
    switch (event.type) {
      case 'match':
        p.fame += importance >= 4 ? 2 : 1;
        p.fanSupport += importance >= 3 ? 2 : 1;
        break;
      case 'transfer':
      case 'transfer_interest':
        p.fame += 2; p.marketability += 2; break;
      case 'social_fans':
        p.fanSupport += event.description.toLowerCase().contains('kryty') ? -2 : 2;
        p.mediaPressure += 4; break;
      case 'social_dressing_room':
      case 'social_manager':
        p.mediaPressure += 5; p.reputation -= 1; break;
      case 'injury':
        p.mediaPressure += 2; break;
      case 'manager_change':
        p.mediaPressure += 3; break;
    }
  }

  void _applyStory(Player p, MediaStory story) {
    final multiplier = (story.credibility / 100.0) * (story.heat / 100.0);
    final negative = _negativeStory(story);
    final sign = negative ? -1 : 1;
    final base = max(1, (2 + story.stage) * multiplier).round();
    p.fame += sign * (base ~/ 2);
    p.reputation += sign * base;
    p.fanSupport += sign * (story.type == 'fan_pressure' ? base : max(1, base ~/ 2));
    p.mediaPressure += (story.heat * .12).round();
    if (!negative) p.marketability += max(1, base ~/ 2);
  }

  bool _negativeStory(MediaStory story) {
    final text = '${story.type} ${story.title} ${story.body}'.toLowerCase();
    return text.contains('presją') || text.contains('konflikt') || text.contains('problem') ||
        text.contains('niepewność') || text.contains('kryty') || text.contains('kontuz') || text.contains('odejść');
  }

  int _marketability(Player p) => (p.fame * .42 + p.reputation * .25 + p.overall * .18 + p.fanSupport * .10 + p.form * .05).round().clamp(1, 100).toInt();
  int _transferPull(Player p) => (p.overall * .45 + p.potential * .20 + p.fame * .15 + p.reputation * .10 + p.marketability * .10).round().clamp(1, 100).toInt();
}
