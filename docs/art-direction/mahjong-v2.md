# Vita Mahjong v2 — ivory jade teahouse direction

Scope: only `mahjong`. The 20-tile order, hit regions, selection behavior,
mismatch mutation, pair legality, removed indices, `+50` score, move count and
terminal clear remain frozen. Tile Club is explicitly outside this slice.

## Experience pillars

1. **Every tile feels collectible.** Intent → the playable object carries
   ceramic body, jade contact edge and bamboo identity → all 20 opening tiles
   remain convincing with effects disabled.
2. **Quiet concentration, immediate truth.** Intent → routine selection stays
   restrained while a mismatch marks both conflicting objects → the next legal
   choice is readable without consulting the HUD.
3. **Matching produces jade resonance.** Intent → a legal pair gathers and
   chimes; terminal clear becomes a broader but still calm ceremony → routine
   and terminal outcomes cannot be confused by color alone.

## Art pillars

1. **Ivory over jade:** a warm blank ceramic face, translucent jade/contact
   backing, crisp bevel and modest pearly edge light.
2. **One natural signature:** a small bamboo sprig anchors every generated tile
   without competing with live glyphs.
3. **Teahouse restraint:** dark woven green field and lacquer/brass enclosure
   frame the pale hero pieces; motion resolves instead of lingering as fog.

## Anti-pillars

1. No flat rounded rectangles posing as Mahjong tiles.
2. No baked Chinese, pips, numbers, pseudo-glyphs or gameplay text in generated
   pixels; all live faces remain code-native and font-gated.
3. No neon/casino bloom or particle volume substituting for object motion and
   material contact.

## Fantasy and tone

- Player fantasy: arrange a small cabinet of hand-finished jade-backed tiles.
- Tone: a measured teahouse ritual whose strongest reward still feels tactile,
  not explosive.
- Style words: crafted, mineral, serene.
- Anti-words: plastic, cyber, noisy.
- Signature motif: ivory tile + lower-right bamboo sprig + jade resonance.

## Visual and font grammar

- `mahjong_tile_blank_gag_v1.png` is the visible hero body at every stable tile,
  fitted inside a 76×96 px runtime component. Its first beat is ordinary play
  before input, with 20 visible instances.
- The project-authored SVG remains a low-cost jade/contact backing and retains
  separate provenance.
- Winds, dragons and pips use live code. CJK labels use the bundled CJK UI role;
  no generated text is accepted.
- Removed tiles settle into quiet jade registration marks, preserving board
  geography and next-choice clarity.

## Semantic feedback grammar

| Importance | Event | Object response | Supporting channels |
| --- | --- | --- | --- |
| routine intent | select/deselect | selected GAG tile lifts and softly expands | quiet click, short haptic |
| correction | mismatch | both conflicting tiles counter-shake and receive a red crossed mark | reject sound, short warning haptic |
| meaningful success | ordinary pair | the two real tile bodies travel toward their midpoint and dissolve after contact | GAG tile-clack/jade chime, grade-2 haptic |
| terminal | final pair / clear | tighter pair gather, wider eight-petal jade/gold bloom, delayed teahouse result plaque | pitched GAG cue, strongest bounded haptic and camera response |

There is no invented grade-three event because the mechanic has no authentic
mid-run milestone. The grammar follows meaning rather than filling a matrix.

## GAG and runtime boundary

The HOME-WSL GAG service ran in pure-API mode. Semantic search rejected generic
rings, card chrome, VFX atlases, music and generic accept/coin sounds. fal.ai
generated two tile candidates; the first was rejected because an ornament read
as an invented glyph. The selected blank tile was background-removed and
trimmed through GAG. ElevenLabs generated the pair resonance; its selected
master was loudness-normalized into runtime OGG. Exact queries, prompts, IDs,
providers, transformations, hashes and runtime references are in
`mahjong-v2.gag-asset-ledger.json`.

Only the PNG and OGG runtime derivatives ship. Source masters, delivery
manifests and rejected candidates stay in the HOME-WSL GAG archive.

## Acceptance and non-goals

- Capture matched stable, select, mismatch, routine pair and terminal-clear
  phases, a continuous clear sequence, semantic states and busy performance.
- Re-run Mahjong mechanics, font roles, all catalog rules, clean archive Web
  export, PCK scan, browser action and exact Aliyun deployment acceptance.
- Non-goals: no tile shuffle, hint system, blocking/availability rule, score
  change, new match grade, Tile Club edit or shared-shell reskin.

