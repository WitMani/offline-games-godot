# Amaze GO v2 — clockwork surveyor direction

Game / slice: Amaze GO only
Reference target: frozen in-repository mechanic; no comparative-original claim
Starting commit: `fab3f93b43eead360bbf9a828c427fedbf6823af`
Runtime / platform: Godot 4.6 / Web / touch and keyboard
Viewport and device class: 540×960 portrait
Direction status: approved under the user's autonomous one-game-at-a-time catalog mandate
Prepared at: 2026-08-20

## Baseline and invariants

The cartographer desk background already establishes a strong world, but the
playfield is an empty-looking dark grid. The player is a generic code circle,
the goal depends on the Chinese character `终`, walls are thin blue strokes,
and ordinary travel/arrival mostly use detached rings. Baseline hashes:

- `baseline/stable.png`: `3809af57bf354da825a1a0ebbbda7bebd8e101adbdfee3c4899d7ecc0e605a82`
- `baseline/step.png`: `dfb072919e907fa826c7571599889c74a0b2be27389e43a38ff0fd7bbdf68b0f`

Frozen gameplay:

| Probe | Expected behavior |
| --- | --- |
| Entry | 6×6 grid; player `[0,0]`; target `[5,5]`; only start painted; score/moves/streak zero; status playing |
| Legal step | orthogonal in-bounds non-wall step updates player, marks destination, adds 5 score, one move and one streak |
| Wall / edge | authoritative state remains unchanged |
| Tap | only an adjacent cell delegates to the same step rule; non-adjacent tap is inert |
| Goal | entering `[5,5]` wins and adds the normal 5 plus terminal 100 |
| Restart | restores the exact deterministic entry state and wall dictionary |

The wall layout, guaranteed route across the top/down the right edge, hit
regions, score, counters, target and terminal rule do not change.

## Experience pillars

1. **Survey a place, not a UI grid.** Player intent → every legal move advances
   one physical brass surveyor over cyanotype paper and pins the traversed cell
   with permanent ink/rivet history → an untouched and a ten-step board are
   distinguishable without reading the HUD.
2. **A wall must feel structurally blocked.** Wrong direction → the real token
   leans into a raised ruler wall, recoils and makes the contacted segment flash
   → position, score and route remain visibly unchanged before control returns.
3. **Arrival seals the expedition.** Final legal step → the surveyor follows the
   actual last edge into a destination beacon, the complete route tightens and
   receives a cartographer seal → the won state and the route that produced it
   remain readable before the result plaque appears.

## Art pillars

1. **Cyanotype paper under aged brass:** deep ultramarine paper, pale drafting
   ink, worn brass walls, ivory enamel and restrained coral wax describe one
   material world.
2. **Navigation by silhouette:** a round compass surveyor, ruler-like barriers,
   pin/rivet trail and star-seal beacon differ by outline before color; generated
   pixels contain no letters, numbers, arrows or pseudo-glyphs.
3. **The route is accumulated evidence:** visited cells receive connected ink
   strokes and brass survey pins; routine motion is measured and mechanical,
   while only five-step waypoints and terminal arrival widen the response.

## Anti-pillars

1. No empty generic dark-grid cells with glow standing in for map craft.
2. No glass/neon sci-fi reskin, particle fog or bloom that obscures walls.
3. No generated gameplay text, baked maze, invented arrows or detached victory
   fireworks unrelated to the actual final route.

## Fantasy, tone and visual development

- Player fantasy: guide a pocket clockwork surveyor across a living blueprint
  and certify a safe route for the expedition.
- Emotional promise: thoughtful discovery with tactile mechanical certainty.
- Style words: cartographic, clockwork, precise.
- Anti-words: holographic, weightless, frantic.
- Signature motif: ivory-and-brass compass pawn + coral-wax destination beacon.

Internal alternatives:

| Direction | Strength | Reason rejected |
| --- | --- | --- |
| Clockwork surveyor | makes player, walls, route and goal one physical system | selected |
| Paper-cut explorer | friendly silhouette | weak contact with walls and existing brass desk |
| Holographic path console | easy glow hierarchy | conflicts with cyanotype/brass world and catalog anti-neon rule |

GAG semantic search ran before generation. `card-spring-scout.png` was the best
visual match but is a character/card illustration rather than a top-down board
token. Logic-game badges, 2048 surfaces, generic magic rings, coin token and wand
were rejected. Audio search returned boss/exploration music rather than a short
ratchet, ink pin or seal impact; all were rejected.

## North Star and hero event

Stable frame: the same seeded 6×6 state, with the GAG surveyor at `[0,0]`, the
GAG beacon at `[5,5]`, raised brass wall segments, quiet paper grain and one
start pin. Active frame: the surveyor compresses/rotates toward the legal next
cell while the exact edge receives a drafting stroke. Result: the final real
edge closes, beacon and surveyor align under a restrained wax/brass seal, then a
dedicated map-certificate plaque enters.

Hero event: final legal step into `[5,5]`; authoritative delta is player target,
painted target, moves `+1`, score `+105`, streak `+1`, status won. Next legal
choice is restart.

| Beat | Object motion | Material / light | Audio / haptic / camera | State proof |
| --- | --- | --- | --- | --- |
| Intent | surveyor needle and body lean toward target | destination pin wakes | short ratchet, tiny haptic | source still authoritative |
| Anticipation | real surveyor crosses exact legal edge | drafting ink draws beneath it | rising mechanical tick | move state already committed |
| Impact | surveyor meets beacon | brass iris + coral wax contact | generated seal cue, grade-4 bounded shake/haptic | target painted; won; +105 |
| Settle | route pins tighten, beacon becomes certificate emblem | secondary dust resolves | short chime decay | result plaque after local event window |

## Production system

- GAG pure-API route: semantic search → fal.ai image generation → critique →
  Remove.bg/crop repair → ledger → runtime; ElevenLabs for two short SFX.
- Required runtime components: one transparent surveyor pawn, one transparent
  destination beacon, one routine ratchet/ink cue and one terminal seal cue.
- First visible beat: pawn and beacon are both visible in the untouched opening
  board at roughly 54×54 and 50×50. They also participate in travel and arrival.
- Code-native layers: paper cells, walls, connected route, rivets, shadows,
  semantic labels and result copy. Generated assets are never full-screen UI.
- Semantic hooks: legal step, five-step waypoint, wall reject, edge reject and
  terminal arrival. No new gameplay grades or rule counters.
- Font contract: all dynamic CJK uses the bundled UI/display subset; numerals use
  the number role; event copy is exercised against the final textured plate.
- Performance: six catalog effects maximum; 120 stable and 180 grade-4 busy
  llvmpipe frames; no per-frame texture creation.
- Delivery: clean Git-archive import/export/PCK scan, fresh local browser action,
  fast-forward-only merge, GitHub push, atomic Aliyun release retaining the Tile
  Club pack, then the same exact-online action.

Non-goals: no maze generation change, pathfinding, backtracking restriction,
fog-of-war, new score system, Arrow GO/Amaze edit, shared-shell reskin or claim
of surpassing an unavailable commercial reference.
