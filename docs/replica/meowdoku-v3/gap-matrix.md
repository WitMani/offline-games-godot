# Meowdoku v3 Stage 0 gap matrix

| Area | Baseline at `3e561fb3` | Required slice | Stage 0 status |
|---|---|---|---|
| Target identity | Traditional 9×9 number Sudoku relabeled “Meowdoku” | Oakever region-cat logic puzzle | Contradiction confirmed; repair authorized |
| Core constraints | Digits 1–9; row/column/3×3 blocks | One cat per row/column/colored region; no diagonal touch | Implemented; renderer-free probe passes |
| Board topology | Fixed 9×9 | Data-driven 5×5/6×6/7×7 authored fixtures | Implemented; each fixture validates as unique under its givens |
| Input | Select cell then numeric keypad 1–9 | Select/mark, double-action cat placement, erase, keyboard parity | Implemented; device-routing probe passes |
| Error/failure | Unlimited wrong numbers; numeric mistake count | Three hearts; wrong cat loses heart; zero hearts locks play | Implemented; failure lock probe passes |
| Completion | Every numeric hole filled | All required cats placed and all constraints valid | Implemented; completion probe passes |
| Restart/recovery | Generic restart only | Same deterministic puzzle restart plus validated checkpoint restore | Implemented; atomic recovery probe passes |
| Presentation | Cat skin over numeric Sudoku | Cat-stationery region board with hearts and cat counter | Locked until mechanics probes pass |
| Feedback | Numeric Sudoku block/correct/error grades | Semantic select/mark/cat/error/heart-loss/complete responses | Locked until mechanics probes pass |
| Existing GAG | Paw reward and completion audio are preloaded by wrong implementation | Proven provenance plus ordinary/stable runtime role | Re-audit after mechanics gate; no new production yet |
| CJK/fonts | Existing shared CJK font smoke | Every new dynamic Chinese string through assigned CJK/UI font | Gate after integration |
| Web release | Existing product Web artifact | Clean fingerprinted Web/PCK, real browser actions, recovery, ready/headers/transfer | Final gate only |

## Stage 0 exit condition

Stage 0 passed on 2026-08-20: `tools/meowdoku_model_smoke.gd` passes 49
renderer-free probes and `tools/meowdoku_integration_smoke.gd` passes 36
integration/input probes. `tools/rules_smoke.gd` also passes, including classic
Sudoku non-regression. Existing historical `meowdoku_art_smoke.gd` remains
evidence for the contradicted numeric game and does not count toward this exit;
it must be replaced before final presentation acceptance.
