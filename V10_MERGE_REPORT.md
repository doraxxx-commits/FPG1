# FPG v10 — raport scalania duplikatów

## Zostawione wersje kanoniczne

| Plik | Decyzja | Powód |
|---|---|---|
| `simulation/world_engine.dart` | pełna wersja | zawiera finanse, kontuzje, kontrakty, transfery, AI składu, generację młodzieży, emerytury, World Simulation 4 i historię |
| `simulation/club_ai_engine.dart` | pełna wersja | realna analiza potrzeb kadrowych zamiast prostego losowania |
| `simulation/mini_game_engine.dart` | pełna wersja | 25 wariantów sytuacji i lepszy model wyniku |
| `models/match_2d.dart` | wersja z `2` | statystyki, doliczony czas, sytuacje i dane minigier |
| `simulation/match_2d_engine.dart` | wersja z `2` | najbardziej kompletna: sytuacje, pojedynki, AI pozycyjne, statystyki, minigry i 90+ |
| `screens/match_screen.dart` | wersja z `2` | obsługuje pełny model 2D, oficjalny wynik i statystyki |

## Odrzucone duplikaty

Usunięto kopie oznaczone ` 2`, ` 3` itd. dla tych samych plików.
Nie usuwano unikalnych silników tylko dlatego, że są jeszcze niewykorzystywane.

## Co dopisano

- start świata: **23.08.2026**,
- sezon piłkarski nie zmienia się 1 stycznia; zmienia się 1 lipca,
- catch-up meczów z datą wcześniejszą niż dzień rozpoczęcia,
- kolejność operacji WorldEngine została uporządkowana,
- `lastDayEvents` / `recentWorldEvents` jako most do przyszłego News/FPG Social,
- raport scalania i zaktualizowany opis V10.
