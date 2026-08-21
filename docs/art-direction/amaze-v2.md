# Amaze v2 — rolling paint workshop direction

- Game / slice: Classic Amaze only
- Reference target: CrazyLabs AMAZE!!! Classic movement/paint/completion contract
- Starting commit: `96bcf5170e1fd916aa1e78927d14534ecbd20c58`
- Runtime / platform: Godot 4.6 / portrait Web, touch, pointer and keyboard
- Viewport: 540×960
- Direction status: approved under the catalog's existing autonomous art mandate
- Prepared at: 2026-08-20

## Baseline and invariants

Stage 0 is frozen by [amaze-gag-v2-stage0.md](amaze-gag-v2-stage0.md).
Official first-party evidence supports a cardinal gesture, travel across every
cell in one straight corridor, a stop on the last playable cell before void or
edge, ordered painting during travel, and completion after every playable cell
is filled. `models/amaze_model.gd` remains authoritative. Art callbacks never
compute topology, legal stops, paint order, revisit, completion, score or level
progression.

The Stage 0 stable frame was readable but prototype-like: flat dark cells,
generic circles, five unrelated paint hues, little material contact, and event
feedback mostly detached from the moving object. Its matched baseline is
`docs/audit/amaze-gag-v2/stage0-candidate/00-topology-stable.webp`.

Frozen probes:

| Contract | Evidence |
| --- | --- |
| Three deterministic connected topologies and exact legal stops | `tools/amaze_model_smoke.gd` |
| Ordered traversal, painting, revisit and all-walkable completion | `tools/amaze_model_smoke.gd` |
| Keyboard, mouse and touch parity; tap inert | `tools/amaze_integration_smoke.gd` |
| Blocked, short, long, revisit, near-complete and complete semantics | `tools/amaze_action_smoke.gd` |
| Restart current maze and explicit next-maze progression | model and integration probes |

## Pillars

### Experience pillars

1. **Paint a physical path, not a grid.** Intent → every cell is a raised canvas
   pad and every committed traversal becomes one connected wet ribbon → at the
   same model state, unpainted topology, painted topology and the next choice are
   readable with the title and HUD hidden.
2. **The pod owns the gesture.** Input → the GAG paint pod compresses, rolls
   through the exact ordered cells, deposits paint, meets the stopping surface
   and settles → matched intent, anticipation, impact and settle captures keep
   the changed object at the center of the response.
3. **Coverage earns contrast.** Progress → revisit stays quiet, a long fresh
   corridor becomes stronger, one-cell-remaining promotes the workshop response,
   and completion seals the canvas → semantic grades 1–4 are distinguishable
   through object motion, ribbon extent, local paint response, haptic cadence,
   sound treatment and bounded camera response rather than label or hue alone.

### Art pillars

1. **Canvas, enamel and wet paint.** Contact shadow → cream porous pad → warm
   edge → wet colored body → pearly highlight is the required construction for
   the board and hero; the stable frame remains crafted with effects disabled.
2. **One rolling paint pod, one ribbon family.** The round plum/coral/mint pod is
   always visible and the current maze uses one controlled paint family with
   slight order variation; unrelated rainbow blobs and generic neon are rejected.
3. **Workshop framing, quiet center.** Plum workbench grooves, edge palette arcs
   and tiny paint dabs frame a high-value cream board; generated art never bakes
   maze cells, text, progress, buttons or fake state.

### Anti-pillars

1. No generic neon grid, bloom-only polish or five-color confetti on routine
   movement.
2. No full-screen generated mockup, generated copy, baked topology, face/mascot
   mechanics or pseudo-UI.
3. No constant maximum shake, dense splashes over unpainted cells, duplicated
   toast/local labels or presentation callbacks that delay or recompute rules.

## Fantasy, tone and visual development

- Player fantasy: roll a refillable pocket paint pod through a miniature canvas
  workshop and seal a perfectly saturated path.
- Emotional promise: immediate tactile flow, followed by a clean crafted settle.
- Tone: cheerful studio confidence with wet, weighty contact—not frantic slime.
- Style words: tactile, saturated, crafted.
- Anti-words: neon, weightless, noisy.
- Signature motif: GAG coral-on-plum paint pod plus connected pearly wet ribbon.
- Shared shell relationship: suite navigation stays common; the workshop board,
  hero material and motion grammar remain Amaze-specific.

Internal alternatives:

| Direction | Strength | Decision |
| --- | --- | --- |
| Rolling paint workshop | makes motion, state and material one system | selected |
| Neon fluid laboratory | easy glow hierarchy | rejected: catalog anti-neon and weak contact craft |
| Paper-cut maze | clean silhouettes | rejected: travel would not visibly deposit a wet material |

The official reference contributes only observable interaction and comparative
baseline. No private screenshot/video is committed and no reference pixel is
used as a generation input. The candidate deliberately keeps the reference's
simple top-down legibility while replacing its plain ball/flat path with an
original workshop hero and material stack.

## North Star and hero event

- Stable: `candidate/00-stable-gag-visible.webp` shows the GAG pod on the first
  painted pad, a complete readable topology and quiet workshop framing.
- Routine action: `candidate/02-roll-intent.webp` through
  `candidate/05-roll-settle.webp` are matched samples of the same four-cell
  ordered movement.
- Peak: `candidate/08-complete-impact.webp` and
  `candidate/09-complete-result.webp` retain the actual final cell and resulting
  solved board before/behind the result canvas.
- Continuous proof: `candidate/continuous-long-roll.webm` and its JSON timeline.

Hero event: final legal corridor command. The model first commits ordered
traversal, final player position, the last newly painted cell, `remaining = 0`,
score, move count and `status = won`. Presentation then renders:

| Beat | Object / paint | World, audio and haptic | State proof |
| --- | --- | --- | --- |
| Intent | pod compresses toward the command | restrained start contact | model outcome already exists |
| Anticipation | pod stretches along the exact straight route; cells reveal in recorded order | repeated GAG wet-roll cue and short cadence | `traversed` / `newly_painted` order |
| Impact | pod reaches the legal stop; local bristles, droplets, ring and grade-4 diamonds align there | strongest bounded shake and haptic; no global obstruction | final player cell and `remaining = 0` |
| Settle | pod rebounds, ribbon highlight stabilizes, then the result canvas shows the same pod | generated cue decays; control exposes “下一迷宫” | solved board remains visible behind the plaque |

## Art Bible and feedback grammar

- Shape: 13–21 px rounded frame corners; structured rounded-square canvas pads;
  one near-circular hero. Voids stay open, not decorated as cells.
- Palette: deep plum workbench `#28192d`, cream canvas `#eadbc8`, coral paint
  `#ff739e`, cyan secondary `#4ed8cf`, restrained completion gold. A level may
  select one paint family; state never relies on color alone.
- Material: every hero object requires contact, body, edge and highlight. Wet
  paint adds one pearly arc and small controlled bead; no bloom requirement.
- Type: live CJK and dynamic event copy use bundled Noto Sans CJK UI/display;
  counters use the numeral role. Generated pixels contain no copy.
- Motion: 0.18–0.54 s route travel based on crossed-cell count, planar rather
  than airborne; 13% maximum directional stretch; object rebound finishes
  inside the semantic event window.
- Intensity: blocked/revisit/short are grade 1; long fresh corridor grade 2;
  one/two cells remaining grade 3; completion grade 4. The labels describe
  outcomes but are not the only difference. Routine motion has no camera shake.
- Accessibility: the changed occupancy, connected ribbon extent, object position
  and final result remain readable without sound, vibration or color nuance.
- Runtime budget: one 324×354 RGBA texture, one 0.449 s mono OGG, 12 bounded
  catalog effects, no per-frame image/stream creation. llvmpipe stable/busy trace
  is recorded in `candidate/performance.json` and is not a device-FPS claim.

## GAG production and shipping boundary

The exact HOME-WSL HTTP MCP was checked first: GAG `1.29.0`, 21 tools, no local
GPU/main-service PyTorch, and healthy Gemini, fal.ai, OpenRouter, ElevenLabs and
Remove.bg API providers. Semantic image/audio search ran before generation.
Existing fruit juice, characters, generic VFX and music/confirmation sounds were
rejected as incompatible.

The selected frequent visual was generated through GAG's fal.ai pure-API route,
reviewed at source and intended runtime size, repaired through GAG Remove.bg and
auto-trim, then bound to the stable player, travel and result plaque. The first
fal candidate was rejected because its cream orbital band read as an ornament
rather than wet paint. The selected frequent audio was generated through GAG's
ElevenLabs route. Variation 1 was chosen objectively for its 0.449 s duration and
headroom; variation 2 was only 0.256 s with a `-1.03 dBTP` report. The low
loudness warning is retained; no subjective listening claim is made.

Full prompts, search scores, provider/model routes, source/intermediate/runtime
hashes, objective audio QA and live references are in
[amaze-v2.gag-asset-ledger.json](amaze-v2.gag-asset-ledger.json). Source masters,
rejected generations, private official evidence, signed URLs and credentials do
not ship.

## Scope and claim

This slice targets art strengthening and expressive strengthening while the
Stage 0 mechanic contract remains green. “Surpasses the reference” remains a
final matched-review claim, not an automatic consequence of generation. Other
commercial modes, hundreds of original levels, exact score/timing parity,
deployment, merge and public release are outside this isolated candidate.
