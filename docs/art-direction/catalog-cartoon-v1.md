# Offline Games cartoon direction package v1

## Decision header

```text
Game / slice: Offline Games catalog art strengthening, excluding the already strengthened 2248 and snake routes
Reference target: frozen existing mechanics; game-specific cartoon expression beyond the pre-slice dark shell
Starting commit: 887a0dd
Runtime / platform: Godot 4.6, Web / desktop
Viewport and device class: 540 × 960 portrait, touch and pointer
Direction status: approved-by-command
Prepared at: 2026-08-20
```

## Baseline and invariants

The stable baseline is [baseline-stable-contact.webp](../audit/catalog-art-v1/baseline-stable-contact.webp). The 2248 candy workshop, GB Snake handheld, and Snakes arena were already distinctive; the other eleven games largely shared a dark, flat suite shell. Their mechanics were readable, but material, world fantasy, and action consequence were weak.

| Probe | Frozen behavior | Evidence |
|---|---|---|
| Entry | all 14 cartridges open and reset | `tools/smoke.gd` |
| Core input | existing tap, swipe, direction, and button routes | `tools/rules_smoke.gd` |
| State change | presentation consumes authoritative state; it never recomputes rules | `tools/catalog_art_smoke.gd` |
| Result / failure | existing win, full-tray, no-move, collision, and invalid-input conditions | rule and game-specific smoke suites |
| Recovery | home and restart remain available | `tools/smoke.gd` |

Constraints: portrait Web first; compact package; generated art may frame play but may not bake playable UI, text, tiles, or state; Chinese and mixed-script runtime copy must render from bundled font roles; generated assets require provenance.

## Pillars

### Experience pillars

| Pillar | Player intent | Production consequence | Observable proof |
|---|---|---|---|
| Read the move | understand the changed object without relying on a toast | feedback originates at the acted-on tile, card, fruit, or path cell | candidate event contact sheet and semantic event smoke |
| Feel the craft | each game should feel like a small physical toy world | world, material, motif, and motion are selected per mechanic | the playfield remains identifiable with its title hidden |
| Earn the peak | rare or difficult outcomes must feel stronger than routine input | restrained routine feedback; promoted shape, duration, haptic, sound, and camera only at higher importance | grade 1–4 event assertions |

### Art pillars

| Pillar | Shape / material / motion rule | Observable proof |
|---|---|---|
| Tactile cartoon materials | rounded but structured silhouettes, contact shadows, edge light, and one legible material per game | wood, fruit, paper, felt, jade, fabric, blueprint, signal light, and paint do not collapse into one skin |
| Authored edge world | environmental props frame a quiet central play zone; generated images contain no UI or text | seven runtime background plates plus four procedural worlds |
| Metaphor-bound motion | particles and object motion borrow from the world: juice and leaves, paw stamp, suits, jade rings, stitches, compass, arrows, paint | `CatalogArtDirector` dispatches by semantic game event |

### Anti-pillars

| Reject | Why it conflicts | Concrete counterexample |
|---|---|---|
| Generic neon reskin | erases game identity | one blue glow particle system reused for cards, fruit, and mahjong |
| Baked fake gameplay | can contradict authoritative state and input | AI-generated board, cards, labels, score, or buttons inside a background |
| Constant maximum juice | destroys contrast and comfort | full shake, vibration, and confetti on every routine tap |

## Fantasy, tone, and game signatures

Tone: a shelf of warmly crafted pocket games, each with its own miniature world, sharing navigation but not visual identity.

| Game | World metaphor and signature motif | Routine response | Promoted / hero response |
|---|---|---|---|
| 2048 | carved number atelier; brass pips | tile travel and small wood ring | multi-merge brass resonance, stronger value carving, graded shake |
| 2048 Balls | orchard packing crate; leaves | fruit lands with droplets | cascade merge sprays juice and leaves; watermelon result reaches grade 4 |
| Meowdoku | cat stationery desk; binding rings and paw | soft paw confirmation | completed block receives a larger paw stamp; mistakes tear a pink zigzag |
| Sudoku | architect's logic folio; compass marks | ink compass confirmation | completed block expands the logic compass; mistakes use red correction strokes |
| Solitaire | emerald conservatory card table | card travel and suit motes | foundation milestone releases suit confetti and tactile haptic cadence |
| TriPeaks | twilight mountain stage | quiet card take | streaks promote from a small suit response to a gold grade-4 peak |
| Vita Mahjong | jade teahouse; raised ivory tile | selected tile physically lifts | pair emits jade resonance rings; final pair promotes to grade 4 |
| Tile Club | fabric craft table; corner stitches | patch travels into the tray | triple match stitches a full ring; clear promotes to grade 4 |
| Amaze GO | cartographer blueprint; brass compass | one cell illuminates | milestone compass expansion and grade-4 goal lock |
| Arrow GO | violet signal garden; chevrons | local arrow propulsion | five-step rhythm promotes; goal becomes a grade-4 signal burst |
| Amaze | paint workshop; wet splats | paint spreads from the moved ball | coverage milestones splatter wider; full coverage promotes to grade 4 |
| GB Snake | retained production handheld direction | existing LCD movement | existing eat, crash, and terminal grammar |
| Snakes | retained production arena direction | existing arena motion | existing eat, near-miss, crash, and leaderboard grammar |

Style words: tactile, cheerful, authored. Anti-words: generic, noisy, photoreal.

## References and generated assets

The generated plates are environmental intent only; live boards, cards, text, buttons, feedback, and state remain runtime layers. GAG semantic search was attempted for number-game, fruit, logic, cards, mahjong/tile, and maze motifs, but the service reported a missing Gemini provider key. The built-in image generation path produced fresh fallback plates; no third-party game artwork was copied.

| Runtime asset | Borrow conceptually | Reject | Provenance |
|---|---|---|---|
| `merge2048_atelier_v1.webp` | carved wood desk and brass craft tools | board, numerals, labels | generated for this project |
| `watermelon_orchard_v1.webp` | sunny orchard crate edges | playable fruit or bins | generated for this project |
| `meowdoku_stationery_v1.webp` | paper, ribbons, cat stationery props | sudoku grid or text | generated for this project |
| `solitaire_conservatory_v1.webp` | emerald felt and conservatory decor | cards or suit UI | generated for this project |
| `mahjong_teahouse_v1.webp` | bamboo, jade, warm teahouse frame | mahjong tiles or glyphs | generated for this project |
| `tileclub_craft_v1.webp` | felt, thread, buttons, fabric edges | puzzle tiles or tray | generated for this project |
| `amaze_blueprint_v1.webp` | navy blueprint desk and brass tools | maze lines, player, or target | generated for this project |

Detailed prompts, source delivery IDs, hashes, and runtime references are in [catalog-cartoon-v1.asset-ledger.json](catalog-cartoon-v1.asset-ledger.json).

## Recommended direction and North Stars

Visual thesis: turn each faithful small game into a tactile cartoon object whose material world explains its feedback.

The candidate stable comparison is [candidate-stable-contact.webp](../audit/catalog-art-v1/candidate-stable-contact.webp), the matched routine event set is [candidate-event-contact.webp](../audit/catalog-art-v1/candidate-event-contact.webp), and the promoted-event set is [candidate-peak-contact.webp](../audit/catalog-art-v1/candidate-peak-contact.webp). Order is catalog order, left-to-right and top-to-bottom. These sheets are review evidence, not runtime assets.

What remains: all mechanics, shared home cartridge system, navigation, score contract, capture/logging, and portrait control layout. Non-goals: replacing the authoritative rule models, reproducing copyrighted source assets, or hiding low-fidelity mechanics behind generated screens.

## Hero-event grammar

```text
Trigger: authoritative game event emitted after its state delta
Authoritative state delta: already committed by the game function
Next legal choice: immediately available after the short presentation settles
```

| Beat | Object motion | VFX / light | Audio / haptic / camera | State evidence |
|---|---|---|---|---|
| Intent | touched object responds immediately | tiny local highlight | key sound or short haptic | selected or moved object |
| Anticipation | travel, lift, or gathering follows mechanic | world-specific motif begins locally | no camera on routine grade | pending destination remains readable |
| Impact | result lands at the changed cell / slot | motif expands by semantic importance | promoted sound, patterned haptic, grade 2–4 shake | score, merge, match, streak, or completion already authoritative |
| Settle | particles and labels clear in under about one second | final ring or trail fades | control returns continuously | resulting board and next choice are unobscured |

Grades are a shared importance vocabulary, not a rigid effect recipe. Grade 1 is routine and does not shake; grade 2 is a meaningful local success or rejection; grade 3 is a milestone or strong streak; grade 4 is cascade, rare peak, or completion. Each game chooses metaphor-appropriate channels.

## Production system

- Shape / material: runtime vector geometry owns interactive objects; generated raster plates own quiet environmental framing.
- Palette / value: game-specific dark header and score materials sit above brighter play objects; state is never communicated by hue alone.
- Type roles: Noto Sans CJK subset for UI/display and dynamic Chinese labels, Roboto Medium for 2048 tile numerals, DejaVu Sans for general numerals, Unifont for card suits and symbols.
- Font gate: `tools/build_cjk_font_subset.py --check` proves the rebuilt subset; `tools/font_coverage_smoke.gd` probes 51 real-copy cases against their assigned roles, including animated labels.
- Runtime ownership: game functions emit semantic catalog events only after rule mutation; `presentation/catalog_art_director.gd` owns rendering, shake, and world grammar.
- Asset size: source PNGs remain outside the game; runtime plates are 540 × 960 WebP. The full rebuild font is under `.gdignore` and excluded from Web export.
- Reduced channel fallback: every event remains understandable from changed object state plus local shape/motion if audio, vibration, or camera is unavailable.
- Busy-event trace: [busy-event-performance.json](../audit/catalog-art-v1/busy-event-performance.json) records 180 Xvfb/llvmpipe frames with the 12-effect cap; it is a regression trace, not a physical-device FPS claim.
- Web acceptance: [web-acceptance.json](../audit/catalog-art-v1/web-acceptance.json) records the fingerprinted Aliyun release hashes and exact-artifact boot; [web-dynamic-font.png](../audit/catalog-art-v1/web-dynamic-font.png) proves the live animated CJK label path.

## Feasibility and approval

Largest production risk: eleven games could drift into a single reusable effect skin. Mitigation: explicit per-game metaphor dispatch and a stable-frame identity check. Largest runtime risk: generated/animated Chinese labels could bind the wrong font or omit a newly introduced glyph. Mitigation: role-aware coverage gates plus clean Web verification.

```text
Approved by: project owner via direct execution instruction
Approved at: 2026-08-20
Approved scope: apply the conservative cartoon-art skill to all remaining Offline Games
Approved exceptions: preserve the established 2248, GB Snake, and Snakes directions while regression-testing them
Direction commit: the repository commit containing this direction package
```
