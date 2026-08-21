# 2248 · candy workshop GAG material pass v3

## Decision and frozen baseline

```text
Game / slice: 2248 stable tokens and graded connection release
Starting commit: d9ee2dcbbec523b66169b40140de352cf2b5f213
Runtime / viewport: Godot 4.6 Web, 540 × 960 portrait
Direction status: isolated production candidate; not merged or deployed while GB Snake is the current review game
Mechanics model: models/merge2248_model.gd
Frozen model SHA-256: 60123a003f66803247040927f4438343b75bd76a1cbbd3df01908d31bbd78d18
```

The approved candy-workshop direction remains intact. The tray, workbench,
cream ribbon, live type and four semantic feedback grades already communicate a
coherent game, but the objects touched on every move were still code-drawn flat
shapes. This pass puts GAG material on all 40 ordinary board slots and reserves a
second generated material event for difficult merges. It does not re-theme the
game, recompute a path, change a score, or bake a mutable number into an image.

The authoritative model smoke remains `10 PASS`; the integration smoke remains
`10 PASS`. Eight-direction adjacency, same-value start, same-or-double path
extension, release calculation, gravity/refill, score, move count, win/loss,
restart and input routing are invariants.

## Preserved pillars

| Pillar | Conservative production rule | Observable proof |
|---|---|---|
| Tactile number candy | every live number sits on one of four coherent GAG confection molds; numerals remain code-native | the stable 540×960 frame shows generated material repeatedly on the actual board, not only on a cover or reward screen |
| Progression has shape | 2, 4, 8 and 16+ retain distinct silhouettes, while live values and the existing tier details continue to carry exact progression | the tier gallery proves silhouette + numeral rather than hue alone |
| Warm workshop, quiet tray | cream, cocoa, pink and caramel stay inside the existing wood/felt workshop; routine play remains quieter than mastery | stable play has no generic neon bloom; grade 3/4 alone reveal the caramel-cream ring |

Anti-pillars remain: generic sci-fi VFX, unrelated asset soup, generated text or
numbers, background-only decoration, a win-only signature asset, maximum shake
on routine merges, and presentation code inventing gameplay truth.

Player fantasy: pull a ribbon through a tray of small confection molds, combine
them into a more elaborate recipe, and earn a brief pastry-showpiece response
when the chain is genuinely difficult. Tone: warm, tactile, playful and concise.

## Art bible delta

- Shape: the stable family is wrapped cream candy, round tart candy, cocoa-rim
  lozenge and flower bonbon. The generated atlas delivered five petals rather
  than the requested six and a tart-like second mold; those deviations are
  recorded and accepted because the four silhouettes remain clean and distinct
  at runtime size.
- Material: frosting highlight, cocoa rim, caramel depth and candy-paper folds
  replace flat fills. The existing code-native shape remains a thin
  value-colored structural backplate, so semantic color is not delegated to AI.
- Type: `NUMBER_FONT` owns every value. `DISPLAY_FONT` owns live Chinese grade
  labels. Generated images contain no text, numeral or pseudo-glyph.
- VFX: the generated hollow caramel/frosting wreath blooms behind the exact
  authoritative destination at grades 3 and 4, leaving the result number in the
  open center. Existing rings, crumbs, token squash and callout remain bounded
  supporting layers rather than competing centers.
- Audio: every legal release uses the short generated candy merge. Grades 3 and
  4 add a distinct generated recipe-mastery layer. Source loudness warnings are
  retained; runtime OGG derivatives use deterministic gain and limiting.
- Accessibility: value remains readable by live numeral and silhouette without
  relying on color, generated audio or haptics. The settled board is visible
  before control continues.

## Feedback grammar

| Meaning | Object / world arc | Audio / haptic / camera | Settled consequence |
|---|---|---|---|
| accepted node | selected GAG candy lifts, compresses and joins the live cream ribbon | restrained existing tick, 9–13 ms haptic, no world shake | exact selected path remains readable |
| grade 1, two-node release | source candies gather into the authoritative destination; result overshoots once | GAG candy merge, 20 ms haptic, sub-pixel board response | live result, score and refill settle visibly |
| grade 2, short chain | wider ribbon cadence, larger non-uniform result pop and promoted callout | pitched GAG merge, three-beat haptic, bounded shake | chain grade and gained score persist long enough to read |
| grade 3, super chain | generated hollow pastry wreath appears behind the result, with promoted crumbs/rings | merge + GAG mastery layer, stronger pattern and shake | result remains centered in the hollow generated asset |
| grade 4, legendary recipe | largest bounded wreath/recoil and longest five-beat response | two generated audio layers, five-beat haptic, strongest bounded camera response | board, exact result, move and score return to a stable legible state |

The form is deliberately not a rigid visual template: intensity is expressed by
the mechanics-relevant object, the exact destination, material reveal, audio,
haptic cadence, camera response and settled consequence. Another game may use a
different combination while preserving the semantic hierarchy.

## Real GAG production

The directly registered EC2 GAG instance was inspected and rejected because it
exposed only a mock image provider. Production used the healthy HOME-WSL
streamable-HTTP service at
`https://desktop-youyuan-wsl.tail17a64.ts.net:11443/mcp` in pure-API mode. The
main service reports no GPU and no PyTorch; this pass used Gemini embeddings for
search, fal.ai Flux Pro for images, Remove.bg for alpha extraction and
ElevenLabs for sound.

Three semantic searches ran before generation. Existing fabric badges, medals,
pink reward bursts, conquest VFX, the 2048 Balls juice burst, long music and
generic magic/coin/accept/warning cues were inspected and rejected for the wrong
material, role or game identity. Exact scores, hashes, prompts, provider/model,
source warnings, derivation steps and runtime bindings are in
[`merge2248-gag-v3.asset-ledger.json`](merge2248-gag-v3.asset-ledger.json).

Source masters and rejected candidates remain in the HOME-WSL GAG archive. The
repository contains only five bounded transparent PNG derivatives and two OGG
runtime files. No generated gameplay text, source JPEG/WAV or rejected candidate
ships.

## Acceptance boundary

Matched evidence is under `docs/audit/merge2248-gag-v3/`. It includes stable
before/after contact, tier gallery, intention, anticipation/preview, impact,
settle, state snapshots, ordinary and grade-4 continuous clips and comparative
llvmpipe traces. The immediate pre-GAG busy trace was 23.352 ms average / 27.698
ms p95; the candidate is 23.867 ms average / 28.138 ms p95. These are software
renderer regression guards, not physical-device FPS claims.

This branch may be fully tested, committed and kept ready. Under the user's
one-game-at-a-time instruction it must not be merged, pushed as `main`, exported
as the public release or deployed over GB Snake until the current review boundary
moves to 2248.
