import '../models/player.dart';
import '../models/world_event.dart';

/// V20.1 — Match Narrative Chains.
/// Turns a single post-match narrative into a persistent multi-match story.
/// The chain remembers the current stage and waits for a later match/day before
/// resolving the next beat, so the story is not consumed on the same tick.
class MatchNarrativeChainEngine {
  final Map<String, _ChainState> _chains = {};
  final Map<String, int> _streakGood = {};
  final Map<String, int> _streakPoor = {};

  List<WorldEvent> processMatch({
    required Player player,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
    required bool appeared,
    required bool started,
    required int minutes,
    required double rating,
    required int goals,
    required int assists,
    required bool won,
  }) {
    final events = <WorldEvent>[];
    final id = player.id;
    final good = appeared && rating >= 7.2;
    final excellent = appeared && rating >= 8.0;
    final poor = !appeared || minutes <= 0 || rating < 5.8;

    if (good) {
      _streakGood[id] = (_streakGood[id] ?? 0) + 1;
      _streakPoor[id] = 0;
    } else if (poor) {
      _streakPoor[id] = (_streakPoor[id] ?? 0) + 1;
      _streakGood[id] = 0;
    } else {
      _streakGood[id] = 0;
      _streakPoor[id] = 0;
    }

    final current = _chains[id];

    if (current == null) {
      if (excellent && started && won) {
        _chains[id] = _ChainState(
          id: '${id}_breakthrough',
          type: 'breakthrough',
          stage: 1,
          nextDay: absoluteDay + 1,
        );
        events.add(_event(year, month, day, player, 'match_narrative_started',
            'Bohater meczu — historia się zaczyna',
            '${player.name} rozegrał świetny mecz i wygrał z zespołem. Trener może dać mu większą rolę w kolejnym spotkaniu.', 4));
      } else if (poor && _streakPoor[id]! >= 2) {
        _chains[id] = _ChainState(
          id: '${id}_setback',
          type: 'setback',
          stage: 1,
          nextDay: absoluteDay + 1,
        );
        events.add(_event(year, month, day, player, 'match_narrative_started',
            'Kryzys formy zaczyna się rozwijać',
            '${player.name} ma serię słabszych występów. Następny mecz może zdecydować o jego roli.', 4));
      } else if (goals > 0 && excellent) {
        _chains[id] = _ChainState(
          id: '${id}_impact',
          type: 'impact',
          stage: 1,
          nextDay: absoluteDay + 2,
        );
        events.add(_event(year, month, day, player, 'match_narrative_started',
            'Gol, który zmienia narrację',
            '${player.name} zdobył bramkę i zwiększył zainteresowanie swoją osobą. Kolejny występ będzie obserwowany uważniej.', 4));
      }
      return events;
    }

    // A new match advances an existing chain only once per match.
    if (absoluteDay < current.nextDay) return events;
    final advanced = _advance(current, good: good, excellent: excellent, poor: poor, started: started, won: won, rating: rating);
    current.stage = advanced.stage;
    current.nextDay = absoluteDay + advanced.waitDays;

    if (advanced.complete) {
      _chains.remove(id);
      events.add(_event(year, month, day, player, 'match_narrative_completed',
          advanced.title,
          advanced.description, 4));
      return events;
    }

    events.add(_event(year, month, day, player, 'match_narrative_progress',
        advanced.title,
        advanced.description, 4));
    return events;
  }

  /// Called once per world day to surface delayed narrative beats. It does not
  /// invent a result; it simply reminds the world that the next match is now
  /// consequential for an active chain.
  List<WorldEvent> processDay({
    required List<Player> players,
    required int absoluteDay,
    required int year,
    required int month,
    required int day,
  }) {
    final events = <WorldEvent>[];
    for (final player in players) {
      final chain = _chains[player.id];
      if (chain == null || chain.nextDay != absoluteDay) continue;
      events.add(_event(year, month, day, player, 'match_narrative_pending',
          'Następny mecz ma znaczenie',
          _pendingDescription(chain), 3));
    }
    return events;
  }

  Map<String, dynamic> toJson() => {
    'chains': {
      for (final e in _chains.entries) e.key: e.value.toJson(),
    },
    'streakGood': Map<String, int>.from(_streakGood),
    'streakPoor': Map<String, int>.from(_streakPoor),
  };

  void restoreFromJson(Map<String, dynamic>? json) {
    _chains.clear();
    _streakGood.clear();
    _streakPoor.clear();
    final rawChains = json?['chains'];
    if (rawChains is Map) {
      for (final entry in rawChains.entries) {
        if (entry.value is Map) {
          _chains[entry.key.toString()] = _ChainState.fromJson(Map<String, dynamic>.from(entry.value));
        }
      }
    }
    _restoreMap(json?['streakGood'], _streakGood);
    _restoreMap(json?['streakPoor'], _streakPoor);
  }

  void _restoreMap(dynamic raw, Map<String, int> target) {
    if (raw is! Map) return;
    for (final e in raw.entries) {
      final value = e.value is num ? (e.value as num).toInt() : int.tryParse('${e.value}');
      if (value != null) target[e.key.toString()] = value;
    }
  }

  _Advance _advance(_ChainState c, {
    required bool good,
    required bool excellent,
    required bool poor,
    required bool started,
    required bool won,
    required double rating,
  }) {
    switch (c.type) {
      case 'breakthrough':
        if (c.stage == 1 && (excellent || (good && started))) {
          return const _Advance(stage: 2, waitDays: 1, title: 'Miejsce w podstawowym składzie?',
              description: 'Kolejny dobry występ wzmacnia argument, że zawodnik powinien utrzymać miejsce w pierwszym składzie.');
        }
        return const _Advance(stage: 3, waitDays: 0, complete: true, title: 'Przełom potwierdzony',
            description: 'Forma nie utrzymała się na oczekiwanym poziomie. Historia przełomu wygasa, ale zawodnik zachowuje zdobyte doświadczenie.');
      case 'setback':
        if (c.stage == 1 && poor) {
          return const _Advance(stage: 2, waitDays: 1, title: 'Trener traci cierpliwość',
              description: 'Kolejny słabszy mecz może oznaczać ławkę albo rozmowę o roli w zespole.');
        }
        if (c.stage == 2 && good) {
          return const _Advance(stage: 3, waitDays: 0, complete: true, title: 'Odpowiedź na kryzys',
              description: 'Dobry występ zatrzymuje kryzys. Trener dostaje powód, by ponownie zaufać zawodnikowi.');
        }
        return const _Advance(stage: 3, waitDays: 0, complete: true, title: 'Kryzys formy eskaluje',
            description: 'Słaba dyspozycja pozostawia znak zapytania przy kolejnej decyzji o składzie.');
      case 'impact':
        if (c.stage == 1 && good) {
          return const _Advance(stage: 2, waitDays: 1, title: 'Zainteresowanie rośnie',
              description: 'Kolejny dobry występ po ważnym golu zwiększa zainteresowanie kibiców i mediów.');
        }
        return const _Advance(stage: 3, waitDays: 0, complete: true, title: 'Efekt gola wygasa',
            description: 'Kolejny występ nie podtrzymał narracji. Świat wraca do normalnego poziomu zainteresowania.');
      default:
        return const _Advance(stage: 99, waitDays: 0, complete: true, title: 'Historia zakończona', description: 'Historia została zamknięta.');
    }
  }

  String _pendingDescription(_ChainState chain) {
    switch (chain.type) {
      case 'breakthrough': return 'Historia przełomowego występu czeka na kolejny mecz. Dobry występ może utrwalić nową rolę.';
      case 'setback': return 'Kryzys formy czeka na odpowiedź boiska. Kolejny słaby mecz zwiększy presję, a dobry może ją zatrzymać.';
      case 'impact': return 'Po ważnym golu kolejny występ zdecyduje, czy zainteresowanie zawodnikiem utrzyma się.';
      default: return 'Aktywna historia meczowa czeka na kolejny występ.';
    }
  }

  WorldEvent _event(int y, int m, int d, Player p, String type, String title, String description, int importance) => WorldEvent(
    year: y, month: m, day: d, type: type, title: title, description: description,
    playerId: p.id, clubId: p.clubId, importance: importance,
  );
}

class _ChainState {
  final String id;
  final String type;
  int stage;
  int nextDay;

  _ChainState({required this.id, required this.type, required this.stage, required this.nextDay});

  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'stage': stage, 'nextDay': nextDay};

  factory _ChainState.fromJson(Map<String, dynamic> json) => _ChainState(
    id: '${json['id'] ?? ''}', type: '${json['type'] ?? 'breakthrough'}',
    stage: (json['stage'] as num?)?.toInt() ?? 1,
    nextDay: (json['nextDay'] as num?)?.toInt() ?? 0,
  );
}

class _Advance {
  final int stage;
  final int waitDays;
  final bool complete;
  final String title;
  final String description;
  const _Advance({required this.stage, required this.waitDays, this.complete = false, required this.title, required this.description});
}
