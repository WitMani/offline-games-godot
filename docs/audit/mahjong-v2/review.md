# Vita Mahjong v2 acceptance review

Result: **feature, native and clean Web acceptance PASS**. This slice changes Mahjong
presentation only. The fixed 20-tile order, hit regions, selection and
deselection behavior, mismatch mutation, pair legality, removed indices,
`+50` score, move count and terminal condition remain frozen. Tile Club is not
included in this release.

## What is visibly different

- The former flat rounded rectangles are now tactile ivory ceramic pieces with
  jade contact backs, bevels, pearly highlights and a bamboo signature. The GAG
  hero component is visible on all 20 tiles in the untouched opening board,
  not hidden in a win screen.
- Winds, dragons and pips remain live code and use the bundled font roles. No
  generated Chinese, pseudo-glyphs or baked gameplay text entered the build.
- Selection lifts and scales the chosen real tile. A mismatch counter-shakes
  both conflicting pieces and crosses them in red. A legal pair sends both real
  tile bodies toward their midpoint before contact and dissolve.
- Final clear reuses the truthful final pair motion, adds the strongest bounded
  shake/haptic, a wider eight-petal gold-jade bloom, and a dedicated ivory
  teahouse result plaque. There is intentionally no fake grade-three milestone:
  this mechanic has no authentic mid-run event to justify one.

## Real GAG use

The HOME-WSL GAG MCP ran in pure-API mode. Semantic search first rejected
generic VFX rings, card chrome, an arrow, ambient music, accept/coin/warning
sounds and fruit audio. fal.ai generated two blank-tile candidates; the first
was rejected because its key-fret ornament resembled an invented glyph. The
selected blank ivory/jade tile was background-removed and tightly trimmed.
ElevenLabs generated the selected tactile tile-clack plus jade resonance; GAG's
source QA warning was repaired by loudness normalization before runtime use.

Exact queries, candidate scores, prompts, IDs, provider/model data, source and
runtime hashes, transformations, QA and runtime references are in
`../../art-direction/mahjong-v2.gag-asset-ledger.json`. Source masters and
rejected candidates remain in the HOME-WSL archive. Only one generated PNG and
one derived OGG ship.

## Evidence-backed checks

- `MAHJONG_ART_SMOKE=116 PASS`: exact initial order, select/deselect, mismatch,
  routine pair, removed-tile inertness, final clear, score/move/mistake/status
  mutations, semantic grade/label/font roles, exact GAG hashes and GAG sound
  routing.
- Shared-router regressions: Sudoku 103, Meowdoku 88, Solitaire 67 and TriPeaks
  62 — all PASS. Whole collection: rules 6, catalog art 10, font coverage 60,
  font subset 3,874 required glyphs, covers 14, home buttons 14 and all games
  14 — all PASS.
- Visual audit: 18 matched 540×960 candidate frames across stable, selection,
  mismatch, ordinary pair, terminal clear and result, paired with two original
  baseline frames. A 36-frame / 30 fps continuous clear sequence preserves the
  complete impact-to-result transition.
- llvmpipe traces: stable 120 frames average 7.090 ms, p95 8.483 ms, max
  10.824 ms; grade-4 busy case 180 frames average 7.845 ms, p95 10.472 ms,
  max 21.280 ms, with a six-effect cap. These are comparative software-renderer
  traces, not physical-device FPS claims.

The clean Git archive exported `index.1b6f0673a41c.pck` and the unchanged
`index.2b558bdb3c3a.wasm` engine. The PCK contains the selected GAG PNG, authored
SVG backing and GAG OGG; source-master identifiers and Tile Club GAG paths are
absent. Fresh Chromium loaded in 1.630 seconds with one canvas, no probe error,
console error, request failure or bad response. It entered Mahjong and performed
one real pair: removed indices became `[0, 10]`, score `0→50`, moves `0→1`, and
status remained `playing`.

## Exact deployed artifact

- Release: `20260820T131532Z-f68621696ea9`
- PCK: `index.f68621696ea9.pck`, SHA-256
  `f68621696ea93b9072dd7d0cfd881098cb44c3d89541e2ff64935a7fdf960afb`
- Engine: `index.2b558bdb3c3a.wasm`, SHA-256
  `2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137`
- Both immutable artifacts return HTTP 200 with gzip and long-lived immutable
  caching. The deployed PCK content scan passed, and the prior Sudoku pack
  `index.3d190f988def.pck` remains available through the atomic switch.

Fresh remote Chromium loaded this exact Aliyun release in a secure context,
entered Mahjong, and paired the matching East tiles at indices 0 and 10. The
removed list became `[0, 10]`, score `0→50`, moves `0→1`, selected returned to
`-1`, and status stayed `playing`. Console errors, failed requests and bad
responses: 0. Cold EC2-to-Aliyun ready time was 220.57 seconds.

Primary evidence:

- `candidate/evidence.json`
- `candidate/performance.json`
- `candidate/continuous/mahjong-clear.webm`
- `candidate/web/local-web-acceptance.json`
- `candidate/web/aliyun-web-acceptance.json`
- `gates.json`
- `stable-comparison.webp`
- `../../art-direction/mahjong-v2.gag-asset-ledger.json`
