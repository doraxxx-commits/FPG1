# FPG V23 — Match Presentation & System Integration

## Cel
Domknięcie najważniejszego problemu po V22: widok 2D ma przedstawiać przebieg tego samego meczu, a nie przeskakiwać między właścicielami piłki.

## Zmiany
- dodano `ballTargetOwnerId` i `ballTravelProgress`;
- podanie ma teraz fazę lotu piłki od podającego do odbiorcy;
- odbiorca otrzymuje piłkę dopiero po zakończeniu lotu;
- ruch bez piłki został rozdzielony od ruchu posiadacza;
- utrzymano role pozycyjne, pressing, szerokość boiska i przesuwanie formacji;
- zmniejszono interwał prezentacji meczu do 160 ms, aby ruch był płynniejszy bez agresywnego zwiększania obciążenia;
- mini-gra nadal zatrzymuje mecz i wpływa na wynik sytuacji;
- oficjalny wynik pozostaje spięty z Fixture i tabelą.

## Zasada architektoniczna
`MatchEngine`/`Fixture` = wynik oficjalny.
`Match2DEngine` = przebieg wizualny tego meczu.
`MiniGameEngine` = wykonanie decyzji gracza w kluczowej sytuacji.
`LeagueEngine` = tabela.

Żaden z tych systemów nie powinien tworzyć drugiego, niezależnego meczu.

## Następny test
1. Nowa kariera.
2. Pierwszy mecz.
3. Obserwacja kilku podań i zmian posiadania.
4. Kluczowa sytuacja zawodnika.
5. Mini-gra.
6. Koniec meczu.
7. Sprawdzenie wyniku w Fixture.
8. Sprawdzenie tabeli.
9. Zapis i wczytanie.
10. Kolejny dzień i kolejny mecz.
