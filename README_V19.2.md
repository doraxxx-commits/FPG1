# FPG V19.2 — Career Storylines

V19.2 adds persistent multi-stage career stories on top of V19.1.

Flow:
Decision / World event → Storyline starts → stage progression → player resolution → consequence → World Event / Media.

The storyline engine is persisted with the world save. The Career Home save action now uses `GameEngine.saveWorld()` so story state is included.
