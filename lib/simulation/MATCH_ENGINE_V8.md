# Match Engine V8

V8 adds the duel layer and the complete five-variant mini-game catalogue.

## Duels
- dribble vs defender
- front/side/recovery/interception/last-man tackle contexts
- stamina, space and overall rating influence the result
- contested duels are distinct from clean wins

## Mini-games
Each role now has five variants:
- GK: ground, high, near post, one-on-one, penalty
- DEF: front, side, recovery, interception, last man
- MID: through ball, one-two, cross, switch, final ball
- WINGER: inside, outside, stop-go, feint, counter
- ST: placement, power, first time, one-on-one, volley

The current UI keeps the five base interaction types and receives the selected
variant through `kind:variant`. This lets us replace each base interaction with
a dedicated control scheme without changing the match engine API.

## Next
V9 should make the result of a player mini-game alter the active situation:
- successful pass -> continue to the next beat
- failed pass -> interception and break
- successful dribble -> defender beaten and space opened
- failed dribble -> turnover
- successful shot -> save/goal branch
- successful tackle -> transition to counter
