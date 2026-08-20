# Merge 2248 candy-workshop runtime art review

## Review identity

- Date: 2026-08-20
- Starting commit: `370a98572d2f7e258d4090ee73112b0810372609`
- Candidate: the commit containing this review
- Runtime: Godot 4.6 GL Compatibility, 540×960 design viewport, Web export
- Direction: tactile number candy on a warm confectioner's workbench
- Signature motif: elastic cream-syrup recipe ribbon
- Formal claim: art strengthening and expressive strengthening
- Not claimed: breakthrough or surpassing the reference; matched reference
  recordings and user review are still required for either claim

## Matched evidence

All retained candidate frames use the same 540×960 viewport and deterministic
visual fixture. The evidence directory is
`docs/audit/merge2248-candy-workshop/`.

| Beat | Artifact | What it proves |
|---|---|---|
| Prior baseline | `00-baseline-before.webp` | Generic glass board, same circular silhouette, simple line |
| Stable | `01-idle.webp` | Workshop environment, physical tray, tactile base materials |
| Progression | `02-tier-gallery.webp` | Pillow, wrapper, lozenge, star, facets, and milestone crown |
| Intent / anticipation | `03-connection-preview.webp` | Lifted candy, cream rim, elastic ribbon, moving pulse, recipe preview |
| Impact | `04-merge-impact.webp` | Gathered copies, result overshoot, cream ring, sugar crumbs |
| Settle | `05-merge-settle.webp` | Staggered board landing with next choices readable |
| Result | `06-final.webp` | Stable post-event consequence |
| Web / responsive | `07-web-540x817.webp` | Exported build preserves the full portrait playfield in a shorter viewport |
| Web input | `08-web-after-drag.webp` | Browser drag changes score to 16, moves to 1, and creates a 16 token |
| Continuous event | `hero-event.webm` | 30 fps gather-to-settle sequence, SHA-256 `a3fe7211e93c73e11e4f0a380e22b1e35363515581bee018812886b15fb3ce38` |
| State delta | `before-release.json`, `after-release.json` | Score 0→8, moves 0→1, preview cleared, board refilled |

## Dimension review

Scale: 0 broken, 1 prototype, 2 production, 3 distinctive.

| Dimension | Level | Evidence and reason |
|---|---:|---|
| Identity | 2 | Candy workshop and syrup ribbon are recognizable without the title; user review decides whether they are distinctive enough for level 3 |
| Composition / hierarchy | 2 | Quiet central felt and edge-only props keep current choices dominant |
| Shape / material craft | 2 | Contact shadow, rim, body, inset, highlight, and live numeral survive with FX removed |
| Color / type / UI | 2 | Cream, teal, honey wood, and value colors have stable roles; numerals remain live and high contrast |
| States / progression | 2 | Base, selected, resolving, result, and high tiers use shape and posture as well as color |
| Intent | 2 | The touched candy lifts, squashes, rims, and leans within the rendered input frame |
| Anticipation | 2 | Thick cream ribbon, traveling pulse, and result label prepare release |
| Impact | 2 | Consumed copies gather into an overshooting result with a bounded splash |
| Settle | 2 | Refilled cells fall with a short stagger without owning or blocking rules |
| Intensity hierarchy | 2 | Chain length changes gather density, pitch, and haptic strength; milestone tiers add facets/crown; global win remains strongest |

## Mechanics and runtime gates

| Gate | Result |
|---|---|
| `merge2248_model_smoke.gd` | PASS, 10 probes |
| `merge2248_integration_smoke.gd` | PASS, 5 probes; known exit-only resource warning unchanged |
| `smoke.gd` | PASS, all 14 games |
| Visual audit | PASS, stable through result plus 30-frame continuous capture |
| Web export | PASS, threads disabled, required HTML/JS/WASM/PCK present |
| Browser boot | PASS on clean localhost export in Chrome/SwiftShader |
| Browser interaction | PASS at 540×817; one drag produced score 16 / move 1 |
| Aliyun atomic deploy | PASS, release `20260820T064125Z-96471303ae16` |
| Public bundle integrity | PASS, HTML references `index.96471303ae16.pck` and `index.2b558bdb3c3a.wasm`; both returned 200/206 |

The candidate busy-event trace under EC2 Xvfb software GL is stored in
`performance.json`: average 22.25 ms, p50 21.32 ms, p95 26.98 ms over 120
frames. The same trace on the starting commit, stored in
`performance-baseline.json`, measured average 39.87 ms and p50 37.01 ms. This
is a regression guard, not end-user GPU telemetry.

## Provenance and known debt

- The only new shipped raster is `candy_workshop_bg_v2.webp`, SHA-256
  `b41c3d5d512d47f4e43a24bac35bbf4538272a8ef67c6a0ab489048904d2686a`.
  Its prompt route, transform, runtime reference, and constraints are recorded
  in `assets/art/merge2248/asset-ledger.json`.
- GAG semantic search failed because the MCP lacked a Gemini API key. GAG
  OpenRouter generation failed because the provider was not registered. No GAG
  asset is falsely claimed; built-in image generation supplied the environment
  fallback and all interactive art is code-native.
- Audio currently reuses the collection's short pluck/merge sounds. A bespoke
  candy Foley family is the clearest bounded next art slice.
- A dedicated reduced-effects toggle is not yet exposed. The low-effects frame
  remains readable because tokens, shape progression, ribbon, and state change
  do not depend on bloom or particles.
- The public cold-cache engine download is large (37.7 MB) but engine fingerprint
  is unchanged from the previous release and therefore cacheable; this art pass
  adds only the new pack fingerprint.
