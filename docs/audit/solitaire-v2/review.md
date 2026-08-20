# Solitaire v2 acceptance review

Result: **PASS**. This release changes Solitaire presentation only; its state
transitions and numeric rules remain frozen, and the prepared TriPeaks GAG
slice is not present in this deployment.

## What is visibly different

- The GAG emerald/brass botanical card back is not a rare reward asset. Eleven
  copies are visible in the opening board: one 72×100 stock card and ten 58×80
  face-down tableau cards.
- Face-up cards use warm paper, standard `♠ ♥ ♣ ♦` suits, quiet fibre rules and
  stronger rank/suit hierarchy. Selection lifts the source card and illuminates
  candidate columns without changing legality.
- Draw, tableau move and foundation placement animate the actual card between
  the authoritative source and destination. Empty-column rejection shakes only
  the rejected object. Grade 3 adds the four-card milestone; grade 4 adds the
  completion crown/leaf resolve, stronger patterned haptic and delayed modal.
- GAG's paper/felt/brass settle sound is actually routed to draw, recycle,
  move, foundation and win. The source loudness warning and runtime limiter
  repair are retained in the asset ledger.

## Evidence-backed checks

- `SOLITAIRE_PRESENTATION_SMOKE=67 PASS`, including frozen stock/tableau/score,
  four animation phases, exact GAG paths, actual audio routing and font roles.
- Whole collection: rules 6, catalog art 10, font coverage 56, font subset 3874,
  covers 14, home buttons 14 and all games 14 — all PASS.
- Visual audit: 21 matched 540×960 frames plus a 36-frame continuous peak.
  Final textured online plate retains readable faces, backs, labels and target
  outlines; no generated text is used.
- llvmpipe trace: average 11.588 ms, p95 14.052 ms, max 16.751 ms over 180
  frames. This is a comparative software-renderer trace, not a device FPS claim.

## Exact deployed artifact

- Release: `20260820T115619Z-5f5d3807cf84`
- PCK: `index.5f5d3807cf84.pck`, SHA-256
  `5f5d3807cf84264b9c696554a86913b0dc38d8c95b026d4b7a84b4c5003a72a2`
- Engine: `index.2b558bdb3c3a.wasm`, SHA-256
  `2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137`
- The deployed PCK was inspected and contains both real GAG runtime paths. The
  previous `index.be40306deae5.pck` remains available across the atomic switch.

Chromium loaded the exact release in a secure context with WebAssembly and one
canvas, entered `solitaire`, then clicked `摸牌`: stock `24→23`, waste `0→1`,
moves `0→1`. Console errors: 0. Request failures: 0. Cold EC2-to-Aliyun ready
time was 216.055 seconds; SwiftShader emitted only audit-side ReadPixels
performance warnings during screenshots.

Primary evidence:

- `candidate/web/aliyun-web-acceptance.json`
- `candidate/web/solitaire-aliyun-stable.png`
- `candidate/web/solitaire-aliyun-after-draw.png`
- `candidate/evidence.json`
- `candidate/performance.json`
- `../../art-direction/solitaire-v2.gag-asset-ledger.json`
