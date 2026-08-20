# Vita Mahjong v2 acceptance review

Result: **feature and native acceptance PASS**. This slice changes Mahjong
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

Clean archive Web export, PCK content scan, browser actual-action acceptance,
and exact Aliyun release fingerprints are recorded after this feature commit.

Primary evidence:

- `candidate/evidence.json`
- `candidate/performance.json`
- `candidate/continuous/mahjong-clear.webm`
- `stable-comparison.webp`
- `../../art-direction/mahjong-v2.gag-asset-ledger.json`
