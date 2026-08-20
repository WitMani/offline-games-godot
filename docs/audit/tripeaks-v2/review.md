# TriPeaks v2 acceptance review

Result: **PASS**. This release changes TriPeaks presentation only. Its tableau,
locking, adjacency, stock, scoring, streak and completion transitions remain
frozen; the shared playing-card helpers also pass the Solitaire regression.

## What is visibly different

- The GAG moon/three-peak card back is not hidden behind a rare win. Six copies
  are visible on the opening board: five locked tableau cards and the stock.
- The table is now a twilight mountain stage. Locked cards use a brass lock
  band, available cards get warm footlights, and cleared slots become route
  markers without changing hit regions or legality.
- Deal and accept actions animate the actual card between authoritative source
  and destination. Locked and non-adjacent rejection remain object-local.
- Grade 1 uses a teal single-ridge response; a long streak grows into a gold
  three-peak crown with a four-step meter, stronger haptic/shake and the full
  GAG two-note summit cadence. Five/ten-card milestones and terminal clear use
  distinct semantic silhouettes.

## Evidence-backed checks

- `TRIPEAKS_PRESENTATION_SMOKE=62 PASS` and `SOLITAIRE_PRESENTATION_SMOKE=67
  PASS`, including frozen state transitions, four animation phases, exact GAG
  paths, audio routing and font roles.
- Whole collection: rules 6, catalog art 10, font coverage 56, font subset 3874,
  covers 14, home buttons 14 and all games 14 — all PASS.
- Visual audit: 29 matched 540×960 frames plus a 36-frame continuous grade-four
  streak. The online textured plate retains readable ranks, suits, labels,
  locked backs and target hierarchy; no generated text is used.
- llvmpipe trace: average 12.107 ms, p95 15.495 ms, max 20.458 ms over 180
  frames. This is a comparative software-renderer trace, not a device FPS claim.

## Exact deployed artifact

- Release: `20260820T122024Z-ec1636cfbd9b`
- PCK: `index.ec1636cfbd9b.pck`, SHA-256
  `ec1636cfbd9b64561e45766572292b6f6bc0b86f237e9c672085bede6dbd5600`
- Engine: `index.2b558bdb3c3a.wasm`, SHA-256
  `2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137`
- The deployed PCK contains both real TriPeaks GAG runtime paths. The previous
  `index.5f5d3807cf84.pck` remains available across the atomic switch.

Fresh Chromium loaded the exact release in a secure context with WebAssembly
and one canvas, entered `tripeaks`, then performed two real actions: deal changed
current `7→Q`, stock `12→11`, moves `0→1`; accepting the exposed K changed
current `Q→K`, removed `[ ]→[10]`, score `0→30`, streak `0→1`, moves `1→2`.
Console errors: 0. Request failures: 0. Cold EC2-to-Aliyun ready time was
236.862 seconds; SwiftShader emitted only audit-side ReadPixels performance
warnings during screenshots.

Primary evidence:

- `candidate/web/aliyun-web-acceptance.json`
- `candidate/web/tripeaks-aliyun-stable.png`
- `candidate/web/tripeaks-aliyun-after-streak.png`
- `candidate/evidence.json`
- `candidate/performance.json`
- `../../art-direction/tripeaks-v2.gag-asset-ledger.json`
