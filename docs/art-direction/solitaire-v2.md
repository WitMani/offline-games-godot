# Solitaire · 翡翠温室牌桌 v2

## Scope

This slice strengthens only `solitaire`. It does not change stock, tableau,
foundation, score, move, win, input or save-state rules, and it deliberately
does not ship the prepared TriPeaks work.

## Art pillars

1. **翡翠温室材质** — 深翡翠牌毡、暖象牙牌纸和拉丝黄铜形成稳定的物件语言；装饰只服务层级，不承载规则。
2. **一眼区分牌态** — 暗牌用植物黄铜牌背，明牌用暖纸与标准四色花色；选中牌抬起，合法目标列亮起，空列拒绝只作用于被点列。
3. **动作必须落到物件** — 翻牌、牌列移动和归位均有 intent → anticipation → impact → settle 的牌体轨迹，不以全屏粒子替代因果。
4. **难度分级但形式不僵化** — 普通动作是单次纸牌落桌；四牌里程碑增加环与花色；完成用四级震屏、触觉节奏、黄铜回响和植物冠饰。
5. **字体按角色分工** — 中文 UI 使用 CJK 子集，A/K/Q/J 使用 Latin，`♠ ♥ ♣ ♦ ↻` 使用符号字体；所有运行时文字继续由引擎绘制。

## GAG signature assets

- `solitaire_card_back_gag_v1.webp`: GAG semantic search found no compatible
  reusable card-back, then pure-API FAL.ai generation produced the accepted
  emerald botanical/brass surface. It is visible on the first stable frame at
  72×100 on the stock and 58×80 on ten face-down tableau cards.
- `solitaire_card_settle_gag_v1.ogg`: GAG pure-API ElevenLabs generation. The
  paper flick, felt contact and brass tick route to draw, recycle, tableau move,
  foundation and win events; grade changes gain and pitch. The source loudness
  warning was repaired before the runtime derivative was accepted.

No generated text, rule state, source master, unused generation or rejected
search candidate is included in the repository.

## Feedback ladder

| Grade | Semantic beat | Object / visual | Audio / haptic |
| --- | --- | --- | --- |
| 1 | select, draw, move | lift/target cue or card travel with one settle ring | paper–felt settle; 8 ms haptic |
| Reject | empty tableau | only the rejected column shakes; red crossed zigzag | short reject tick; 12 ms haptic |
| 2 | normal foundation | card arcs into its exact suit slot; two-ring resolve | louder settle; two-pulse haptic |
| 3 | every fourth foundation card | denser rings, more suit sparks, score/label reinforcement | raised pitch/gain; stronger pattern |
| 4 | terminal completion | card arrival, four-stage crown/leaf resolve, delayed result overlay | peak settle, strongest patterned haptic and shake |

## Acceptance evidence

- Matched 540×960 stable and four-stage event frames:
  `docs/audit/solitaire-v2/candidate/`
- Continuous 36-frame / 30 fps peak recording:
  `docs/audit/solitaire-v2/candidate/continuous/solitaire-win.webm`
- Frozen-mechanics and runtime-route assertions:
  `tools/solitaire_presentation_smoke.gd`
- Provenance ledger:
  `docs/art-direction/solitaire-v2.gag-asset-ledger.json`
- Aliyun exact-artifact acceptance:
  `docs/audit/solitaire-v2/candidate/web/aliyun-web-acceptance.json`

Accepted release: `20260820T115619Z-5f5d3807cf84`, sourced from Git commit
`837c3361efbfb1d2d2a137264ef1558f50f29b3b`.
