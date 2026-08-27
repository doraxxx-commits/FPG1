# FPG V25 — Daily Simulation Core

## Cel

V25 wprowadza jeden centralny mechanizm wykonania dnia. UI nie steruje już
kolejnością systemów. `DailySimulationCore` jest orkiestratorem, a istniejące
silniki pozostają wyspecjalizowanymi modułami.

## Kolejność dnia

`DATE → RECOVERY → FORM → SQUAD DECISION → CAREER MATCHES → WORLD AI → CAREER/WORLD BRIDGE → SEASON MAINTENANCE`

### 1. DATE
Przesuwa wyłącznie datę symulacji przez `GameState.nextDay()`.

### 2. PLAYER RECOVERY
Regeneracja zmęczenia i fitnessu zawodnika.

### 3. PLAYER FORM
Dzienna korekta formy wynikająca m.in. ze zmęczenia.

### 4. SQUAD DECISION
Trener ustala status zawodnika przed meczem. Snapshot meczu jest czyszczony.

### 5. CAREER MATCHES
Wszystkie mecze kariery zaplanowane na konkretny dzień są rozstrzygane.

### 6. WORLD AI
`WorldEngine.processDay()` uruchamia autonomiczny świat: mecze AI,
kontuzje, rozwój, składy, trenerów, finanse, transfery, relacje, media,
wydarzenia i pozostałe systemy.

### 7. CAREER/WORLD BRIDGE
Wynik realnego meczu kariery wraca do świata i aktualizuje konsekwencje.

### 8. SEASON MAINTENANCE
Jeżeli sezon się skończył, przejście sezonowe jest wykonywane w ramach tego
samego ticka dnia.

## Ważna zasada architektury

`DailySimulationCore` **nie zawiera logiki transferów, treningu, relacji,
mediów ani meczów**. On ustala tylko kolejność i granice transakcji dnia.
Dzięki temu nie tworzymy kolejnego monolitycznego silnika.

Następny etap V25.x powinien rozszerzyć ten mechanizm o:
- kolejkę zdarzeń dnia,
- priorytety zdarzeń,
- zależności przyczynowo-skutkowe,
- budżet losowości,
- raport dnia,
- bezpieczne save/load ticka,
- tryby symulacji dnia/tygodnia/meczu/do końca sezonu.
