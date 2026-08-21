# Amaze v3 art direction — paint workshop

Date: 2026-08-20
Baseline: `offline-games-2048balls-visible@3e561fb3`
Scope: isolated Classic Amaze candidate at 540×960; no merge, push, or deploy

## Contract and claim boundary

The renderer-free `amaze-stage0-v2` model and the evidence split in
`docs/replica/amaze-v3/` are authoritative. Presentation may reveal an ordered
traversal, but it may not choose stops, paint cells, complete a level, advance
progression, or change input semantics.

This slice is an **internal strengthening** against its exact repository
baseline. Commercial-reference surpass is **NOT_CLAIMED**: exact original
levels, progression volume, scoring, timing, audio, and a matched external
candidate/reference review remain unresolved.

## Approved catalog pillars applied conservatively

The parent direction remains `catalog-cartoon-v1`; Amaze does not create a new
catalog style.

1. **Crafted pocket world.** The maze is a raised cream canvas on a quiet plum
   workbench, not a generic debug grid.
2. **Readable toy materials.** Every playable cell has contact, body, edge, and
   highlight layers. Painted cells read as one connected wet ribbon.
3. **Object-first response.** The acted-on paint pod compresses, stretches,
   travels, impacts, and settles before supporting particles or labels.
4. **Semantic escalation.** Blocked, routine/revisit, long-roll,
   near-complete, and complete beats use different combinations of path extent,
   object response, sound, haptics, local marks, and result staging.

Anti-pillars: unrelated rainbow confetti, neon bloom, text as the only feedback,
full-screen particles for routine actions, generated text/UI, hidden topology,
and effects that delay the next command.

## Hero object and material grammar

The stable signature is the existing GAG v2 paint pod, retained under its
original asset identity. It is visible on the untouched board, after every
settle, during every legal roll, and on the completion plaque. Its runtime
silhouette remains legible at approximately 49×54 to 68×74 pixels.

The board uses a fixed layer order:

1. workbench/environment;
2. canvas contact shadow and rim;
3. unpainted cream body and pearl highlight;
4. model-derived connected wet ribbon;
5. paint pod and model-derived travel overlay;
6. bounded semantic event marks and live text.

All rule text, level names, counters, and feedback labels remain code-native.
Chinese and mixed-script labels use the bundled `ui_cjk` role; GAG pixels never
bake text or state.

## Event ladder

| Beat | Semantic authority | Object response | Supporting response |
|---|---|---|---|
| blocked | inert model command | boundary compression/recoil | quiet local reject mark + short haptic |
| revisit / short | accepted command, no or small new paint | short travel and restrained settle | grade-1 route mark + wet-roll family |
| long roll | ordered multi-cell traversal | stretch, exact corridor travel, stop rebound | ordered wet ribbon + grade-2 cadence |
| near complete | model reports one cell remaining | stronger settle at authoritative stop | grade-3 local stamp, label, haptic pattern |
| complete | model status becomes `won` | final-cell impact then calm plaque hero | grade-4 bounded peak and delayed result |

The ladder is semantic rather than a rigid reusable four-effect skin. It exists
to make materially different Amaze outcomes readable.

## Reduced-effects contract

`prefers-reduced-motion: reduce`, `?reduced_effects=1`, and the native audit
environment switch activate the same runtime mode. It:

- makes gameplay state transitions immediate;
- suppresses camera shake, impact displacement, object recoil/stretch, ambient
  drift, and transition wipes;
- suppresses native vibration while retaining an auditable suppression count;
- reduces each event to one local outline and a readable semantic label;
- preserves topology, ordered paint, player position, completion, sound routing,
  input cadence, and checkpoint behavior.

This is a real alternative runtime path, not merely an effects-cleared
screenshot.

## Asset and performance budgets

- No per-frame texture or audio construction; both GAG derivatives are
  preloaded.
- Catalog effects remain capped at 12.
- Source masters and rejected candidates remain on HOME-WSL GAG; only the
  324×354 RGBA pod and 0.448688-second Ogg derivative ship.
- The llvmpipe trace is a regression envelope, not a physical-device FPS claim.
  Stable, continuous busy, reduced-busy, and peak static memory are retained in
  `docs/audit/amaze-v3/art/performance.json`.

## Acceptance boundary

Acceptance requires dedicated mechanics/action probes, stable and all event
frames, continuous long-roll and completion-peak recordings, true reduced-mode
evidence, CJK coverage, full catalog regression, clean Git-archive export,
fingerprinted PCK/WASM, PCK inclusion/exclusion scan, and real browser pointer,
keyboard, restart, completion, reload recovery, haptic suppression, headers,
and full-transfer checks.
