# FPG — World Simulation 4.0 progress

## Added
- AcademyEngine: talent generation based on academy quality, youth focus, club reputation and country football strength.
- ReputationEngine: separate player and manager reputation tracking.
- RivalryEngine: persistent club rivalries with evolving intensity.
- WorldSimulation4Engine: orchestration layer integrated into WorldEngine.
- Player agent fields: `agentId`, `agentInfluence`.
- Club manager identity fields: `managerId`, `managerName`, `managerReputation`.

## Integration points
- Daily world processing updates player/manager reputations.
- End-of-season processing generates academy talents and updates rivalries.
- Existing match, finance, transfer, aging and retirement engines remain intact.

## Completed in WORLD ENGINE 08 → 09
- AgentEngine with individual agents and client portfolios.
- TransferInterestEngine with persistent club/player interest.
- NegotiationEngine with multi-round counteroffers and closing logic.
- DressingRoomEngine with hierarchy, tension and frustration events.
- WorldSimulation4Engine now feeds these events into the global WorldEventEngine / FPG Social pipeline.
- NationalTeamEngine: country squads, call-ups and season-level international results.
- Player nationality field; academy graduates inherit club country.

## Remaining World Simulation 4.0
1. Agent preferences, loyalty, wage demands and agent poaching.
2. Player awareness/choice when interest becomes serious.
3. Full loan negotiations and contract clauses.
4. Manager personality changes and board hiring/firing decisions.
5. Rivalry match modifiers and derby-specific events.
6. Career-player integration with the same world systems.


## WORLD ENGINE 11
- PlayerDecisionEngine: zawodnik staje się świadomym uczestnikiem rynku; może zaakceptować zainteresowanie, odrzucić je albo zażądać transferu.
- AgentEngine rozszerzony o lojalność, żądania płacowe i agresywność negocjacyjną.
- NegotiationEngine wymaga świadomości zawodnika i uwzględnia wpływ agenta oraz oczekiwania płacowe.
- Player rozszerzony o szczęście, żądanie transferu i składniki pakietu kontraktowego.
- TransferInterest przechowuje dzień poinformowania zawodnika i jego decyzję.
- ContractEngine zaczyna budować pełniejszy pakiet: bonus występowy, gol, asysta i trofeum.

## Next
1. Pełne negocjacje kontraktu zawodnika z agentem.
2. Wypożyczenia jako negocjacje: opłata, podział pensji, klauzula wykupu, gwarantowane minuty.
3. Manager/Board Engine: zatrudnianie, zwalnianie, presja zarządu i zmiana stylu trenera.
4. Derby/rivalry modifiers w MatchEngine.
5. Career Player jako pełnoprawny uczestnik tych samych systemów świata.
- RivalryEngine exposed derby intensity; GlobalMatchEngine now receives rivalry intensity and adds controlled derby modifiers.
- LoanNegotiationEngine: loan fee, wage share, guaranteed minutes and buyout clause are negotiated before a loan is completed.

## Iteracja 11 -> 12

Dodano:
- BoardEngine: zaufanie zarządu, presja wyników/finansów i reakcje na kryzys trenera.
- ContractNegotiation model + ContractNegotiationEngine: wieloetapowe przedłużenia, pensja, bonusy, długość i klauzula.
- AgentEngine: zmiana agenta, wyszukiwanie alternatywy i rozwój portfela.
- Integracja BoardEngine, ContractNegotiationEngine i wzrostu portfeli agentów z WorldSimulation4Engine.
- Korekta PlayerDecisionEngine: reputacja kupującego jest liczona względem neutralnego poziomu 50.

Następne braki:
- pełna wymiana agenta jako wydarzenie świata i decyzja zawodnika,
- zwalnianie/zatrudnianie trenerów z kandydatami i kontraktami,
- realne konsekwencje konfliktów szatni,
- pełna reprezentacja: powołania, turnieje i osobne statystyki zawodnika,
- wspólny rdzeń MatchSimulation dla świata i kariery,
- 2D Match Engine i minigry pozycyjne,
- save/load dla nowych systemów.

## Iteracja 13
- Dodano wspólny `MatchSimulationCore` używany przez `GlobalMatchEngine` i `MatchEngine` do obliczania siły zespołów, xG i goli.
- Rozszerzono historię reprezentacyjną `Player`: caps, gole, asysty, powołania i rok ostatniego powołania.
- Rozszerzono `NationalTeam` o mecze towarzyskie/konkurencyjne/turniejowe i statystyki turniejowe.
- `NationalTeamEngine.processSeason()` aktualizuje indywidualne statystyki reprezentacyjne.
- `DressingRoomEngine` może teraz eskalować napięcie do żądania transferu i obniżenia zaufania do trenera/stabilności klubu.
- Dodano `ManagerCandidate` i pulę trenerów AI; `ManagerWorldEngine` dobiera kandydatów według jakości, reputacji, stylu, rozwoju młodzieży i kosztu.
- `WorldSimulation4Engine.processSeason()` uruchamia pełną symulację sezonu reprezentacyjnego.
- Nadal brak możliwości wykonania `flutter analyze` w środowisku bez Flutter SDK.
