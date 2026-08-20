# Arrow GO v2 acceptance review

Result: **feature, native, clean Web and Aliyun acceptance PASS**. This slice
changes Arrow GO presentation only. Its exact 9×9 board, player `[0,0]`, target
`[8,8]`, eight right-pointing columns, one down-pointing column, legal scoring,
wrong-direction and edge inertness, five-step cadence, terminal score/status and
restart contract remain frozen. Amaze GO and Amaze retain their own rules and
presentation.

## What is visibly different

- The untouched opening contains 81 GAG-generated indigo enamel wind sockets,
  the generated paper-wing courier at `[0,0]`, and the generated brass sky
  harbor at `[8,8]`. These are stable gameplay objects, not a rare reward or a
  decorative cover. Live code-native fins keep all arrow directions readable.
- A legal move carries the courier across the exact selected edge, leaves a
  coral airmail route and plays the short generated paper-wing/brass cue. Every
  fifth step promotes the route knot, rings, haptic rhythm and bounded camera
  response to grade 2.
- A wrong-direction or edge attempt does not alter authoritative state. The
  same courier recoils locally while crosswind bars identify the attempted
  direction; generic screen-center confetti is not used as rejection feedback.
- The final down move docks the courier into the harbor, expands a grade-4
  harbor iris/ray sequence, uses the separate generated dock cue, and resolves
  to the dedicated `航信送达` result plaque. Live CJK copy is never baked into
  generated art.

The before/after plates are `stable-comparison.webp` and
`step-comparison.webp`; the full matched sequences and authoritative state
records are in `candidate/evidence.json`.

## Real GAG use

The HOME-WSL GAG MCP ran in pure-API mode without local GPU or PyTorch. Three
semantic searches first rejected pink humanoid sprite sheets, pseudo-glyph
compasses, an insect enemy, generic card frames, a gear-marked 2048 tile,
opaque audio hashes, warnings and long-form music. Fresh fal.ai generation then
produced the blank wind socket, paper courier and harbor through GAG. Remove.bg,
GAG auto-trim and deterministic image transforms produced four runtime PNGs.
The first courier generation was rejected for an upward silhouette and baked
stars; the selected no-symbol replacement was deterministically rotated to
authoritative right/down variants rather than silently accepted.

ElevenLabs generated the frequent kite-step cue and the distinct harbor-dock
cue. The source loudness warnings and the dock normalization are recorded
without omission. This review claims waveform, loudness, import, hash and
runtime-routing QA; it does not claim subjective listening by an audio-capable
reviewer.

Exact queries, candidates, prompts, provider/model data, source and runtime
hashes, transformations and references are in
`../../art-direction/arrow-go-v2.gag-asset-ledger.json`. Source masters and
rejected generations remain only in the HOME-WSL GAG archive. The repository
and deployed PCK contain four PNG and two OGG runtime derivatives, with no WAV
master, rejected image or generated gameplay text.

## Evidence-backed checks

- `ARROW_GO_MECHANICS_SMOKE=175 PASS` freezes opening state, exact arrows,
  legal/wrong/edge movement, scores, move and streak counters, five-step grade,
  completion and restart.
- `ARROW_GO_ART_SMOKE=189 PASS` gates exact hashes, dimensions, alpha and audio
  lengths; stable bindings; ordinary step, waypoint, wrong-direction, edge and
  completion feedback; live CJK font; GAG audio routing; and shared path-game
  isolation.
- Shared regressions all pass: Amaze GO mechanics/art 61/176, Tile Club 223,
  Mahjong 116, Sudoku 103, Meowdoku 88, Solitaire 67, TriPeaks 62,
  merge-2048 7, merge-2248 integration/model 10/10 and Watermelon 9. Whole
  collection: rules 6, catalog art 10, font coverage 65, 3,879 required subset
  glyphs, covers 14, home buttons 14 and all games 14.
- Visual audit: 22 matched 540×960 candidate frames across stable, ordinary
  step, wrong-direction rejection, five-step waypoint, terminal dock and result
  states, paired with two pre-change baselines. The 20-frame step and 42-frame
  dock WebMs preserve continuous timing at 30 fps.
- llvmpipe traces: stable 120 frames average 13.962 ms, p95 16.091 ms, max
  20.435 ms; grade-4 busy case 180 frames average 14.933 ms, p95 17.886 ms,
  max 20.623 ms. These are comparative software-renderer traces, not a physical
  device FPS claim.

The clean Git archive of feature commit `6ef3161` exported
`index.1dcb0a3017d7.pck` with the unchanged
`index.2b558bdb3c3a.wasm` engine. Fresh local Chrome loaded in 1.662 seconds,
entered Arrow GO and clicked the visible adjacent `[1,0]` cell: player
`[0,0]→[1,0]`, destination painted `false→true`, score `0→5`, moves `0→1`,
streak `0→1`, status playing. Probe, console, request and response errors were
all zero.

## Exact deployed artifact

- Release: `20260820T153322Z-94cdf396b261`
- PCK: `index.94cdf396b261.pck`, SHA-256
  `94cdf396b2614fb2b799b198f55d655299705690b4757d761499c23d1b2a1e66`
- Engine: `index.2b558bdb3c3a.wasm`, SHA-256
  `2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137`

The immutable PCK returns HTTP 200 both raw and gzip encoded. The atomic release
retains the preceding Amaze GO pack `index.8a91a10f0ccd.pck`, preventing stale
HTML from losing its referenced pack during refresh. A direct deployed-PCK scan
found all six Arrow GO runtime derivatives.

Fresh remote Chrome loaded the exact Aliyun release in a secure context, entered
Arrow GO, and performed the same adjacent-cell action with the exact expected
state delta. Console errors, failed requests and bad responses were all zero.
Cold EC2-to-Aliyun ready time was 247.678 seconds.

Play:

`https://aliyun-ecs.tail17a64.ts.net:8788/?release=20260820T153322Z-94cdf396b261`

Primary evidence:

- `candidate/evidence.json`
- `candidate/performance.json`
- `candidate/continuous/arrow-go-step.webm`
- `candidate/continuous/arrow-go-grade4-dock.webm`
- `candidate/web/local-web-acceptance.json`
- `candidate/web/aliyun-web-acceptance.json`
- `gates.json`
- `stable-comparison.webp`
- `step-comparison.webp`
- `../../art-direction/arrow-go-v2.gag-asset-ledger.json`
