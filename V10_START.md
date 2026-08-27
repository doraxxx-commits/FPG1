# FPG V10 — World Truth

## Cel V10
Świat ma wykonywać autonomiczny tick każdego dnia. Oficjalny `MatchResult` z meczów AI jest źródłem zmian tabeli, formy, morale, serii wyników i danych dla przyszłego News/FPG Social.

### Obecny przepływ dnia
1. regeneracja zawodników
2. kontuzje
3. wybór składów AI
4. trenerzy i zarządzanie
5. mecze świata AI
6. konsekwencje meczów
7. ekonomia tygodniowa
8. transfery/wypożyczenia
9. relacje, agenci, negocjacje i reprezentacje
10. wydarzenia organiczne
11. przeliczenie siły klubów

### Ważne
- Data startowa: 23.08.2026.
- Sezon zmienia się 1 lipca, nie 1 stycznia.
- Świat nadrabia zaległe mecze sprzed daty rozpoczęcia kariery.
- `WorldEngine.lastDayMatchResults` zawiera oficjalne wyniki AI z ostatniego ticka.
- `WorldEngine.lastDayEvents` zawiera wydarzenia powstałe w wyniku świata.
- `targetHomeGoals/targetAwayGoals` pozostają tymczasowo w prezentacyjnym Match2D. Usunięcie ich nastąpi dopiero po spięciu interaktywnego Match2D z jednym źródłem wyniku.
