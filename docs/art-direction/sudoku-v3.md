# Sudoku v3 — verified drafting-folio direction

Scope: only `sudoku`. Meowdoku is a regression neighbor. This package supersedes
the v2 claim that mechanics were frozen: v3 first repaired the ambiguous puzzle
and then opened the art gate. Reference facts, measured screenshots, inference,
and local decisions remain separated in `docs/replica/sudoku-v3/claim-ledger.md`.

## Experience and art pillars

1. **A puzzle worth marking by hand.** The board is a clipped architect's folio:
   layered ivory stock, graphite/slate rules, brass registration corners and a
   restrained indigo handwritten layer.
2. **The changed object tells the truth.** Selection registers on the cell;
   notes stay small; correct ink stays indigo; a wrong retained digit stays red
   with a crossed proofing mark; a completed block keeps a compass seal.
3. **Ceremony is earned.** Routine notation is quiet. The existing sourced GAG
   compass/pencil medallion is ordinary-visible in the header, returns for a
   completed 3×3 block, and becomes the full-board/result reward.

This follows the approved catalog pillars: authored focal hierarchy, tactile
materials, metaphor-bound motion, CJK-safe live text, and bounded Web cost.

## Anti-pillars

- No neon, generic sci-fi dashboard, particle fog, or full-screen shake as a
  substitute for the changed cell.
- No rasterized digits, Chinese labels, generated pseudo-glyphs, or gameplay
  state baked into art.
- No guessed heart failure, score, difficulty, hint, or progression rule is
  presented as exact behavior of Offline Games 3.14.1.
- No new mascot or redundant GAG generation: the verified compass family fills
  the signature-role need.

## Stable composition and font roles

- The 9×9 grid and strong 3×3 boundaries preserve the first-party visible
  topology. Selected row, column and block remain readable under all events.
- Printed givens use the dark numeric role; player ink uses indigo; wrong player
  ink uses red plus a persistent crossed proofing mark; notes use a live 3×3
  candidate layout.
- Dynamic Chinese—tool labels, hint counts, note state, toasts and result copy—
  always uses `UI_FONT` / the shipped Noto Sans CJK subset. Digits remain live
  `NUMBER_FONT`. GAG pixels contain no text.
- `sudoku_compass_reward.png` is visible at about 39×39 px in the ordinary
  header before input. This stable beat is captured in
  `docs/audit/sudoku-v3/candidate/00-stable-ordinary.webp`.

## Contextual semantic feedback

The implementation carries numeric grades for the shared event router, but the
design does not manufacture one event for every grade. Intensity follows the
actual Sudoku context:

| Context | Intent → impact → settle | Persistent proof |
|---|---|---|
| cell selection | paper press and registration focus → short rebound → still focus | selected cell and related row/column/block |
| note / correct / erase / undo | pencil stroke, ink settle, eraser pass, or reverse proofing arc | candidate, final digit, empty cell, or restored state |
| hint | restrained brass guide arc and small compass cue | solved selected cell plus decremented live hint count |
| wrong entry | cell counter-shake and red-pencil correction | retained red digit plus crossed corner mark; mistake count increments |
| 3×3 completion | local block wash and compass stamp | small block-corner compass seal |
| full completion | board-wide stagger, 122 px GAG compass/pencil reward and authored completion cue | paper result folio with the same GAG seal |

Routine correct and note feedback remain below a correction; a block milestone is
local; only legal full-board completion reaches the global peak. Error recovery
does not erase the wrong state.

## Reduced-effects contract

Native audit runs may set `SUDOKU_REDUCED_EFFECTS=1`; Web reads
`prefers-reduced-motion: reduce`. In reduced mode cell bounce, event overlays,
catalog VFX and camera shake are removed, and the result overlay is not delayed.
The authoritative board still changes immediately. Selection focus, indigo or
red ink, crossed wrong mark, candidate notes, block seals, live counts and result
folio remain sufficient without motion, vibration or audio.

## GAG reuse and provenance

No new GAG query or generation was justified for v3. The v2 HOME-WSL MCP ledger
already records semantic searches, rejected candidates, Gemini/Remove.bg image
generation and derivation, ElevenLabs audio generation, prompts, source masters,
hashes and runtime references. v3 reverified the exact runtime bytes, ordinary
visibility and completion audio route. The concise reuse ledger is
`sudoku-v3.gag-reuse-ledger.json`; it links rather than relabels the v2 assets.

## Acceptance contract

- Mechanics: renderer-free unique-puzzle and adapter probes must pass before
  these presentation claims are considered.
- Visual: matched stable and intent/impact/settle frames for selection, correct,
  notes/hint/undo, retained error, repeated error, block and full completion;
  continuous error and completion recordings; explicit reduced-effects frame.
- Quality: CJK source and subset gates, Meowdoku and 14-game regression, stable
  and busy llvmpipe traces, clean source archive, fingerprinted Web/PCK, PCK
  resource scan, and real-browser correct/wrong/restart/reload actions.
- Release boundary: this isolated candidate is never described as deployed or
  online-visible unless separately merged and released. This task does neither.
