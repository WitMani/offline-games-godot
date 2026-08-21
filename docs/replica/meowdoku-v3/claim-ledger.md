# Meowdoku v3 claim ledger

Facts, measurements, inferences, and product decisions are deliberately kept
separate. A decision may make the independent slice usable; it is not evidence
about the reference.

| Claim | Kind | Confidence | Product consequence |
|---|---|---:|---|
| The selected target is Oakever package `com.oakever.meowdoku`, Android 1.14.0 | fact | high | The previous 9×9 number-Sudoku implementation is a target-identity contradiction and cannot pass Stage 0 |
| The reference blends Sudoku-style row/column constraints with region and Minesweeper-like deduction | fact | high | A dedicated renderer-free region-cat model replaces reuse of numeric Sudoku |
| Every colored region must contain exactly one cat | fact | high | Completion validates one cat per region |
| Every row and column must contain exactly one cat | fact | high | Completion validates both axes |
| Cats cannot touch, including diagonally | fact | high | A candidate cat is illegal when diagonally adjacent to another cat |
| A double-tap places a cat | fact | high | Pointer/touch integration distinguishes selection from cat placement |
| The player has three mistake chances and a wrong guess removes one heart | fact | high | Incorrect solution attempts decrement hearts without mutating cats |
| Official Android screenshots show 5×5 Level 1 with counters from `1/5` to `5/5` and three hearts | measurement | high | The first deterministic fixture and HUD use size five and a placed/required counter |
| Official Android screenshot 06 shows a 7×7 Level 24 board at `5/7` | measurement | high | The model must support variable square sizes; a deterministic 7×7 fixture is included |
| Later official imagery also depicts larger boards and `?` cells | measurement | high | Board sizing is data-driven; `?` semantics remain unimplemented and unclaimed |
| White X marks correspond to cells excluded from cat placement | inference | medium | The model exposes manual marks and rule-derived exclusions, but does not claim the exact reference auto-mark algorithm |
| A single action selects a cell; a second action on the same cell toggles an X; an explicit double-action atomically attempts a cat and supersedes its preliminary single event | decision | high | Touch/mouse/keyboard have deterministic, testable parity without presenting this exact single-action behavior as recovered fact |
| Correct cat placement is checked against an authored solution | decision supported by “wrong guess” rule | high | Wrong guesses can consume hearts while legal puzzle state remains unchanged |
| Empty cells sharing a row, column, region, or diagonal neighborhood with a placed cat render as derived X marks | decision | medium | Provides readable deduction feedback consistent with still imagery; exact automatic behavior remains outside the claim |
| Authored fixtures may contain immutable given cats | architecture decision | high | The model covers given-cell immutability and recovery even though the frozen early-level screenshots do not establish given-cat behavior |
| Arrow/WASD movement, Space/X mark, Enter/C cat, Backspace/Delete erase, and R restart are accessibility decisions | decision | high | Desktop/Web input parity is covered without claiming mobile-reference keyboard support |
| Loss locks board mutations until restart; restart restores the same deterministic fixture | decision | high | Failure/restart/recovery are testable despite absent first-party terminal-flow footage |

## Unknowns that remain outside the claim boundary

- Target APK/build digest and serialized level data.
- Whether a single tap toggles an X, only selects, or uses another gesture.
- Whether X marks are automatic, manual, or a mixture in Android 1.14.0.
- Exact meaning and behavior of `?` cells.
- Exact heart-loss timing, haptic, sound, shake, and error recovery sequence.
- Exact loss screen, restart confirmation, and checkpoint persistence behavior.
- Exact Clear, Locate, Hint, and Coordinates behavior.
- Exact progression/generation rules and official 6×6 topology.
- Exact motion curves and timing; no first-party gameplay recording was found.
