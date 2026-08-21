# Sudoku v3 Stage-0 gap matrix

| Area | Starting state at `3e561fb` | Status | Evidence | Required next action |
|---|---|---|---|---|
| Identity | Catalog item maps to Jindoblu Sudoku; exact iOS 3.14.1 listing locked. | aligned | target manifest | preserve mapping |
| Topology | 9×9 / 3×3 layout matches the first-party still. | aligned | reference and baseline frames | freeze layout semantics |
| Puzzle truth | Starting fixed puzzle had 3 solutions while code accepted only one. Candidate generates a deterministic 36-given puzzle and retains removals only while the solver count is exactly one. | pass | `sudoku_model_smoke.gd` across four seeds; `ee75d92` | preserve renderer-free gate |
| Given | Model and runtime reject writes to givens without changing board, moves, or mistakes. | pass | `SUDOKU_MODEL_SMOKE`, `SUDOKU_RUNTIME_SMOKE` | preserve |
| Select/place/erase | Model owns mutations; pointer/button and keyboard paths route through the same adapter. | pass | runtime smoke | preserve input parity |
| Error | A wrong digit is retained and marked in model/runtime state without inventing a terminal heart rule. | pass | model/runtime smoke; matched and continuous visual evidence; real-browser retained-error and reload proof | preserve red digit plus crossed proof mark in stable frames |
| Notes | Bounded candidate-note behavior, toggle UI, keyboard input, peer cleanup, and undo are implemented. | pass | model/runtime smoke; matched note impact/stable frames | preserve live 3×3 candidate layout and CJK-safe tool state |
| Hint | Selected-cell hint consumes one of three hints and is undoable. This remains a local decision, not an exact-reference claim. | pass-local-decision | model/runtime/presentation smoke; matched hint frames | do not promote detailed semantics to a reference fact |
| Undo | Bounded 128-entry model history is wired to touch and Ctrl/Cmd+Z. | pass-local-decision | model/runtime/presentation smoke; matched undo frames | do not promote undo depth to a reference fact |
| Completion | Completion requires board equality with an independently valid Sudoku solution. | pass | model, runtime, and presentation smoke | preserve |
| Restart | Explicit reset clears mutable state and recreates the same deterministic unique puzzle. | pass | runtime smoke; real-browser restart and post-restart reload | preserve |
| Recovery | Strict snapshot restore and Web `localStorage` binding exist; corrupt state is rejected. | pass | model/runtime smoke; real-browser wrong-state reload recovery | preserve schema/fingerprint validation |
| Input parity | Pointer selection/buttons and keyboard arrows, digits, erase, notes, hint, and undo reach the same model. | pass | runtime smoke | preserve in Web build |
| Art identity | Drafting folio and GAG compass are distinctive and ordinary-visible. | aligned | v2 stable runtime capture | reuse; do not generate another mascot |
| Expression | Selection, correct, note, hint, undo, retained/repeated error, block and full completion follow the drafting-object grammar; reduced-effects preserves state truth without transient effects. | pass | 30 matched frames; continuous error/completion clips; reduced-effects frame and browser state | preserve contextual hierarchy and effect cap |
| CJK/font | All new dynamic Chinese uses `UI_FONT`; source scan and shipped subset gate pass. | pass | `FONT_COVERAGE_SMOKE=65`; `FONT_SUBSET_GATE=PASS required=3879 bytes=1816916`; clean Web screenshots | preserve live text; no rasterized Chinese |
| Delivery | A clean archive of runtime commit `2b03aca` produced a fingerprinted Web/PCK bundle and passed local real-browser actions/reload, headers, ranges and complete transfers. | pass-local-only | `docs/audit/sudoku-v3/candidate/clean-export.json`; Web acceptance report/screenshots | no merge, push, deploy, or online-visible claim |

Final local-candidate result: `PASS`. Stage 0 first cleared mechanics at
`7f70019b1a6bbb689e0a03f8a60eaa42d744ef46`; presentation and local delivery
then cleared independently. This isolated branch is not merged, pushed,
deployed, or online-visible, and the available evidence still does not establish
the reference's exact heart/failure, score, detailed hint/undo/note, difficulty,
progression, or restart semantics.
