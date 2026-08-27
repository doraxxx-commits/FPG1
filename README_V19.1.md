# FPG V19.1 — Career Events & Consequences

Based on V19.0 Career Decision Center.

The Career Decision Center is now connected to a consequence layer. Player decisions create real WorldEvents, are visible to the world/media pipeline, and can create delayed consequences on following days.

Save compatibility is preserved through the existing WorldEngine JSON structure; the new engine stores its own cooldown state under `careerEventConsequences`.
