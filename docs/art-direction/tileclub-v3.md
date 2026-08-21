# Tile Club v3 — layered keepsake cabinet

Scope: `tileclub` only. This package replaces the obsolete v2 assumption of a
flat 7×7 source board. The renderer-independent contract in
`models/tileclub_model.gd` is authoritative for this candidate; presentation
must not mutate or bypass it.

## Frozen mechanics and claim boundary

- The legal target is GamoVation **Tile Club**, Android package
  `com.gamovation.tileclub`, Apple resource `1640075364`. Version and evidence
  hashes are frozen in `docs/replica/tileclub-v3/target-manifest.md`.
- First-party video directly supports a layered pile, exposed/top-facing
  selection, ordered seven-slot tray and removal/compaction on a third equal
  tile. Three original deterministic layered fixtures exercise those rules.
- Seven unmatched tiles causing failure and an empty board plus empty tray
  causing success are conservative decisions. Exact loss timing/UI, covered
  edge response, production level data, goals, scoring, boosters, progression,
  checkpoint policy, animation, audio and haptics remain **NOT_CLAIMED**.
- Local `+100` per triple is a shell decision, not an original-parity claim.

## Experience pillars

1. **Every move sorts a real keepsake.** The untouched layered pile is made of
   tactile GAG felt badges, not colored placeholders; the same object travels
   into the exact ordered tray slot and remains recognizable there.
2. **Depth opens like a cabinet.** Covered pieces are visibly recessed. A legal
   removal can uncover lower pieces, while a completed upper layer earns a
   stronger thread-opening response without changing selectability rules.
3. **The tray tells the danger story.** Five occupied slots read as tightening,
   six as one-space urgency, and seven as snapped tension. The hierarchy follows
   actual tray capacity rather than an invented combo ladder.
4. **A match is sewn, not deleted.** Three actual tray badges gather, cinch and
   settle with the reviewed felt/thread/button cue. A full clear broadens the
   same language into the final sampler plaque.

## Art pillars

1. **Cocoa felt under cream thread:** contact shadow, dark cloth body, chunky
   piping, corner stitches and a small edge highlight form each hero tile.
2. **Appliqué silhouette first:** leaf, moon, berry, star, flower, shell and
   crystal are distinguishable by shape before hue.
3. **Warm workshop restraint:** berry, coral, teal and thread accents remain
   subordinate to tile/tray legibility; no generic neon or reward confetti.

Anti-pillars: no generated text; no character-glyph substitutes for motifs; no
victory-only asset used to claim normal-state improvement; no effect that hides
the slot count, source removal, blocking truth or next selectable piece.

## Stable signature and GAG roles

`tileclub_badge_atlas_gag_v1.png` supplies six reviewed motif cells and
`tileclub_shell_badge_gag_v1.png` repairs the rejected shell cell. Every live
board tile and every occupied tray slot calls `_draw_fabric_patch`; therefore the
signature is stable and frequent, not a preload or cover-only claim.

| Fixture | Opening board badges | Initially selectable | Stable role |
| --- | ---: | ---: | --- |
| four nests | 12 | 4 | ordinary first playable frame |
| six nests | 18 | 6 | ordinary first playable frame, shell family present |
| seven nests | 21 | 7 | ordinary first playable frame, all seven motifs present |

The GAG audio role is intentionally narrower: `fabric_triple_stitch_gag_v1.ogg`
supports a real triple and final matching clear. Collection, blocked input,
layer reveal and risk warnings use restrained existing cues; they are not
mislabelled as generated fabric audio.

## Semantic feedback grammar

| Truthful event | Grade | Object arc | Supporting channels |
| --- | ---: | --- | --- |
| covered selection | 1 | intent mark, short blocked settle, recovery | red thread/copy, reject cue, short haptic |
| ordinary collection | 1 | selected badge lifts, travels to exact slot, settles | motif-colored thread, click, short haptic |
| ordinary triple | 2 | three real tray badges gather and cinch | GAG felt/thread/button cue, bounded shake |
| upper layer cleared | 3 | newly exposed pieces become legible; wider stitch seal | gold thread, stronger bounded impact |
| tray reaches 5 | 2 | static capacity remains readable under low tension | amber border/copy |
| tray reaches 6 | 3 | one-space urgency and stronger slot tension | pink-red border/copy, warning pattern |
| tray reaches 7 | 4 | all seven real slots counter-kick under snapped thread | failure plaque after consequence reads |
| final matching clear | 4 | truthful triple gather expands into sampler seal | GAG cue, result plaque after consequence reads |

This is Tile Club-specific orchestration, not a mandatory four-tier template for
other genres.

## Motion, haptic and font modes

Normal mode permits bounded travel, object ghosts, shake, slot kicks, impact and
haptic patterns. `prefers-reduced-motion`, `?reduced_effects=1`, or
`OFFLINE_GAMES_REDUCED_EFFECTS=1` selects the low-effects path. It preserves the
authoritative model result, board/tray motifs, risk border, semantic event and
CJK status copy while suppressing travel duration, object ghosts, impact,
shake, animated slot tension, decorative event FX and all Tile Club haptics.

All dynamic Chinese text and event labels use the bundled `ui_cjk` role. GAG
pixels contain motifs only; no generated or rasterized gameplay copy ships.

## Acceptance boundary

Required evidence includes stable/high-frequency signature counts, blocked and
collection arcs, ordinary triple, layer clear, risk 5/6, full tray, final clear,
continuous match/failure/success peaks, reduced-effects parity, comparative
llvmpipe performance, font gates, full-catalog regression, and a fingerprinted
Web/PCK export produced from a clean implementation commit. Commercial or
visual superiority over the original is **NOT_CLAIMED** without matched-device
reference evidence.
