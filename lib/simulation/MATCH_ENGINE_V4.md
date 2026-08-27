# FPG Match Engine v4

The match system is being moved toward an event-driven model.

## Core sequence

build-up -> progression -> duel -> final third -> shot/cross -> result -> restart

A player mini-game pauses the presentation only at a decisive action. The mini-game result is then applied to the live Match2DState.

## Important boundary

`MatchFlowEngine` contains no Flutter/UI code. `Match2DEngine` owns the live 2D state. `GameEngine` remains the career/world authority until its fixture API is migrated to accept an externally resolved match result.

## Next migration

1. Add a `MatchResultDraft`/`MatchOutcome` contract to the core simulation layer.
2. Stop calling `GameEngine.playFixture()` before the interactive match starts.
3. Run the same event engine for AI matches in headless mode.
4. Commit the final result once at the end of the match.
5. Feed goals, shots, passes, cards, injuries, form and morale into the world engine.
