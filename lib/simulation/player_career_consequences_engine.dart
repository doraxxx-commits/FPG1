import 'dart:math';

import '../models/player.dart';
import '../models/world_event.dart';

/// V18.5: Fame is now allowed to create career consequences.
/// The engine is deliberately deterministic in direction: fame opens doors,
/// pressure creates costs, and sustained performance converts attention into
/// real career opportunities.
class PlayerCareerConsequencesEngine {
  final Random _random;
  PlayerCareerConsequencesEngine({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processDay({
    required List<Player> players,
    required int year,
    required int month,
    required int day,
    required int absoluteDay,
  }) {
    final events = <WorldEvent>[];
    for (final p in players) {
      _ensure(p);
      _decay(p);

      if (p.fame >= 75 && p.marketability >= 70 && p.form >= 65) {
        p.sponsorInterest = min(100, p.sponsorInterest + 2);
        p.agentAttention = min(100, p.agentAttention + 1);
        p.interviewInvites = min(99, p.interviewInvites + 1);
        p.shirtDemand = min(100, p.shirtDemand + 1);
      } else if (p.fame >= 55) {
        p.sponsorInterest = min(100, p.sponsorInterest + 1);
        p.agentAttention = min(100, p.agentAttention + 1);
      }

      // Strong fame creates occasional commercial opportunities, but never daily spam.
      if (p.sponsorInterest >= 78 && p.fame >= 70 && p.form >= 60 && _random.nextInt(100) < 7) {
        p.sponsorTier = min(3, p.sponsorTier + 1);
        p.sponsorIncome = max(p.sponsorIncome, _sponsorIncome(p));
        p.commercialEvents++;
        events.add(_event(
          year, month, day, 'commercial', p,
          'Sponsorzy zwracają uwagę na ${p.name}',
          '${p.name} zaczyna być postrzegany jako coraz bardziej atrakcyjna postać marketingowa. Pojawia się realne zainteresowanie współpracą sponsorską.',
          3,
        ));
      }

      if (p.fame >= 65 && p.interviewInvites > 0 && _random.nextInt(100) < 8) {
        p.interviewInvites--;
        p.mediaAppearances++;
        p.mediaPressure = min(100, p.mediaPressure + 4);
        events.add(_event(
          year, month, day, 'media_interview', p,
          '${p.name} coraz częściej w centrum uwagi',
          'Rosnąca popularność zawodnika sprawia, że media coraz częściej proszą go o komentarz i udział w wywiadach.',
          2,
        ));
      }

      // Popularity is useful, but the dressing room and manager can react to pressure.
      final pressure = (p.mediaPressure + (p.fame - p.reputation).abs() ~/ 2);
      if (pressure >= 80) {
        p.coachPressure = min(100, p.coachPressure + 2);
        if (p.managerRelationship > 25) p.managerRelationship--;
      } else if (p.mediaPressure <= 25 && p.form >= 70) {
        p.coachPressure = max(0, p.coachPressure - 1);
      }

      if (p.fame >= 60 && p.fanSupport >= 65 && p.form >= 65) {
        p.shirtDemand = min(100, p.shirtDemand + 1);
        if (_random.nextInt(100) < 3) {
          p.fanMoments++;
          events.add(_event(
            year, month, day, 'fan_reaction', p,
            'Kibice coraz mocniej stoją za ${p.name}',
            'Dobra forma i rosnąca rozpoznawalność przekładają się na wyraźnie pozytywną reakcję trybun.',
            2,
          ));
        }
      }

      // Fame can attract agents and clubs, but the existing transfer system still decides transfers.
      if (p.agentAttention >= 75 && p.fame >= 60) {
        p.clubInterestLevel = min(100, p.clubInterestLevel + 1);
      }
      p.marketingValue = (p.marketability * 0.65 + p.fame * 0.35).round().clamp(0, 100).toInt();
    }
    return events;
  }

  void _ensure(Player p) {
    if (p.sponsorInterest == 0 && p.fame > 0) {
      p.sponsorInterest = (p.fame * .55).round();
    }
    if (p.agentAttention == 0 && p.fame > 40) {
      p.agentAttention = (p.fame * .45).round();
    }
    if (p.shirtDemand == 0 && p.fame > 30) {
      p.shirtDemand = (p.fame * .35).round();
    }
  }

  void _decay(Player p) {
    if (p.fame < 45) p.sponsorInterest = max(0, p.sponsorInterest - 1);
    if (p.fame < 40) p.agentAttention = max(0, p.agentAttention - 1);
    if (p.mediaPressure < 40) p.coachPressure = max(0, p.coachPressure - 1);
    p.shirtDemand = max(0, p.shirtDemand - (p.fame < 35 ? 1 : 0));
    p.marketingValue = (p.marketability * 0.65 + p.fame * 0.35).round().clamp(0, 100).toInt();
  }

  int _sponsorIncome(Player p) {
    final base = p.marketability * 250;
    return (base * (1 + p.sponsorTier * .75)).round();
  }

  WorldEvent _event(int year, int month, int day, String type, Player p, String title, String description, int importance) => WorldEvent(
    year: year, month: month, day: day, type: type,
    title: title, description: description, playerId: p.id, importance: importance,
  );
}
