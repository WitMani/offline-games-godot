# Tile Club v2 — stitched keepsake workshop

Scope: only `tileclub`. The 7×7 source board, deterministic shuffle, tap hit
regions, source-tile removal, tray append order, three-equal removal, `+100`
score, move count, seven-slot loss and empty-board win remain frozen.

## Baseline and constraints

- Stable baseline: the workshop background already supplies a convincing world,
  but the 48 playable objects are flat colored squares whose single Chinese
  characters carry almost all identity.
- Weakest event: a triple disappears from the tray with generic rings and no
  material-specific action connecting three pieces.
- Runtime: Godot 4.6, 540×960 portrait Web/touch, bounded software fallback.
- Rights boundary: only repository assets and documented HOME-WSL GAG API
  deliveries may ship; no reference screenshots or source masters enter PCK.

## Experience pillars

1. **Every choice is a physical keepsake.** Tap intent → every ordinary board
   object has felt depth, piping, stitches and a bold appliqué silhouette → the
   untouched opening board is recognizable without title or event effects.
2. **The tray visibly tightens before failure.** Risk rises → five and six
   occupied slots progressively tension the tray and its real patches → players
   can read two spaces, one space and full without depending on color or copy.
3. **A triple feels sewn, not deleted.** Legal match → the three actual tray
   patches gather, thread cinches, a button-like seal lands and the board settles
   → the authoritative removal and next empty tray are readable in one arc.

## Art pillars

1. **Cocoa felt under cream thread:** dark cloth bodies, chunky piping, corner
   stitches, soft contact shadow and small edge highlights describe one material.
2. **Appliqué silhouette first:** leaf, moon, berry, star, flower, shell and
   crystal differ in outline and internal construction before palette.
3. **Warm workshop restraint:** berry/coral/teal accents sit inside the existing
   wood, thread, button and fabric world; the board stays denser than the quiet
   tray and result plaque.

## Anti-pillars

1. No flat rounded color squares or Chinese characters standing in for artwork.
2. No generic glass, neon, candy bloom or coin burst unrelated to felt and thread.
3. No confetti volume that hides tray count, source removal or the next choice.

## Fantasy and tone

- Player fantasy: sort a tabletop cabinet of handmade fabric badges and stitch
  matching keepsakes into a finished sampler.
- Tone: playful craft-club concentration with rising but never hostile tension.
- Style words: tactile, stitched, cheerful.
- Anti-words: plastic, synthetic, frantic.
- Signature motif: cocoa felt badge + cream piping + bold appliqué + thread seal.

## Visual and font grammar

- `tileclub_badge_atlas_gag_v1.png` supplies reviewed regions for leaf, moon,
  berry, star, flower and crystal. `tileclub_shell_badge_gag_v1.png` repairs the
  atlas shell cell that failed silhouette review.
- The two GAG families are visible on all 48 playable opening patches at a
  56×56 component size, then remain identifiable inside the tray and match
  ghosts. They are not victory-only decoration.
- Empty board cells use quiet thread-registration marks. Occupied tray slots
  render the same real patches at compact size.
- Dynamic Chinese labels use the bundled CJK UI role; numerals use the number
  role. Generated pixels contain no text or pseudo-glyphs.

## Semantic feedback grammar

| Importance | Truthful event | Object response | Supporting channels |
| --- | --- | --- | --- |
| routine | collect one patch | tapped GAG patch lifts and arcs to its exact tray destination | restrained click, short haptic |
| warning | tray reaches 5 | tray border tightens; occupied patches receive a low pulse | amber thread, grade-2 warning |
| critical warning | tray reaches 6 | stronger staggered slot kicks and tighter pulse | red thread, grade-3 warning haptic/audio |
| meaningful success | three equal patches | three actual tray patches gather and cinch at center before dissolving | generated felt/thread/button sound, grade-3 bounded shake |
| terminal failure | tray reaches 7 | all real slots counter-kick under a snapped-thread frame; no success seal | strongest warning haptic, failure plaque |
| terminal success | final triple / empty board | truthful triple gather expands into a wider stitched rosette and sampler plaque | pitched GAG cue, strongest bounded success shake/haptic |

The hierarchy follows real tray thresholds. It does not invent combo tiers.

## GAG and runtime boundary

HOME-WSL GAG ran in pure-API mode. Semantic search rejected a generic reward
badge, conquest/card UI, environment props, characters, music, magic, sword,
coin and fruit sounds. fal.ai generated a badge atlas; six regions passed review
and three regions were rejected as duplicates or an unreadable shell. A second
fal.ai generation repaired the shell. Remove.bg produced the transparent runtime
derivatives. ElevenLabs generated the felt-pop, thread-cinch and button reward
cue, then its loudness-only source warning was normalized for runtime.

Exact query results, prompts, provider/model data, hashes, selected/rejected
regions, derivations and runtime references are in
`tileclub-v2.gag-asset-ledger.json`. Only two PNG derivatives and one OGG ship.

## Acceptance and non-goals

- Capture matched stable, collect, risk-5, risk-6, triple, full-tray failure,
  terminal clear and result phases, plus continuous terminal success and failure.
- Gate frozen mechanics, exact GAG hashes/regions/audio routing, dynamic fonts,
  busiest effect frame time, all catalog regressions, clean archive Web, PCK
  boundary, browser action and exact Aliyun release.
- Non-goals: no tile blocking/stacking rule, hint AI, tray sorting, undo, score
  change, new match grade, Mahjong edit or shared-shell reskin.
