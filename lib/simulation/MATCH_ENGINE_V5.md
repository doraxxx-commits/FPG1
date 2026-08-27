# FPG Match Engine v5

## Cel

v5 przesuwa mecz 2D z prostego ruchu właściciela piłki w stronę **budowania akcji**.
Mecz nadal pozostaje zgodny z istniejącym API projektu, ale otrzymuje warstwę statystyk i zachowania taktycznego.

## Nowe elementy

- statystyki posiadania naliczane co sekundę meczu,
- strzały i strzały celne,
- podania i podania zakończone przejęciem partnera,
- dryblingi i odbiory,
- liczba kluczowych momentów,
- wybór celu podania na podstawie przestrzeni, kierunku ataku, roli i presji,
- większa stabilność szerokości oraz struktury formacji,
- statystyki widoczne podczas meczu 2D.

## Ważna zasada

Nie usuwamy jeszcze `GameEngine.playFixture()`. Oficjalny wynik ligi nadal pozostaje źródłem prawdy. v5 przygotowuje dane i zachowanie potrzebne do kolejnej migracji, w której wynik będzie powstawał z symulacji meczu, a nie będzie wcześniej ustalany.

## Następny krok: v6

1. osobny stan posiadania (`PossessionPhase`),
2. wybór akcji przez AI na podstawie ryzyka,
3. ruch zawodników bez piłki do wolnych stref,
4. pressing całej jednostki zamiast pojedynczego zawodnika,
5. kontry po stracie,
6. odbite piłki i drugie piłki,
7. tworzenie sytuacji bramkowych z kilku zdarzeń,
8. dopiero potem pełne odłączenie wyniku od `playFixture()`.

Docelowy rytm nadal pozostaje inspirowany New Star Soccer: większość meczu jest automatyczna, a gracz przejmuje tylko kilka naprawdę ważnych decyzji.
