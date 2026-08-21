# Snakes GAG v2 direction package — implemented candidate

## 1. Decision header

```text
Game / slice: Snakes / 竞技场抢食与截击循环
Reference target: Offline Games / No Wifi Games Snakes, Apple track 6448104157 and Android package com.JindoBlu.OfflineGames
Historical starting commit: d9ee2dcbbec523b66169b40140de352cf2b5f213
Runtime / platform: Godot 4.6 Web, CanvasItem renderer, mobile-first browser
Viewport and device class: 540x960 logical portrait, touch/keyboard/mouse
Direction status: approved parent task; implemented as an isolated, undeployed candidate
Prepared at: 2026-08-20 UTC
```

This is the historical v2 asset-production package, reused by the isolated v3
candidate only after `docs/replica/snakes-v3/mechanics-gate.json` set
`gag_production_authorized` true. The
repository label `136_SNAKES` is not acquired-source evidence and is not treated
as the original identity. Exact original boost/collision/death/respawn/rank,
win, restart, and recovery semantics remain unknown; see the v3 claim ledger.

The direction was first frozen at preflight commit
`be96278f98526f1904d813905c0c34e7124fe62b`, then implemented only in the
`codex/art-snakes-gag-v2` worktree. It is a review candidate: it has not been
merged, pushed, or deployed. The old v2 feature did not change its then-current
mechanics. The v3 integration targets the separately committed recovery-capable
model and proves presentation subscriptions against that current model instead
of reusing the old model hash.

## 2. Baseline and invariants

### Current player-visible result

- Stable frame: `docs/audit/snakes-arena-baseline.webp` at 540x960.
- Complete loop: deterministic visual audit covers steering, own-body pass,
  eating, boost, bot death/scavenge, player death, terminal, and restart.
- Strongest existing element: continuous arena mechanics and the readable
  sticker-like leaderboard/boost/radar shell.
- Weakest existing element: core snakes and pellets are flat colored geometry;
  the player depends on rainbow bands and the `你` label rather than a unique
  silhouette or material signature.
- Main identity problem: a generic dark doodle/neon-candy arena remains after
  the title and HUD are hidden; no verified GAG runtime component exists.
- Main expression problem: eat, boost, knockout, and death frequently resolve
  through labels, stars, rings, or particle count instead of a material change
  with clear object causality.

### Frozen gameplay

| Probe | Expected behavior | Evidence |
| --- | --- | --- |
| Entry | Reset creates one player, five live bots, bounded pellets, a sorted leaderboard, mass 38, and `playing` state | `tools/snakes_arena_model_smoke.gd`; 18/18 PASS |
| Core input | Pointer/touch direction continuously steers; arrows set aim; boost button, Space, and Shift request boost | `main.gd` input handlers and `player_steered` probe |
| State change | Fixed simulation advances position/tick; eating grows mass and replenishes pellets; boost trades mass for speed and sheds edible trail | model smoke PASS |
| Collision | Own body/tail is nonlethal; arena boundary and rival body are lethal; head-to-head is symmetric and mass based | model smoke PASS |
| Competition | Bot death creates real debris, bots scavenge, leaderboard reorders, and dead bots respawn | model smoke and visual sequence 12a–12c |
| Result/failure | Local candidate decision: player death clears pointer/boost, exposes terminal reason/rank, and normally gives the event 0.72 s before the result; reduced-effects shows state truth immediately | v3 contract/runtime and art smoke |
| Restart/recovery | Local offline-quality decision: `再来` returns to a live arena at mass 38; valid live Web snapshots restore input-neutral, while corrupt or terminal snapshots reject | `tools/snakes_v3_contract_smoke.gd`; `tools/snakes_v3_runtime_smoke.gd` |

Current v3 model: `models/snakes_arena_model.gd`, SHA-256
`7aeb9eb720233e4d957649293289935f46106d9b94320126c9682ca0e6f22852`.
Presentation must subscribe to its semantic events and must not recompute
collision, growth, ranks, pellet ownership, or result timing.

### Constraints

- Audience: short-session casual players; readable without prior arena-game
  vocabulary.
- Camera: player-following top-down portrait arena with look-ahead.
- Input: direct pointer/touch steering plus optional keyboard; a 92x92 boost
  target remains available.
- Required viewports: 540x960 logical portrait and current Web stretch policy.
- Performance/package limits: preserve bounded 120 presentation particles,
  off-screen culling, sampled remote bodies, and Web frame-time budget.
- Accessibility/localization: player/risk/rank cannot be color-only; all live
  CJK labels remain code-native and must retain assigned font roles.
- Rights/provenance: no source master or private reference ships; generated
  gameplay text is forbidden.

## 3. Pillars

### Experience pillars

| Pillar | Player intent | Production consequence | Observable proof |
| --- | --- | --- | --- |
| Head leads, body answers | I should feel that I am steering a living racer, not dragging a polyline | Directional head/gaze reacts in the first authoritative tick; body curvature and wake propagate behind it without delaying control | Matched 1-tick head frame and 0.16 s body-follow frame remain mechanically identical |
| Mass has candy weight | Eating should feel like gaining substance; boost should feel like spending it | Gummy contact, compression, stretch, sugar highlight, and shed pieces scale with the existing mass/boost events | Eat visibly resolves into a thicker settled body; boost leaves real edible candy while mass falls |
| Rank is won in the arena | I should read an opponent's defeat as an opportunity and choose to scavenge | Knockout produces readable candy debris, bot/player intention points toward it, and the rank consequence settles in the play space before the HUD confirms it | Continuous bot-death → debris → chase/eat → leaderboard reorder sequence is readable without debug labels |

### Art pillars

| Pillar | Shape/material/motion rule | Observable proof |
| --- | --- | --- |
| Soft-gummy carnival | Hero objects use rounded, slightly translucent gummy silhouettes with one dark candy edge, a broad body highlight, and sparse sugar flecks; no generic glow is needed to describe volume | Player head and prize pellets remain tactile with particles/bloom disabled and at their real 48/16–22 px sizes |
| Sticker-race hierarchy | Cream/yellow sticker HUD frames the arena; the player receives a unique parade-leader head/crown silhouette while rivals share a coherent but subordinate mascot family | Player is identifiable in a busy stable frame after hiding `你` and desaturating the screenshot |
| Material cause and consequence | Steering flexes, eating compresses and rebounds, boost stretches/fizzes, collision squashes then tears into edible pieces; the state change owns the visual peak | Each event has intent, impact, and settled consequence tied to real model timestamps, not a generic particle overlay |

### Anti-pillars

| Reject | Why it conflicts | Concrete counterexample |
| --- | --- | --- |
| Generic neon confetti | Glow and particle count cannot substitute for player identity or gummy material | Adding more cyan rings/stars to the current eat frame while the core pellet stays a flat circle |
| Hostile fantasy cobra | Aggressive scales, fangs, and large full-body animation fight the friendly short-session fantasy and cannot follow the continuous model path | Reusing `enemy_cobra_death_spritesheet.png` |
| Candy asset soup | Reusing another game's fabric badge, fruit burst, or 2248 token erases catalog-specific identity and becomes noisy at arena density | Tile Club atlas as pellets or 2048 Balls citrus burst as every knockout |

## 4. Fantasy and tone

- Player fantasy: lead a mischievous soft-gummy parade, cut into the scramble,
  and turn rivals' spills into first place.
- Emotional promise: steering stays playful and immediate; risk is legible;
  growth feels chewy and satisfying rather than explosive by default.
- Tone sentence: a midnight candy fair where bright gummy racers compete like
  friendly bumper cars.
- Three style words: soft-gummy, sticker-race, mischievous.
- Three anti-words: cyber-neon, predatory, cluttered.
- Game-specific signature motif: a parade-leader gummy head with a small
  crown/rosette and a trail of prize-bean pennants.
- Relationship to shared suite shell: keep collection navigation and CJK font
  roles; the full playfield remains an independent candy-race world.

## 5. Annotated references

The verified HOME-WSL GAG search produced no reusable runtime asset. Exact fresh
queries, scores, downloaded hashes/containers, rejection reasons, API prompts,
source masters, transformations, and runtime hashes are in
`snakes-gag-v2.asset-ledger.json`.

| Reference / GAG candidate | Borrow conceptually | Reject | Provenance / rights |
| --- | --- | --- | --- |
| `enemy_cobra_death_spritesheet.png`, 0.446686 | Clear frame staging only | Menacing full cobra, scales/fangs, 2560² atlas, unrelated silhouette and motion contract | Existing GAG archive; reviewed, not selected |
| GB Snake fal source, 0.445686 | Strong directional head read at small size | Monochrome pixel/LCD vocabulary, white JPEG source, belongs to GB Snake | Existing GAG archive; reviewed, not selected |
| Tile Club badge derivative, 0.432174 | Limited icon family and strong outer edge | Fabric square, nine dense motifs, unreadable as 16 px food and belongs to Tile Club | Existing GAG archive; reviewed, not selected |
| `impact-burst.png`, 0.405387 | Empty-center instantaneous contact | Generic orange comic explosion; does not describe gummy tear/scatter | Existing GAG archive; reviewed, not selected |
| 2048 Balls juice burst, 0.403873 | Hollow center and material droplets | Citrus/fruit identity belongs to another game | Existing GAG archive; reviewed, not selected |
| Fruit cascade reward audio, 0.678964 | A short reward cadence may inform timing | Cross-game identity; not proof of chew, fizz, or competitive takeover | Existing GAG archive; metadata reviewed, not selected |

Internal directions:

| Direction | Strength | Reason rejected |
| --- | --- | --- |
| Pixel snake tournament | Strong small-scale clarity | Duplicates GB Snake's identity and loses soft continuous body motion |
| Neon space worms | Easy to layer over current scene | Repeats the generic glow language the art pass is meant to replace |
| Soft-gummy parade arena | Core mechanic naturally supplies flex, mass, shedding, scavenging, and rank spectacle | Recommended |

## 6. Recommended direction

- One-sentence visual thesis: turn the existing arena into a soft-gummy parade
  race where the player mascot, prize beans, and knockout debris are physical
  candy objects, while live paths and text remain authoritative code layers.
- Why it fits the mechanic: continuous curvature reads as gummy flex; boost
  shedding and defeated-snake debris already exist as edible state.
- Why it is distinctive: the crown/rosette head, prize-bean family, and
  sugar-ribbon knockout belong specifically to competitive Snakes.
- Why it is feasible: generated art is limited to small isolated components;
  arbitrary snake bodies, direction arrows, labels, and collision remain
  code-native.
- What changes from baseline: player/rival head family, repeated pellet family,
  gummy contact/highlight treatment, knockout burst, and semantic audio layers.
- What deliberately remains: model, camera, world scale, HUD geometry, input,
  leaderboard, radar, result delay, and exact collision rules.
- Non-goals: no baked full-screen arena mockup, no model/rule changes, no 3D,
  no gameplay text inside images, and no replacement of every pixel with art.

## 7. North Star frames

These targets are now backed by the isolated implementation and captured at the
real 540x960 runtime viewport.

| Frame | Required content | Artifact |
| --- | --- | --- |
| Stable | Unique player gummy head at 50–58 px, subordinate rival heads, 16–22 px prize beans, quiet doodle field, current HUD and choices readable | `docs/audit/snakes-gag-v2/candidate/stable-core.png` |
| Active | Immediate head bank/gaze, gummy body flex, directional sugar wake, held boost reserve and mass cost readable | `docs/audit/snakes-gag-v2/candidate/collect-intent.png` through `collect-settle.png` |
| Result | Rival compresses/tears into edible gummy pieces, player/bot intent turns toward debris, crown/rank consequence settles without covering the next route | `docs/audit/snakes-gag-v2/candidate/knockout-contact-sheet.png` and `knockout-continuous.webm` |

## 8. Hero-event storyboard

```text
Trigger: a rival dies through the authoritative collision system and leaves debris
Authoritative state delta: rival alive=false; real debris pellets spawn; later eat events add mass; leaderboard may reorder
Next legal choice: steer toward the debris, contest it, or avoid the cluster
```

| Beat | Object motion | VFX/light | Audio/haptic/camera | State evidence |
| --- | --- | --- | --- | --- |
| Intent | Rival head focuses/leans; dangerous contact side compresses; nearby scavenger gaze points toward conflict | Narrow contact glint only | Soft tension tick; no shake | Rival and collision geometry still alive before the model step |
| Anticipation | Body bands bunch toward contact for a few presentation frames without delaying simulation | Sugar edge tightens at the collision point | Short gummy strain | Pending semantic `bot_died` has not been visually resolved yet |
| Impact | Rival tears along its body into the exact real debris positions; player head recoils subtly | Hollow sugar-ribbon burst behind debris, not over it | Candy snap/scatter; light local camera kick | `bot_died`, pellet spawn, alive=false already authoritative |
| Settle | Debris becomes ordinary collectible prize beans; player/bots curve toward it; rank rosette settles if order changes | Burst clears before route choice | Chew pops follow actual `ate`; crown cue only on leader change | Mass, pellets, bot state, and leaderboard are readable and control never pauses |

## 9. Production system

### Visual language

- Shape/proportion: round mascot heads with one directional nose/cheek mass;
  tapered gummy body; five simple pellet silhouettes maximum.
- Palette/value: retain dark navy arena and cream/yellow HUD; player uses
  lime/cyan/cream with a gold rosette; rivals use controlled 2–3-color families.
- Material/light: contact shadow, translucent gummy body, dark candy edge,
  broad upper-left highlight, very sparse sugar texture.
- Type/numerals/icons: current CJK/Latin/number roles remain live and code-native.
- Component states: idle/focused/boosting/compressed/defeated for heads;
  ambient/debris/boost-shed for pellets.
- Progression tiers: mass changes body radius and highlight width; leader state
  adds rosette/crown silhouette rather than only a yellow label.
- Motion weight/cadence: immediate head lead, 120–180 ms gummy compression,
  280–480 ms rebound/tear, under 900 ms clean settle.
- Intensity hierarchy: steer is quiet; eat is tactile; boost is sustained;
  knockout is localized; player death and taking first place are terminal peaks.

### GAG plan

- Verified production endpoint: HOME-WSL
  `https://desktop-youyuan-wsl.tail17a64.ts.net:11443/mcp`, streamable HTTP,
  health version 0.2.0, MCP server 1.29.0, 21 tools.
- Configuration drift: Codex's directly registered EC2 GAG reported only the
  mock provider and was rejected. The verified HOME-WSL service reports no
  detected host GPU, main-service PyTorch absent with pure API available, and
  fal/Gemini/OpenRouter/ElevenLabs/Remove.bg enabled.
- Semantic search queries: mascot head, repeated prize bean, gummy knockout
  burst, and four-role short audio; all exact strings retained in the ledger.
- Reviewed/rejected candidates: all retrieved library candidates were rejected;
  none were silently relabeled as GAG output.
- API generation completed: fal.ai supplied the player head, prize bean, and
  hollow sugar-ribbon burst; Remove.bg supplied alpha masters; ElevenLabs
  supplied semantic eat, boost, knockout, and leader cues. One head and one
  crowded bean iteration were explicitly rejected before selection.
- Style anchor: the selected fal player head source master anchors every shipped
  derivative; no full-screen mock or generated gameplay text ships.
- Transparent outputs: generate on simple background through fal/OpenRouter as
  selected, then Remove.bg; verify real container, alpha, trim, dimensions, and
  hashes.
- Provenance ledger: `docs/art-direction/snakes-gag-v2.asset-ledger.json` is the
  production record. Source masters remain only in the GAG archive on HOME-WSL.
- First visible beat/runtime size: player head 50–58 px in every gameplay frame;
  rival heads 42–52 px; prize beans 16–22 px in every frame; burst 110–170 px
  only at knockout.
- Stable placement: player head and pellets are mandatory signature assets;
  knockout-only art cannot satisfy the slice by itself.
- Runtime density: inspect at 540x960 with at least four snakes and 24 visible
  pellets; generated micro-detail must disappear cleanly instead of producing
  noise.

### Runtime plan

- Semantic hooks: `player_steered`, `player_ate`, `boost_started`,
  `boost_rejected`, `boost_shed`, `bot_died`, `bot_ate`, `player_died`, and
  existing leader/rank diffs.
- Presenter ownership: extract Snakes drawing/feedback into a presentation-only
  class only if that reduces risk; the model remains untouched and frozen.
- Shader/sprite/vector split: generated textures for head/pellet/burst; existing
  Canvas geometry for continuous bodies, paths, radar, labels, and culling.
- Responsive strategy: preserve 540x960 logical coordinates and stretch rules.
- Reduced-motion/low-effects: disable shake/wake/burst layers while retaining
  head state, material change, debris, and rank consequence.
- Performance: busy four-snake/debris trace, bounded FX count, no per-frame
  texture/style allocation, Web llvmpipe/SwiftShader validation.
- Text/controls: recheck live CJK over final dark texture and generated objects.
- Web handoff: validate a clean content-addressed PCK/engine and a fresh browser
  real-steer probe locally; this isolated candidate is not authorized to deploy.
- Runtime visibility: stable player head/pellets plus peak burst/audio and their
  exact clean-export PCK records must pass before review handoff.

## 10. Implemented slice and review boundary

- Quality opportunity: the mechanics already expose unusually rich semantic
  events; a small coherent component family can change the ordinary frame and
  make knockout/scavenge materially causal.
- Largest production risk: generated mascot art may become unreadable when
  rotated and reduced below 58 px.
- Largest runtime risk: repeated textured pellets may add noise/draw cost.
- Mitigation: generate low-detail silhouettes, test source and runtime sizes,
  reuse atlases/texture regions, cap families, and preserve quiet space.
- Implemented stable signature: one fal/Remove.bg player gummy head at 50–58 px
  plus a tintable fal/Remove.bg prize bean at 16–22 px for every ambient,
  boost-shed, and real-debris pellet.
- Implemented hero event: authoritative `bot_died` starts anticipation,
  144 px hollow candy impact, and a 0.92 s settle behind the actual snakes and
  debris; the model is not paused or rewritten.
- Implemented audio roles: GAG/ElevenLabs chomp, boost, knockout, and first-place
  cues subscribe to existing semantic events. Objective container, duration,
  waveform, loudness, and peak checks exist; no subjective listening claim is
  made because no audio reviewer was available.
- Proof sequence: the 28-frame/30 fps WebM begins before `bot_died`, preserves
  the player's legal route through impact, then reaches real debris, mass gain,
  and rank-one settlement. The matching state record is
  `docs/audit/snakes-gag-v2/candidate/semantic-state.json`.
- Review boundary: this branch is a self-contained candidate only. Final merge,
  push, deployment, and product approval remain with the parent workflow.
