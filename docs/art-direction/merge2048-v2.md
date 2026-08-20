# 2048 · crafted atelier direction v2

## Decision and invariants

```text
Game / slice: classic 2048 board, live tiles, and graded move feedback
Starting commit: dae205d
Runtime / viewport: Godot 4.6 Web, 540 × 960 portrait
Direction status: production candidate under the catalog cartoon-art skill
Mechanics invariant: four-direction compression, one-merge-per-pair ordering,
random 2/4 spawn, scoring, 2048 victory, no-move loss, restart, and input routing
remain authoritative in main.gd
```

The prior pass already had an illustrated workshop background, but the pieces
the player actually touches were still generic code-drawn rectangles. This
slice makes every live number sit on a visible GAG-produced crafted object and
uses a GAG wood-shaving burst at the exact authoritative merge destination.

## Pillars and anti-pillars

| Pillar | Production rule | Runtime proof |
|---|---|---|
| A tile worth keeping | values progress through coherent birch, amber lacquer, blue enamel, and purple masterwork materials | stable family frame `00` contains all four tiers with live numbers |
| The board remembers direction | rule output includes source-to-destination mappings; intent, compression, travel, impact, and settle follow those mappings | routine sequence `10`–`13` |
| Mastery makes shavings fly | grade 2 adds a firm pop, grade 3 adds reward audio and promoted motion, grade 4 reveals the GAG wood-shaving crown with the strongest bounded shake | grade captures `20`, `30`, and `40`–`43` |

Reject: another background-only pass; sci-fi rune VFX in a hand-crafted wood
workshop; generated numbers baked into textures; maximal shake on every move;
presentation code recomputing a merge or inventing a destination.

Player fantasy: slide a set of tactile artisan plaques across a dark workbench
until ordinary birch becomes a master-carved heirloom. Tone: warm, crafted,
quiet on routine moves, concise and rewarding on difficult merges.

## Art Bible

- Shape: square plaques retain the instant scanability of 2048, but their
  bevels, corner fasteners, enamel insets, and notches make them physical toys.
- Material: tier 1 is pale birch, tier 2 amber lacquer, tier 3 blue enamel over
  dark wood, and tier 4 purple enamel with a gold rim. Empty wells stay low
  contrast so live tiles own the silhouette hierarchy.
- Palette roles: honey wood frames the playfield; cyan is reserved for routine
  directional feedback; gold marks difficult crafting; red/pink marks blocked
  movement. The generated material never owns live semantic color alone.
- Type roles: all values use the bundled numeric font; CJK instructions and
  feedback use the bundled CJK role. No text or number is baked into generated
  imagery.
- Progression: the material tier changes at 8, 64, and 512. Code-native notch
  count preserves value progression inside a tier without asking image models
  to render mutable numbers.
- Motion: a legal move compresses briefly, travels along the real direction,
  impacts at the real destination, rebounds, and settles. The spawned plaque
  appears only after the move result has become readable.

## Feedback grammar

| Meaning | Object / world response | Audio / haptic / camera | Settled consequence |
|---|---|---|---|
| Blocked direction | local text-free zigzag toward the attempted edge; persistent toast carries the explanation | reject click and short separated haptic; no state mutation | full board and move count remain unchanged |
| Legal slide, grade 1 | source plaques compress, travel, then settle; new plaque pops in late | GAG wooden slide, 6 ms haptic, no camera shake | authoritative destination and spawn remain visible |
| Merge worth 8+, grade 2 | result plaque gets a stronger non-uniform pop and ring | GAG slide + warm wood clack, three-beat haptic, small bounded shake | result value is the focal tile |
| Merge worth 32+, grade 3 | promoted rebound and gold callout | clack + GAG milestone layer, promoted haptic and shake | higher material is readable after the envelope |
| Merge worth 128+ or target, grade 4 | GAG wood-shaving crown blooms behind the exact result, then clears | layered reward, five-beat haptic, strongest bounded shake | board is fully legible again before control continues |

`_slide_line()` remains the rule resolver. It now also returns presentation-only
source mappings derived during that same authoritative calculation. The
presenter consumes those mappings and never mutates board, score, moves, spawn,
or terminal status.

## GAG production record

Semantic image search ran first on the HOME-WSL GAG HTTP MCP. The strongest
legacy 2048 burst candidate was a teal/orange sci-fi rune sheet (score about
0.429); a generic pink/yellow reward burst was also inspected. Both were
rejected because they contradicted the locked crafted-atelier pillars. A fresh
coherent four-tile family and hollow wood-shaving crown were generated through
GAG's fal.ai API path. GAG then handled manual crops, Remove.bg, auto-trim, and
archive provenance. Three sound families were generated through GAG's
ElevenLabs API path. No local GPU model was required.

Full providers, prompts or prompt summaries, source and derivative hashes,
archive paths, search rejections, and runtime references are recorded in
[`merge2048-v2.asset-ledger.json`](merge2048-v2.asset-ledger.json).

## Runtime evidence and gates

- `tools/merge2048_presentation_smoke.gd`: runtime assets, material tiers,
  unchanged line resolution, source mappings, legal slide, rejection invariant,
  grades 2–4, and target promotion.
- `tools/merge2048_visual_audit.gd`: stable family; routine intent, travel,
  impact, and settle; grade boundaries; 24 pinned grade-4 frames; rejection;
  and semantic snapshot.
- `tools/merge2048_performance_audit.gd`: empty-board baseline, full material
  board, and 180-frame busy trace with six bounded catalog envelopes plus one
  GAG wood-shaving burst. Xvfb/llvmpipe records 17.41 ms average and 21.88 ms
  P95 in the busy phase; this is comparative evidence, not a device FPS claim.
- Existing catalog event, mechanics, contrast, font, all-game, and clean Web
  export suites remain release gates.

Claim target: art strengthening + expressive strengthening. User-visible
deployment and hands-on review decide whether it has exceeded the original;
generated files alone are never accepted as proof.
