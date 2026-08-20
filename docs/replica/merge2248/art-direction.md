# Merge 2248 cartoon art direction

## Decision header

- Game / slice: `merge2248` stable board, drag chain, merge, refill settle
- Reference target: Offline Games 3.14.1 / `83_2248`
- Starting commit: `370a98572d2f7e258d4090ee73112b0810372609`
- Runtime / platform: Godot 4.6, portrait Web, 540×960 design viewport
- Direction status: approved pilot
- Approval basis: user requested direct execution through
  `direct-cartoon-game-art` and a playable result on 2026-08-20

## Baseline and invariants

The clean-room Number Connect mechanic already has a 5×8 board, continuous
eight-direction path selection, reference-backed path rules, power-of-two merge,
gravity/refill, 2048 win, no-move loss, restart, and separate 2048 behavior.

Frozen probes:

| Probe | Expected behavior | Evidence |
|---|---|---|
| Entry | 5×8 dense board; only Home/Restart controls | `tools/merge2248_integration_smoke.gd` |
| Core input | equal pair first; later equal or doubled; eight directions | `tools/merge2248_model_smoke.gd` |
| State change | one release increments score/moves once and refills | integration smoke |
| Result | 2048 wins; no equal adjacent pair loses | model smoke |
| Catalog | all 14 games still enter and accept one action | `tools/smoke.gd` |

Baseline art uses one circular silhouette for every value, a generic dark glass
board, a bright line, and a short post-merge particle burst. The background is
authored, but the interactive components still read as placeholders.

## Pillars

### Experience pillars

| Pillar | Intent → rule | Observable proof |
|---|---|---|
| Touch the candy | Every touched token deforms and lifts immediately | First selected token changes scale, rim, shadow, and posture |
| Pull a recipe | The path behaves like elastic cream syrup carrying energy | Ribbon has thickness, rounded joints, moving pulse, and connected-token lean |
| Feel the merge | Merge becomes gather → impact → fall → settle | Consumed tokens travel to the result; result pops; the new board lands in stagger |

### Art pillars

| Pillar | Production rule | Observable proof |
|---|---|---|
| Tactile number candy | Build each token from contact shadow, body, inset face, edge, highlight, and live numeral | Frame remains crafted with particles disabled |
| Progression has shape | Preserve the measured value palette but add wrapper, inset, star/flower, and milestone silhouettes | 2, 4, 8, 16+ remain distinguishable in grayscale |
| Warm workshop, quiet tray | Use honey wood, cream edging, and deep-teal cloth; keep the playfield dominant | Background frames the tray without competing with the current path |

### Anti-pillars

| Reject | Reason |
|---|---|
| Neon energy vault / generic glass | It erases the physical candy metaphor |
| Same circle with different hue | It cannot communicate progression or authored craft |
| Particle-only polish | It leaves the base frame and state changes weak |

## Fantasy and tone

- Player fantasy: connect and combine number candies on a small confectioner's
  workbench.
- Emotional promise: calm tactile play with a satisfying burst of reward.
- Style words: plump, handcrafted, buoyant.
- Anti-words: cyber, glassy, noisy.
- Signature motif: an elastic cream syrup ribbon carrying a colored pulse.
- Shared shell relationship: keep Home/Restart and collection state stable, but
  let the tray own the playfield.

## Visual development and recommendation

Internally considered:

| Direction | Strength | Reason rejected |
|---|---|---|
| Candy workshop | Direct physical metaphor for linking and merging | Selected |
| Jelly creatures | Highest character ceiling | Requires a larger character/animation scope than this pilot |
| Paper toys | Cheap, legible, Web-friendly | Merge impact has less material drama |

The selected North Star is an original generated style frame stored outside the
product repository at
`/home/ubuntu/private-evidence/offline-games/merge2248-art/candy-workshop-north-star.png`
(SHA-256
`95d40b855a7dbd085cae4dac94a1d585b97630e24694825f6fbeaebb116cbf9f`).
It is a visual target only; no baked UI or token pixels from the frame ship.

The shipped background is a separate low-detail environment layer at
`assets/art/merge2248/candy_workshop_bg_v2.webp`. Live tokens, values, ribbon,
selection, and event animation remain code-native.

## Hero-event storyboard

Trigger: release a legal path.

Authoritative state delta: consume the path, create the power-of-two result,
apply gravity/refill, increment score and moves.

| Beat | Object motion | VFX / sensory role |
|---|---|---|
| Intent | Selected candy squashes, lifts, and leans toward the pointer | Soft ascending pluck and short haptic |
| Anticipation | Cream ribbon thickens; pulse travels through each connection | Warm rim and preview label |
| Impact | Path candies stream into the destination; result overshoots | Cream splash, restrained star crumbs, rounded impact |
| Settle | Updated board falls a short distance with row/column stagger | Contact puffs; input stays available |

## Production and risk

- GAG semantic searches were attempted for tokens, board, and FX but failed
  because the MCP lacks `providers.gemini.api_key`.
- GAG OpenRouter generation was attempted and failed with
  `Provider not found: openrouter`.
- The approved fallback uses built-in image generation for the environment and
  code-native construction for interactive assets.
- Largest runtime risk: excessive per-frame allocation in immediate drawing.
  Mitigate with bounded polygons, no per-token textures, capped FX, and the
  existing 40-token board.
- Non-goals: change mechanics, add difficulty/undo, redesign the full catalog,
  or claim reference superiority without matched reference recordings.
