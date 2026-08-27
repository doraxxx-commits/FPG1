# FPG v10 — World Engine / Living Calendar

## Stan po scaleniu

V10 nie jest już tylko szkieletem. Projekt ma jeden aktywny `WorldEngine`, który
koordynuje codzienny obieg świata AI, a `GameState` prowadzi rzeczywistą datę
od 23.08.2026.

### Wybrane jako kanoniczne wersje

- `simulation/world_engine.dart` — pełny orchestrator świata.
- `simulation/club_ai_engine.dart` — analiza potrzeb kadrowych.
- `simulation/mini_game_engine.dart` — katalog 25 wariantów minigier.
- `simulation/match_2d_engine.dart` — najbardziej rozwinięta wersja meczu 2D:
  sytuacje, pojedynki, statystyki, doliczony czas i minigry.
- `models/match_2d.dart` — model zgodny z powyższym silnikiem.
- `screens/match_screen.dart` — ekran zgodny z pełnym silnikiem 2D.

## Ważne decyzje

1. `targetHomeGoals/targetAwayGoals` pozostaje tymczasowo jako warstwa
   synchronizacji z oficjalnym `MatchEngine`. Nie usuwamy go w V10, dopóki
   wynik meczu nie zostanie przeniesiony do jednego źródła prawdy.
2. Świat ma rzeczywistą datę i sezon piłkarski trwa od 1 lipca do 30 czerwca.
3. Przy starcie kariery świat nadrabia mecze, których data już minęła.
4. `WorldEngine.lastDayEvents` udostępnia przyczynowe wydarzenia dla przyszłego
   News/FPG Social — feed nie powinien losować historii niezależnych od świata.
5. Kolejność dnia to: regeneracja -> kontuzje -> decyzje kadrowe -> mecze ->
   konsekwencje -> ekonomia -> rynek -> wydarzenia społeczne.

## Następny etap

### V11
- jeden wynik meczu jako źródło prawdy,
- pełne statystyki `MatchResult` -> forma/morale/finanse/news,
- generowanie nowych zawodników jako pełnoprawnych członków świata,
- dynamiczne OVR i historia klubów.

### V12+
- scouting AI oparty o potrzeby klubów,
- negocjacje wieloetapowe,
- transfery jako proces: zainteresowanie -> scouting -> oferta -> negocjacje -> decyzja,
- reprezentacje i powołania,
- FPG Social generowany wyłącznie z realnych wydarzeń świata.
