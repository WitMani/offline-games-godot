# Merge 2248 Stage 0 fidelity audit v4

## Result

`FAIL — mechanics contract is not yet safe to freeze.`

The existing candy-workshop/GAG slice is a valid presentation candidate, but
its art gate is closed until the rule model below is corrected and probed. In
particular, the current model ends the run when it creates 2048; secondary
runtime evidence shows continuing boards with values and scores many orders of
magnitude above 2048. No merge, public deployment, new GAG generation, or
comparative art claim is authorized by this audit.

## Evidence discipline

This audit uses four distinct labels:

- **First-party fact**: product identity, listing text or a directly visible
  element in an Apple/Google asset.
- **Secondary runtime observation**: directly visible UI/state in a player
  capture, corroborated where possible, but not an official specification.
- **Hypothesis**: a plausible rule that still needs a real action trace,
  authorized build, or reproducible implementation measurement.
- **Local decision**: a compatibility choice made to keep development moving;
  it must never be described as recovered original behavior.

The immutable sources and hashes are recorded in `target-manifest.md`. Private
captures are not repository assets and must not enter a Web pack.

## First-party facts and direct observations

| Observation | Consequence | Limit |
|---|---|---|
| Apple's versioned listing identifies the product and explicitly includes both 2048 and 2248 | `merge2248` has a valid current product target | The prose does not specify rules |
| The current official 2248 phone and tablet images show a 5-column board, `Score`, `All Time`, a next-result display reading `512`, back and settings controls, and colored power-of-two tiles | Width, major HUD roles and a preview/result affordance belong in the contract | A promotional still cannot prove transition order or persistence semantics |
| The official phone image shows seven visible rows | A 5 x 7 presentation exists in the current product | The image does not name its difficulty, so it cannot prove that seven rows means `Medium` or that it is the default |
| The yellow promotional connector includes diagonal-looking segments | Diagonal connection is visually consistent with the target | The line branches from a tile and is therefore a marketing composite, not one valid drag trace |

The composite connector is an explicit negative finding. It must not be used to
prove chain order, result rounding, backtracking, or that the displayed `512`
came from every highlighted tile.

## Secondary runtime observations

| Observation | Confidence | Product consequence |
|---|---:|---|
| An `EASY MODE` capture shows a 5 x 8 board; a `HARD MODE` capture shows 5 x 6 | high for those two modes | Difficulty changes board height; implement these two mappings once the model is revised |
| Both captures show a reset control and an `Undo` control with a rewarded-video badge | high for affordance existence | Provide reset and an honest local undo; ads/monetization are out of scope |
| Captures show values beyond 2048, scores such as `224,575P` and `156,600T`, and a current/all-time pair | high | 2048 is not a terminal win; tile/score representation and formatter must support long runs |
| Players in the linked thread describe keeping the same run for months and trying to reach still larger values | medium-high | Persist active board, current score, best score, difficulty and deterministic continuation state |

These observations falsify the current `result >= 2048 -> WON` behavior. They
do not by themselves define the exact loss condition, score arithmetic, refill
probability, or undo depth.

## Hypotheses and unresolved rules

The following are deliberately **not** original-fidelity claims:

- A chain begins with two equal values, then accepts a value equal to or double
  the immediately previous value. This is supported by historical local
  measurements, but its original evidence is not currently reproducible.
- A released chain sums its values and rounds upward to the next power of two.
  The current implementation keeps this as a compatibility decision; the
  official composite cannot validate it.
- Eight-neighbor movement is likely, but an actual input trace is still needed
  to freeze diagonal acceptance and corner behavior.
- Backtracking over the last selected node is unknown.
- Exact spawn/refill values, probability curves and any adaptation to the
  highest tile are unknown.
- `Medium = 7 rows` is plausible from the official image, and `Extra Hard = 5
  rows` is retained from prior notes; neither mapping is yet reproduced.
- The exact no-move/loss behavior and whether a reshuffle/recovery path exists
  are unknown.
- Undo depth, whether undo restores RNG state, and when an undo is offered are
  unknown.

Where a local compatibility choice is necessary, it must be named in code,
tests and the claim ledger. Unknowns must not be hidden behind a passing smoke
test.

## Current implementation gap

| Contract area | Current implementation | Stage 0 status | Required evidence/work |
|---|---|---|---|
| Identity and width | Dedicated 5-column Number Connect model | PASS | Keep separate from classic 2048 |
| Difficulty | `reset(rows)` accepts 5–8 but UI fixes one seed/height and exposes no modes | FAIL | Implement at least observed Easy 8 and Hard 6; label uncertain mappings |
| Path input | Eight-neighbor, equal first pair, then same/double; repeated nodes rejected | PARTIAL | Preserve as compatibility behavior until real action evidence; probe pointer/touch parity |
| Release/result | Sum then next-power-of-two, gravity, refill | UNKNOWN | Full deterministic transition probes; do not claim original rounding yet |
| Progression | `int` tiles and score | FAIL | Use a long-run-safe numeric representation and target-style compact formatting |
| Terminal behavior | Creating 2048 sets `WON`; no equal pair sets `OVER` | FAIL | Remove the false 2048 terminal; separately validate true loss/recovery |
| Persistence | Snapshot has no restore/versioned save/RNG recovery | FAIL | Persist board, score, all-time, moves, mode and continuation state |
| Undo | Absent | FAIL | Add a bounded, deterministic undo without reproducing ads |
| Restart | Model reset exists | PARTIAL | Confirm UI flow and best-score preservation; add recovery probes |
| Reduced effects | No explicit runtime route/evidence | FAIL | Add semantic reduced-effects behavior without changing model transitions |
| Existing GAG art | Real runtime derivatives and graded feedback exist in the isolated candidate | FROZEN | Reopen only after mechanics probes pass |

## Stage 1 entry gates

Before art production resumes, all of the following must be true:

1. A renderer-independent model probe covers every frozen rule, difficulty,
   long-run value, restart, undo, persistence round trip and terminal freeze or
   recovery state.
2. Integration probes prove pointer and touch share one action path and that a
   legal release creates exactly one authoritative transition.
3. Tests label compatibility choices separately from original facts.
4. The false 2048 win is removed and long-run state survives reload.
5. Reduced-effects mode preserves exact rule state and remains readable without
   camera shake, haptics or dense particles.
6. Existing GAG hashes and runtime bindings remain unchanged while mechanics
   are repaired.

Until these gates pass, the honest status is `mechanics FAIL / art candidate
frozen`, not “aligned with the original.”
