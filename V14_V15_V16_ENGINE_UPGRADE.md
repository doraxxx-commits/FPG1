# FPG V14–V16 ENGINE UPGRADE

## V14 — World Engine
- Results now affect fan support, stability, board confidence, finances and transfer activity.
- Tactical identity, manager quality and stability affect club strength gradually.
- Financial crisis increases board pressure and pushes clubs toward youth development.
- Successful clubs gain resources and become more active on the market.

## V15 — Match Engine 2.0
- Match results now expose shots, shots on target, corners, fouls, cards and possession.
- Team strength uses squad quality, form, fitness, morale, finances, reputation, tactical identity and manager quality.
- Matches can produce discipline events and realistic short injuries.
- The same MatchResult remains the source of truth for the autonomous world.

## V16 — Career Gameplay Foundation
- Match performances continue to feed form, morale, manager relationship and development.
- Young players gain career milestones through real match minutes.
- Injuries and fitness now influence selection and subsequent matches.
- The engine is prepared for the later UI overhaul without changing the simulation contract.

## Design rule
The world should evolve through chains of consequences, not isolated random events:

results → morale/fans → finances → board pressure → manager decisions → tactics/squad building → transfers → team strength → future results.
