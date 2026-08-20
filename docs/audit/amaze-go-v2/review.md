# Amaze GO v2 acceptance review

Result: **feature, native, clean Web and Aliyun acceptance PASS**. This release
changes Amaze GO presentation only. The deterministic 6×6 board, start and
target, wall dictionary, orthogonal input, `+5` legal-step score, move/streak
counters, wall/edge inertness, terminal `+100`, win rule and reset contract
remain frozen. Arrow GO and Amaze retain their existing rules and presentation.

## What is visibly different

- The untouched board now reads as a cyanotype survey table instead of a generic
  empty grid. A GAG-generated brass/cobalt clockwork surveyor is visible at
  `[0,0]`; a separate GAG-generated brass/coral destination beacon is visible at
  `[5,5]`. Neither asset is hidden behind a rare reward state.
- Every legal move carries the real surveyor across the exact edge, lays a pale
  drafting line and leaves an ordered coral/brass rivet. Five-step waypoints use
  grade-2 rings, haptics and camera response; the route remains visible after
  recovery.
- A blocked move does not decorate empty screen space: the surveyor recoils from
  the exact contacted raised-ruler segment while that segment changes material.
  Position, score, moves and route stay unchanged.
- The final legal edge aligns the surveyor with the beacon, expands a grade-4
  brass seal and bounded shake/haptic sequence, then reveals a dedicated paper
  route certificate using both GAG objects. All gameplay copy remains live text.

The before/after plates are `stable-comparison.webp` and
`step-comparison.webp`. The full four-phase sequences and state records are in
`candidate/evidence.json`.

## Real GAG use

The HOME-WSL GAG MCP ran in pure-API mode without local GPU or PyTorch. Gemini
semantic search first rejected character cards, logic badges, 2048 materials,
generic rings, coin/wand props and long-form music. The first fal.ai surveyor
generation was also rejected because it rendered prominent N/E/S/W letters.
The repaired fal.ai generation produced a no-text top-down clockwork rover; a
second fal.ai generation produced the destination beacon. Remove.bg and GAG
auto-trim yielded the two transparent runtime PNGs.

ElevenLabs generated a short brass-ratchet/ink-pin cue for every legal step and
a separate iris/wax/chime cue for terminal arrival. Source loudness and trailing
silence issues were repaired with bounded ffmpeg derivations before the runtime
OGGs. This review claims waveform, loudness, import, hash and runtime-routing
QA; it does not claim subjective listening by an audio-capable reviewer.

Exact queries, rejected candidates, prompts, provider/model data, source and
runtime hashes, derivations and references are in
`../../art-direction/amaze-go-v2.gag-asset-ledger.json`. Source masters and
rejected images remain only in the HOME-WSL GAG archive. The repository and PCK
contain two PNG and two OGG runtime derivatives, with no generated gameplay
text, WAV master or rejected candidate.

## Evidence-backed checks

- `AMAZE_GO_MECHANICS_SMOKE=61 PASS` freezes entry, exact walls, legal movement,
  adjacent/non-adjacent tap behavior, wall/edge rejection, five-step streak,
  terminal score/status and reset.
- `AMAZE_GO_ART_SMOKE=176 PASS` gates exact dimensions, alpha, SHA-256 and audio
  durations; opening signature bindings; ordered route; step, waypoint, wall,
  edge and completion object feedback; CJK font role; real GAG audio routing;
  and Arrow GO/Amaze isolation.
- Shared regressions all pass: Tile Club 223, Mahjong 116, Sudoku 103, Meowdoku
  88, Solitaire 67, TriPeaks 62, merge-2048 7, merge-2248 integration/model
  10/10 and Watermelon 9. Whole collection: rules 6, catalog art 10, font
  coverage 65, 3,877 required subset glyphs, covers 14, home buttons 14 and all
  games 14.
- Visual audit: 22 matched 540×960 candidate frames across stable, ordinary
  step, wall rejection, five-step waypoint, final arrival and result states,
  paired with two pre-change baselines. A 20-frame / 30 fps ordinary-step clip
  and 42-frame / 30 fps completion clip preserve continuous timing.
- llvmpipe traces: stable 120 frames average 9.750 ms, p95 12.092 ms, max
  15.368 ms; grade-4 busy case 180 frames average 10.386 ms, p95 13.107 ms,
  max 16.923 ms. These are comparative software-renderer traces, not a physical
  device FPS claim.

The clean Git archive of feature commit `ee2c6ce` exported
`index.5653beec85c6.pck` with the unchanged
`index.2b558bdb3c3a.wasm` engine. Fresh local Chrome loaded in 1.396 seconds
with one canvas and no probe/console/request errors. It entered Amaze GO and
clicked the visible adjacent `[1,0]` cell: player `[0,0]→[1,0]`, destination
painted `false→true`, score `0→5`, moves `0→1`, streak `0→1`, status playing.

## Exact deployed artifact

- Release: `20260820T143312Z-8a91a10f0ccd`
- PCK: `index.8a91a10f0ccd.pck`, SHA-256
  `8a91a10f0ccdb725ac1d09bde7dc1dcdf18a057708d74dc75ec5cfb3e4e799e1`
- Engine: `index.2b558bdb3c3a.wasm`, SHA-256
  `2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137`

Both immutable artifacts return HTTP 200 with gzip and year-long immutable
caching. The deployed PCK contains all four Amaze GO GAG runtime derivatives,
excludes its source masters/rejected candidates, and retains the prior Tile Club
pack `index.182852a0f846.pck` across the atomic switch.

Fresh remote Chrome loaded the exact Aliyun release in a secure context, entered
Amaze GO and performed the same visible adjacent-cell action. The exact state
delta matched local acceptance; console errors, failed requests and bad
responses were all zero. Cold EC2-to-Aliyun ready time was 261.619 seconds.

Play:

`https://aliyun-ecs.tail17a64.ts.net:8788/?release=20260820T143312Z-8a91a10f0ccd`

Primary evidence:

- `candidate/evidence.json`
- `candidate/performance.json`
- `candidate/continuous/amaze-go-step.webm`
- `candidate/continuous/amaze-go-complete.webm`
- `candidate/web/local-web-acceptance.json`
- `candidate/web/aliyun-web-acceptance.json`
- `gates.json`
- `stable-comparison.webp`
- `step-comparison.webp`
- `../../art-direction/amaze-go-v2.gag-asset-ledger.json`
