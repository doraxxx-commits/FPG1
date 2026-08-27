# FPG — Stability Pass 3 (P0.3)

## Cel
Domknięcie ścieżki `Fixture → MatchResult → League` oraz zabezpieczenie wyniku meczu przed utratą szczegółów po ponownym otwarciu ekranu lub po SAVE/LOAD.

## Zmiany
- `MatchResult` otrzymał pełną serializację `toJson/fromJson`.
- `Fixture` przechowuje `resultSnapshot` z pełnym oficjalnym wynikiem.
- `GameEngine.playFixture()` nie symuluje ponownie rozegranego meczu; najpierw próbuje zwrócić zapisany pełny wynik.
- `GameEngine.playFixture()` odrzuca uszkodzony stan `played=true` bez wyniku zamiast po cichu symulować mecz drugi raz.
- Wynik po `reconcileInteractiveFixtureResult()` aktualizuje również snapshot wyniku, zachowując statystyki meczu.
- `WorldSave` zapisuje `resultSnapshot` fixture'a.
- `GameEngine.restoreFromJson()` odtwarza snapshot wyniku fixture'a.
- Dodano test round-trip `MatchResult` oraz test przechowywania pełnego wyniku przez `Fixture`.
- Dodano test `LeagueEngine.replaceMatch()`, potwierdzający, że korekta wyniku nie zwiększa liczby rozegranych meczów.

## Bezpieczeństwo wstecznej kompatybilności
`resultSnapshot` jest polem opcjonalnym. Starsze save'y bez tego pola nadal mogą zostać wczytane; dla starego fixture'a zachowany jest fallback do wyniku zapisanego jako `homeGoals/awayGoals`.

## Ograniczenie testowe
W środowisku audytu nie ma Flutter SDK, więc nie uruchomiono `flutter analyze` ani `flutter test`. Kod został sprawdzony statycznie i testy zostały dodane do projektu.

## Następny etap
P0.4: pełny Save → Load oraz test długiej symulacji (30 dni), ze szczególnym naciskiem na spójność fixture'ów, tabeli i kariery.
