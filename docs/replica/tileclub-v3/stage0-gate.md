# Tile Club v3 Stage 0 mechanics gate

Decision: **PASS for the bounded core mechanics slice**

## Independent evidence review

Facts, measurements, conservative inferences, local decisions, and unknowns are
separated in `target-manifest.md` and `claim-ledger.md`. The official Google Play
trailer directly shows layered overlapping piles, exposed-tile collection into
an ordered seven-cell tray, and automatic removal/compaction of the third equal
item. Official Google and Apple screenshots independently show layered layouts,
seven tray cells, cute motif families, multiple backgrounds, and boosters.

The short media does not establish exact loss, covered-edge, level-content,
score, booster, or recovery behavior. Those remain inference, local decision,
or `NOT_CLAIMED`, never reconstructed fact.

## Renderer-free contract

`models/tileclub_model.gd` owns:

- authored tile positions/layers and geometry-derived blockers;
- exposed/selectable status and inert covered/removed/terminal rejection;
- ordered seven-slot tray collection;
- third-equal resolution before the capacity failure check, preserving other
  tray order;
- newly exposed tiles, cleared layers, bounded failure and completion;
- three deterministic solvable clean-room layouts, restart, and level advance;
- JSON-safe snapshots and replay-validated checkpoint recovery with atomic
  corruption rejection.

The renderer consumes model snapshots and semantic outcomes. It does not decide
selection legality, match resolution, capacity, failure, or completion.

## Deterministic fixtures

| ID | Tiles | Initially selectable | Layers | Frozen primary probe |
|---|---:|---:|---:|---|
| `four_nests_intro` | 12 | 4 | 2 | block/reveal, four triples, completion |
| `six_nests_ribbon` | 18 | 6 | 2 | ordered tray, restart/progression |
| `seven_nests_fan` | 21 | 7 | 2 | match-before-capacity, 5/6-slot risk, 7-slot loss |

These are mechanics fixtures, not copies of first-party layouts.

## Current-baseline verification

Re-run on Godot 4.6 against exact baseline `3e561fb3` plus this isolated slice:

```text
TILECLUB_MODEL_SMOKE=152       PASS
TILECLUB_INTEGRATION_SMOKE=54  PASS
TILECLUB_ACTION_SMOKE=70       PASS
RULES_RESULT=PASS
SMOKE_GAMES=14                 PASS
```

The dedicated probes cover all three deterministic solves, covered rejection
and reveal, ordered tray and compaction, triple-before-capacity, 5/6/7-slot
states, completion, restart, next level, mouse/touch/keyboard model parity,
reopen recovery, lost/won recovery, transient clearing, and atomic rejection of
malformed/tampered checkpoints. Runtime-only frames and state payloads are in
`../../audit/tileclub-v3/stage0/`.

Stage 0 therefore unlocks live GAG/provenance and presentation review. It does
not accept the inherited v2 art ledger, assets, screenshots, audio, Web build,
performance report, or deployment. Those require current live and runtime gates.
