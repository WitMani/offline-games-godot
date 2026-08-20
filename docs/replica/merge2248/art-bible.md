# Merge 2248 candy-workshop Art Bible

## Composition

- Preserve the 540×960 design viewport.
- Keep the playfield between the section label and the bottom recipe label.
- Let the tray occupy the first visual read; persistent collection chrome stays
  compact and dark teal.
- Keep decorative background detail outside the central interaction zone.

## Shape grammar

- Use plump asymmetry, softened corners, shallow bevels, and compact contact
  shadows.
- Preserve a 5×8 hit grid independently from drawn deformation.
- Map visible value tiers:
  - 2: rounded pillow candy;
  - 4: wrapped candy with side ridges;
  - 8: inset squircle/lozenge;
  - 16–32: star or flower silhouette;
  - 64–256: doubled rim and small sugar facets;
  - 512+: milestone crown/star treatment.
- Keep numerals code-native and centered on the undeformed token space.

## Palette and hierarchy

Retain the evidence-backed value sequence while adapting it to candy materials:

| Value | Role |
|---:|---|
| 2 | coral |
| 4 | grape violet |
| 8 | mango yellow |
| 16 | mint green |
| 32 | sky blue |
| 64+ | rotate through warm orange, blue, cocoa, jade, and milestone cyan |

- Use cream for the active ribbon and strongest selection edge.
- Use deep teal for the quiet tray surface.
- Use honey wood and warm cream for frame depth.
- Give current selection and merge impact the highest local contrast.

## Material construction

Build each token in this order:

1. compact offset contact shadow;
2. darker outer body/rim;
3. saturated candy body;
4. lighter inset face or tier detail;
5. short upper-left specular stroke;
6. live numeral shadow and cream face;
7. selection edge and sugar sparkle only when active.

Do not use bloom or generic cyan glow as the material.

## Component states

- Base: grounded, quiet breathing below one pixel.
- Pressed: vertical squash and horizontal spread.
- Selected: lift, cream rim, stronger shadow, rhythmic pulse, lean toward path.
- Resolving: travel toward destination while shrinking.
- Result: 0.72→1.18→1.0 pop with cream splash.
- Landed: short overshoot and contact puff.
- Milestone: extra rim/facets and a stronger but bounded celebration.

## Ribbon

- Draw shadow, cream body, light highlight, and colored pulse as separate layers.
- Use round joints at every selected token.
- Keep width below the numeral body and place tokens above the ribbon.
- Let the unfinished tail stretch toward the pointer with lower opacity.

## Motion timing

| Beat | Target |
|---|---:|
| Input response | within one rendered frame |
| Selected-token compression | 60–90 ms |
| Gather to destination | 160–220 ms |
| Result overshoot | 180–260 ms |
| Board fall and settle | 360–560 ms |
| Whole routine event | under 850 ms |

Keep interaction available; presentation follows the already-completed model
transition and never owns game rules.

## Audio, haptic, and intensity

- Raise pitch slightly for each accepted chain node.
- Use one rounded merge sound at impact.
- Keep short haptics for accepted nodes and a stronger bounded pulse for merge.
- Treat chain length and result tier as two inputs to one semantic feedback
  grade. The stronger input wins; animation never changes the model result.
- Property animation must carry the event with particles disabled: board
  squash/rebound, result stretch and rotation recoil, token landing squash, and
  score scale/color kick.
- Win: reserve the strongest celebration.

### Merge-feedback grades

| Grade | Trigger | Readable label | Haptic | Camera / board | Property and VFX peak |
|---:|---|---|---|---|---|
| 1 | 2 nodes and result below 16 | 轻甜 | one 20 ms tap | 0.7 px micro-shake | modest pop, one ring, 10 crumbs |
| 2 | 3+ nodes or result 16+ | 连携 | 18–24–34 ms pattern | 2.8 px shake | firmer board squash, two rings, 14 crumbs |
| 3 | 5+ nodes or result 128+ | 超连携 | 24–18–48 ms pattern | 6 px directional shake | result rotation recoil, local flash, three rings, 18 crumbs, layered impact sound |
| 4 | 8+ nodes or result 512+ | 传奇配方 | 30–16–46–18–72 ms pattern | 10.5 px directional shake with longer decay | largest bounded score/result kick, gold flash, four rings, 22 crumbs, deepest layered sound |

The haptic arrays alternate vibration and pause on supporting Web/mobile
platforms. Desktop browsers without vibration must still expose every grade
through label, ribbon pulse count, shake, scale, rotation, rings, particles, and
sound. Never let grade 1 approach the visual or tactile peak of grade 4.

## Runtime and accessibility

- Encode value/state with shape plus color plus numeral.
- Keep a low-effects result readable with particles removed.
- Cap active merge effects and expire them within one second.
- Avoid per-frame texture creation and unbounded arrays.
- Preserve touch hit geometry, required viewports, CJK/number coverage, Web boot,
  clean-clone import, and the separate `merge2048` route.
