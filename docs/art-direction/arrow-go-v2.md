# Arrow GO v2 — midnight kite courier direction

Game / slice: Arrow GO only
Reference target: frozen in-repository mechanic; no comparative-original claim
Starting commit: `d2a7dd040c54f5f652a03cd6e189f554d2f392ff`
Runtime / platform: Godot 4.6 / Web / touch and keyboard
Viewport and device class: 540×960 portrait
Direction status: approved under the user's autonomous one-game-at-a-time catalog mandate
Prepared at: 2026-08-20

## Baseline and invariants

The 9×9 arrow field communicates the rule, but it reads as a prototype matrix:
81 nearly identical dark rectangles, tiny text-like arrow glyphs, a flat purple
triangle as the player and a generic `终` goal. The ordinary move adds detached
chevrons and rings but leaves little physical history in the board. Baseline
hashes:

- `baseline/stable.png`: `39bb477130a450069b8a8068cec8d9d488395c4511fe2c3fdd93c7004825295b`
- `baseline/step.png`: `cad464bf12494c5e66d28bf52bef980b97d6ce554e238a11d93cd8ff2abdaecb`

Frozen gameplay:

| Probe | Expected behavior |
| --- | --- |
| Entry | 9×9 grid; player `[0,0]`; target `[8,8]`; only start painted; score/moves/streak zero; status playing |
| Arrow field | columns 0–7 point right; column 8 points down in every row |
| Legal step | only the current cell's direction may advance; destination paints; score `+5`; moves/streak `+1` |
| Wrong direction | authoritative state remains unchanged and emits the existing reject event |
| Tap | only an adjacent cell delegates to the same directional rule; non-adjacent tap is inert |
| Goal | eight right plus eight down steps reach `[8,8]`; score `180`; moves/streak `16`; status won |
| Restart | restores the exact deterministic arrow field and entry state |

The grid, arrow values, input regions, score, counters, target, hint and terminal
rule do not change. The unused shared maze-wall payload also remains untouched.

## Experience pillars

1. **Read a wind machine, not a character grid.** Player intent → every cell is
   a tactile wind-vane plate whose live fin silhouette states the required
   direction → the legal next movement remains legible without reading labels.
2. **The courier leaves a journey behind.** Legal movement → the real kite
   courier follows the exact edge and lays a stitched airmail ribbon with knots
   at visited cells → opening, five-step and final boards differ after effects
   settle.
3. **Crosswind and harbor are opposite outcomes.** Wrong input → the acted-on
   vane clamps and the courier banks back with no state delta; final input → the
   courier enters a star harbor, route ribbon tightens and the flight is stamped
   complete → success and rejection cannot be confused by color alone.

## Art pillars

1. **Midnight kite-maker materials:** aubergine flight cloth, indigo enamel,
   ivory paper, warm brass studs and restrained coral ribbon form one crafted
   object world.
2. **Navigation by silhouette:** broad live vane fins, a compact paper-wing
   courier and a circular cloud-harbor rosette remain distinct at a 40-pixel
   gameplay size before hue or copy.
3. **Airmail route as settled evidence:** routine motion is quick and light;
   visited cells quiet, coral thread connects exact centers, and only five-step
   knots or terminal docking widen the response.

## Anti-pillars

1. No generic cyber-neon/glass grid or bloom standing in for crafted components.
2. No generated arrows, baked 9×9 board, letters, numbers, pseudo-glyphs or live
   gameplay copy inside pixels.
3. No confetti or undirected particle storm that obscures the current vane or
   makes a wrong-direction rejection look rewarding.

## Fantasy, tone and visual development

- Player fantasy: pilot a pocket paper-wing courier through a mechanical night
  wind chart and deliver it to a safe sky harbor.
- Emotional promise: brisk directional certainty with a warm handmade arrival.
- Style words: airborne, crafted, precise.
- Anti-words: holographic, noisy, weightless.
- Signature motif: indigo wind-vane plates + coral airmail ribbon + paper-wing
  courier and star harbor.

Internal alternatives:

| Direction | Strength | Reason rejected |
| --- | --- | --- |
| Midnight kite courier | binds arrow reading, movement history and goal into one physical system | selected |
| Toy train switching yard | strong path history | rails imply free junction choice that the mechanic does not offer |
| Neon data packet | obvious direction flow | repeats the generic glow/grid anti-pattern and lacks material warmth |

## North Star and hero event

Stable frame: the same deterministic 9×9 state. Every cell uses a GAG-derived
blank wind plate with a code-native directional fin; the GAG kite courier is at
`[0,0]`, the GAG harbor at `[8,8]`, and only the starting knot is tied. Active
frame: the courier banks along the required right/down edge while coral ribbon
draws under it. Result: the last down edge closes, the courier nests inside the
harbor rosette and a dedicated flight certificate appears.

Hero event: final legal down step into `[8,8]`; authoritative delta is player at
target, target painted, moves `+1`, score `+105`, streak `+1`, status won. Next
legal choice is restart.

| Beat | Object motion | Material / light | Audio / haptic / camera | State proof |
| --- | --- | --- | --- | --- |
| Intent | current vane compresses and courier banks toward it | ivory fin brightens | short cloth-wing click, tiny haptic | source remains visible |
| Anticipation | courier crosses the exact cell edge | coral thread pulls from previous knot | restrained air pass | model already committed the legal step |
| Impact | courier enters the harbor center | brass/star iris closes around real objects | generated dock stamp, grade-4 bounded shake/haptic | target painted; won; `+105` |
| Settle | final knot cinches and route remains | small secondary ribbon tails settle | short chime decay | certificate follows the local event window |

## Production system

- GAG pure-API route: semantic search → reuse or fal.ai generation → critique →
  repair → Remove.bg/crop → ledger → runtime; ElevenLabs for short feedback SFX.
- Required runtime visual family: one no-arrow blank wind plate repeated on the
  stable 81-cell board, one transparent paper-wing courier and one transparent
  star/cloud harbor. Live arrows, route, knots, copy and state remain code-native.
- First visible beats: wind plate on all 81 opening cells at roughly 44×44;
  courier at `[0,0]` around 42×42; harbor at `[8,8]` around 42×42. The courier
  also participates in every legal move, rejection and final docking.
- Semantic hooks: legal step, five-step waypoint, wrong-direction rejection,
  edge rejection and terminal arrival. No new rule grade or counter.
- Font contract: all CJK event/result copy uses the bundled UI/display subset;
  numerals use the number role; generated pixels contain no text.
- Performance: one repeated plate texture, two hero textures, bounded route and
  catalog envelopes; 120 stable and 180 grade-4 busy llvmpipe frames.
- Delivery: clean Git-archive import/export/PCK scan, fresh local browser action,
  fast-forward-only merge, GitHub push, atomic Aliyun release retaining the
  Amaze GO pack, then the same exact-online action.

Non-goals: no arrow generation change, route branching, shortest-path rewrite,
new score system, input delay, change to Amaze GO/Amaze, shared-shell reskin or
claim of surpassing an unavailable commercial reference.
