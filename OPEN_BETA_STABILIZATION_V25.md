# FPG — Open Beta Stabilization V25

## Cel
V25 jest teraz traktowane jako warstwa stabilizacyjna, nie jako pretekst do dodawania kolejnych systemów.

## Naprawione w tej rewizji
- Centrum Decyzji nie używa już `Player` jako modelu ekranu kariery; dane profilu są pobierane z `PlayerCareer`.
- Model świata (`Player`) pozostaje używany wyłącznie do negocjacji, konsekwencji i integracji z WorldEngine.
- Przy odświeżeniu Centrum Decyzji bridge jest ponownie podpinany, więc ekran nie zależy od przypadkowego stanu inicjalizacji.
- Główne przejście `Następny dzień` ma granicę bezpieczeństwa UI: wyjątek symulacji nie zamyka aplikacji.
- Dodano test regresyjny rozdzielający model kariery od projekcji świata.

## Zasada przed Open Betą
Nie dodawać kolejnych dużych systemów. Najpierw przejść przez wszystkie istniejące ekrany i ścieżki użytkownika, znaleźć wyjątki, naprawić integracje i dopiero potem oznaczyć funkcję jako gotową.
