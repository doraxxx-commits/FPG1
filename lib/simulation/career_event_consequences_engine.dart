import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';

/// V19.1 — Career Events & Consequences.
///
/// Converts important career decisions into persistent world consequences.
/// This engine does not create a parallel simulation: it observes the same
/// player/club state used by transfers, contracts, media and social systems.
class CareerEventConsequencesEngine {
  final Random _random;
  final Map<String, int> _cooldowns = {};
  final Map<String, int> _flags = {};

  CareerEventConsequencesEngine({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processDay({
    required List<Player> players,
    required List<Club> clubs,
    required int year,
    required int month,
    required int day,
    required int absoluteDay,
  }) {
    final events = <WorldEvent>[];
    _cooldowns.removeWhere((_, until) => until <= absoluteDay);

    for (final p in players) {
      final club = p.clubId == null
          ? null
          : clubs.where((c) => c.id == p.clubId).firstOrNull;
      if (club == null) continue;

      // Rejecting/ending a contract negotiation creates pressure only after
      // it persists. This prevents one decision from spamming daily news.
      if (p.happiness <= 35 && p.contractYearsRemaining <= 1 &&
          _ready('contract_pressure:${p.id}', absoluteDay, 7)) {
        p.coachPressure = min(100, p.coachPressure + 3);
        p.managerRelationship = max(0, p.managerRelationship - 2);
        events.add(_event(
          year, month, day, 'career_contract_pressure', p,
          'Napięcie wokół przyszłości ${p.name}',
          '${p.name} nadal nie osiągnął porozumienia z ${club.name}. W klubie rośnie presja, a temat przyszłości zawodnika zaczyna żyć własnym życiem.',
          club.id, 3,
        ));
      }

      // A transfer request combined with media heat escalates into a genuine
      // career storyline rather than immediately forcing a transfer.
      if (p.transferRequest && p.mediaPressure >= 55 &&
          _ready('transfer_pressure:${p.id}', absoluteDay, 6)) {
        p.fanSupport = max(0, p.fanSupport - 2);
        p.coachPressure = min(100, p.coachPressure + 4);
        events.add(_event(
          year, month, day, 'career_transfer_pressure', p,
          'Presja wokół przyszłości ${p.name} rośnie',
          'Nasilająca się presja medialna i żądanie transferu sprawiają, że ${club.name} musi zająć stanowisko w sprawie zawodnika.',
          club.id, 4,
        ));
      }

      // High fame + good fan support can turn a positive career choice into
      // a tangible boost in commercial momentum.
      if (p.sponsorTier > 0 && p.fanSupport >= 70 && p.fame >= 70 &&
          p.form >= 65 && _ready('sponsor_success:${p.id}', absoluteDay, 14)) {
        p.sponsorInterest = min(100, p.sponsorInterest + 4);
        p.marketingValue = min(100, p.marketingValue + 2);
        p.fanMoments++;
        events.add(_event(
          year, month, day, 'career_sponsor_success', p,
          'Popularność ${p.name} przyciąga nowych partnerów',
          'Udana współpraca komercyjna i dobra forma zwiększają zainteresowanie markami oraz kibicami.',
          club.id, 2,
        ));
      }

      // Media choices have a delayed cost when pressure gets very high.
      if (p.mediaPressure >= 88 && p.mediaAppearances >= 3 &&
          _ready('media_pressure:${p.id}', absoluteDay, 10)) {
        p.happiness = max(15, p.happiness - 2);
        p.coachPressure = min(100, p.coachPressure + 2);
        events.add(_event(
          year, month, day, 'career_media_pressure', p,
          'Rosnąca presja medialna zaczyna ciążyć',
          '${p.name} jest coraz częściej obecny w mediach. Klub i sztab zaczynają oczekiwać większego skupienia na boisku.',
          club.id, 3,
        ));
      }

      // Very strong fan support can protect the player from a bad spell.
      if (p.fanSupport >= 82 && p.form < 55 &&
          _ready('fan_protection:${p.id}', absoluteDay, 14)) {
        p.happiness = min(100, p.happiness + 3);
        events.add(_event(
          year, month, day, 'career_fan_support', p,
          'Kibice stają za ${p.name}',
          'Mimo słabszej formy trybuny okazują zawodnikowi wsparcie. Presja wyniku jest odczuwalna, ale relacja z kibicami pozostaje mocna.',
          club.id, 2,
        ));
      }

      // Agent pressure: high attention without a transfer opportunity creates
      // a conversation rather than an automatic move.
      if (p.agentAttention >= 82 && p.clubInterestLevel >= 70 &&
          !p.transferRequest && _ready('agent_talk:${p.id}', absoluteDay, 21)) {
        p.happiness = min(100, p.happiness + 1);
        events.add(_event(
          year, month, day, 'career_agent_talk', p,
          'Agent rozmawia z ${p.name} o przyszłości',
          'Zwiększone zainteresowanie rynku skłania agenta do rozmowy o dalszym rozwoju kariery i możliwych opcjach.',
          club.id, 2,
        ));
      }
    }

    return events;
  }

  /// Called by the Decision Center immediately after a player makes a choice.
  WorldEvent? decisionEvent({
    required String decision,
    required String category,
    required Player player,
    Club? club,
    required int year,
    required int month,
    required int day,
  }) {
    final clubName = club?.name ?? 'klub';
    switch ('$category:$decision') {
      case 'transfer:reject':
        player.happiness = max(10, player.happiness - 2);
        player.clubInterestLevel = max(0, player.clubInterestLevel - 3);
        return _event(year, month, day, 'career_decision_transfer_reject', player,
            'Zawodnik odrzuca ofertę transferową',
            '${player.name} odrzucił warunki przedstawione przez $clubName. Agent rozpoczyna analizę kolejnych możliwości.',
            club?.id, 3);
      case 'transfer:negotiate':
        player.mediaPressure = min(100, player.mediaPressure + 2);
        return _event(year, month, day, 'career_decision_transfer_negotiate', player,
            '${player.name} rozpoczyna negocjacje',
            '${player.name} nie zamyka drzwi przed transferem. Agent wraca do rozmów i próbuje poprawić warunki.',
            club?.id, 3);
      case 'transfer:accept':
        player.happiness = min(100, player.happiness + 2);
        return _event(year, month, day, 'career_decision_transfer_accept', player,
            '${player.name} zaakceptował warunki osobiste',
            '${player.name} zaakceptował warunki osobiste. Teraz kluby muszą doprowadzić do porozumienia transferowego.',
            club?.id, 3);
      case 'contract:reject':
        player.happiness = max(10, player.happiness - 6);
        player.coachPressure = min(100, player.coachPressure + 3);
        return _event(year, month, day, 'career_decision_contract_reject', player,
            '${player.name} odrzuca ofertę kontraktu',
            '${player.name} nie zaakceptował propozycji $clubName. Przyszłość zawodnika staje się jednym z tematów w klubie.',
            club?.id, 4);
      case 'contract:counter':
        player.mediaPressure = min(100, player.mediaPressure + 1);
        return _event(year, month, day, 'career_decision_contract_counter', player,
            '${player.name} wysyła kontrofertę',
            'Agent ${player.name} wraca do rozmów z $clubName. Kluczowe pozostają pensja, długość umowy i rola w zespole.',
            club?.id, 3);
      case 'contract:accept':
        player.happiness = min(100, player.happiness + 5);
        player.mediaPressure = max(0, player.mediaPressure - 2);
        return _event(year, month, day, 'career_decision_contract_accept', player,
            '${player.name} zostaje w klubie',
            'Nowe warunki kontraktu zostały zaakceptowane. Zawodnik deklaruje skupienie na dalszej karierze w $clubName.',
            club?.id, 4);
      case 'sponsor:accept':
        player.fame = min(100, player.fame + 1);
        player.marketingValue = min(100, player.marketingValue + 3);
        return _event(year, month, day, 'career_decision_sponsor_accept', player,
            '${player.name} rozpoczyna współpracę sponsorską',
            'Zawodnik wykorzystuje rosnącą popularność do rozwinięcia swojej obecności komercyjnej.',
            club?.id, 3);
      case 'sponsor:reject':
        player.sponsorInterest = max(0, player.sponsorInterest - 5);
        return _event(year, month, day, 'career_decision_sponsor_reject', player,
            '${player.name} odrzuca ofertę sponsorską',
            'Zawodnik nie zdecydował się na proponowaną współpracę. Kolejne marki mogą podejść do niego ostrożniej.',
            club?.id, 2);
      case 'interview:accept':
        player.fame = min(100, player.fame + 1);
        player.mediaPressure = min(100, player.mediaPressure + 5);
        return _event(year, month, day, 'career_decision_interview_accept', player,
            '${player.name} pojawia się w mediach',
            'Zawodnik przyjął zaproszenie do wywiadu. Popularność rośnie, ale wraz z nią rośnie oczekiwanie kolejnych występów.',
            club?.id, 2);
      case 'interview:reject':
        player.mediaPressure = max(0, player.mediaPressure - 2);
        return _event(year, month, day, 'career_decision_interview_reject', player,
            '${player.name} odmawia wywiadu',
            'Zawodnik ograniczył aktywność medialną, wybierając większe skupienie na treningach i meczach.',
            club?.id, 1);
    }
    return null;
  }

  bool _ready(String key, int absoluteDay, int days) {
    final until = _cooldowns[key];
    if (until != null && until > absoluteDay) return false;
    _cooldowns[key] = absoluteDay + days;
    return true;
  }

  WorldEvent _event(int year, int month, int day, String type, Player p,
      String title, String description, String? clubId, int importance) => WorldEvent(
        year: year,
        month: month,
        day: day,
        type: type,
        title: title,
        description: description,
        playerId: p.id,
        clubId: clubId,
        importance: importance,
      );

  Map<String, dynamic> toJson() => {
        'cooldowns': Map<String, int>.from(_cooldowns),
        'flags': Map<String, int>.from(_flags),
      };

  void restoreFromJson(Map<String, dynamic>? json) {
    _cooldowns.clear();
    _flags.clear();
    if (json == null) return;
    final rawCooldowns = json['cooldowns'];
    if (rawCooldowns is Map) {
      for (final e in rawCooldowns.entries) {
        final value = e.value is num ? (e.value as num).toInt() : int.tryParse('${e.value}');
        if (value != null) _cooldowns[e.key.toString()] = value;
      }
    }
    final rawFlags = json['flags'];
    if (rawFlags is Map) {
      for (final e in rawFlags.entries) {
        final value = e.value is num ? (e.value as num).toInt() : int.tryParse('${e.value}');
        if (value != null) _flags[e.key.toString()] = value;
      }
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
