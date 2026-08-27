# FPG — P0 Stability Pass 6

## Cel
Długoterminowa integralność świata i pierwszego dnia kariery. Ten etap nie dodaje nowych mechanik gameplayowych.

## Zmiany

### 1. Naprawiono pierwszy matchday kariery
`GameState` przesuwa dzień na początku normalnej transakcji `advanceDay()`. Poprzedni terminarz ustawiał pierwszą kolejkę na 24.07, czyli dokładnie w dniu startu gry. W efekcie pierwsza kolejka mogła zostać pominięta przez normalny przepływ dnia.

Pierwsza kolejka nowego sezonu zaczyna się teraz 25.07.

### 2. Naprawiono domyślne wartości `GameState.fromJson`
Stary fallback miał 24.08.2026, mimo że nowa kariera startuje 24.07.2026. Fallback jest teraz spójny z konstruktorem: 24.07.2026.

### 3. `WorldEngine` respektuje rok sezonu
Konstruktor przyjmuje `seasonStartYear`, a `GameEngine` przekazuje aktualny sezon. Dzięki temu autonomiczny terminarz nie jest na stałe zakotwiczony w 2026.

### 4. Testy integralności terminarza
Dodano `test/world_long_run_integrity_test.dart` sprawdzający:
- pierwszy mecz jest osiągalny przez normalny `advanceDay()`;
- brak duplikatów identyfikacji meczu;
- każda para klubów spotyka się dokładnie dwa razy;
- sezon pozostaje stabilny do 30.06 i przechodzi na nowy rok 01.07.

## Ważne ograniczenie
Flutter SDK nie jest dostępne w środowisku wykonawczym tego audytu, dlatego nie raportuję `flutter analyze` ani `flutter test` jako wykonanych. Kod został sprawdzony statycznie i ZIP został zweryfikowany jako poprawne archiwum.

## Następny etap
P0.7: audyt długoterminowego obiegu zawodników — transfery, wypożyczenia, emerytury, akademia/regeneracja oraz minimalne kadry po 1–5 sezonach.
