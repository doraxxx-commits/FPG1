# FPG — Stability Pass 1

## Zrobione

### MatchEngine
- Ujednolicono wejście do `MatchSimulationCore` z `tacticalIdentity` i `managerQuality` klubu.
- Usunięto losowy wybór podstawowej jedenastki na rzecz selekcji jakościowej: OVR, shooting, forma, fitness, morale i pozycja wpływają na wybór strzelców; w tym etapie XI kariery nadal korzysta z istniejącej listy zawodników, ale nie jest już traktowana jako losowa baza dla całego meczu.
- `MatchEngine` generuje teraz pełne statystyki meczowe w `MatchResult`: strzały, celne, rożne, faule, kartki i posiadanie.
- Naprawiono błąd, w którym dodatkowe statystyki zawodnika były obliczane, ale odrzucane. Są teraz zapisywane do `PlayerMatchPerformance`.
- Strzelcy są ważeni po pozycji, jakości strzeleckiej, OVR, formie, fitnessie i minutach.

### Save / Load
- `PlayerMatchStats` ma serializację JSON.
- `WorldSave` zapisuje `PlayerCareer.matchStats`.
- `PlayerCareer.fromJson()` odtwarza `matchStats` po wczytaniu.
- Schema save podniesiono z 10 do 11; starsze zapisy nadal są akceptowane.

### Test
- Dodano `test/match_engine_regression_test.dart` z podstawowymi inwariantami wyniku i statystyk meczu.

## Ważne

Flutter SDK nie jest dostępne w środowisku audytu, dlatego nie wykonano `flutter analyze` ani `flutter test`. ZIP został jednak sprawdzony pod kątem integralności archiwum.

## Następny etap

P0.2: pełne ujednolicenie wyboru XI kariery z istniejącym `SquadAIEngine`, a następnie test Save → Load oraz test 30 dni / pełnego sezonu.
