# FPG V24 — Simulation Calendar & Season Start

## Cel
Kariera jest sterowana wyłącznie przez kalendarz symulacji. Faktyczny zegar telefonu nie przesuwa dnia/nocy ani postępu kariery.

## Zmiany
- Start nowej kariery: **24.07.2026**.
- Sezon 2026/27 ma pierwszy dzień kalendarza 24 lipca 2026.
- Terminarz Ekstraklasy jest zakotwiczony na 24.07.2026.
- Druga runda jest generowana od 09.01.2027.
- Koniec meczu nie przechodzi automatycznie do kolejnego dnia.
- Gracz sam uruchamia `advanceSimulationDay()` / `nextDay`.
- Trening, relacje, media, decyzje, świat AI i mecze wykonują się w ramach aktualnego dnia symulacji.
- Save/load zachowuje datę symulacji.

## Główna zasada
`SIMULATION DATE -> PLAYER ACTIONS -> DAILY WORLD TICK -> NEXT SIMULATION DAY`

Nie używamy czasu urządzenia jako źródła postępu kariery.
