# Vita Mahjong v3 — layered ivory-jade cabinet

Scope is `mahjong` only. This direction begins after the v3 renderer-free
mechanics gate. It does not change tile identities, free-tile decisions, legal
selection, pair removal, tools, terminal state, recovery, or input routing.

## Evidence boundary

- Target fact: the first-party Vita Mahjong listing identifies the product as
  Mahjong Solitaire and says players tap or slide matching tiles that are not
  blocked or concealed; clearing all tiles succeeds. Hint, undo and shuffle are
  advertised. Version and source details are frozen in
  `docs/replica/mahjong-v3/target-manifest.md`.
- Screenshot observation: current store captures show overlapping layers,
  bright/free versus dim/blocked tiles, a pair rail, and shuffle/hint/undo
  controls.
- Unknown: the target's exact free-tile geometry, layout generator, special
  equivalence classes, scoring, tool economy and loss/deadlock policy.
- Local quality decision: the bounded model uses the traditional Shanghai
  availability rule (no live higher footprint, and at least one horizontal
  side open). This is not claimed as a Vita implementation fact.

## Experience and art pillars

1. **The untouched board already carries the fantasy.** All 36 ordinary live
   tiles use the verified GAG ivory hero body above a jade contact backing. A
   multi-layer cabinet silhouette must remain obvious with effects disabled.
2. **Authority lives on the tile.** Free tiles remain bright, blocked tiles
   remain dim, selection stays on the chosen object, and code-native faces
   never depend on a transient label.
3. **Pairs gather like ceramic pieces on felt.** A legal pair progresses from
   intent through midpoint contact to a settled rail/result. Near-clear and
   final-clear responses widen the ceremony without obscuring the board.

Visual pillars are warm ivory over translucent jade, a single restrained leaf
signature, and a dark teahouse/cabinet field. Anti-pillars are flat placeholder
rectangles, generated/baked glyphs, English reward panels, match-3 badge atlases,
casino bloom, or effects used to conceal weak stable material.

## Stable composition and text

- `mahjong_tile_blank_gag_v1.png` is the ordinary high-frequency hero body on
  every active tile, including the opening 36-tile stable frame. It is also
  reused for pair ghosts and the terminal badge.
- `mahjong_tile_base.svg` is project-authored jade/contact support and must not
  be relabeled as GAG.
- Winds, dragons, dot/bamboo counts and character faces remain code-native.
  Dynamic Chinese uses `UI_FONT` (`NotoSansCJKsc-Subset.otf`); generated pixels
  contain no text or authoritative symbol.
- Overlap and draw order communicate layer. Brightness communicates free versus
  blocked. The same authoritative state remains readable in reduced-effects
  mode.

## Mahjong semantic feedback grammar

| Context | Intent | Impact | Settle/result | Grade |
| --- | --- | --- | --- | --- |
| select/deselect | local jade outline | short lift when motion is allowed | persistent selected face | 1 |
| blocked tile | attempted object stays in place | fixed red cross/material tint | board is unchanged | 1 |
| mismatch | second free tile becomes the next selection | both involved objects counter-shake/cross | no removal; mismatch count remains visible | 1 |
| hint | two authoritative free tiles are marked | restrained cyan registration | selection stays legal and unchanged | 1 |
| ordinary pair | selected pair identifies source tiles | two ivory bodies gather and jade resonance sounds | pair enters the top rail; board removes exactly two | 2 |
| undo | last removed pair is named | both bodies return when motion is allowed | restored board is authoritative | 2 |
| reshuffle/deadlock | whole-board condition is stated | gold rearrangement or fixed reject seal | a guaranteed free pair or stuck status is readable | 3 |
| four tiles remain | real pair gathers more tightly | five-petal jade/gold contact | remaining count reads four | 3 |
| final pair | the last real pair begins the same gather | strongest bounded eight-petal contact and GAG resonance | delayed ivory-jade result plaque | 4 |

The hierarchy follows state meaning rather than requiring every event to occupy
an arbitrary tier. A mismatch stays grade 1 because it is a correction, while
deadlock/reshuffle is grade 3 because it changes the decision context.

## Reduced-effects contract

Reduced effects preserve selected/free/blocked/removed/won authority and audio,
but disable tile translation and scaling, mismatch shake, reshuffle drift,
camera shake and haptics. Pair and catalog outcomes become fixed-position seals
whose only changing channel is opacity. No rule mutation or timing is delayed.

## GAG decision and shipping boundary

The 2026-08-20 HOME-WSL pure-API audit performed fresh semantic searches for an
ordinary blank tile, state feedback and pair audio. It reselected the already
archived v1 blank ivory tile and exact jade resonance master by content hash.
State-atlas, English result, generic UI/VFX, music, generic accept/warning,
other-game audio and sword/coin candidates were rejected. There is no uncovered
asset role: generated state art would bake authority that belongs in code, so
no new generation was justified.

Exact endpoint health, queries, candidate scores, historical provider/model and
prompt provenance, fresh master hashes, derivations and runtime bindings are in
`mahjong-v3.gag-reuse-audit.json`. Only existing runtime PNG/OGG derivatives
ship; source masters, rejected candidates and signed URLs remain outside the
repository.

## Acceptance slice

Acceptance requires renderer-free mechanics and integration probes; stable,
blocked, select, mismatch, routine pair, hint/tool, near-clear, final-clear and
reduced screenshots; continuous pair and terminal sequences; CJK/font checks;
stable-versus-busy llvmpipe comparison; and a clean archive Web/PCK with real
browser select, blocked reject, pair, reload recovery, restart and reduced-mode
checks. This branch is a candidate only and is not deployed.
