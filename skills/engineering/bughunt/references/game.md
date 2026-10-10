# Profile: game

Use for turn-based, real-time, idle, puzzle, card and auto-battler games. The core [personas](../personas.md) and [oracles](../oracles.md) are written in game vocabulary: apply every ID as written.

## Where games break

- **Phase transitions**: draft → battle → results → next round, and every screen opened from them. Each transition is a resume point, a readiness gate, and a place for a stale enabled control.
- **Bot readiness** (O-3): an AI or opponent acts only after its screen is presented, and the human's decision window starts at readiness, not at phase open.
- **Economy and identity** (O-5): currency, HP, inventory, unit ownership and board slots stay inside their documented bounds; every removal is explained by an event.
- **Simulation speed**: 1x/2x/3x changes stay out of real-time deadlines and leave equal logical results.
- **Save at every phase**, including elimination and results; a finished run's Continue never comes back.

## Extra cases

| Case | Stress |
|---|---|
| reward double-claim | `masher` on claim, buy, upgrade and reroll buttons; one effect per enabled press. |
| pause during transition | Pause and resume exactly at phase change and during reveal animations. |
| tutorial skip | Skip and re-enter onboarding at each step; no locked controls afterward. |
| clock change | Idle/offline timers with the device clock moved forward and back, where the game grants time-based rewards. |

## Fixtures

Pin the game RNG separately from the persona RNG and record both seed lists. Use deterministic simulation fixtures for each phase (start of draft, mid-battle, results, eliminated). The Godot adapter is the usual driver; native and web builds use theirs.

Worked failures from a real release candidate: [examples/transition-misses.md](../examples/transition-misses.md).
