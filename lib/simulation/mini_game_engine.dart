import 'dart:math';
import '../models/player.dart';
import '../models/match_2d.dart';

enum MiniGameType {
  goalkeeperSave,
  goalkeeperOneOnOne,
  goalkeeperPosition,
  goalkeeperCross,
  goalkeeperPenalty,
  defenderTackle,
  defenderBlock,
  defenderInterception,
  defenderPositioning,
  defenderClearance,
  midfielderShortPass,
  midfielderThroughBall,
  midfielderVision,
  midfielderPress,
  midfielderLongPass,
  attackerFinish,
  attackerHeader,
  attackerOneTouch,
  attackerRunBehind,
  attackerHoldUp,
}

/// Fala trójkątna 0 -> 1 -> 0 używana do animowania "okna trafienia" w
/// mini-grach dotykowych (np. suwak celownika poruszający się tam i z
/// powrotem). [t] to postęp animacji w zakresie 0..1.
double triangleWave(double t) {
  final x = t % 1.0;
  return x < 0.5 ? x * 2 : (1 - x) * 2;
}

/// Ogólna kategoria interakcji w mini-grze — od niej zależy, jaki widget
/// dotykowy (i jaka logika trafienia) zostanie pokazany na ekranie meczu.
enum MiniGameKind { shot, pass, dribble, tackle, save }

MiniGameKind _kindForType(MiniGameType type) {
  switch (type) {
    case MiniGameType.goalkeeperSave:
    case MiniGameType.goalkeeperOneOnOne:
    case MiniGameType.goalkeeperPosition:
    case MiniGameType.goalkeeperCross:
    case MiniGameType.goalkeeperPenalty:
      return MiniGameKind.save;
    case MiniGameType.defenderTackle:
    case MiniGameType.defenderBlock:
    case MiniGameType.defenderInterception:
    case MiniGameType.defenderPositioning:
    case MiniGameType.defenderClearance:
      return MiniGameKind.tackle;
    case MiniGameType.midfielderShortPass:
    case MiniGameType.midfielderThroughBall:
    case MiniGameType.midfielderVision:
    case MiniGameType.midfielderPress:
    case MiniGameType.midfielderLongPass:
      return MiniGameKind.pass;
    case MiniGameType.attackerFinish:
    case MiniGameType.attackerHeader:
      return MiniGameKind.shot;
    case MiniGameType.attackerOneTouch:
    case MiniGameType.attackerRunBehind:
    case MiniGameType.attackerHoldUp:
      return MiniGameKind.dribble;
  }
}

class MiniGameDefinition {
  final MiniGameType type;
  final String title;
  final String instruction;
  const MiniGameDefinition(this.type, this.title, this.instruction);

  MiniGameKind get kind => _kindForType(type);
}

class MiniGameResult {
  final MiniGameDefinition game;
  final double executionScore;
  final bool actionExecuted;
  final bool generatedStatOutcome;
  final String message;
  const MiniGameResult({required this.game, required this.executionScore, required this.actionExecuted, required this.generatedStatOutcome, required this.message});
}

/// Mini-gra NIE rozstrzyga akcji. Daje tylko wynik wykonania gracza.
/// Potem niezależny rzut świata decyduje, czy akcja rzeczywiście przyniosła
/// efekt (asysta, drybling, gol, przechwyt itd.).
class MiniGameEngine {
  final Random random;
  MiniGameEngine({Random? random}) : random = random ?? Random();

  List<MiniGameDefinition> forPosition(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return const [
          MiniGameDefinition(MiniGameType.goalkeeperSave, 'OBRONA STRZAŁU', 'Przesuń rękawice w kierunku piłki'),
          MiniGameDefinition(MiniGameType.goalkeeperOneOnOne, 'SAM NA SAM', 'Wybierz moment wyjścia'),
          MiniGameDefinition(MiniGameType.goalkeeperPosition, 'USTAWIENIE', 'Zajmij właściwy kąt'),
          MiniGameDefinition(MiniGameType.goalkeeperCross, 'DOŚRODKOWANIE', 'Wyjdź lub zostań na linii'),
          MiniGameDefinition(MiniGameType.goalkeeperPenalty, 'RZUT KARNY', 'Odczytaj kierunek strzału'),
        ];
      case PlayerPosition.defender:
        return const [
          MiniGameDefinition(MiniGameType.defenderTackle, 'ODBÓR', 'Wybierz moment wejścia'),
          MiniGameDefinition(MiniGameType.defenderBlock, 'BLOK', 'Zamknij tor strzału'),
          MiniGameDefinition(MiniGameType.defenderInterception, 'PRZECHWYT', 'Czytaj podanie'),
          MiniGameDefinition(MiniGameType.defenderPositioning, 'USTAWIENIE', 'Ustaw się między rywalem a bramką'),
          MiniGameDefinition(MiniGameType.defenderClearance, 'WYCZYSZCZENIE', 'Oddal zagrożenie'),
        ];
      case PlayerPosition.midfielder:
        return const [
          MiniGameDefinition(MiniGameType.midfielderShortPass, 'PODANIE', 'Wskaż partnera i siłę zagrania'),
          MiniGameDefinition(MiniGameType.midfielderThroughBall, 'PROSTOPADŁE PODANIE', 'Wybierz moment zagrania'),
          MiniGameDefinition(MiniGameType.midfielderVision, 'WIZJA', 'Znajdź najlepszą opcję'),
          MiniGameDefinition(MiniGameType.midfielderPress, 'PRESSING', 'Wybierz kierunek doskoku'),
          MiniGameDefinition(MiniGameType.midfielderLongPass, 'DŁUGIE PODANIE', 'Ustal trajektorię'),
        ];
      case PlayerPosition.winger:
      case PlayerPosition.striker:
        return const [
          MiniGameDefinition(MiniGameType.attackerFinish, 'WYKOŃCZENIE', 'Wybierz kierunek i siłę'),
          MiniGameDefinition(MiniGameType.attackerHeader, 'GŁÓWKA', 'Wybierz moment wyskoku'),
          MiniGameDefinition(MiniGameType.attackerOneTouch, 'PIERWSZY KONTAKT', 'Ustaw kierunek pierwszego kontaktu'),
          MiniGameDefinition(MiniGameType.attackerRunBehind, 'WYJŚCIE ZA LINIĘ', 'Wybierz moment wbiegnięcia'),
          MiniGameDefinition(MiniGameType.attackerHoldUp, 'GRA TYŁEM', 'Osłoń piłkę i znajdź wsparcie'),
        ];
    }
  }

  /// Wybiera konkretną definicję mini-gry na podstawie ogólnego typu akcji
  /// zgłoszonego przez silnik meczu (np. 'shot', 'pass', 'dribble', 'tackle',
  /// 'save') oraz pozycji zawodnika, który ją wykonuje.
  MiniGameDefinition definitionFor(String miniGameType, PlayerPosition position) {
    final options = forPosition(position);
    final kind = MiniGameKind.values.firstWhere(
      (k) => k.name == miniGameType,
      orElse: () => MiniGameKind.shot,
    );
    return options.firstWhere(
      (g) => g.kind == kind,
      orElse: () => options.first,
    );
  }

  MiniGameResult resolve(MiniGameDefinition game, Player player, double inputQuality) {
    final skill = _relevantSkill(game.type, player);
    final noise = (random.nextDouble() - .5) * 20;
    final execution = (inputQuality * .60 + skill * .40 + noise).clamp(0, 100);
    final actionExecuted = execution >= 50;

    // KLUCZOWA ZASADA: nawet idealna mini-gra nie gwarantuje efektu boiskowego.
    // Ten drugi rzut reprezentuje AI przeciwnika, pozycję, timing i kontekst.
    final contextRoll = random.nextDouble() * 100;
    final contextQuality = (player.form * .25 + player.fitness * .15 + player.morale * .10 + player.overall * .20 + execution * .15 + contextRoll * .15).clamp(0, 100);
    final generatedOutcome = contextQuality >= 68;

    final message = actionExecuted
        ? (generatedOutcome ? 'Dobra próba, a sytuacja rozwinęła się korzystnie.' : 'Dobra próba, ale AI/przeciwnik zneutralizował akcję.')
        : 'Mini-gra nie wyszła idealnie, ale akcja może mimo to zakończyć się korzystnie dzięki sytuacji meczowej.';
   return MiniGameResult(
      game: game,
      executionScore: execution.toDouble(),
      actionExecuted: actionExecuted,
      generatedStatOutcome: generatedOutcome,
      message: message,
    );


  }

  int _relevantSkill(MiniGameType type, Player p) {
    switch (type) {
      case MiniGameType.goalkeeperSave:
      case MiniGameType.goalkeeperOneOnOne:
      case MiniGameType.goalkeeperPenalty:
        return p.defending;
      case MiniGameType.goalkeeperPosition:
      case MiniGameType.goalkeeperCross:
        return (p.defending + p.physical) ~/ 2;
      case MiniGameType.defenderTackle:
      case MiniGameType.defenderBlock:
      case MiniGameType.defenderInterception:
      case MiniGameType.defenderPositioning:
      case MiniGameType.defenderClearance:
        return (p.defending + p.physical) ~/ 2;
      case MiniGameType.midfielderShortPass:
      case MiniGameType.midfielderThroughBall:
      case MiniGameType.midfielderVision:
      case MiniGameType.midfielderLongPass:
        return p.passing;
      case MiniGameType.midfielderPress:
        return (p.defending + p.physical) ~/ 2;
      case MiniGameType.attackerFinish:
        return p.shooting;
      case MiniGameType.attackerHeader:
        return (p.shooting + p.physical) ~/ 2;
      case MiniGameType.attackerOneTouch:
      case MiniGameType.attackerRunBehind:
        return (p.dribbling + p.pace) ~/ 2;
      case MiniGameType.attackerHoldUp:
        return p.physical;
    }
  }
}
