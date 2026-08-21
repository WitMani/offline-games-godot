# TriPeaks v3 · 月影三峰牌桌

## Decision header

```text
Game / slice: TriPeaks only
Target identity: Solitaire Farm: TriPeaks 1.0.53 / package pfreecell.pyramid.klondike.solitaire.tripeaks.solitaire
Evidence status: PARTIAL_EVIDENCE; no reproducible first-party play sequence
Starting baseline: 3e561fb3c55f3b0b813da2b9ee9468cd4d290bae
Mechanics gate: renderer-free 13/13 and shell 9/9 PASS at a516b82
Approved parent direction: docs/art-direction/catalog-cartoon-v1.md
Runtime: Godot 4.6, Web / desktop, 540x960 portrait
Direction status: approved-by-command; no new target-fidelity or surpass claim
Prepared at: 2026-08-20
```

## Invariants and claim boundary

The v3 board is the authoritative local clean-room contract: 52 unique cards,
28 tableau slots in a 3/6/9/10 three-peak blocker graph, one initial waste,
23 stock, exposed-only adjacent clears, explicit local A/K wrap, terminal
win/loss freeze, deterministic restart, and strict live-state recovery. Art may
respond only after those model commands resolve. It may not delay, infer, or
rewrite them.

The lawful first-party listing establishes identity, version, offline/classic
family marketing, and a farm-card visual tone. It does not establish the exact
rules or a reproducible action sequence. Therefore this slice can claim local
mechanics and art strengthening, but target fidelity remains `PARTIAL` and
surpassing the target remains `NOT_CLAIMED`.

## Retained pillars and v3 production consequences

The approved catalog pillars remain unchanged: **Read the move**, **Feel the
craft**, **Earn the peak**; tactile cartoon materials; authored edge world;
metaphor-bound motion. The TriPeaks signature remains a twilight mountain stage.

| Pillar | v3 consequence | Runtime proof |
|---|---|---|
| 暮色登峰舞台 | deep plum table, moon cream paper, lavender ridges, restrained gold route/light | ordinary stable frame reads as TriPeaks without relying on the title |
| 牌态一眼可辨 | all 18 locked entry cards and the stock use one moon/three-peak GAG back; ten exposed cards remain face-up | stable-state visibility count and runtime screenshot |
| 动作落在真实纸牌上 | stock travels to waste; legal clear travels from its exact slot; reveal flips the exact newly exposed card; rejection moves only the attempted card | semantic effect ledger and four-phase frames |
| 连击按难度升级 | routine clear is compact; streak expands ridge/suit cadence; a cleared peak lights one summit; final peak/win owns the full board ceremony; loss extinguishes the route | grade/state probes plus continuous peak sequence |
| 字体按角色分工 | dynamic Chinese uses `UI_FONT`/`DISPLAY_FONT`, ranks use `LATIN_FONT`, suits use `SYMBOL_FONT`, counts use `NUMBER_FONT` | source-role audit, glyph probes, Web screenshot |

Anti-pillars remain: no generic neon reskin, no generated playable card faces or
text, no decorative effect that implies a false legal move, and no constant
maximum shake/confetti.

## GAG decision

Fresh HOME-WSL pure-API semantic search found the original FAL.ai moon/three-
peak master as the highest-scoring image candidate for the role. Visual review
confirmed that its moon, three summits and route remain distinct in the shipped
290x400 derivative and contain no text/rule state. The alternate Gemini image
was rejected for v3 reuse: its larger central emblem is clean but the crescent
and three peaks lose the established full-route story and its pale exterior
glow competes with the live locked/exposed hierarchy.

After indexing the exact GAG archive, fresh audio search found four historical
TriPeaks masters. The retained v3 master is the 0.748 s ElevenLabs result. It has
the complete impact-plus-tail envelope and matches the existing repaired runtime
derivative. Review here is waveform/metadata-only; no subjective listening is
claimed. No role gap justified new generation, so v3 reuses two verified GAG
assets and produces no new source master.

Full endpoint, query, candidate, provider, mismatch, hash, repair and runtime
records are in [tripeaks-v3.gag-asset-ledger.json](tripeaks-v3.gag-asset-ledger.json).

## Semantic feedback grammar

The four-phase envelope is a reading aid, not a rule timer. The model state is
already final at intent time.

| Event | Intent | Anticipation | Impact | Settle / result |
|---|---|---|---|---|
| stock draw | stock compresses | real card turns toward waste | waste face lands | stock count and next legal choices remain clear |
| locked reject | touched back dents locally | gold crossing straps tighten | short red blocked mark | exact back returns; state is unchanged |
| rank reject | face card nudges locally | adjacent-rank bracket appears | short red paper zigzag | exact face returns; streak/state are unchanged |
| legal clear | selected face presses | card arcs toward waste | card settles on waste with one ridge/suit accent | source slot is empty and newly legal cards read immediately |
| reveal | exact covered back narrows | moon back rotates through edge-on | correct face appears in place | focus/legality outline resolves on the live card |
| streak | legal-clear envelope continues | ridge and suit cadence widen by streak | stronger gold summit pulse and GAG cadence | grade clears before the next choice is obscured |
| peak milestone | cleared top card travels | one summit gathers a route line | one persistent peak lamp turns gold | `peak_count` stays visible in shell status |
| final peak / win | final top card commits | three summit lamps and route gather | full moon/peak crest, grade-four cadence | terminal overlay follows the readable empty tableau |
| loss | final stock card commits | route light contracts | red dusk seal without celebratory crown | no-move terminal overlay and restart remain clear |

Grade is semantic contrast: routine clear `1`, short streak `2`, strong streak
or reveal group `3`, final peak/win `4`. A peak milestone is promoted regardless
of raw streak. Rejection does not borrow success audio or camera.

## Accessibility and runtime budgets

- `prefers-reduced-motion` preserves the same authoritative state and local
  text result while suppressing card displacement, shake and haptics.
- The reduced path does not fake a face-down state during reveal; the settled
  exposed face is visible immediately.
- Haptic evidence is emission-count instrumentation unless verified on a
  physical actuator; no felt-amplitude claim is allowed.
- Stable board uses at most 29 small card draws (28 tableau plus stock/waste),
  one preloaded 290x400 WebP and bounded semantic effects.
- Busy audit samples the highest plausible overlapping reveal/streak/milestone
  envelopes under llvmpipe and compares full versus reduced modes.
- Source masters, rejected candidates and private target evidence remain outside
  the product archive. Only the two runtime derivatives may ship.

## Verified acceptance evidence

- stable entry proves 19 ordinary GAG-back instances;
- legal, stock, locked, rank, reveal, streak, peak, final win and loss phase
  sequences are captured at 540x960;
- the continuous grade-four artifact records 42 frames at 30 fps over 1.4 s;
- reduced mode preserves the authoritative settled state with zero catalog
  effect, zero shake and zero haptic emission;
- the matched llvmpipe busy trace measures 14.209 ms full-mode P95 versus
  12.176 ms reduced-mode P95; this is not a device-FPS claim;
- the clean Git-archive export produced fingerprinted PCK
  `index.9dc9433387dd.pck`
  (`9dc9433387ddc94b8d645add512bfaa93ae41c98fe5a209eb8ea5c9557eda3d9`),
  with zero source-master/private/tools/docs/full-CJK-master matches;
- real Chrome passes 26 secure-context, state, mouse/touch/keyboard, recovery,
  restart, reduced-effects, headers, Range and full-transfer checks with zero
  console, page or request errors.

The machine-readable result is in `docs/audit/tripeaks-v3/gates.json`. This
closes the internal runtime/art candidate gate, not the missing original-match
gate or any production release gate.
