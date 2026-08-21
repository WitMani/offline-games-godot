# Tile Club v3 claim ledger

## Direct facts and observations

| Statement | Confidence | Runtime consequence |
|---|---:|---|
| The target identity is GamoVation Tile Club with Android package `com.gamovation.tileclub` and Apple ID `1640075364` | high | The implementation and evidence are scoped to this product, not a generic tile-matching title |
| Official media shows a heavily layered, overlapping tile pile | high | Tiles have authored position/layer data and render back-to-front |
| A clicked exposed tile enters the next position of a seven-cell tray | high | Accepted selection appends to an ordered tray with capacity 7 |
| On the third identical tray item, those three items disappear automatically and the remaining items compact without being reordered | high | Triple resolution runs before the full-tray check and preserves all other ordering |
| Official copy describes classic triple-tile matching, thousands of layouts, cute motif families, offline play, boosters, and level progression | high | The bounded slice includes only triple matching, clean-room layouts, restart, and next-level progression |
| Mouse/touch are reference-platform input forms | high | Pointer and touch feed the same authoritative collect operation |

## Measurements

| Statement | Confidence | Runtime consequence |
|---|---:|---|
| The visible tray has seven cells throughout the official trailer | high | `TRAY_CAPACITY = 7` |
| The official Google trailer is 1280×720, 6.950 seconds, 20 fps, 139 frames | high | Frame-order observations are reproducible from the private hash |
| Apple reported version `3.5.2` on 2026-07-01; Google Play reported an update on 2026-07-28 | high | Version/date are frozen in the target manifest; later store drift does not silently change the target |

## Conservative inferences

| Statement | Confidence | Runtime consequence |
|---|---:|---|
| A tile overlapped by a live higher-layer tile is unavailable until its blocker is removed | medium | Geometry-derived blockers reject covered selections without mutation |
| Filling all seven tray cells without a resolving triple is the bounded loss condition | medium | The local model enters `over` after triple resolution leaves seven items |
| Removing every tile with an empty resolved tray completes this bounded level | medium | The model enters `won` only when board and tray are both empty |

These rows are deliberately not promoted to direct facts: the short official
trailer does not show a covered-edge rejection, the exact failure screen, or a
full completion arc.

## Local product and reliability decisions

| Statement | Runtime consequence |
|---|---|
| Three deterministic `nest` layouts are original mechanics fixtures | They exercise 12, 18, and 21 tiles without claiming copied level data or reference difficulty |
| An overlap fraction of at least 0.18 blocks the lower tile | A deterministic geometry threshold replaces unknown proprietary hit geometry |
| Arrow/WASD plus Enter/Space are desktop accessibility controls | Keyboard uses the same collect function; it is not claimed as mobile reference behavior |
| One accepted selection increments `moves`; each triple adds 100 shell points | Shared catalog counters remain useful, but original scoring is `NOT_CLAIMED` |
| Checkpoints replay accepted tile IDs and validate all derived fields | Reopen/recovery is deterministic; this is a reliability feature, not an original behavior claim |
| Blocked/collect/match/layer-clear/risk/full/complete semantic feedback grades are presentation decisions | Feedback can strengthen meaning without changing model authority |

## Explicit unknowns

- Exact current level graphs, tile counts, motif distribution, layout order,
  difficulty curve, goal variants, and unlock pacing.
- Exact response to clicking a partially visible but covered tile edge.
- Exact loss threshold timing, failure UI, continuation offers, undo/shuffle/wand
  booster rules, and checkpoint/restart semantics.
- Exact score, move counting, animation, audio, haptic, and transition timing.

No visual similarity, GAG asset, or passing local smoke can resolve these facts.
