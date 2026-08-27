# FPG — Match 2D design

The match is a provisional top-down visualization. AI controls all 22 players and the ball. It is deliberately a presentation/simulation layer over the shared match simulation core.

## Key moments / mini-games

There are five mini-games per role:
- GK: save, one-on-one, positioning, cross, penalty
- DEF: tackle, block, interception, positioning, clearance
- MID: short pass, through ball, vision, press, long pass
- ATT: finish, header, one-touch, run behind, hold-up play

Wingers use the attacker set for now. This can later receive its own five-game set without changing the architecture.

## Important gameplay rule

A mini-game result is **never the football outcome**. `MiniGameEngine.resolve()` produces two separate values:
1. `executionScore` / `actionExecuted` — how well the player performed the interactive challenge.
2. `generatedStatOutcome` — an independent world roll using context, attributes, form, fitness, morale and AI/opponent randomness.

Therefore:
- a perfect pass mini-game does not guarantee an assist;
- a successful dribble mini-game does not guarantee the next pass is accurate;
- a failed finishing mini-game can still produce a goal because of the wider match context;
- a good tackle challenge can still fail against the opponent's action.

This separation is intentional and should remain when the visual mini-games become more sophisticated.
