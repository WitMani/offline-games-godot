# Meowdoku v3 — 猫咪领地手账方向

## Decision header

```text
Game / slice: Meowdoku only
Reference target: Oakever com.oakever.meowdoku Android 1.14.0
Starting commit: 3e561fb3c55f3b0b813da2b9ee9468cd4d290bae
Mechanics gate: docs/replica/meowdoku-v3/stage0-gate.json = passed
Runtime / viewport: Godot 4.6 Web, 540 × 960 portrait
Direction status: approved inherited catalog pillars, corrected target identity
Prepared at: 2026-08-20
```

This package supersedes `meowdoku-v2.md` for the Meowdoku cartridge. The v2
document remains historical evidence for a 9×9 numeric-Sudoku implementation
that Stage 0 proved was the wrong target. Classic `sudoku` keeps its own
numeric implementation and presentation.

## Frozen mechanics and claim boundary

The renderer consumes the independent `MeowdokuModel` snapshot. It does not
decide whether a cat is correct, remove hearts, calculate exclusions, detect
completion, or recover checkpoints. The frozen slice is one cat per row,
column, and colored region; cats cannot touch diagonally; wrong guesses consume
one of three hearts. First-party facts and unresolved reference behavior are in
`docs/replica/meowdoku-v3/claim-ledger.md`.

The exact single-tap/X-mark algorithm, question-cell semantics, original level
data, terminal choreography, and motion timing remain unclaimed. This product
uses clearly labeled independent decisions for those gaps.

## Conservative pillars

1. **The board is a cat-stationery hero object.** A stable frame must show
   notebook contact shadow, paper body, plum edge, top highlight, cat-ear tabs,
   binding rings, and quiet stationery props before any event plays.
2. **Regions and cats remain the first read.** Each region has a tactile pastel
   body plus explicit dark seams and a tiny pattern family, so region structure
   is not color-only. Cats are code-native faces with contact, body, edge,
   highlight, facial details, and a gold given marker.
3. **Feedback speaks the puzzle’s semantics.** Selection is pencil-corner
   intent; manual/derived X marks have different construction; a correct cat
   receives a local felt-paw stamp; a mistake tears the exact cell and removes
   a visible heart; zero hearts breaks one large heart; completion gathers the
   authored cats around the GAG paw reward. This is not a transplanted merge
   game’s rigid four-step recipe.

Anti-pillars: numeric keypad residue, generic neon particles, hue-only region
boundaries, a toast as the sole consequence, fake cats or rules baked into a
generated plate, and constant camera shake.

## Stable object and state grammar

| Runtime role | Stable construction | State distinction |
|---|---|---|
| Region tile | contact shadow → pastel paper body → plum seam → top edge light → region micro-pattern | thick boundaries remain legible without hue |
| Cat | soft contact shadow → ear/head silhouette → fur body → plum edge → forehead highlight → eyes/nose/whiskers | dark/cream fur variation is decorative; position is authoritative |
| Given cat | ordinary cat plus gold arc and ribbon corner | immutable without relying on color |
| Manual X | plum stitched cross with four endpoint knots | player-authored exclusion |
| Derived X | smaller cream cross with dark contact line | rule-derived exclusion |
| Hearts | three stable constructed heart silhouettes | filled/empty body, not a transient toast |
| GAG paw | header and footer identity sticker | stable and ordinary visibility, plus local correct-cat stamp and completion/result hero |

The inherited `meowdoku_stationery_v1.webp` remains a quiet environmental
plate. It contains no playable board, rule text, cat state, buttons, or score.

## Semantic feedback

| Event | Intent / consequence / settle | Channels |
|---|---|---|
| Select | one tile compresses and receives pencil corners; no rule state changes | paper click, 4 ms haptic, no shake |
| Mark / unmark | stitched X appears or erases on that tile | small local line response, short label below board |
| Correct cat | authored cat lands; a 34–46 px GAG paw stamp appears locally, then exposes the cat and derived X marks | felt/paper confirmation, short haptic, no global camera requirement |
| Wrong cat | cats and marks remain unchanged; the attempted tile shakes and receives three claw tears; one stable heart empties | correction scratch, short patterned haptic, bounded local shake |
| Hearts exhausted | board locks, a constructed heart breaks at board center, then a dedicated retry card appears | stronger but bounded haptic/camera, loss-specific copy |
| Completion | final cat lands before the board receives a gold wash, expanding rings, 92–126 px GAG paw, dedicated audio, and result card | peak paw/chime audio, completion cadence, result after the authoritative board remains readable |

Importance values passed to the shared effect envelope remain an implementation
detail for amplitude/cap compatibility. They do not redefine the semantic table
above.

## Reduced-effects path

`OFFLINE_GAMES_REDUCED_EFFECTS=1` or Web `prefers-reduced-motion: reduce`
disables catalog camera shake and transient catalog particles for Meowdoku,
collapses cell/paw amplitude, reduces haptics to one short pulse, and bypasses
the result-delay envelope. Cats, X marks, emptied hearts, lock state, completion,
and result copy remain unchanged and fully readable.

## GAG reuse decision

HOME-WSL GAG was rechecked live through
`https://desktop-youyuan-wsl.tail17a64.ts.net:11443/mcp`. It reported no GPU and
no main-service PyTorch, while Gemini, Fal, OpenRouter, ElevenLabs, Remove.bg,
and Codex providers were available in pure-API mode. Semantic search returned
the existing cat-paw derivative first and the exact generated completion-audio
master first when queried by stable name.

There is no uncovered visual or audio role that justifies more generation:
code-native cats must carry rule state, while the existing GAG paw already owns
stable identity, ordinary correct-cat feedback, completion, and result. The
existing audio owns completion only. No old asset was relabeled and no source
master was added to the repository. Full queries, rejections, prompts,
transforms, source hashes, runtime hashes, and live references are in
`meowdoku-v3.gag-asset-ledger.json`.

## Acceptance

- `tools/meowdoku_model_smoke.gd`: renderer-free rules, validity, uniqueness,
  failure/restart/recovery.
- `tools/meowdoku_integration_smoke.gd`: pointer/touch/keyboard parity and
  classic Sudoku non-regression.
- `tools/meowdoku_art_smoke.gd`: stable GAG, ordinary/peak routes, semantic
  events, CJK role, given/mark/error/loss/completion, reduced effects.
- `tools/meowdoku_visual_audit.gd`: stable, intent, mark, cat, error, loss,
  continuous 30-frame completion, result, and reduced-effects captures.
- `tools/meowdoku_performance_audit.gd`: 180-frame busy completion regression.
- `tools/meowdoku_web_acceptance.py`: real Chrome ready, headers/PCK transfer,
  actual pointer actions, keyboard erase/restart, reload recovery, failure,
  completion, and runtime-error gate.
