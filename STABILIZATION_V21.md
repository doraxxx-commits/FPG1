# FPG V21 — Core Stabilization

## Source of truth
- `Fixture` is the authoritative record of a league match.
- `LeagueEngine` is rebuilt from played fixtures when a save is loaded.
- Interactive 2D results reconcile the same fixture exactly once.

## Career start
- New career no longer catches up old league fixtures.
- First league round starts on the first Saturday on/after 23 August of the season.
- No phantom points or played matches at career creation.

## Matchday flow
1. Player match is resolved.
2. Interactive 2D result reconciles the fixture.
3. All remaining fixtures on the same calendar day are simulated.
4. Only then does the game advance to the next day.

## Save
Fixtures are persisted. Older saves without fixture data are migrated safely; their
league table is rebuilt from any fixture results available in the save.

## 2D
- Official scheduled goals are materialised at their planned minutes.
- Missing goals are no longer dumped into the final minute unless a genuine
  synchronization fallback is required.
- Passes no longer teleport the ball directly to the receiver; the ball starts
  from the passer and is pulled toward the new owner by the movement loop.
- Visual tick interval reduced from 350ms to 180ms.

## Decision Center
External negotiation failures are caught and shown as a recoverable message instead
of taking down the whole screen.
