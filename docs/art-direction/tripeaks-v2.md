# TriPeaks · 三座暮色牌峰 v2

## Scope

This slice strengthens only `tripeaks`. It preserves the existing card layout,
unlock graph, rank-adjacency rule, stock, score, streak, win and save-state
transitions. Solitaire and every other catalog game keep their current rules and
runtime assets.

## Art pillars

1. **暮色登峰舞台** — 深梅紫桌面、月白牌纸、薰衣草光和软金路线组成三峰远征基调；背景山脊只强化空间层次，不承载规则。
2. **牌态一眼可辨** — 锁牌持续展示月夜三峰牌背；可打牌有暖色脚灯，已清牌退为路线节点，当前牌与牌堆留在独立控制台。
3. **动作落在真实纸牌上** — 翻牌由牌堆飞向当前牌，消牌由原槽位飞向当前牌；拒绝只震动并划过被点中的具体牌。
4. **连击按难度升级** — 一级是单峰与一次落牌，二至四级逐步增加山脊、星点、皇冠、震屏、触觉和声音强度；峰顶里程碑与三峰清场各有独立语义造型。
5. **字体按角色分工** — 中文 UI 使用 CJK 子集，牌面 `A/K/Q/J` 使用 Latin，`♠ ♥ ♣ ♦` 使用符号字体；生成素材不含文字。

## GAG signature assets

- `tripeaks_card_back_gag_v1.webp`: GAG semantic search rejected unrelated
  frames and crests, then pure-API FAL.ai generation produced the accepted
  moon/three-peak/route surface. Five locked cards plus the stock show it in the
  first stable frame, so it is part of ordinary play rather than a rare reward.
- `tripeaks_streak_peak_gag_v1.ogg`: GAG pure-API ElevenLabs generation. Its
  card snap and two rising brass/glass notes route to accepted-card streaks,
  peak milestones and completion; semantic grade changes gain and pitch. The
  GAG loudness warning was retained and the shipped derivative was repaired.

No generated text, rule state, source master, unused generation or rejected
search candidate is included in the repository.

## Feedback ladder

| Grade | Semantic beat | Object / visual | Audio / haptic |
| --- | --- | --- | --- |
| Reject | locked or non-adjacent card | only the touched card shakes; local red zigzag | short reject tick and brief pulse |
| 1 | first accepted card | exact card travel, one teal ridge and one lit summit | paper snap, first rising note, light haptic |
| 2–3 | growing streak | wider ridge, more summits/stars and stronger target settle | progressively raised gain/pitch and patterned pulse |
| 4 | long streak | gold three-peak ridge, four-step crown meter and stronger shake | full two-note summit cadence and strongest streak pulse |
| Milestone | five or ten cleared | cleared socket plus a gold peak-lighting crest | distinct summit-grade accent |
| Win | all tableau cards cleared | empty mountain sockets, three-peak crown and delayed completion state | terminal grade-four cadence, shake and haptic |

## Acceptance evidence

- Matched 540×960 stable and four-stage event frames:
  `docs/audit/tripeaks-v2/candidate/`
- Continuous 36-frame / 30 fps peak recording:
  `docs/audit/tripeaks-v2/candidate/continuous/tripeaks-grade4-streak.webm`
- Frozen-mechanics and runtime-route assertions:
  `tools/tripeaks_presentation_smoke.gd`
- Provenance ledger:
  `docs/art-direction/tripeaks-v2.gag-asset-ledger.json`
- Aliyun exact-artifact acceptance:
  `docs/audit/tripeaks-v2/candidate/web/aliyun-web-acceptance.json`

Accepted release: `20260820T122024Z-ec1636cfbd9b`, sourced from Git commit
`6109827098d93ddc5de990609f210a2478543cda`.
