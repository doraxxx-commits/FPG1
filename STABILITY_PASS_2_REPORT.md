# FPG — Stability Pass 2 (P0.2)

## Zakres

Ten pass domyka pierwszy element P0.2: wybór podstawowej jedenastki w `MatchEngine`.

### Zrobione

- Usunięto `shuffle()` jako mechanizm wyboru XI w `MatchEngine`.
- Dodano deterministyczną selekcję jakościową opartą o:
  - OVR,
  - formę,
  - fitness,
  - morale,
  - relację z trenerem,
  - zmęczenie,
  - status regularnego startera.
- Dodano preferowaną strukturę 4-3-3:
  - 1 GK,
  - 4 DEF,
  - 3 MID,
  - 2 WINGER,
  - 1 ST.
- Jeżeli kadra nie ma wystarczającej liczby zawodników na danej pozycji, brakujące miejsca są uzupełniane najlepszymi dostępnymi zawodnikami zamiast powodować błąd.
- Zawodnicy z ekstremalnym zmęczeniem lub bardzo niskim fitness są pomijani.
- Ławka jest wybierana spośród pozostałych dostępnych zawodników według tego samego scoringu.
- Dodano regresyjny test sprawdzający m.in. obecność bramkarza, wysokiej jakości obrońcy i napastnika oraz wykluczenie niedostępnego zawodnika.

## Ważne

`GlobalMatchEngine` posiada już własny wybór XI dla zawodników świata AI. Ten pass nie tworzy kolejnego silnika i nie dubluje tamtej logiki.

## Ograniczenie testowania

Środowisko nie posiada Flutter SDK ani Dart SDK, więc nie można było wykonać `flutter analyze` / `flutter test`.

ZIP został zweryfikowany jako poprawne archiwum. Kod został sprawdzony statycznie po zmianach.

## Następny krok

P0.3: pełny test i uszczelnienie przepływu `Fixture → MatchResult → League → Career`, a następnie Save → Load i test wielodniowy.
