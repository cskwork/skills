# Worked examples: three transition misses

Generic patterns distilled from real release-candidate misses in a turn-based mobile game. All three passed full unit and UI suites and fresh-game autoplay, and were found only by a human playing on a device. Each shows the missing oracle and the persona that would have caught it.

## 1. Resume rejects the first command

**Symptom.** After "Continue" from a saved match, the first player action (e.g. Ready) is rejected with a rate-limit / out-of-order error. Repeated taps eventually succeed.

**Cause.** The authoritative state (core) persisted a per-player command sequence counter and restored it on load. The client-side controller that stamps outgoing commands was recreated with its counter at zero. The core requires `client_seq == saved_seq + 1`, so every command was rejected until the client counter happened to catch up.

```text
# Before: client counter restarts on resume
controller.configure(match_id, fresh_controller_key, last_seq = 0)
# After: client continues from the restored authoritative counter
controller.configure(match_id, fresh_controller_key, last_seq = core.get_command_seq(player))
```

A fresh controller key keeps command IDs unique across sessions; it does not restore the sequence. Both are needed.

**Why tests missed it.** A new match starts at zero on both sides, so fresh-game autoplay never exposed the mismatch. Tests that called the core directly bypassed the broken client layer.

**Catch it with.** `save-resume` followed by `masher`; oracle O-2 (every enabled command is accepted on its first try) observed at the controller boundary, not by calling the core directly; O-8 (cold-load reconstruction).

## 2. AI acts before its screen is visible

**Symptom.** In a timed shared-pick round, AI players had already picked before the pick screen finished appearing.

**Cause.** The presentation layer advanced the simulation in large time chunks per frame. Bots decide on a short tick, so the round-open event and every bot pick were processed in the same frame, before the screen's reveal animation ran. The final ownership was correct, so state-only checks passed.

**Fix pattern.** Advance the simulation one tick at a time and stop the frame on the round-open event; hold the clock until the screen reports ready (with a bounded fail-safe that is itself treated as a failure by the oracle); give bot turns a deterministic, human-scale think delay derived from a hash (not from the gameplay RNG stream, which would change outcomes); start the human's timer only after the hold.

**Why tests missed it.** Correct final state does not prove the choices were visible.

**Catch it with.** `slow-player` and speed-changer personas; oracle O-3 compares the screen-ready timestamp with the first AI action timestamp. A fail-safe release counts as a failure even if the game progresses.

## 3. A checkpoint resurrects a finished player's save

**Symptom.** "Continue" in the lobby opens a match with an empty board: no units, no bench, shop collapsed, no knock-out message.

**Cause.** On elimination the game deleted the save, but the core emitted its end-of-round checkpoint request in the same event batch, which wrote the save again (and later pause / quit / checkpoint events rewrote it). The eliminated player's state was valid but ineligible for resume.

```text
save():
    if not player_alive():
        delete_save()
        return ok          # removal is the correct save outcome
    write_atomic(export_save())
```

Also drop already-written ineligible saves at load, so stale device data stops offering Continue.

**Why tests missed it.** Resume tests used live phases only. A round-trip check (save → load → equal state) passes even when both states describe a finished player.

**Catch it with.** A `save-resume` persona that also saves at terminal states (elimination, results), plus interruption (background/foreground) after elimination; oracle O-8 must check save *eligibility* and event ordering, not only round-trip equality. Never "fix" the symptom by inventing replacement units.

## Common lesson

All three live on a **transition** (resume, screen open, end of life) and are invisible to final-state checks. Put oracles on transitions, observe through the same layer the user goes through, and include terminal states in the save/resume matrix.
