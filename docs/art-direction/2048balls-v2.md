# 2048 Balls · orchard toy direction v2

## Decision and invariants

```text
Game / slice: 2048 Balls hero objects and graded merge feedback
Starting commit: 80438df
Runtime / viewport: Godot 4.6 Web, 540 × 960 portrait
Direction status: approved through the catalog cartoon-art direction
Mechanics invariant: seven columns, tap-to-drop, vertical equal-value cascades,
score/win/full-column rules, restart, and input routing remain authoritative in main.gd
```

The v1 frame had an orchard background but its playable fruits were still
programmatic circles. This slice makes the fruit family—not the backdrop—the
visual hero and stages feedback on the exact authoritative result fruit.

## Pillars and anti-pillars

| Pillar | Production rule | Runtime proof |
|---|---|---|
| A toy worth dropping | every fruit has a distinct silhouette, warm rim, painted body, face, stem/leaf, and contact shadow | the five-value gallery is readable without hue labels |
| The crate acknowledges weight | drop stretches, lands, squashes, rebounds, and settles inside a layered wooden container | routine sequence `10`–`13` |
| Cascades earn spectacle | merge importance promotes gathering, object deformation, local juice, audio, haptic, and camera contrast | grade 2, grade 3, and grade 4 probes and captures |

Reject: another background-only pass; generic neon particles; a maximum burst
on routine drops; feedback centered on the wrong surviving fruit; baked text or
game state inside generated images.

Player fantasy: pack a cheerful orchard crate until small fruit recipes bloom
into a prized watermelon. Tone: sunny, tactile, juicy, celebratory without
obscuring the next legal column.

## Art Bible

- Shape: rounded fruit bodies grow in silhouette complexity—lemon lobes,
  orange crown, apple leaf, grape cluster, watermelon striping.
- Material: warm outline + painted edge + body gradient + glossy highlight;
  a code-native soft contact ellipse grounds every runtime texture.
- Crate: honey outer rails, dark quiet cavity, raised posts, fasteners, plank
  highlights, rope-and-pennant danger line, and subtle lane stitching.
- Palette roles: fruit owns saturated focal contrast; the cavity stays dark
  brown; danger uses pink plus triangular pennants rather than color alone.
- Type roles: CJK/UI copy and generated callouts use the bundled Noto CJK role;
  no live text is baked into art.
- Progression: fruit scale and silhouette prestige rise from value 1 to 5;
  value 5 gains a restrained ambient crown.
- Motion: routine drop uses travel → squash → rebound → settle. Merge uses two
  source ghosts gathering → authoritative result impact → damped deformation →
  readable settled object.

## Feedback grammar

| Meaning | Object / world response | Audio / haptic / camera | Settled consequence |
|---|---|---|---|
| Routine drop, grade 1 | falling hero sprite, short trail, landing squash | soft crate plop, 7 ms haptic, no shake | one new fruit visibly occupies the column |
| Single merge, grade 2 | two source ghosts gather, result pops, local droplets | juicy pop, three-beat haptic, small shake | upgraded fruit remains readable |
| Two-step chain, grade 3 | stronger deformation and bounded juice ring | merge + cascade layer, promoted haptic and shake | highest surviving result is the focal object |
| Long cascade / harvest, grade 4 | fal.ai juice crown behind the exact result, largest ring and rebound | layered reward, five-beat haptic, strongest bounded shake | board clears visually within the event duration and control never leaves the player |
| Full column rejection | local zigzag and corrective callout on that lane | reject click and short haptic | state and move count remain unchanged |

The renderer consumes `catalog_fx` only after the rule mutation. Presentation
does not compute merges, score, or terminal state. Grade-4 contact is resolved
by finding the surviving `highest_result` row, avoiding a visually impressive
burst on the wrong fruit.

## GAG production record

Semantic search ran first on the HOME-WSL GAG HTTP MCP for fruit sprites, juice
VFX, crate material, and fruit SFX. Existing-library image matches scored around
0.38–0.43 and were rejected for subject/style mismatch. A coherent fruit family
was generated through GAG; the requested fal.ai call rejected the raw pixel-size
shape, and GAG transparently fell back to Gemini. The grade-4 juice crown was
then generated successfully through fal.ai using its native `square_hd` size.
GAG crop, Remove.bg, and indexing produced the runtime derivatives. Three SFX
families were generated through GAG's ElevenLabs path.

Full prompts, hashes, providers, transformations, archive paths, and runtime
references are recorded in
[`2048balls-v2.asset-ledger.json`](2048balls-v2.asset-ledger.json).

## Runtime evidence and gates

- `tools/watermelon_presentation_smoke.gd`: hero assets, routine, grades 2–4,
  rejection invariants, harvest promotion, audio routes, live CJK role, and
  the six-envelope Web overdraw cap.
- `tools/watermelon_visual_audit.gd`: stable family, staged routine and merge
  frames, grade-3 boundary, 24-frame peak sequence, rejection, and semantic
  snapshot. The continuous sequence pins the event clock at 60 Hz so PNG
  encoding time on a software renderer cannot age the effect out.
- `tools/watermelon_performance_audit.gd`: 180-frame worst-case trace with six
  concurrent grade-4 envelopes. On the Xvfb/llvmpipe comparison host it records
  17.96 ms average and 22.24 ms P95; this is a regression trace, not a device
  FPS claim.
- `docs/audit/2048balls-v2/`: stable-to-peak contact sheet, selected source
  frames, the complete 24-frame grade-4 WebM, state snapshot, and performance
  JSON.
- Catalog mechanics, art-event, font, and all-game smoke suites remain release
  gates.

Claim target: art strengthening + expressive strengthening. “Breakthrough” is
reserved until the clean Web build and user-visible runtime are reviewed; the
presence of generated files alone is not acceptance evidence.
