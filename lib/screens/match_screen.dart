import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../models/fixture.dart';
import '../models/match_result.dart';
import '../models/player.dart';
import '../models/match_2d.dart';
import '../simulation/match_2d_engine.dart';
import '../simulation/mini_game_engine.dart';

class MatchScreen extends StatefulWidget {
  final GameEngine engine;
  const MatchScreen({super.key, required this.engine});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  late final Match2DEngine _match;
  late final MiniGameEngine _miniGames;
  Timer? _timer;
  Match2DState? _state;
  Match2DEvent? _lastEvent;
  MiniGameDefinition? _pendingMiniGame;
  bool _started = false;
  bool _finishedDay = false;
  bool _paused = false;
  final List<String> _eventFeed = <String>[];

  // Prawdziwy, oficjalny wynik z silnika ligowego — to on trafia do
  // tabeli. Symulacja 2D jedynie go dramatyzuje na boisku.
  MatchResult? _officialResult;
  Fixture? _fixture;
  bool _fixtureWasAlreadyPlayed = false;
  String _homeName = 'GOSPODARZE';
  String _awayName = 'GOŚCIE';

  @override
  void initState() {
    super.initState();
    _match = Match2DEngine();
    _miniGames = MiniGameEngine();
    _start();
  }

  Fixture? _findTodayFixtureForClub(String? clubId, {bool includePlayed = false}) {
    final s = widget.engine.state;
    for (final f in widget.engine.fixtures) {
      if (f.played && !includePlayed) continue;
      if (f.year != s.year || f.month != s.month || f.day != s.day) continue;
      if (clubId == null) return f;
      if (f.homeClubId == clubId || f.awayClubId == clubId) return f;
    }
    return null;
  }

  void _start() {
    final engine = widget.engine;
    final career = engine.careerPlayer;
    final clubId = career?.clubId;

    final fixture = _findTodayFixtureForClub(clubId);
    final alreadyPlayed = _findTodayFixtureForClub(clubId, includePlayed: true);
    _fixture = fixture ?? alreadyPlayed;
    _fixtureWasAlreadyPlayed = fixture == null && alreadyPlayed != null;

    String homeClubId;
    String awayClubId;

    if (fixture != null) {
      homeClubId = fixture.homeClubId;
      awayClubId = fixture.awayClubId;
      if (_fixtureWasAlreadyPlayed) {
        // DailySimulationCore may have already resolved today's official
        // fixture. The match screen is then a presentation/replay layer and
        // MUST NOT simulate the same fixture a second time.
        _officialResult = MatchResult(
          homeClubId: fixture.homeClubId,
          awayClubId: fixture.awayClubId,
          homeGoals: fixture.homeGoals ?? 0,
          awayGoals: fixture.awayGoals ?? 0,
        );
      } else {
        // Preview only: the fixture stays unplayed until the interactive
        // match finishes. The final 2D score is the transaction that updates
        // the table and career statistics.
        _officialResult = engine.previewFixture(fixture);
      }
    } else {
      // Brak meczu ligowego oznacza dzień bez meczu. Nie tworzymy już
      // sztucznego sparingu tylko po to, żeby ekran miał co pokazać.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dzisiaj nie masz zaplanowanego meczu.')),
        );
        Navigator.pop(context);
      });
      return;
    }

    final homeClub = engine.clubs.firstWhere((c) => c.id == homeClubId, orElse: () => engine.clubs.first);
    final awayClub = engine.clubs.firstWhere((c) => c.id == awayClubId, orElse: () => engine.clubs.last);
    _homeName = homeClub.name;
    _awayName = awayClub.name;

    final homePlayers = engine.players.where((p) => p.clubId == homeClubId).toList();
    final awayPlayers = engine.players.where((p) => p.clubId == awayClubId).toList();

    final state = _match.create(
      home: homePlayers.isNotEmpty ? homePlayers : engine.players,
      away: awayPlayers.isNotEmpty ? awayPlayers : engine.players,
      targetHomeGoals: _officialResult?.homeGoals,
      targetAwayGoals: _officialResult?.awayGoals,
      controlledPlayerId: career?.id,
    );
    _state = state;
    _started = true;
    _timer = Timer.periodic(const Duration(milliseconds: 160), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _state == null || _paused) return;
    final step = _match.tick();
    if (step.event != null) {
      final e = step.event!;
      final line = '${e.minute}\'  ${e.description}';
      _eventFeed.insert(0, line);
      if (_eventFeed.length > 8) _eventFeed.removeLast();
    }
    setState(() => _lastEvent = step.event);
    if (step.event?.isKeyMoment == true && !_fixtureWasAlreadyPlayed) {
      _tryOpenMiniGame(step.event!);
    }
    if (_state!.finished) {
      _timer?.cancel();

      // The 2D layer is now interactive: mini-games can legitimately move
      // the result by a small amount. Reconcile the league table once.
      if (_fixture != null && !_fixtureWasAlreadyPlayed) {
        widget.engine.reconcileInteractiveFixtureResult(
          fixture: _fixture!,
          finalHomeGoals: _match.finalHomeGoals,
          finalAwayGoals: _match.finalAwayGoals,
        );
      }
      _finishDayLater();
      // Mecz musi się jawnie "zakończyć" w oczach gracza — inaczej ekran
      // po prostu zamraża się na 90+X' i jedyną opcją jest cofnięcie
      // przyciskiem wstecz, co (przy braku odświeżenia ekranu kariery)
      // sprawiało wrażenie, że ten sam mecz zaczyna się od nowa.
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMatchFinished());
    }
  }

  void _tryOpenMiniGame(Match2DEvent event) {
    final career = widget.engine.careerPlayer;
    if (career == null || event.playerId != career.id) return;
    final games = _miniGames.forPosition(career.position);
    if (games.isEmpty) return;
    final game = _miniGames.definitionFor(event.miniGameType ?? 'shot', career.position);
    if (_pendingMiniGame != null) return;
    setState(() => _pendingMiniGame = game);
    _showMiniGame(game, event);
  }

  Future<void> _showMiniGame(MiniGameDefinition game, Match2DEvent originEvent) async {
    final career = widget.engine.careerPlayer;
    if (career == null || !mounted) return;
    // Zatrzymujemy symulację na czas mini-gry, żeby mecz nie "leciał
    // w tle" niezauważenie i gracz nie tracił kontekstu akcji.
    setState(() => _paused = true);
    final quality = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MiniGameDialog(game: game),
    );
    if (!mounted) return;
    final result = _miniGames.resolve(game, _worldPlayer(career), quality ?? 50);
    setState(() => _pendingMiniGame = null);

    // Wynik mini-gry realnie wpływa na przebieg akcji na boisku, a nie
    // tylko na tekst w dymku.
    final synthetic = _match.applyMiniGameOutcome(originEvent, result.actionExecuted && result.generatedStatOutcome);
    if (synthetic != null) {
      setState(() => _lastEvent = synthetic);
    }

    if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => _MiniGameResultDialog(result: result, synthetic: synthetic),
      );
    }
    if (!mounted) return;
    setState(() => _paused = false);
  }

  Player _worldPlayer(dynamic career) {
    return widget.engine.players.firstWhere(
      (p) => p.id == career.id,
      orElse: () => Player(
        id: career.id, name: career.fullName, age: career.age, position: career.position,
        nationality: career.nationality, overall: career.overall, potential: career.potential,
        pace: career.pace, shooting: career.shooting, passing: career.passing,
        dribbling: career.dribbling, defending: career.defending, physical: career.physical,
        value: 0, weeklyWage: 0,
      ),
    );
  }

  bool _finishedDialogShown = false;

  Future<void> _showMatchFinished() async {
    if (_finishedDialogShown || !mounted) return;
    _finishedDialogShown = true;
    final s = _state!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('MECZ ZAKOŃCZONY'),
        content: Text(
          '$_homeName ${s.homeGoals} : ${s.awayGoals} $_awayName',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // zamyka dialog
              Navigator.pop(context, true); // wraca z ekranu meczu
            },
            child: const Text('WYJDŹ'),
          ),
        ],
      ),
    );
  }

  void _finishDayLater() {
    if (_finishedDay) return;
    _finishedDay = true;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      // Najpierw domykamy CAŁĄ kolejkę z tego samego dnia. Wcześniej
      // przechodziliśmy od razu do następnego dnia, więc tabela dostawała
      // tylko wynik meczu gracza, a pozostałe spotkania tej kolejki
      // pozostawały niezmienione aż do przypadkowego terminu.
      try {
        widget.engine.playMatchesForToday();
      } catch (_) {}
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    return Scaffold(
      backgroundColor: const Color(0xFF07110A),
      appBar: AppBar(
        title: const Text('MECZ 2D — WIDOK Z GÓRY'),
        backgroundColor: const Color(0xFF07110A),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _scoreBar(s),
            // Center luzuje sztywne ograniczenie wysokości z Expanded, dzięki
            // czemu AspectRatio w _Pitch faktycznie liczy proporcje 1.45
            // zamiast wypełniać całą dostępną (pionową) wysokość kolumny —
            // to właśnie powodowało "boisko w złą stronę".
            Expanded(
              child: Center(
                child: s == null ? const CircularProgressIndicator() : _Pitch(state: s),
              ),
            ),
            _eventPanel(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: s?.finished == true ? null : () => setState(() => _paused = !_paused),
                      icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18),
                      label: Text(_paused ? 'WZNÓW MECZ' : 'PAUZA'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Text(
                _paused
                    ? 'Mecz wstrzymany — dokończ mini-grę powyżej.'
                    : 'AI steruje wszystkimi 22 zawodnikami. AI prowadzi mecz, a maksymalnie kilka najważniejszych akcji Twojego zawodnika przechodzi w krótką mini-grę.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _clockText(Match2DState? s) {
    if (s == null) return "0'";
    if (s.minute <= 90) return "${s.minute}'";
    return "90+${s.minute - 90}'";
  }

  Widget _scoreBar(Match2DState? s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(_homeName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            Text('${s?.homeGoals ?? 0}  :  ${s?.awayGoals ?? 0}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Expanded(child: Text(_awayName, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 2),
        Text(_clockText(s), style: const TextStyle(color: Colors.white70)),
        if (s != null && s.stoppageTime > 0)
          Text('DOLICZONY CZAS: +${s.stoppageTime} MIN', style: const TextStyle(color: Colors.white38, fontSize: 9)),
        if (s != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatChip(label: 'POS', value: '${s.stats.homePossessionPercent.round()}%')),
              Expanded(child: _StatChip(label: 'STRZAŁY', value: '${s.stats.homeShots} - ${s.stats.awayShots}')),
              Expanded(child: _StatChip(label: 'CELNE', value: '${s.stats.homeShotsOnTarget} - ${s.stats.awayShotsOnTarget}')),
              Expanded(child: _StatChip(label: 'PODANIA', value: '${s.stats.homeCompletedPasses} - ${s.stats.awayCompletedPasses}')),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _eventPanel() => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
    decoration: BoxDecoration(color: const Color(0xFF111A14), borderRadius: BorderRadius.circular(12)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: Colors.amber),
            const SizedBox(width: 6),
            const Text('NA ŻYWO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            const Spacer(),
            if (_paused) const Text('PAUZA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.amber)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          _lastEvent == null ? (_started ? 'Trwa budowanie akcji...' : 'Przygotowanie meczu...') : '${_lastEvent!.minute}\'  ${_lastEvent!.description}',
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (_eventFeed.length > 1) ...[
          const SizedBox(height: 5),
          SizedBox(
            height: 30,
            child: ListView.builder(
              reverse: true,
              scrollDirection: Axis.horizontal,
              itemCount: _eventFeed.length.clamp(0, 6),
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.05), borderRadius: BorderRadius.circular(8)),
                child: Text(_eventFeed[index], style: const TextStyle(fontSize: 9, color: Colors.white60)),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8)),
    ],
  );
}

// ==========================================================
// KOLORY KLUBOWE — deterministyczne na podstawie id klubu, zamiast
// zawsze tego samego niebieskiego/pomarańczowego.
// ==========================================================

const _kitPalette = [
  [Color(0xFFE53935), Color(0xFFFFFFFF)],
  [Color(0xFF1E88E5), Color(0xFFFFEB3B)],
  [Color(0xFF43A047), Color(0xFFFFFFFF)],
  [Color(0xFF212121), Color(0xFFFFFFFF)],
  [Color(0xFF8E24AA), Color(0xFFFFFFFF)],
  [Color(0xFFFB8C00), Color(0xFF212121)],
  [Color(0xFF00838F), Color(0xFFFFFFFF)],
  [Color(0xFFC62828), Color(0xFFFDD835)],
];

Color _kitColor(String clubId) => _kitPalette[clubId.hashCode.abs() % _kitPalette.length][0];

class _Pitch extends StatelessWidget {
  final Match2DState state;
  const _Pitch({required this.state});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.45,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(painter: _PitchPainter(state)),
    ),
  );
}

class _PitchPainter extends CustomPainter {
  final Match2DState state;
  _PitchPainter(this.state);
  @override
  void paint(Canvas canvas, Size size) {
    _paintGrass(canvas, size);
    _paintMarkings(canvas, size);
    _paintPlayers(canvas, size);
    _paintBall(canvas, size);
  }

  void _paintGrass(Canvas canvas, Size size) {
    const light = Color(0xFF2E8B4E);
    const dark = Color(0xFF267A44);
    const stripes = 10;
    final stripeWidth = size.width / stripes;
    for (var i = 0; i < stripes; i++) {
      final paint = Paint()..color = i.isEven ? light : dark;
      canvas.drawRect(Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height), paint);
    }
  }

  void _paintMarkings(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withOpacity(.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Obrys boiska.
    canvas.drawRect(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), line);
    // Linia środkowa i okrąg.
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.height * .14, line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2, Paint()..color = Colors.white);

    // Pole karne + pole bramkowe + punkt karny (lewa i prawa strona).
    for (final left in [true, false]) {
      final penW = size.width * .16;
      final penH = size.height * .62;
      final sixW = size.width * .06;
      final sixH = size.height * .30;
      final x = left ? 0.0 : size.width - penW;
      canvas.drawRect(Rect.fromLTWH(x, (size.height - penH) / 2, penW, penH), line);
      final sixX = left ? 0.0 : size.width - sixW;
      canvas.drawRect(Rect.fromLTWH(sixX, (size.height - sixH) / 2, sixW, sixH), line);
      final spotX = left ? penW * .62 : size.width - penW * .62;
      canvas.drawCircle(Offset(spotX, size.height / 2), 1.8, Paint()..color = Colors.white);
      // Łuk przy polu karnym.
      final arcRect = Rect.fromCircle(center: Offset(spotX, size.height / 2), radius: size.height * .14);
      canvas.drawArc(arcRect, left ? -0.9 : pi - 0.9, 1.8, false, line);
      // Bramka.
      final goalH = size.height * .14;
      final goalX = left ? -3.0 : size.width - 2.0;
      canvas.drawRect(Rect.fromLTWH(goalX, (size.height - goalH) / 2, 5, goalH), line);
    }

    // Narożniki.
    for (final corner in [
      Offset(0, 0), Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height),
    ]) {
      canvas.drawArc(Rect.fromCircle(center: corner, radius: 5), 0, 2 * pi, false, line);
    }
  }

  void _paintPlayers(Canvas canvas, Size size) {
    final homeColor = state.players.isNotEmpty
        ? _kitColorForTeam(Match2DTeam.home)
        : Colors.blueAccent;
    final awayColor = _kitColorForTeam(Match2DTeam.away);

    for (final p in state.players) {
      final color = p.team == Match2DTeam.home ? homeColor : awayColor;
      final isGk = p.position == PlayerPosition.goalkeeper;
      final pos = Offset(p.x / 100 * size.width, p.y / 100 * size.height);

      // Cień pod zawodnikiem.
      canvas.drawOval(
        Rect.fromCenter(center: pos.translate(0, 5), width: 12, height: 5),
        Paint()..color = Colors.black.withOpacity(.25),
      );

      if (p.hasBall) {
        canvas.drawCircle(pos, 11, Paint()..color = Colors.white.withOpacity(.35));
      }

      final radius = p.hasBall ? 8.5 : 7.0;
      canvas.drawCircle(pos, radius, Paint()..color = isGk ? const Color(0xFFFFC107) : color);
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = Colors.black.withOpacity(.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${p.shirtNumber}',
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  Color _kitColorForTeam(Match2DTeam team) {
    final ids = state.players.where((p) => p.team == team).map((p) => p.id).toList();
    if (ids.isEmpty) return team == Match2DTeam.home ? Colors.blueAccent : Colors.orangeAccent;
    return _kitColor(ids.first);
  }

  void _paintBall(Canvas canvas, Size size) {
    final pos = Offset(state.ballX / 100 * size.width, state.ballY / 100 * size.height);
    canvas.drawOval(Rect.fromCenter(center: pos.translate(0, 3), width: 8, height: 3), Paint()..color = Colors.black.withOpacity(.35));
    canvas.drawCircle(pos, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 4.5, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) => true;
}

// ==========================================================
// MINI-GRY — akcje sytuacyjne, a nie jeden wspólny suwak.
// Każda pozycja ma własny sposób wykonania.
// ==========================================================

class _MiniGameDialog extends StatefulWidget {
  final MiniGameDefinition game;
  const _MiniGameDialog({required this.game});

  @override
  State<_MiniGameDialog> createState() => _MiniGameDialogState();
}

class _MiniGameDialogState extends State<_MiniGameDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _quality = 0;
  bool _locked = false;

  // --- Strzał: przeciąganie = cel + moc, jak w procy — odciągasz palec od
  // bramki, a piłka leci w przeciwną stronę. Dłuższe odciągnięcie = mocniej.
  Offset _shotPull = Offset.zero;
  bool _shotDragging = false;
  late final double _keeperBias;

  // --- Drybling: przeciągasz piłkę w poziomie, żeby ominąć obrońcę, który
  // z opóźnieniem kopiuje twój tor i zbliża się w dół ekranu.
  double _dribbleX = 0; // -1..1
  double _defenderX = 0; // -1..1

  bool get _isDragKind =>
      widget.game.kind == MiniGameKind.shot || widget.game.kind == MiniGameKind.dribble;

  @override
  void initState() {
    super.initState();
    _keeperBias = (Random().nextDouble() * 2 - 1) * 0.55;
    final kind = widget.game.kind;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: kind == MiniGameKind.dribble ? 1700 : 1150),
    )..addListener(() {
        if (!mounted || _locked) return;
        if (kind == MiniGameKind.dribble) {
          _defenderX += (_dribbleX - _defenderX) * .10;
          if (_controller.value >= 1.0) _finishDribble();
        }
        setState(() {});
      });
    if (kind == MiniGameKind.dribble) {
      _controller.forward(from: 0);
    } else if (!_isDragKind) {
      _controller.repeat();
    }
  }

  double get _wave => triangleWave(_controller.value);

  void _finish(double quality) {
    if (_locked) return;
    _controller.stop();
    setState(() {
      _quality = quality.clamp(0, 100).toDouble();
      _locked = true;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) Navigator.pop(context, _quality);
    });
  }

  void _tap(TapUpDetails details, Size size) {
    if (_locked) return;
    final p = details.localPosition;

    switch (widget.game.kind) {
      case MiniGameKind.pass:
        final gateX = size.width * (.12 + progressSafe * .76);
        final d = ((p.dx - gateX).abs() * 2.0 + (p.dy - size.height * .52).abs());
        _finish((100 - d * 1.8).clamp(0, 100));
      case MiniGameKind.tackle:
        final target = Offset(
          size.width * (.20 + progressSafe * .60),
          size.height * (.72 - progressSafe * .44),
        );
        _finish((100 - (p - target).distance * 2.2).clamp(0, 100));
      case MiniGameKind.save:
        final ball = Offset(
          size.width * (.18 + ((progressSafe + .18) % 1) * .64),
          size.height * (.26 + ((progressSafe * .73) % 1) * .44),
        );
        _finish((100 - (p - ball).distance * 2.0).clamp(0, 100));
      case MiniGameKind.shot:
      case MiniGameKind.dribble:
        break; // obsłużone przez przeciąganie (patrz _onShot*/_onDribble*).
    }
  }

  double get progressSafe => _wave;

  double _shotMaxPull(Size size) => size.shortestSide * .55;

  void _onShotPanUpdate(DragUpdateDetails d, Size size) {
    if (_locked) return;
    final maxPull = _shotMaxPull(size);
    setState(() {
      _shotDragging = true;
      final next = _shotPull + d.delta;
      final dist = next.distance;
      _shotPull = dist > maxPull ? next * (maxPull / dist) : next;
    });
  }

  void _onShotPanEnd(Size size) {
    if (_locked || !_shotDragging) return;
    final maxPull = _shotMaxPull(size);
    final power = (_shotPull.distance / maxPull).clamp(0.0, 1.0);
    final aim = (-_shotPull.dx / maxPull).clamp(-1.0, 1.0);

    // Najlepsza skuteczność jest w "strefie idealnej" mocy — za słabo i
    // bramkarz łapie bez trudu, za mocno i tracisz kontrolę nad strzałem.
    final powerScore = power < .35
        ? power / .35 * 55
        : power > .92
            ? 100 - (power - .92) / .08 * 60
            : 70 + (1 - (power - .63).abs() / .30) * 30;

    // Celność liczona względem pozycji bramkarza — im dalej od niego (ale
    // wciąż w świetle bramki), tym lepiej.
    final distFromKeeper = (aim - _keeperBias).abs();
    final accuracyScore = aim.abs() <= 1.0 ? (40 + distFromKeeper * 60).clamp(0, 100) : 15.0;

    _finish(powerScore * .45 + accuracyScore * .55);
  }

  void _onDribblePanUpdate(DragUpdateDetails d, Size size) {
    if (_locked) return;
    setState(() {
      _dribbleX = (_dribbleX + d.delta.dx / (size.width * .5)).clamp(-1.0, 1.0);
    });
  }

  void _finishDribble() {
    if (_locked) return;
    final separation = (_dribbleX - _defenderX).abs();
    _finish((separation * 140).clamp(0.0, 100.0));
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.game.kind;
    return AlertDialog(
      title: Row(
        children: [
          Icon(_iconFor(kind)),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.game.title)),
        ],
      ),
      content: SizedBox(
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.game.instruction, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            SizedBox(
              height: 170,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapUp: _isDragKind ? null : (details) => _tap(details, size),
                    onPanUpdate: kind == MiniGameKind.shot
                        ? (d) => _onShotPanUpdate(d, size)
                        : kind == MiniGameKind.dribble
                            ? (d) => _onDribblePanUpdate(d, size)
                            : null,
                    onPanEnd: kind == MiniGameKind.shot ? (_) => _onShotPanEnd(size) : null,
                    child: CustomPaint(
                      painter: _ActionPainter(
                        kind: kind,
                        progress: kind == MiniGameKind.dribble ? _controller.value : _wave,
                        locked: _locked,
                        shotPull: _shotPull,
                        keeperBias: _keeperBias,
                        dribbleX: _dribbleX,
                        defenderX: _defenderX,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _locked
                  ? 'Wynik: ${_quality.round()}/100'
                  : kind == MiniGameKind.shot
                      ? (_shotDragging
                          ? 'PUŚĆ, ABY ODDAĆ STRZAŁ'
                          : 'PRZECIĄGNIJ PALEC OD BRAMKI — CEL I MOC')
                      : kind == MiniGameKind.dribble
                          ? 'PRZECIĄGAJ PALCEM W LEWO / PRAWO, BY OMINĄĆ OBROŃCĘ'
                          : 'DOTKNIJ W ODPOWIEDNIM MOMENCIE',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(MiniGameKind kind) => switch (kind) {
        MiniGameKind.shot => Icons.sports_soccer,
        MiniGameKind.pass => Icons.alt_route,
        MiniGameKind.dribble => Icons.directions_run,
        MiniGameKind.tackle => Icons.shield,
        MiniGameKind.save => Icons.pan_tool,
      };
}

class _ActionPainter extends CustomPainter {
  final MiniGameKind kind;
  final double progress;
  final bool locked;
  final Offset shotPull;
  final double keeperBias;
  final double dribbleX;
  final double defenderX;

  _ActionPainter({
    required this.kind,
    required this.progress,
    required this.locked,
    this.shotPull = Offset.zero,
    this.keeperBias = 0,
    this.dribbleX = 0,
    this.defenderX = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF173C25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(12),
      ),
      bg,
    );

    switch (kind) {
      case MiniGameKind.shot:
        _shot(canvas, size);
      case MiniGameKind.pass:
        _pass(canvas, size);
      case MiniGameKind.dribble:
        _dribble(canvas, size);
      case MiniGameKind.tackle:
        _tackle(canvas, size);
      case MiniGameKind.save:
        _save(canvas, size);
    }
  }

  void _shot(Canvas c, Size s) {
    final goal = Rect.fromLTWH(s.width * .12, s.height * .08, s.width * .76, s.height * .30);
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    c.drawRect(goal, line);

    // Bramkarz — celuj z dala od niego.
    final keeperX = goal.left + goal.width * (0.5 + keeperBias * .5);
    c.drawCircle(Offset(keeperX, goal.center.dy), 10, Paint()..color = const Color(0xFFFFC107));

    final ballOrigin = Offset(s.width * .5, s.height * .84);
    final maxPull = s.shortestSide * .55;
    final aimVector = -shotPull;
    final power = (shotPull.distance / maxPull).clamp(0.0, 1.0);
    final target = Offset(
      (ballOrigin.dx + aimVector.dx).clamp(0.0, s.width),
      (ballOrigin.dy + aimVector.dy).clamp(0.0, s.height),
    );

    if (shotPull.distance > 1) {
      final arrow = Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      c.drawLine(ballOrigin, target, arrow);
      c.drawCircle(target, 5, Paint()..color = Colors.redAccent);

      final barRect = Rect.fromLTWH(s.width * .04, s.height * .40, 9, s.height * .48);
      c.drawRect(barRect, Paint()..color = Colors.white24);
      final fillH = barRect.height * power;
      c.drawRect(
        Rect.fromLTWH(barRect.left, barRect.bottom - fillH, barRect.width, fillH),
        Paint()..color = power > .85 ? Colors.orangeAccent : Colors.greenAccent,
      );
    }

    _ball(c, ballOrigin, 9);
    _text(c, 'ODCIĄGNIJ I PUŚĆ', Offset(s.width * .26, s.height * .58));
  }

  void _pass(Canvas c, Size s) {
    final y = s.height * .52;
    final start = Offset(s.width * .12, y);
    final end = Offset(s.width * .88, y);
    final line = Paint()
      ..color = Colors.white.withOpacity(.45)
      ..strokeWidth = 3;
    c.drawLine(start, end, line);

    final gateX = s.width * (.12 + progress * .76);
    c.drawRect(
      Rect.fromCenter(center: Offset(gateX, y), width: 34, height: 70),
      Paint()..color = Colors.white.withOpacity(.85),
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(gateX, y), width: 20, height: 52),
      Paint()..color = const Color(0xFF173C25),
    );

    _ball(c, start, 8);
    _text(c, 'OKNO PODANIA', Offset(s.width * .30, s.height * .18));
  }

  void _dribble(Canvas c, Size s) {
    double xFor(double t) => s.width * (.5 + t * .38);
    final laneY = s.height * .74;
    final defStartY = s.height * .22;

    c.drawLine(
      Offset(xFor(-1), laneY),
      Offset(xFor(1), laneY),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 2,
    );

    final defY = defStartY + (laneY - defStartY) * progress;
    c.drawCircle(
      Offset(xFor(defenderX), defY),
      14,
      Paint()..color = Colors.redAccent.withOpacity(.85),
    );
    _ball(c, Offset(xFor(dribbleX), laneY), 9);
    _text(c, 'OMIŃ OBROŃCĘ', Offset(s.width * .30, s.height * .06));
  }

  void _tackle(Canvas c, Size s) {
    final duelX = s.width * (.20 + progress * .60);
    c.drawLine(
      Offset(s.width * .10, s.height * .72),
      Offset(s.width * .90, s.height * .28),
      Paint()
        ..color = Colors.white.withOpacity(.25)
        ..strokeWidth = 4,
    );
    c.drawCircle(
      Offset(duelX, s.height * (.72 - progress * .44)),
      28,
      Paint()..color = Colors.white.withOpacity(.18),
    );
    _ball(c, Offset(duelX, s.height * (.72 - progress * .44)), 8);
    _text(c, 'WEJDŹ W POJEDYNEK', Offset(s.width * .28, s.height * .08));
  }

  void _save(Canvas c, Size s) {
    final goal = Rect.fromLTWH(s.width * .10, s.height * .20, s.width * .80, s.height * .56);
    c.drawRect(
      goal,
      Paint()
        ..color = Colors.white.withOpacity(.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final ballX = s.width * (.18 + ((progress + .18) % 1) * .64);
    final ballY = s.height * (.26 + ((progress * .73) % 1) * .44);
    final keeperX = s.width * (.18 + progress * .64);
    c.drawCircle(
      Offset(keeperX, s.height * .72),
      20,
      Paint()..color = const Color(0xFFFFC107),
    );
    _ball(c, Offset(ballX, ballY), 9);
    _text(c, 'OBROŃ', Offset(s.width * .40, s.height * .08));
  }

  void _ball(Canvas c, Offset p, double r) {
    c.drawCircle(p, r, Paint()..color = Colors.white);
    c.drawCircle(
      p,
      r,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _text(Canvas c, String text, Offset position) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, position);
  }

  @override
  bool shouldRepaint(covariant _ActionPainter oldDelegate) => true;
}

class _MiniGameResultDialog extends StatelessWidget {
  final MiniGameResult result;
  final Match2DEvent? synthetic;

  const _MiniGameResultDialog({
    required this.result,
    required this.synthetic,
  });

  @override
  Widget build(BuildContext context) {
    final scored = synthetic?.type == Match2DEventType.goal;
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            scored
                ? Icons.sports_soccer
                : (result.actionExecuted
                    ? Icons.check_circle
                    : Icons.cancel),
            color: scored
                ? Colors.green
                : (result.actionExecuted
                    ? Colors.blueAccent
                    : Colors.redAccent),
          ),
          const SizedBox(width: 8),
          Text(
            scored
                ? 'GOL!'
                : (result.actionExecuted
                    ? 'AKCJA UDANA'
                    : 'AKCJA NIEUDANA'),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wykonanie: ${result.executionScore.round()}/100'),
          const SizedBox(height: 6),
          Text(synthetic?.description ?? result.message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('WRÓĆ DO MECZU'),
        ),
      ],
    );
  }
}
