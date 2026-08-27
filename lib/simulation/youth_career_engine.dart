import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';

/// V11.1B: prowadzi młodego zawodnika od akademii do profesjonalnej piłki.
/// Nie symuluje każdego treningu - podejmuje decyzje na granicach etapów kariery.
class YouthCareerEngine {
  final Random _random;

  YouthCareerEngine({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processSeason({
    required int year,
    required List<Club> clubs,
    required List<Player> players,
  }) {
    final events = <WorldEvent>[];

    for (final player in players.where((p) => p.clubId != null && p.age <= 24)) {
      final club = _clubFor(player, clubs);
      if (club == null) continue;

      if (!player.hasProfessionalContract && player.age >= 18) {
        final promoted = _shouldPromote(player, club);
        player.hasProfessionalContract = true;
        player.firstContractYear = year;
        player.contractYearsRemaining = promoted ? 3 + _random.nextInt(2) : 2;
        player.contractRole = promoted ? 'development' : 'academy';
        player.careerStage = promoted ? 'firstTeamCandidate' : 'reserves';
        player.squadStatus = promoted ? 'reserves' : 'academy';
        player.preferences.preferredRole = promoted ? 'development' : 'academy';

        events.add(_event(
          year, player, club, 'first_contract',
          promoted ? 'Pierwszy profesjonalny kontrakt' : 'Kontrakt profesjonalny, ale bez awansu',
          promoted
              ? '${player.name} podpisał pierwszy profesjonalny kontrakt z ${club.name} i został włączony do planów pierwszego zespołu.'
              : '${player.name} podpisał profesjonalny kontrakt z ${club.name}, ale pozostaje na ścieżce rezerw/rozwoju.',
          promoted ? 3 : 2,
        ));
      }

      if (player.hasProfessionalContract && player.age >= 18 && player.appearances == 0) {
        final debutReady = _debutChance(player, club);
        if (_random.nextDouble() < debutReady) {
          player.careerStage = 'firstTeam';
          player.squadStatus = 'reserves';
          player.morale = min(100, player.morale + 5);
          events.add(_event(
            year, player, club, 'debut_ready',
            'Młody zawodnik jest gotowy na debiut',
            '${player.name} został przesunięty bliżej pierwszego zespołu ${club.name}. Jego debiut staje się realną możliwością.',
            2,
          ));
        }
      }

      // Gdy klub ma zbyt dużą konkurencję, zawodnik trafia na listę do rozwoju.
      // LoanNegotiationEngine może następnie przeprowadzić faktyczne wypożyczenie.
      if (player.age >= 19 && player.age <= 22 && player.appearances == 0 &&
          player.squadStatus != 'academy' && _shouldPrepareLoan(player, club, players)) {
        player.squadStatus = 'reserves';
        player.contractRole = 'loanCandidate';
        player.careerStage = 'loanCandidate';
        events.add(_event(
          year, player, club, 'loan_candidate',
          'Klub rozważa wypożyczenie młodego zawodnika',
          '${player.name} potrzebuje regularnych minut. ${club.name} może poszukać dla niego wypożyczenia rozwojowego.',
          2,
        ));
      }
    }

    return events;
  }

  bool _shouldPromote(Player player, Club club) {
    final qualityGap = player.overall - club.overall;
    final personality = player.personality.professionalism * .08 +
        player.personality.adaptability * .05 +
        player.personality.discipline * .03;
    final score = club.youthFocus * .35 + player.overall * .40 +
        (player.potential - player.overall) * .25 + personality + qualityGap * .5;
    final threshold = 58 + club.boardPressure * .08;
    return score >= threshold || (club.youthFocus >= 80 && player.potential >= 78);
  }

  double _debutChance(Player player, Club club) {
    var chance = 0.06;
    chance += club.youthFocus / 500.0;
    chance += club.managerQuality / 900.0;
    chance += player.personality.professionalism / 1800.0;
    chance += max(0, player.overall - club.overall + 12) / 700.0;
    chance += max(0, player.potential - player.overall) / 1200.0;
    if (player.preferences.minutesExpectation >= 75) chance += .01;
    return chance.clamp(.04, .24);
  }

  bool _shouldPrepareLoan(Player player, Club club, List<Player> players) {
    final samePosition = players.where((p) => p.clubId == club.id && p.position == player.position && p.id != player.id).toList();
    final better = samePosition.where((p) => p.overall >= player.overall + 5).length;
    final minutesNeed = player.preferences.minutesExpectation >= 65;
    return better >= 2 && minutesNeed && player.potential >= player.overall + 10;
  }

  Club? _clubFor(Player player, List<Club> clubs) {
    for (final club in clubs) {
      if (club.id == player.clubId) return club;
    }
    return null;
  }

  WorldEvent _event(int year, Player player, Club club, String type, String title, String description, int importance) {
    return WorldEvent(
      year: year,
      month: 7,
      day: 1,
      type: type,
      title: title,
      description: description,
      clubId: club.id,
      playerId: player.id,
      importance: importance,
    );
  }
}
