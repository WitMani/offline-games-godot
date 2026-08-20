# Sudoku v2 acceptance review

Result: **PASS**. This release changes Sudoku presentation only. The givens,
solution, immutable-cell rule, input coordinates, move/mistake mutations,
completion check, and score formula remain frozen. Meowdoku and all fourteen
catalog entries pass regression.

## What is visibly different

- The GAG brass compass and crossed indigo pencils are visible in the ordinary
  game header before any action. They return as a 76 px 3×3-block stamp, a
  122 px full-board ceremony, and the result-card seal; this is not a hidden
  victory-only asset.
- The former generic dark control shell and flat spreadsheet have become an
  architect's drafting folio: layered ivory paper, slate grid, brass
  registration corners, alternating block stock, printed-given versus entered
  digit hierarchy, and warm paper keycaps.
- The feedback ladder now has different semantic silhouettes. Selection is a
  quiet press/focus; correct input scales and underlines its digit; erase uses a
  graphite mark; error shakes the cell and draws a red-pencil correction;
  3×3 completion washes the local block and stamps it; full completion adds the
  board-wide compass ceremony, strongest bounded haptic, authored GAG sound,
  and matching paper result card.

## Real GAG use

HOME-WSL `game-assets-generator 1.29.0` ran in pure-API mode. Semantic searches
first rejected generic project icons, a badge/ring, sword audio, ambient music,
and warning audio. Gemini generated the selected drafting medallion, Remove.bg
removed and trimmed its background, and ElevenLabs generated the selected
pencil/brass/two-note completion cue. Exact prompts, provider/model names,
rejected candidates, source/runtime hashes, derivation, and runtime references
are in `../../art-direction/sudoku-v2.gag-asset-ledger.json`. Source masters
remain in the HOME-WSL GAG archive; the repository and shipped PCK contain only
the two derived runtime resources.

## Evidence-backed checks

- `SUDOKU_PRESENTATION_SMOKE=103 PASS`, including immutable givens, exact move,
  mistake, score and completion mutations, semantic grade/label/font roles,
  GAG hashes, and GAG audio routing. Meowdoku regression: 88 PASS.
- Whole collection: rules 6, catalog art 10, font coverage 58, font subset 3874,
  covers 14, home buttons 14 and all games 14 — all PASS. Solitaire 67 and
  TriPeaks 62 also pass because the shared event router was touched.
- Visual audit: 24 matched 540×960 frames across stable, selection, correct,
  erase, error, block, board completion, and result states, plus a 36-frame
  continuous completion sequence. Textured-plate digits and CJK copy remain
  readable; generated pixels contain no text.
- llvmpipe busy-completion trace over 180 frames: average 26.633 ms, p95 34.214
  ms, max 40.650 ms, with a 12-effect cap. This is a bounded comparative
  software-renderer trace, not a physical-device FPS claim.

## Exact deployed artifact

- Release: `20260820T124706Z-3d190f988def`
- PCK: `index.3d190f988def.pck`, SHA-256
  `3d190f988defaf44ab3753c8ed8ce0f06a895b8779482aa7433ccec80e80b9bf`
- Engine: `index.2b558bdb3c3a.wasm`, SHA-256
  `2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137`
- Both immutable artifacts return HTTP 200 with gzip and long-lived immutable
  caching. The deployed PCK contains the two Sudoku GAG runtime paths and no
  source-master identifiers. Previous `index.ec1636cfbd9b.pck` remains present
  across the atomic switch.

Fresh Chromium loaded the exact Aliyun release in a secure context, entered
`sudoku`, selected row 1 column 3, and entered the correct digit 4. The target
changed `0→4`, moves `0→1`, mistakes stayed `0`, and status stayed `playing`.
Console errors: 0. Request failures: 0. Cold EC2-to-Aliyun ready time was
199.08 seconds.

Primary evidence:

- `candidate/web/aliyun-web-acceptance.json`
- `candidate/web/sudoku-aliyun-stable.png`
- `candidate/web/sudoku-aliyun-after-correct.png`
- `candidate/evidence.json`
- `candidate/performance.json`
- `../../art-direction/sudoku-v2.gag-asset-ledger.json`

