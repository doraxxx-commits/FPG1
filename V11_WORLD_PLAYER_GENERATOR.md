# FPG V11 — World Player Generator

V11 turns the world player generator into a persistent part of the main `Player` model.

## What changed

- New academy prospects are generated at the end of every season.
- Generated players are real `Player` objects, not a parallel `WorldPlayer` universe.
- Age, OVR and POT are correlated with club strength.
- Position-specific attributes are generated instead of cloning a single generic stat line.
- Academy intake is controlled by squad size, so the world does not explode with free agents.
- Existing retirement/replacement logic remains active.
- Generated players inherit a club immediately and are therefore visible to Squad AI, transfers, development and Match Engine.
- Save/load now restores the complete player and club collections, which is required once players can be created and retired dynamically.

## Long-term career effect

A club can now lose an older generation and continuously replace it with younger players. Over many seasons the same club can therefore develop a different squad from the original 2026 database.

This is the foundation for V11.1: nationality-aware scouting, academy quality, youth contracts, loan pathways, breakthrough probabilities and genuinely unique wonderkids.
