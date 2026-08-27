# FPG Match Engine v9

## Branching situations
A key action is now part of a connected situation. The result of the mini-game changes the next state of that situation:

- successful pass -> receiver/next beat remains active;
- failed pass -> interception and the attack is broken;
- successful dribble -> attacker advances and the next beat remains active;
- failed dribble -> turnover and the attack is broken;
- successful tackle -> possession changes and play can transition;
- missed save -> goal branch;
- successful shot -> goal branch and the situation ends.

This is the foundation for counter-attacks, second balls, rebounds and corners in later versions.

## Stoppage time
The match no longer ends automatically at 90'. At exactly 90' the engine calculates added time from match disruptions:

- baseline delay: 0:45–2:00;
- goals: +0:45–1:15 each;
- injuries: +1:00–3:00 each;
- substitutions: +0:25–0:50 each;
- cards: +0:15–0:35 each.

The result is clamped to **1–15 minutes**.

The clock is displayed as:

- 90'
- 90+1'
- 90+2'
- ...
- 90+15'

Only after the final added minute does the match become `finished` and the official score is synchronized.
