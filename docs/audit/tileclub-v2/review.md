# Tile Club v2 acceptance review

Result: **feature, native and clean Web acceptance PASS**. This slice changes
Tile Club presentation only. The 7×7 source board, deterministic shuffle, tap
contract, source removal, tray append order, three-equal removal, `+100` score,
move count, seven-slot loss and empty-board win remain frozen. Mahjong and the
other catalog games are not part of this release.

## What is visibly different

- The former flat colored glyph squares are now 48 tactile cocoa-felt keepsakes
  with cream piping and distinct leaf, moon, berry, star, flower, shell and
  crystal silhouettes. The GAG families fill the untouched opening board; they
  are not hidden in a rare reward screen.
- Collection moves the actual selected patch to its exact tray destination.
  Five occupied slots tighten the tray at grade 2; six produce a stronger
  staggered warning at grade 3. The thresholds reflect real remaining capacity.
- An ordinary triple gathers the three removed patch bodies and cinches them
  with a thread seal before the empty tray settles. Full-tray failure instead
  counter-kicks all occupied slots under a snapped-thread frame. Terminal clear
  expands the truthful final triple into a stitched rosette and dedicated
  sampler plaque.
- Dynamic Chinese and numbers stay live and use bundled font roles. Generated
  pixels contain no gameplay copy or pseudo-glyphs.

## Real GAG use

The HOME-WSL GAG MCP ran in pure-API mode. Gemini semantic search first rejected
a generic reward badge, unrelated card/conquest UI, props and characters, then
rejected music, magic, slash, coin and fruit sounds. fal.ai generated a badge
atlas; six cells passed silhouette review while duplicate moons/flowers and an
unreadable shell were rejected. A second fal.ai generation repaired the shell,
and Remove.bg/crop produced the two runtime PNGs. ElevenLabs generated a
felt-pop, thread-cinch and wooden-button cue. Its loudness-only source warning
was repaired before the runtime OGG; the derived file measures -16.85 LUFS and
-1.65 dBTP.

Exact queries, candidates, rejection reasons, prompts, IDs, provider/model data,
hashes, selected atlas regions, derivations and runtime references are in
`../../art-direction/tileclub-v2.gag-asset-ledger.json`. Source masters and
rejected candidates remain in the HOME-WSL archive. Only two PNG derivatives
and one OGG ship.

## Evidence-backed checks

- `TILECLUB_ART_SMOKE=223 PASS`: initial 49-cell/triple-count contract, single
  open slot, inert empty/out-of-bounds inputs, collect, risk-5, risk-6, ordinary
  match, full tray, both final-clear paths, exact score/move/status mutations,
  semantic grade/label/font roles, atlas regions, hashes and GAG audio routing.
- Shared regressions: Mahjong 116, Sudoku 103, Meowdoku 88, Solitaire 67,
  TriPeaks 62, merge-2048 7, merge-2248 integration/model 10/10 and Watermelon
  9 — all PASS. Whole collection: rules 6, catalog art 10, font coverage 65,
  font subset 3,875 required glyphs, covers 14, home buttons 14 and all games 14
  — all PASS.
- Visual audit: 29 matched 540×960 candidate frames across stable, collect,
  risk-5, risk-6, triple, terminal failure, terminal clear and both result
  states, paired with two pre-change baselines. Two 42-frame / 30 fps recordings
  preserve the complete clear and full-tray arcs.
- llvmpipe traces: stable 120 frames average 7.186 ms, p95 9.774 ms, max
  10.695 ms; grade-4 busy case 180 frames average 7.546 ms, p95 9.391 ms, max
  11.117 ms, with a six-effect cap. These are comparative software-renderer
  traces, not physical-device FPS claims.

The clean Git archive exported `index.93b9dac4d052.pck` and the unchanged
`index.2b558bdb3c3a.wasm` engine. The PCK contains all three Tile Club GAG
runtime derivatives and excludes its source masters and rejected candidates.
Fresh Chromium loaded in 1.272 seconds with one canvas, a secure context, no
probe error, console error, failed request or bad response. It entered Tile
Club, read the deterministic board, selected the first non-empty patch at index
1 and verified that tile `1` became `0`, tray `[]→[1]`, moves `0→1`, score stayed
`0`, and status remained `playing`.

Aliyun deployment and the second fresh-browser action are the remaining release
gate; they will be appended to this review after the atomic switch.

Primary evidence:

- `candidate/evidence.json`
- `candidate/performance.json`
- `candidate/continuous/tileclub-clear.webm`
- `candidate/continuous/tileclub-full.webm`
- `candidate/web/local-web-acceptance.json`
- `gates.json`
- `stable-comparison.webp`
- `collect-comparison.webp`
- `../../art-direction/tileclub-v2.gag-asset-ledger.json`
