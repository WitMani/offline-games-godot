# GB Snake v2 · field telemetry direction

## Decision

```text
Game / slice: GB Snake stable objects and the turn / forage / milestone / crash loop
Reference target: existing clean-room GB/LCD implementation and its frozen rules
Starting commit: 2e9d241f87054fa5dd3a52e2ca737376806a3d37
Runtime / platform: Godot 4.6 Web, touch + keyboard
Viewport: 540 × 960 portrait
Direction status: approved under the user-authorized one-game-at-a-time catalog rollout
Prepared at: 2026-08-20
```

The existing olive handheld and leather case already form a strong shell. The
presentation gap is inside the hardware: the playable snake and lure are plain
rectangles, a turn mostly highlights the D-pad, and forage, growth, failure and
target completion do not form a sufficiently legible intensity hierarchy. This
slice keeps the physical device and replaces placeholder-like hero-object
language with a field-telemetry specimen hunt.

## Baseline and frozen gameplay

Matched 540×960 baseline frames are in `../audit/gb-snake-v2/baseline/`.

| Probe | Frozen result | Evidence |
|---|---|---|
| Entry | 15×23 board, four segments, right heading, food at `[11,11]`, target 120 | `SNAKE_GB_MODEL_CASES=9 PASS` |
| Turn | one queued cardinal turn; duplicate, reverse, invalid and queued-again requests reject | model + input smoke |
| Tick | fixed grid step, tail vacates unless pending growth | model smoke |
| Forage | entering the one food cell queues exactly one growth and spawns one legal new food | model/integration smoke |
| Failure | wall or occupied non-vacating body cell ends the run without an extra legal move | model smoke |
| Result | materializing length 120 wins; reset reproduces the deterministic opening | model/integration smoke |
| Input | 54×54 D-pad and keyboard arrows route to the same model request | `SNAKE_INPUT_SMOKE_CASES=8 PASS` |

The model, board dimensions, movement interval, target, collision rules,
scoring, RNG, input routing and restart contract are invariants. Presentation
consumes model events after the authoritative mutation.

## Pillars

### Experience pillars

| Pillar | Intent → production rule | Observable proof |
|---|---|---|
| Read the living signal | the head, body and lure must read as distinct specimens within one monochrome LCD grammar | opening frame identifies heading and target without relying on title or color |
| Feel the hardware answer | input begins at the real D-pad and travels into phosphor response on the acted-on head | accepted and rejected turns produce different local hardware + screen arcs while state truth remains visible |
| Make growth feel earned | forage, ten-length field logs, crash and target completion use progressively different cadence and settled consequences | routine food stays restrained; milestones persist as log notches; failure and win cannot be confused |

### Art pillars

| Pillar | Shape/material/motion rule | Observable proof |
|---|---|---|
| Field herpetology instrument | olive Bakelite, dark leather, aged brass, stamped specimen seal; no generic sci-fi chrome | stable handheld remains recognizable while a GAG serpent seal gives it a specific research identity |
| Phosphor has memory | square LCD pixels, one dark-ink palette, stepped motion and short afterimages; generated art is recolored into the display | head and lure have authored silhouettes, but never become full-color stickers inside the LCD |
| Telemetry, not confetti | range ticks, lock brackets, scan sweeps and recorded length notches grow from exact cells | each feedback peak is spatially correlated to head, lure, boundary or score rail |

### Anti-pillars

| Reject | Why | Counterexample |
|---|---|---|
| neon cyber reskin | contradicts the aged field instrument and erases the existing identity | cyan bloom, holographic glass and RGB snake segments |
| full-color character pasted into LCD | breaks the single-ink display fiction and state legibility | detailed green cartoon cobra floating over the grid |
| maximum shake on routine food | destroys contrast and makes a 120-length run exhausting | every snack triggering the same terminal explosion |

Player fantasy: carry a battered pocket ecology instrument, guide its live
serpent trace toward specimen lures, and complete the 120-unit field record.

Tone: patient, tactile and slightly mysterious; an analog expedition tool, not
a horror prop or toy-neon arcade cabinet.

## Annotated GAG search and internal alternatives

The registered in-process GAG tool was first checked and rejected as an EC2
misconfiguration (`mock` only, missing Gemini key). Production uses the actual
HOME-WSL streamable-HTTP MCP at
`https://desktop-youyuan-wsl.tail17a64.ts.net:11443/mcp`, server 1.29.0, with
Gemini semantic embedding and fal.ai / ElevenLabs / Remove.bg API providers.

Three successful semantic searches returned 15 candidates each. Reviewed
examples were rejected before generation:

| Candidate | Decision |
|---|---|
| `enemy_cobra_idle_spritesheet_cropped.png`, score 0.374, SHA `612e1e45…` | purple/red many-eyed combat cobra; wrong role, palette and scale |
| `scrap_circuit.png`, score 0.420, SHA `0af093e0…` | material is close, but it is a circuit scrap rather than a serpent identity or lure |
| `pixel_art_green_ghost`, score 0.411, SHA `05bd67aa…` | clean pixel silhouette but unrelated ghost subject and full-color shading |
| `Game_icon_sprite_sheet`, score 0.408, SHA `216cd121…` | cyan laboratory symbols, asset-sheet soup and incompatible display color |
| `cute_cartoon_turtle`, score 0.379, SHA `f8fefe26…` | explorer theme is relevant but the mascot species and soft full-color rendering are wrong |
| audio exploration music / boss music / warning / magic / coin | long-form or semantically generic; not repeatable D-pad, forage or terminal cues |

Internal directions:

| Direction | Strength | Rejected because |
|---|---|---|
| combat threat scanner | strong stakes | too grim and militarized for a cozy catalog game |
| translucent neon pocket toy | immediate color spectacle | generic cyber treatment and incompatible with the LCD |
| field telemetry specimen recorder | preserves the shell and turns mechanics into a specific fantasy | selected |

## Art Bible

- Shape: head is a compact right-facing wedge with one readable eye and two
  antenna-like scan prongs; body remains rounded-square segmented pixels; lure
  is a symmetric seed/capsule with a central phosphor core.
- Palette: all live LCD components resolve to `#27321e` ink, `#536342` ghost
  memory and `#b9c58d` highlight over the existing olive screen. Brass/coral is
  reserved for the external physical seal and rare hardware acknowledgement.
- Material: the outer seal uses aged brass rim, olive enamel and a dark inlaid
  serpent. The LCD assets are alpha silhouettes tinted by code; their source
  colors are never authoritative.
- Type: `NUMBER_FONT` owns `LEN`, `TARGET`, counts and English terminal telemetry;
  the bundled CJK UI role owns live Chinese prompts. No generated image contains
  text, numerals or pseudo-glyphs.
- Motion: accepted turn is press → head focus → stepped reorientation → settle.
  Forage is lure lock → head contact → scan ring → body growth. Crash is local
  contact compression → phosphor smear → screen/case recoil → result. Win is
  full-record sweep → seal acknowledgement → stable certificate.
- Accessibility: direction, rejection, food, milestone and terminal states use
  silhouette/pattern/motion as well as alpha. Effects remain bounded and the
  deterministic state is readable with haptics unavailable.

## Feedback grammar

| Meaning | Object/world arc | Audio/haptic/camera | Settled consequence |
|---|---|---|---|
| accepted turn | touched D-pad depresses; head focus brackets rotate with the queued direction | short key tick, 8 ms haptic, no shake | next stepped movement visibly uses the new heading |
| rejected reverse/pending turn | rejected D-pad kicks back; head shows a short opposing ghost | quiet reject tick, no world shake | queue and state remain unchanged |
| routine forage | GAG lure contracts into the exact head cell; scan ring and one phosphor afterimage | GAG collect cue, 18 ms haptic, tiny screen flex | one pending-growth pip and new lure are visible |
| ten-length field log | forage arc promotes to double sweep, hardware indicator pulse and stronger score recoil | collect + milestone layer, rhythmic haptic, bounded 2 px case response | one persistent telemetry notch records the reached decade |
| wall/self crash | head compresses at exact contact; directional LCD smear and case recoil | dedicated crash cue, 50 ms haptic, strongest negative shake | specific wall/self result remains readable |
| length 120 | last segment materializes, complete sweep reaches brass specimen seal | distinct completion cue, five-beat haptic, bounded grade-4 response | stable target certificate shows real length and steps |

Grades are semantic rather than cosmetic: routine input remains quiet; forage is
repeatable; decade milestones, failure and completion own clearly larger but
different responses.

## GAG and runtime production plan

Generate through GAG pure-API mode:

1. a right-facing monochrome LCD serpent-head glyph, transparent derivative,
   first visible on the opening head at approximately 14×14 and enlarged only
   during semantic feedback;
2. a monochrome specimen-lure glyph, first visible on the opening food cell at
   approximately 15×15 and reused in every forage lock;
3. an aged-brass/olive serpent field seal, first visible above the LCD at
   approximately 42×42 and reused in milestone/result acknowledgement;
4. short forage and completion SFX through ElevenLabs. Existing key/reject/crash
   cues remain unless a generated replacement is objectively cleaner in
   waveform, loudness, duration and routing QA.

Source masters and rejected generations remain in the HOME-WSL GAG archive.
Only bounded PNG/OGG derivatives ship. The ledger records exact searches,
prompts, providers/models, candidate decisions, transforms, hashes, first beats,
runtime sizes and bindings.

Runtime work stays in `main.gd` presentation state and drawing helpers; the
model is untouched. Acceptance requires matched 540×960 stable, turn, forage,
milestone, crash and win captures; continuous forage and peak clips; font and
glyph probes; 120/180-frame llvmpipe traces; clean Git-archive Web export; PCK
asset scan; atomic Aliyun deployment retaining the prior PCK; and one real
online D-pad turn with state evidence and zero console/request errors.
