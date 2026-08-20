# GB Snake v2 acceptance review

Result: **feature, native, clean Web and Aliyun acceptance PASS**. This slice
changes only GB Snake presentation. Its 15×23 grid, deterministic four-segment
opening, one queued cardinal turn, reverse/duplicate rejection, one-cell tick,
pending-growth rule, collision truth, target length 120 and restart contract
remain frozen. `snake_gb_model.gd` is byte-for-byte unchanged; Snakes
(`snake_io`) is outside this slice.

## What is visibly different

- The ordinary opening now contains three real GAG derivatives: the compact
  serpent head on the authoritative first body cell, the specimen lure on the
  authoritative food cell, and the aged-brass serpent field seal above the LCD.
  They are not cover art, an unused asset folder or a win-only reward.
- A legal turn starts at the pressed hardware D-pad, brackets the same generated
  head and settles only when the queued direction becomes authoritative. A
  rejected reverse kicks back the attempted D-pad and shows a short opposing
  head ghost while the queue and model remain unchanged.
- Routine forage is grade 2: the generated lure locks and contracts at the exact
  contact cell, the display scans that cell, one growth is queued and the short
  generated specimen cue is routed. The next tick visibly materializes the
  segment; presentation never awards growth itself.
- Every reached decade promotes the same semantic arc to grade 3 with a double
  scan, seal acknowledgement, restrained case response and a persistent
  telemetry notch. It does not reuse terminal confetti.
- Wall/self failure and length-120 success both reach grade 4 but communicate
  opposite meanings. Crash compresses and smears the head into the exact
  contact direction. Completion sweeps the full field record into the seal,
  plays the distinct generated completion cue and settles on the real length
  and move values.

Matched before/after plates are `stable-comparison.webp`,
`feedback-contact.webp` and `intensity-contact.webp`. The 33 candidate frames,
four continuous 30 fps sequences and authoritative state records are indexed in
`candidate/evidence.json`.

## Real GAG use

Production used the HOME-WSL GAG streamable-HTTP MCP in pure-API mode, without
local GPU or the main PyTorch service. Three Gemini semantic searches reviewed
45 image/audio candidates before new generation. Existing purple combat cobras,
generic ghosts, cyan icon sheets, explorer turtles, long music and generic
magic/coin/warning sounds were rejected as the wrong subject, scale, palette or
event role.

fal.ai generated the head, two lure attempts and the field seal through GAG.
The first lure was rejected for pseudo-writing and a plate-like silhouette. The
selected head arrived facing the wrong direction with excess neck; that defect
is recorded and repaired by deterministic crop/flip rather than hidden.
Remove.bg produced the three alpha sources, then bounded crop/scale/recolor
derivatives made them legible inside the existing monochrome display.

ElevenLabs produced specimen-collect and field-log-complete families through
GAG. Source loudness warnings are retained in the ledger; deterministic
compression/gain/limiting created the runtime OGG files and the exact Godot
routes are gated. This review claims waveform, duration, sample rate, channels,
loudness, peak, hash, import and routing QA; it does not claim subjective
listening by an audio-capable reviewer.

Exact searches, reviewed candidates, prompts, provider/model records, failures,
source and runtime hashes, transformations, first-visible beats and bindings are
in `../../art-direction/gb-snake-v2.gag-asset-ledger.json`. Source masters and
rejected generations remain in the HOME-WSL GAG archive. The repository and
deployed PCK contain exactly three PNG and two OGG runtime derivatives, with no
WAV master, rejected image or generated gameplay text.

## Evidence-backed checks

- Frozen gameplay passes: GB model 9, two-mode integration 5 and input routing 8.
  `GB_SNAKE_ART_CASES=141 PASS` gates exact dimensions, hashes, alpha, audio
  duration/import, model hash, stable bindings and all semantic feedback grades.
- Whole collection passes: rules 6, catalog art 10, font coverage 65, 3,879
  required subset glyphs, covers 14, home buttons 14 and all games 14.
- Visual audit covers five matched pre-change baselines and 33 540×960 candidate
  frames: stable, accepted turn, rejected reverse, forage, decade log, crash and
  target completion. Continuous evidence contains 18-frame turn, 20-frame
  forage, 26-frame milestone and 48-frame completion sequences at 30 fps.
- A 119-body-cell llvmpipe trace measured stable 120 frames at 5.145 ms average,
  6.286 ms p95 and 8.622 ms maximum. The grade-4 180-frame case measured 5.450
  ms average, 7.306 ms p95 and 11.527 ms maximum. These are comparative
  software-renderer traces, not a physical-device FPS claim.

The clean Git archive of feature commit `c9cd556` exported
`index.19482cf641d1.pck` with the unchanged
`index.2b558bdb3c3a.wasm` engine. Fresh local Chrome loaded in 1.684 seconds,
entered GB Snake and tapped the visible hardware Up D-pad. The sampled state
bridge observed the legal direction change from right to up, expected movement,
unchanged score/length and playing status. Probe, console, request and response
errors were all zero.

## Exact deployed artifact

- Release: `20260820T162259Z-06b02a654e47`
- PCK: `index.06b02a654e47.pck`, SHA-256
  `06b02a654e4746cdf5f259498d3aa18645a4a6cb2d7d0656877195019c5d45ff`
- Engine: `index.2b558bdb3c3a.wasm`, SHA-256
  `2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137`

The immutable PCK returns HTTP 200 gzip encoded. The atomic release retains the
preceding Arrow GO pack `index.94cdf396b261.pck`, so a stale HTML tab cannot lose
its referenced pack during refresh. A deployed-PCK scan found all five GB Snake
runtime derivatives and no source master.

Fresh remote Chrome loaded the exact Aliyun release in a secure context, entered
GB Snake and clicked the visible Up control. Direction changed `[1,0]→[0,-1]`,
the head advanced consistently with three sampled ticks, score and length stayed
at four, and status remained playing. Console errors, failed requests and bad
responses were all zero. Cold EC2-to-Aliyun ready time was 273.126 seconds; this
is network startup latency, not a frame-time measurement.

Play:

`https://aliyun-ecs.tail17a64.ts.net:8788/?release=20260820T162259Z-06b02a654e47`

Primary evidence:

- `candidate/evidence.json`
- `candidate/performance.json`
- `candidate/turn-response.webm`
- `candidate/forage-response.webm`
- `candidate/milestone-response.webm`
- `candidate/complete-response.webm`
- `candidate/web/local-web-acceptance.json`
- `candidate/web/aliyun-web-acceptance.json`
- `gates.json`
- `stable-comparison.webp`
- `feedback-contact.webp`
- `intensity-contact.webp`
- `../../art-direction/gb-snake-v2.gag-asset-ledger.json`
