import 'dart:math';

import '../models/club.dart';
import '../models/player.dart';
import '../models/world_event.dart';

/// V11.1C: dzienna warstwa decyzji kariery młodego zawodnika.
///
/// Nie zastępuje transferów ani wypożyczeń. Pilnuje tylko, aby ścieżka
/// akademia -> pierwszy zespół -> wypożyczenie -> zainteresowanie była
/// konsekwencją minut, wieku, potencjału i preferencji zawodnika.
class YouthCareerProgressionEngine {
  final Random _random;
  final Map<String, String> _lastStage = {};

  YouthCareerProgressionEngine({Random? random}) : _random = random ?? Random();

  List<WorldEvent> processDay({
    required int year,
    required int month,
    required int day,
    required int absoluteDay,
    required List<Club> clubs,
    required List<Player> players,
  }) {
    final events = <WorldEvent>[];

    for (final player in players.where((p) => p.age <= 24 && p.clubId != null)) {
      final club = _clubFor(player, clubs);
      if (club == null) continue;

      final previous = _lastStage[player.id] ?? player.careerStage;
      var stage = player.careerStage;

      if (player.age < 18 || !player.hasProfessionalContract) {
        stage = 'academy';
      } else if (player.appearances > 0 || player.debutDay > 0) {
        stage = 'firstTeam';
      } else if (player.loanFromClubId != null) {
        stage = 'loan';
      } else if (player.age >= 19 &&
          player.potential - player.overall >= 10 &&
          player.consecutiveBenchDays >= 14) {
        stage = 'loanCandidate';
      } else {
        stage = 'firstTeamCandidate';
      }

      if (stage != player.careerStage) player.careerStage = stage;
      _lastStage[player.id] = stage;

      if (stage != previous) {
        events.add(_event(
          year, month, day, player, club,
          'career_stage',
          _title(stage),
          _description(stage, player, club),
          stage == 'firstTeam' ? 3 : 2,
        ));
      }

      // Wysoki profesjonalizm pomaga odzyskać miejsce po słabszym okresie,
      // ale ambicja zwiększa presję na regularne minuty.
      if (player.hasProfessionalContract && player.age >= 18 && player.appearances == 0) {
        if (player.consecutiveBenchDays >= 28 && player.personality.ambition >= 75) {
          player.morale = max(20, player.morale - 1);
          if (_random.nextDouble() < .008) {
            events.add(_event(
              year, month, day, player, club,
              'youth_frustration',
              'Młody zawodnik chce grać więcej',
              '${player.name} coraz mocniej naciska na regularne minuty w ${club.name}.',
              2,
            ));
          }
        }
      }

      // Po debiucie pierwsze miesiące są ważne dla utrzymania ścieżki rozwoju.
      if (stage == 'firstTeam' && player.age <= 21 && player.minutesPlayed >= 450) {
        player.squadStatus = 'rotation';
      }
    }

    return events;
  }

  String _title(String stage) {
    switch (stage) {
      case 'firstTeamCandidate': return 'Młody zawodnik wchodzi do planów pierwszego zespołu';
      case 'firstTeam': return 'Młody zawodnik przebił się do pierwszego zespołu';
      case 'loanCandidate': return 'Klub rozważa wypożyczenie młodego zawodnika';
      case 'loan': return 'Młody zawodnik rozpoczyna etap wypożyczenia';
      default: return 'Zmiana etapu kariery młodego zawodnika';
    }
  }

  String _description(String stage, Player p, Club c) {
    switch (stage) {
      case 'firstTeamCandidate':
        return '${p.name} jest coraz bliżej regularnych treningów i występów w pierwszym zespole ${c.name}.';
      case 'firstTeam':
        return '${p.name} ma już za sobą występ w seniorskiej piłce i zaczyna być traktowany jako członek pierwszego zespołu ${c.name}.';
      case 'loanCandidate':
        return '${p.name} ma potencjał na rozwój, ale potrzebuje regularnych minut. ${c.name} może szukać wypożyczenia.';
      case 'loan':
        return '${p.name} rozwija się poza macierzystym klubem, zbierając doświadczenie w seniorskiej piłce.';
      default:
        return '${p.name} pozostaje na ścieżce akademii ${c.name}.';
    }
  }

  Club? _clubFor(Player player, List<Club> clubs) {
    for (final club in clubs) {
      if (club.id == player.clubId) return club;
    }
    return null;
  }

  WorldEvent _event(int year, int month, int day, Player p, Club c, String type,
      String title, String description, int importance) {
    return WorldEvent(
      year: year,
      month: month,
      day: day,
      type: type,
      title: title,
      description: description,
      clubId: c.id,
      playerId: p.id,
      importance: importance,
    );
  }
}
