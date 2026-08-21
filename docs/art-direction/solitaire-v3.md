# Solitaire v3 · 翡翠温室牌桌

## Scope and claim boundary

This slice changes Solitaire presentation only after the legal Klondike model
gate passed. It does not alter deal topology, stock/waste rules, card legality,
foundation order, terminal state, input mapping or recovery. The current Apple
and Google first-party listings identify Solitaire as part of Offline Games but
do not show its gameplay, so target alignment remains **PARTIAL** and surpassing
the reference is **NOT_CLAIMED**. This branch is not deployed.

The approved catalog cartoon pillars remain authoritative. The existing
conservatory backdrop is catalog-owned legacy art and is not relabeled as GAG.
Only the card-back surface and card-settle sound have verified GAG provenance.

## Stable material family

- Deep emerald felt is the quiet rule surface; warm brass marks borders,
  foundation progress and completion hierarchy.
- Warm paper faces and conventional code-native ranks/suits preserve rule
  readability. No generated asset carries rank, suit, score or legal state.
- The botanical GAG card back appears on the legal opening frame in 22 ordinary
  instances: one stock and 21 face-down tableau cards.
- Selected cards lift as a stack, legal destinations remain spatially stable,
  and only a rejected object shakes.

## Object feedback grammar

| Beat | Intent | Impact | Settle / result | Material sound |
| --- | --- | --- | --- | --- |
| Select | selected card or suffix lifts | cyan local cue | selection remains visibly held | quiet generic key; no success settle |
| Draw / recycle | stock card compresses | card flips/arcs between stock and waste | authoritative waste/stock state remains | GAG paper–felt–brass settle |
| Tableau move | selected suffix identifies its source | card arc lands on the exact destination | authoritative stack and exposed-card state remain | GAG settle, grade 1 |
| Reject | attempted source/target stays authoritative | only that object receives red cross/shake | no model mutation; selection remains recoverable | short muted reject tick |
| Foundation | card travels to its suit slot | brass rings and suit marks resolve locally | foundation card/progress arc remain | GAG settle, grade 2 |
| Thirteen-card suit milestone | same foundation route | broader suit/ring reinforcement | completed suit remains visible | raised GAG settle, grade 3 |
| Four-foundation completion | last King travels to its exact slot | botanical crown and four-suit peak remain continuous through settle | a warm-paper result folio appears only after settle | strongest graded GAG settle, grade 4 |

The implementation samples `stable → intent → anticipation → impact → settle →
result`; the anticipation sub-beat is part of the card-table motion, not a
mandatory catalog-wide intensity tier.

## Reduced effects and fonts

On Web, `prefers-reduced-motion: reduce` selects a static-result mode. It caps
the presentation envelope at 0.24 seconds, removes travel overlays, particles,
global shake, rejected-object shake and every haptic emission. The same command
produces an identical model snapshot; semantic color, authoritative final state
and audio remain available. The mode is also test-settable and exposed in the
acceptance state.

All dynamic Chinese feedback and result copy use the UI/CJK font role. Latin
ranks use the Latin font and `♠ ♥ ♣ ♦ ↻` use the symbol font.

## GAG reuse decision

Fresh HOME-WSL semantic review found the existing FAL.ai botanical card back to
be the strongest compatible source and found no better indexed paper/felt audio
candidate. No role gap justified a new generation. The image source master was
freshly downloaded and hash-verified; the historical ElevenLabs WAV master was
not exposed by the current index, so its provider/model/master hash remains
explicitly ledger-attested while the repository OGG was freshly measured.

See `solitaire-v3.gag-reuse-ledger.json` for queries, rejected candidates,
provider/model prompts, hashes, derivations and runtime routes.

## Evidence routes

- Renderer-free rules: `tools/solitaire_v3_contract_smoke.gd`
- Shell/input/recovery parity: `tools/solitaire_v3_runtime_smoke.gd`
- Presentation/GAG/reduced/CJK: `tools/solitaire_presentation_smoke.gd`
- Matched stills and continuous peak: `tools/solitaire_v3_visual_audit.gd`
- Full/reduced busy trace: `tools/solitaire_v3_performance_audit.gd`
- Candidate evidence root: `docs/audit/solitaire-fidelity-v3/candidate/`
