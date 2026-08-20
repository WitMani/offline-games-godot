# Meowdoku v2 运行时美术审查

## 结论

通过。稳定帧已经是独立的猫咪手账物件，不依赖粒子或动效成立；G1–G4 的对象动画、局部/全局范围、音效、振动和震屏可区分。GAG 图像与音效都存在真实运行时引用，不是只存档不接入。

## 证据读法

| 证据 | 观察 |
|---|---|
| `runtime/01_stable.webp` | 猫耳页、装订环、叠纸、文具背景、纸面数字层级均在无事件状态成立；GAG 猫爪出现在页眉 |
| `runtime/02_selection_intent.webp` | 选格有局部按压/回弹和同行、同列、九宫定位，不改变棋盘 |
| `runtime/04_correct_impact.webp` | 正确数字出现、放大回落、局部猫爪压印，范围保持单格 |
| `runtime/06_error_impact.webp` | 错误数字不写入棋盘；残影、撕纸抓痕和抖动与成功反馈方向相反 |
| `runtime/08_block_impact.webp` | 九宫洗色、双环和 76px GAG 猫爪形成中级奖励 |
| `runtime/09_block_settle.webp` | 峰值退去后只保留右上角小猫爪完成标记，状态可读 |
| `runtime/10_complete_impact.webp` | 九宫依次盖印、金色洗色、122px GAG 主奖励形成整局峰值 |
| `runtime/11_complete_settle.webp` | 连锁衰减中仍保持数字清晰，无峰值素材永久遮盘 |
| `runtime/12_complete_result.webp` | 结果卡沿用纸艺和猫爪语言，不回落到通用深色弹窗 |
| `runtime/complete-motion.webm` | 30 帧连续序列证明 anticipation → impact → settle，不是挑一张峰值图冒充完整表现 |

`runtime/contact.webp` 的六格顺序为稳定、正确、错误、九宫、整局、结果，便于直接比较层级。

## 规则与可读性

- 给定格不可写；错误不改棋盘且只增加错误数；擦除、普通正确、九宫完成、整局完成均保持原状态迁移。
- 输入数字使用独立数字字体；动态中文使用 CJK 子集并固定在棋盘页脚，未发现乱码或遮挡。
- 画面不将数字、网格或规则信息烘焙进 GAG 图片；实时状态仍由程序绘制。

## 性能

`performance.json` 是 Xvfb + llvmpipe 下 180 帧、每 60 帧重触发一次 G4 的忙态回归：平均 17.275 ms、P95 21.129 ms、最大 23.339 ms。它只作同环境回归证据，不冒充真实手机帧率。
