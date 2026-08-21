# Amaze GAG v2 — Stage 0 original-mechanics gate

Date: 2026-08-20
Branch: `codex/art-amaze-gag-v2`
Frozen base: `75ac45bf282e432ad82a1bf3c3c3b2102ba79adc`
Decision: **PASS mechanics gate; art production may start in a later change**

This is a clean-room, renderer-independent mechanics slice. It replaces the
previous wall-less `8 × 8` one-cell flood-fill with the observed Classic
AMAZE!!! loop. It does not copy source code, level data, artwork, audio, or
other proprietary assets. The earlier STOP decision was correct and remained
in force until every gate in this document passed.

No GAG search or generation was performed in this change. Passing Stage 0 only
unlocks a future Stage 1; it does not claim that art has already been produced.

## Reference scope and provenance

Only official or first-party-hosted observable material was used:

- [CrazyLabs — Amaze Console Game](https://www.crazylabs.com/games-console/amaze/)
  identifies the game and describes moving a ball and painting across maze
  puzzles.
- [Apple App Store — AMAZE!!!](https://apps.apple.com/us/app/amaze/id1452526406)
  identifies Crazy Labs as the developer. On 2026-08-20 the US page exposed
  version `6.2.2`, four current iPhone screenshots, and copy describing swiping
  through mazes, filling each square, and unlocking new challenges.
- [Nintendo — AMAZE!](https://www.nintendo.com/us/store/products/amaze-switch/)
  is product `70010000066194`. Its publisher-provided description says to fill
  every square completely and lists Classic, Time Rush, and Limited Moves. The
  official page also exposes a Nintendo-hosted 43-second trailer and six
  screenshots.

Raw reference media is intentionally outside the product repository at:

```text
/home/ubuntu/private-evidence/offline-games/amaze-stage0/
```

Committed audit images contain only this project's candidate runtime. None of
the App Store or Nintendo reference pixels are shipped.

### Capture ledger

| Artifact | Measurement | SHA-256 |
|---|---:|---|
| `app-store.html` | official App Store page | `039b0148ef97c969b71cd61e22216560ddf7d0511cf5d8f2e23e1023d5e3051f` |
| `appstore-iphone-01.jpg` | 1290 × 2796 | `328a4e9d7d9c2fb1b4eb8778aef542c729f05ff06818c94bdedc8d597937e283` |
| `appstore-iphone-02.jpg` | 1290 × 2796 | `6a01ed0f325ff596ea9fe1be2283912fbcd154bbf77453cc072e15faf5ecf4b7` |
| `appstore-iphone-03.jpg` | 1290 × 2796 | `f1f5f2d802e73f0823b355a6a1e088f1a37438fdb03d1645ee9dd1322d3b9a0b` |
| `appstore-iphone-04.jpg` | 1290 × 2796 | `704832da26aff7c26edada252c4014689c876a1f6f9daa9481dda2e185d11f20` |
| `nintendo-store.html` | official Nintendo page | `82da8e9fb97c9035ee5b44c8c546db54886a62cec49f82a72caab683ffea5d62` |
| `nintendo-official-trailer.mp4` | 1280 × 720, 43.109733 s, 30000/1001 fps | `192606aa114755ec8b3c53c5f6bdfc4db6cc9520a2f2adb2201bfb6be3d00483` |
| six Nintendo screenshots | 1280 × 720 | `333f8f29…03c6`, `f73709ea…5f8c`, `420cc8e5…73f9`, `f150a378…ac5e`, `5e483ef0…a266`, `2d46c580…0f18` |

The CrazyLabs official YouTube trailer was identified, but YouTube required an
interactive sign-in in this environment. It was not treated as inspected
evidence. The same observable mechanics were resolved from the Nintendo-hosted
official video instead.

## Facts, measurements, inferences, and decisions

### Observable facts

1. App Store and Nintendo screenshots show a discrete grid of traversable
   squares separated by void/non-playable space. The target is not an open
   rectangle.
2. Official store copy explicitly describes swipe/directional control and
   filling every square.
3. In the Nintendo official trailer, the Level 20 sequence at approximately
   `00:08.5–00:10.3` shows several separate axial commands. Each command moves
   the ball across multiple cells in one straight line and stops on the last
   playable square before a void or outside edge.
4. The same sequence shows the crossed cells changing from dark to painted as
   the ball passes. The ball does not automatically turn at a junction; a new
   axial command starts each subsequent leg.
5. Official screenshots show `RESTART`, `MOVES`, numbered levels, a level
   selection screen, and increasingly complex maze silhouettes.
6. Official store copy defines completion as filling every playable square and
   describes a completed maze unlocking a new challenge.

### Measurements

- Video inspection used 2 fps overview sheets followed by 5/10 fps cropped
  frame sequences. Stop positions were checked against the next grid cell, not
  inferred from a single still.
- App Store screenshots at levels 5, 10, 18, and 30 show long painted runs with
  the ball at a terminal cell and confirm that void cells are excluded.
- Nintendo screenshots include Classic boards, move counters, explicit restart,
  level selection, and other modes. Other modes are evidence of product scope,
  not part of this Classic slice.

### Conservative implementation decisions

| Decision | Status | Reason |
|---|---|---|
| One cardinal command rolls until the next cell would be void/outside | frozen | Directly observed across multiple official video legs. |
| Crossed cells are emitted and painted in travel order | frozen | Directly observed; ordered output is required for later presentation. |
| Re-entering painted cells remains legal | conservative inference | Official material shows no no-revisit rule. Adding one would be unsupported and can make valid slide mazes impossible. A revisit changes position and consumes a move but adds no painted progress. |
| One accepted direction command increments `moves` once | implementation decision | Matches the observed command-level loop and official `MOVES` concept; the trailer does not expose input telemetry frame-by-frame. |
| Score is `5 × newly painted cells`, plus a local 100-point completion bonus | shell-only decision | The shared collection requires a score field. This is not represented as an original AMAZE!!! scoring rule. |
| Restart restores the same authored topology; `下一迷宫` advances after a win | conservative progression decision | Preserves the explicit restart meaning while satisfying official challenge progression without pretending the exact original transition timing was measured. |
| Three locally authored topologies wrap after level three | Stage 0 fixture | They prove mechanics and progression. They are not copied levels and do not claim parity with the original's content volume. |

Swipe threshold, travel animation duration, score, Chinese copy, and the exact
three topology shapes are local product decisions. They are not reference facts.

## Frozen mechanics contract

The authoritative model is `models/amaze_model.gd` (`rules_version`:
`amaze-stage0-v1`). It owns topology, player position, ordered paint state,
move count, completion, restart, and progression. Rendering reads snapshots and
does not determine legal movement.

For every command the model returns:

- `from` and legal terminal `to`;
- ordered `traversed` cells;
- ordered `newly_painted` cells;
- `revisit_count`, `remaining`, `completed`, and a stop reason.

Blocked and post-terminal commands are state-inert. Completion compares painted
count with `walkable_count`; void cells never contribute to the denominator.

### Deterministic topology fixtures

| Level | Size | Walkable | Frozen solve | Purpose |
|---|---:|---:|---|---|
| `corner_intro` | 5 × 5 | 9 | `U R` | long slide, corner stop, full-area completion |
| `ribbon_switchback` | 6 × 5 | 21 | `L U R D L` | repeated wall stops and a switchback |
| `nested_detour` | 7 × 7 | 31 | `R U L D L D U R D L` | long/short runs, partial revisit, near-complete state |

All three are connected, independently deterministic, and solved by model tests
without renderer state mutation.

## Input and action contract

- Arrow/WASD input calls the same model command as pointer gestures.
- Mouse drag and `InputEventScreenTouch` use the same dominant-axis mapping and
  threshold.
- A tap or sub-threshold gesture is inert for Classic Amaze; the old adjacent
  tap rule has been removed.
- Plain Amaze is isolated from `amaze_go` and `arrow_go`; their wall/arrow rules
  and GAG presentation state remain unchanged.
- Runtime actions expose distinct semantics for blocked contact, long travel,
  short travel, revisit, near completion, completion, and restart recovery.
- Every dynamic Chinese action label carries `font_role: ui_cjk`. The shipped
  subset gate and a real browser screenshot confirm readable Chinese rather
  than placeholder glyphs.

## Verification

### Dedicated mechanics probes

```text
AMAZE_MODEL_SMOKE=58             PASS
AMAZE_INTEGRATION_SMOKE=42       PASS
AMAZE_ACTION_SMOKE=26            PASS
```

These cover ordered long travel, legal stops, blocked commands, invalid input,
pure revisit, void exclusion, all three solutions, deterministic snapshots,
restart, level advance/wrap, mouse/touch/keyboard parity, and all semantic
action grades.

### Full repository regression

Every one of the 29 `tools/*smoke.gd` scripts passed. This includes:

```text
RULES_RESULT=PASS
SMOKE_GAMES=14 / SMOKE_RESULT=PASS
CATALOG_ART_RESULT=PASS
AMAZE_GO_MECHANICS_RESULT=PASS
ARROW_GO_MECHANICS_RESULT=PASS
AMAZE_GO_ART_RESULT=PASS
ARROW_GO_ART_RESULT=PASS
FONT_COVERAGE_RESULT=PASS
```

The static subset gate also passed:

```text
FONT_SUBSET_GATE=PASS required=3879 bytes=1816916
```

### Visual and state evidence

Candidate evidence is in `docs/audit/amaze-gag-v2/stage0-candidate/`:

- `00-topology-stable.webp`
- `01-long-roll.webp` + JSON
- `02-revisit.webp` + JSON
- `03-near-complete.webp` + JSON
- `04-complete-impact.webp`
- `05-complete-result.webp` + JSON
- `06-web-complete.png`

Manual review confirmed that the visible topology equals the model, long travel
paints the ordered corridor, a pure revisit keeps progress at 16% while moves
increase, the near-complete capture has exactly one playable cell left, the
completion capture has 31/31 painted, and the Web result Chinese is readable.

### Performance

`stage0-candidate/performance.json` records the software-renderer regression:

| Case | Average | p95 | Max | Peak static memory |
|---|---:|---:|---:|---:|
| stable, 180 frames | 10.82 ms | 17.21 ms | 20.52 ms | 61,605,409 B |
| deterministic busy loop, 240 frames | 10.48 ms | 13.30 ms | 31.42 ms | 62,275,167 B |

This is an llvmpipe regression trace, not a physical-device FPS claim. No
unbounded trail/effect structure was added.

### Web release integrity

A fresh Web export was fingerprinted with the repository's production helper
and exercised in headless Chrome through the actual canvas:

```text
engine token: 2b558bdb3c3a
pack token:   1e8633541cf0
index.2b558bdb3c3a.js    200
index.2b558bdb3c3a.wasm  200
index.1e8633541cf0.pck   200
```

`stage0-candidate/web-acceptance.json` records `PASS` for boot, 14-game catalog,
model entry, keyboard long roll, pointer/keyboard parity, completion, PCK/WASM
loads, and zero console/page/runtime errors. This specifically guards against a
stale or missing fingerprinted `.pck`.

## Art gate conclusion

Stage 0 is green. A later Stage 1 may inherit the already approved pillars in
`docs/art-direction/catalog-cartoon-v1.md`, define Amaze-specific hero objects
and events, then perform real GAG semantic search/generation with a provenance
ledger. That later work must preserve this model and its probes.

Deferred on purpose:

- GAG search, selection, generation, derivation, or asset ledger;
- new Amaze artwork, generated audio, and high-intensity juicing;
- Time Rush, Limited Moves, multiplayer, hundreds of levels, or exact content
  volume parity;
- claims of frame-perfect timing or scoring parity that official evidence did
  not expose.
