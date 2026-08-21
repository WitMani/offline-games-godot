# 2248 fidelity + candy-workshop runtime direction v4

## Decision

This is an **isolated reviewable candidate**, not an original-parity or public
release claim. Stage 0 (`docs/replica/merge2248/stage0-fidelity-v4.md`) proved
that the prior tree's 2048 terminal, bounded integer domain, fixed layout, lack
of undo and lack of persistence contradicted observed target behavior. Commit
`46cd36b1d36e2875c648848dabb09b9315e86705` corrects those hard gaps and adds
mechanics, input, persistence and reduced-effects gates.

The exact original chain transform, backtracking, refill distribution, undo
depth and loss/recovery behavior still lack a reproducible authorized action
trace. The candidate keeps those paths explicitly labelled compatibility
decisions. It must not be described as fully aligned with or visually superior
to the commercial original.

```text
Game: 2248 / Number Connect
Runtime: Godot 4.6, portrait 540 x 960, Web threadless export
Stage-0 evidence commit: b4fb321
Mechanics candidate commit: 46cd36b
Public review boundary: 2048 Balls
Merge / push / public deploy: not performed
```

## Conservative pillars

| Pillar | Production rule | Observable consequence |
|---|---|---|
| Endless confection ledger | 2048 is a milestone, not a finish; tile magnitude is stored as an exponent and score/all-time are exact arbitrary-length values | `2.36Z` tiles and `2,361E` score render without overflow; refresh restores the active run |
| Difficulty changes density | expose only evidence-backed Easy 5 x 8 and Hard 5 x 6 | the same 5-column language becomes denser or calmer without inventing names for uncertain 7/5-row modes |
| Tactile candy, live truth | GAG provides material and silhouette; code owns every number, rule state and result | all ordinary slots visibly use the candy family while extreme values remain exact live text |
| Difficulty earns response | grade is derived from authoritative chain length/result power; intensity grows through object, audio, haptic, camera and density channels | routine merges remain readable; grade 3/4 earn the hollow caramel showpiece and mastery layer |
| Accessibility preserves meaning | reduced motion changes presentation only | result, score, board, RNG and callout remain identical while shake, transforms, haptics and dense motion are removed |

Anti-pillars: generated numerals, reward-only GAG art, generic neon/magic VFX,
maximum feedback on routine merges, presentation-derived legality, scientific
notation drift, hidden source masters, and a fake 2048 victory.

Player fantasy: maintain a long-running candy recipe ledger, pull a clear path
through tactile molds, and earn a pastry-showpiece response when the connection
is genuinely difficult. Tone: warm, legible, playful and concise.

## Mechanics-facing implementation boundary

- Board cells store positive power-of-two exponents (`1` means `2`). This keeps
  tile state exact after ordinary signed integers would overflow.
- Score and all-time score use an exact binary bit array with deterministic
  decimal conversion. Target-style compact labels retain six visible
  coefficient digits, including the observed `224,575P` and `156,600T` forms.
- 2048 does not terminate play. The candidate continues to arbitrary powers and
  uses symbolic `2^N` only past the bounded decimal-rendering safety limit.
- Easy 5 x 8 and Hard 5 x 6 are the only exposed modes. The 7-row and 5-row
  mappings remain hidden and marked compatibility until evidence names them.
- One local undo restores the exact pre-transition board, score, status and RNG
  position while retaining all-time score. Ads/monetization are not reproduced.
- The versioned save restores board, exact score, all-time, move count, mode,
  status, RNG continuation and one undo state. Invalid schema, shape, powers,
  bits and RNG fields are rejected safely.
- Restart preserves all-time and selected evidence-backed mode. Mouse, touch and
  direct integration probes share the same authoritative action route.
- Equal-first, then same-or-next-power path extension; repeated-node rejection;
  sum-to-ceil-power result; adaptive refill; and no-pair terminal remain named
  compatibility behavior, not original facts.

## Preserved GAG material family

No new billable generation was needed for v4. The previously reviewed GAG v3
family remains byte-identical:

- four transparent candy token molds visible on ordinary board cells;
- one hollow caramel/cream burst used only for grade 3/4 impact;
- one short candy-merge sound on every legal release;
- one mastery layer on grade 3/4.

The original production route was HOME-WSL GAG semantic search, explicit
candidate rejection, fal.ai Flux Pro v1.1, Remove.bg derivation and ElevenLabs
sound generation. On 2026-08-20 the production HTTPS MCP was rechecked directly
and identified itself as `game-assets-generator 1.29.0`; its main service still
supports pure API operation without local GPU/PyTorch, with Gemini, fal,
ElevenLabs, Remove.bg and OpenRouter enabled. All two source images, five
transparent runtime sources and two selected WAV masters were re-hashed over
Tailscale SSH and match the historical ledger.

The historical search queries, rejected candidates, exact prompts, provider
models, source warnings and derivation details remain authoritative in
`merge2248-gag-v3.asset-ledger.json`. The v4 supplement records the current
service check and superseded mechanics hash without rewriting that history.

## Semantic feedback grammar

| Grade | Trigger examples | Normal presentation | Reduced presentation |
|---|---|---|---|
| 1 · 轻甜 | two-node routine result | short gather/pop, one ring family, light candy sound, 20 ms release haptic | exact result + static local ring + callout; no haptic/board motion |
| 2 · 连携 | three nodes or promoted result | wider ribbon cadence, stronger non-uniform pop, three-beat haptic | exact result + promoted callout, bounded 0.44 s effect |
| 3 · 超连携 | five nodes or high result | hollow GAG caramel burst, denser rings/crumbs, mastery audio and stronger shake | no generated moving burst/rings/crumbs; semantic grade remains explicit |
| 4 · 传奇配方 | eight nodes or major result | largest bounded recoil, two audio layers, five-beat haptic, maximum authored density | identical board/score/result/RNG, static local confirmation and readable legendary callout |

The hierarchy is semantic rather than a rigid per-game template. In this game,
the live destination candy is the hero object; camera and particles support it.

## Runtime and delivery budgets

- Native visual contract: 540 x 960 stable, intention, impact, settle, result,
  Hard mode, exact long-run and undo frames; 30 continuous legendary frames.
- Software-GL regression budget, declared before the final trace: p95 <= 33.34
  ms and max <= 66.68 ms at the pinned legendary impact. Final normal trace is
  24.341 ms average / 29.081 ms p95 / 31.664 ms max; reduced is 20.524 / 23.626
  / 27.845 ms. This is not end-user GPU telemetry.
- Browser readiness budget: <= 15 s on the local clean bundle. Observed normal
  1.387 s and reduced 1.040 s in Chrome/SwiftShader.
- Fingerprinted clean pack: `index.cc4857f95339.pck`, 14,644,212 bytes, exact
  SHA-256 `cc4857f95339d2c2bdbfec27589e2944ae1bedcb38a98295a96c008ea76ef2d8`.
- Engine: `index.2b558bdb3c3a.wasm`, 37,686,550 bytes, exact SHA-256
  `2b558bdb3c3af1f822ce6c43e09e1fa844d82fa440fe40d2d25d6c36ddf95137`.
- The pack contains all seven 2248 runtime derivatives and their import records,
  the CJK subset font, and none of the named GAG source masters, runtime-source
  intermediates, private evidence or full CJK source fonts.

## Acceptance boundary

Evidence lives in `docs/audit/merge2248-fidelity-v4/`. Native and browser
captures were visually inspected for GAG visibility, hierarchy, clipping and
CJK legibility. The fresh browser performed a real drag, captured normal Web
haptics, undid the move, reproduced the exact RNG outcome, reloaded the exact
active state, restarted, switched to Hard, and repeated the rule consequence in
a system reduced-motion context with zero vibration calls.

The isolated candidate is internally coherent and materially stronger than its
prior tree. Remaining original-behavior unknowns prevent `READY` or “surpasses
the original” language. It is not merged, pushed or deployed while 2048 Balls
remains the user's public review game.
