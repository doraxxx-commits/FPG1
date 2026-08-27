# FPG V19.7 — Relationship Events

V19.7 turns the Relationship Web into interactive career scenes. The player no longer only changes relationship numbers: important situations open a scene with multiple responses.

### Examples
- Coach asks about role.
- Agent calls with market information.
- Sporting director asks about the player's future.
- Media request an answer under pressure.

Every choice feeds back into the existing relationship, fame, media, transfer and happiness systems and emits a WorldEvent for the Media/Social pipeline.

Save compatibility: V19.6 data remains readable; missing `relationshipEvents` data starts empty.
