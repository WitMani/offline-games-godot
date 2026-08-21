# Amaze v3 Stage 0 mechanics gate

Decision: **PASS for the bounded Classic mechanics slice**

## Independent evidence review

Facts, measurements, inference, and decisions are separated in
`target-manifest.md` and `claim-ledger.md`. The v3 re-review inspected the
private hashes and the Nintendo trailer's Level 20 sequence around
`00:08.5–00:10.3`, including overview and cropped frame sequences. It again
showed multi-cell straight travel, ordered painting, no auto-turn, and stopping
at the last playable square before void/outside. App Store screenshots at
levels 5/10/18/30 independently show irregular playable silhouettes and long
painted runs.

Exact original levels and progression remain unresolved. Therefore the three
locally authored deterministic topologies are mechanics fixtures, not content
parity claims.

## Renderer-free contract

`models/amaze_model.gd` owns:

- topology/walkability and exactly one start cell;
- cardinal trace to the last legal stop;
- ordered traversal and first-paint order;
- legal revisit, blocked/invalid/post-terminal inertness;
- playable-cell completion, restart, and bounded level advance;
- JSON-safe snapshots;
- replay-validated checkpoint/recovery with atomic corruption rejection.

The runtime renderer consumes snapshots and semantic outcomes. It does not
decide movement legality or completion.

## Deterministic fixtures

| ID | Board | Walkable | Frozen solve | Primary probe |
|---|---:|---:|---|---|
| `corner_intro` | 5×5 | 9 | `U R` | long roll, boundary/void stop, completion |
| `ribbon_switchback` | 6×5 | 21 | `L U R D L` | switchback and repeated legal stops |
| `nested_detour` | 7×7 | 31 | `R U L D L D U R D L` | long/short legs, revisit, near/full |

## Current-baseline verification

Re-run on Godot 4.6 against the `3e561fb3` public baseline plus this isolated
mechanics slice:

```text
AMAZE_MODEL_SMOKE=76       PASS
AMAZE_INTEGRATION_SMOKE=50 PASS
AMAZE_ACTION_SMOKE=26      PASS
RULES_RESULT=PASS
SMOKE_GAMES=14             PASS
```

The dedicated probes cover all three solutions, long travel and ordered paint,
void/boundary stops, blocked state inertness, revisit, completion, restart,
mouse/touch/keyboard parity, next-level behavior, save/reopen recovery, won
recovery, transient-effect clearing, and malformed/tampered checkpoint atomic
rejection.

Stage 0 therefore unlocks art migration. It does not accept the prior art
commit, prior screenshots, prior Web build, or prior performance report; those
must pass separate v3 runtime gates.
