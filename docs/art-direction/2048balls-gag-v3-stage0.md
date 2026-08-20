# 2048 Balls · exact-title mechanics contract and GAG-visible direction v3

## Review boundary

```text
Exact-title target: Voodoo, “2048 Balls 3D” (Apple App Store id 1485247734)
Official source: https://apps.apple.com/us/app/2048-balls-3d/id1485247734
Evidence acquired: 2026-08-20 UTC
Runtime / viewport: Godot 4.6 Web, 540 × 960 portrait
Private evidence root: /home/ubuntu/private-evidence/offline-games/2048balls-stage0/
Public review boundary: this game only; no merge or deploy implied by this document
```

The exact-title assumption is explicit: “original” means Voodoo's `2048 Balls
3D`, not a generic watermelon-drop game. Official screenshots remain private
reference evidence and are not shipped in the repository or Web bundle.

## Facts, direct observation, inference, local choice

| Class | Frozen statement |
|---|---|
| First-party fact | The official description says “Drop balls and merge them! How far can you go?” |
| Direct screenshot observation | A dotted vertical aim guide can occupy non-grid horizontal positions; a numbered ball is held at the top; numbered power-of-two balls form an irregular pile; the board has side/floor boundaries and a horizontal danger marker; equal-value contacts are shown amid a merge effect; 256 and 2048 appear as successive target/progression objects. |
| Conservative inference | The player selects a continuous horizontal release position; the released ball visibly falls; circles use gravity and wall/floor/ball contact; equal balls merge on contact; a stable pile above the danger line ends a run; reaching a displayed target advances the run rather than forcing a fixed-score victory. |
| Still unknown | Exact gesture sampling, gravity/restitution/friction coefficients, random distribution, scoring formula, danger grace duration, high-tier cap, target cadence after 2048, ads/economy, and every mode outside the core run. |
| Local compatibility choice | Fixed 120 Hz deterministic circles; conservative bounded restitution/friction; 0.86 s stable danger grace; first target 256 then target tier +3; open run; restart keeps local best; keyboard aliases share the same aim/drop route. |

## Fidelity gate result

The prior v2 implementation failed Stage 0. It used seven arrays, quantized
click-to-column input, instantaneous append, same-column adjacency merges, a
seven-item column failure, a tier-five cap, and a score-1000 hard win. Those
behaviors contradicted the observable aim/free-pile/contact grammar, so the v2
art candidate was not eligible for approval merely because its assets looked
better.

The v3 repair moves rules into `models/watermelon_physics_model.gd`:

- continuous x aim from pointer/touch, plus keyboard nudging;
- visible falling balls stepped at a deterministic fixed interval;
- circular wall, floor, and ball contacts with bounded bounce and friction;
- equal-tier merge on physical contact anywhere in the playable cavity;
- tiers continue beyond the five-picture fruit family while live numbers stay
  authoritative;
- sustained danger-line overflow ends the run; brief crossings do not;
- 256/2048-and-beyond targets promote feedback but keep the run open;
- restart clears the run and preserves best score.

Model and runtime integration probes cover these statements independently.
Presentation consumes semantic events and serialized positions; it does not
recompute a merge, target, failure, or score.

## Conservative art pillars

| Pillar | Runtime rule | Stable-frame proof |
|---|---|---|
| Fruit-orchard identity | Every live ball uses the coherent five-piece GAG fruit family, then cycles that visual family for higher tiers while a code-native power-of-two number remains readable. | A settled free pile shows five distinct fruits and live `2…32` labels. |
| A recipe always in view | The newly generated honey-wood GAG recipe tray is present throughout play, not hidden in a transient reward. | The full-width lower tray survives cold start and ordinary play. |
| Weight before fireworks | The physical ball travels and settles first; landing adds only local squash/ring. No presenter fakes a second fall. | Release, travel, contact, and settle frames differ through model positions. |
| Earned juice | Grade 2/3/4 merge envelopes scale object gather, deformation, juice burst, rings, callout, sound, haptic, and bounded shake without obscuring settled state. | Separate grade captures plus a 24-frame peak trace. |

Anti-pillars: background-only “enhancement”; seven decorative lanes; baked
numbers or localized copy; generic assets counted as GAG use; maximum splash on
a routine landing; spectacle attached to a vanished source rather than the
surviving result; art approval while fidelity is red.

## GAG visibility repair

HOME-WSL GAG `1.29.0` was used through its Streamable HTTP MCP at
`https://desktop-youyuan-wsl.tail17a64.ts.net:11443/mcp`. The service reported
no local GPU/PyTorch on its main process, while fal.ai, OpenRouter, Gemini,
Remove.bg, and ElevenLabs API paths were enabled. Four semantic searches ran
before generation. Representative generic card frames, unrelated atlases,
generic magic VFX, and non-semantic music/SFX were inspected and rejected.

fal.ai Flux Pro v1.1 then generated a honey-wood orchard recipe-tray source.
The source contained two trays despite the single-object instruction, so it was
not shipped directly. GAG manual crop selected the coherent upper tray,
Remove.bg isolated it, GAG auto-trim produced the runtime shape, and a local
WebP derivative reduced the shipped asset to 20,606 bytes. Source masters stay
in the HOME-WSL GAG archive. The repository and PCK receive only the runtime
derivative. Full provenance and hashes are in
`2048balls-gag-v3.asset-ledger.json`.

## Acceptance gates

- Stage 0 model smoke: aim, travel, collision, unequal/equal contact, cascade,
  high tiers, danger grace, failure, restart, target progression, determinism.
- Runtime integration smoke: mouse/touch routes, continuous x, visible travel,
  contact result identity, state serialization, failure/restart, open target.
- Presentation smoke: real runtime assets, grades 1–4, blocked release,
  player-visible tray, audio routes, CJK coverage, Web effect cap.
- Stable/contact/peak/rejection/target screenshots at 540 × 960 and a complete
  24-frame grade-four sequence.
- Comparative performance trace, clean Web export, PCK asset-path inspection,
  and a real browser input/state probe before approval.

Claim target remains “candidate for original-aligned mechanics and stronger
cartoon expression.” User review, clean Web evidence, and explicit sequential
merge/deploy approval are still required before calling it accepted.
