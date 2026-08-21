# Meowdoku v3 acceptance probes

## Renderer-free mechanics gate

- Puzzle loading rejects non-square region grids, incorrect region counts,
  disconnected regions, invalid solutions, duplicate rows/columns/regions,
  diagonal-touching cats, and inconsistent given cats.
- Independently authored 5×5, 6×6, and 7×7 fixtures load deterministically and
  are solvable by their declared solutions.
- Selecting a valid cell changes only selection.
- A manual mark toggles on an empty mutable cell and never changes hearts or
  placed-cat count.
- A correct cat attempt places exactly one cat, clears a local manual mark, and
  updates derived exclusions.
- A wrong cat attempt changes no cat or mark state and removes exactly one of
  three hearts.
- A given cat cannot be marked, erased, or replaced.
- Erasing a non-given cat restores a legal playing state and recalculates
  exclusions.
- The third wrong attempt enters `lost`; further mutating actions are rejected.
- Placing the final correct cat enters `won` exactly once.
- Restart restores the same fixture, three hearts, initial givens, and no manual
  marks.
- A valid checkpoint round-trips board/selection/hearts/status; malformed or
  cross-puzzle checkpoints are rejected without partial mutation.

## Input/integration gate

- Mouse release and touch release route through the same cell action.
- A double mouse/touch action and Enter/C on the keyboard route through the same
  cat-attempt command.
- When a browser/touch stack emits the preliminary single action of a double
  gesture, that same-cell preview is rolled back before the cat attempt; it
  cannot leak an X mark or extra move into failure state.
- Arrow/WASD navigation clamps to the board; Space/X mark and Backspace/Delete
  erase route through the same commands as pointer controls.
- R uses the common deterministic restart path.
- The separate numeric `sudoku` cartridge retains its existing 9×9 behavior.

## Presentation/release gates after Stage 0

- Stable play shows colored regions, cat counter, three heart states, manual and
  derived X marks, selection, and immutable givens without relying on transient
  effects.
- Select/mark/cat/error/heart-loss/completion feedback uses event meaning, not a
  copied fixed grading table from a merge game.
- Reduced-effects mode preserves semantic state changes while reducing shake,
  particle count, and property-animation amplitude.
- Every dynamic Chinese label and fallback string passes assigned-font coverage.
- Full loop, consecutive-peak, busy-performance, and clean Web/PCK probes pass.
- A real browser trace proves ready state, pointer/keyboard actions, reload
  recovery, HTTP headers, and transferred fingerprinted PCK bytes.
