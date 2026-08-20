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
- Routine merge: ribbon, pop, small crumbs.
- High tier/milestone: larger silhouette ring and richer sound.
- Win: reserve the strongest celebration.

## Runtime and accessibility

- Encode value/state with shape plus color plus numeral.
- Keep a low-effects result readable with particles removed.
- Cap active merge effects and expire them within one second.
- Avoid per-frame texture creation and unbounded arrays.
- Preserve touch hit geometry, required viewports, CJK/number coverage, Web boot,
  clean-clone import, and the separate `merge2048` route.
