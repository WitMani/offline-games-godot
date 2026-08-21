# Sudoku v3 claim ledger

Types are deliberately separated. A `decision` is not evidence for a reference
`fact`; an older public capture is not silently upgraded to the current build.

| ID | Claim | Type | Evidence | Confidence | Consequence / probe | Status |
|---|---|---|---|---|---|---|
| SUD-REF-001 | App Store track 6448104157 is `Offline Games - No Wifi Games`, version 3.14.1, seller Jindoblu Limited. | fact | `itunes-lookup.json` | high | freeze target identity | verified |
| SUD-REF-002 | The first-party listing names Sudoku as an included brain game. | fact | App Store description and Google Play listing | high | map catalog `sudoku` to this target | verified |
| SUD-REF-003 | The current first-party screenshot shows a 9×9 grid with heavy 3×3 boundaries. | measurement | App Store iPhone/iPad screenshot | high | `SUD-MODEL-TOPOLOGY` | verified |
| SUD-REF-004 | Printed givens are dark, an entered value is blue, and the selected empty cell plus its row, column, and block are highlighted. | measurement | App Store screenshot | high | `SUD-UI-SELECTION` | verified |
| SUD-REF-005 | The visible tool surface contains Undo, Erase, Notes, Hint with count 3, digits 1–9, and three heart icons. | measurement | App Store screenshot | high | tool/input coverage | verified |
| SUD-REF-006 | Sticky notes are an explicitly shipped Sudoku feature by version 3.2.3 and remain in the 3.14.1 version lineage. | fact | App Store version history | high | notes are in scope | verified |
| SUD-OBS-001 | An older verified public player-run thumbnail shows correct entered digits in blue, a wrong entered digit in red, and a changed heart display. | measurement | `speedrun-maxresdefault.jpg`; run `ywx182pm` | medium | retain wrong-cell consequence; do not infer exact current life/failure semantics | verified |
| SUD-UNK-001 | Exact 3.14.1 score formula, heart depletion/failure rule, hint policy, undo depth, note conflict policy, puzzle progression, and restart prompt are not demonstrated by the available first-party stills. | fact | evidence inventory | high | remain explicit unknowns; no reference-fidelity claim for these details | open |
| SUD-RULE-001 | A Sudoku solution must contain digits 1–9 exactly once in every row, column, and 3×3 block. | decision | conventional Sudoku contract implied by product identity; independently probed | high | `SUD-MODEL-VALIDITY` | verified-local |
| SUD-RULE-002 | The bounded shipped puzzle must have exactly one solution so an alternative legal completion is never rejected. | decision | quality/fidelity safeguard; baseline counterexample | high | `SUD-MODEL-UNIQUE` | verified-local |
| SUD-RULE-003 | Givens are immutable; selected editable cells accept place/erase; completion requires the unique solved board. | inference + decision | visible given/entered distinction and standard contract | high | model probes | verified-local |
| SUD-RULE-004 | Notes toggle candidates in an editable empty cell; placing a final value clears that cell's notes and removes the value from peer notes. | decision | feature existence is fact; detailed behavior is not captured | medium | `SUD-MODEL-NOTES` | verified-local |
| SUD-RULE-005 | Hint reveals the selected cell's solution, consumes one of three bounded hints, and is undoable. | decision | current screenshot shows Hint count 3; exact behavior unknown | medium | `SUD-MODEL-HINT` | verified-local |
| SUD-RULE-006 | A wrong digit remains visibly marked, increments mistakes, but does not trigger a guessed terminal failure rule. | decision | older captured frame shows retained red digit; 3.14.1 life semantics unknown | medium | `SUD-MODEL-ERROR`; stable, continuous and browser proof | verified-local |
| SUD-RULE-007 | The Web build restores the last valid in-progress Sudoku snapshot; explicit restart replaces it with a fresh initial state. | decision | offline-first product requirement; reference recovery details unknown | medium | `SUD-MODEL-RECOVERY`; browser action/reload/restart | verified-local |
| SUD-BASE-001 | Baseline puzzle has 54 givens, 27 holes, and 3 legal solutions. | measurement | independent solution counter at starting HEAD | high | historical blocker resolved by `ee75d92` | resolved-candidate |
| SUD-BASE-002 | Baseline rejects every digit that differs from its single stored solution, even when another complete legal solution exists. | measurement | `main.gd::_classic_sudoku_place` plus SUD-BASE-001 | high | historical blocker resolved by `7f70019` | resolved-candidate |
| SUD-ART-001 | Existing HOME-WSL GAG compass reward is visible in the ordinary header and at block/full completion; its source/runtime hashes and route are already ledgered. | measurement | runtime capture, `sudoku-v2.gag-asset-ledger.json`, presenter bindings | high | reuse; no new character generation | verified |
| SUD-AUD-001 | Existing HOME-WSL GAG completion audio is bound only to the full-completion semantic event and has objective duration/loudness/peak evidence. | measurement | v2 GAG ledger and runtime binding | high | reuse; re-probe actual runtime event | verified |
| SUD-DEL-001 | Runtime commit `2b03aca` exports from a clean Git archive to a content-fingerprinted PCK/Web bundle whose runtime contains the Sudoku model and verified GAG visual/audio paths. | measurement | `candidate/clean-export.json`; PCK string probes | high | local delivery gate | verified-local |
| SUD-DEL-002 | Headless Chrome completed ready, correct entry, retained wrong entry, reload recovery, restart, post-restart reload, reduced-effects, full transfers and Range/header probes without logged runtime/request errors. | measurement | `candidate/web/local-web-acceptance.json` and five screenshots | high | browser gate | verified-local |
| SUD-REL-001 | This candidate has not been merged, pushed, deployed, or observed on the public Aliyun runtime. | fact | task boundary and isolated branch | high | prohibit online-visible wording | verified |

## Current claim boundary

The candidate may claim a locally proved, independently valid, uniquely solvable
Sudoku with given, selection, place/erase, retained errors, notes, hint, undo,
legal completion, reset, strict restore, pointer/keyboard adapter coverage,
object-level visual feedback, verified GAG reuse, clean fingerprinted export and
real-browser recovery. It may not claim that its unknown score, heart/failure,
detailed hint/undo/note, difficulty, restart or progression semantics exactly
reproduce version 3.14.1. It is an isolated local candidate, not a merged,
deployed or online-visible release.
