# Amaze GO v3 Stage-0 gap matrix

Baseline inspected: `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae`.

| Contract area | Frozen evidence / bounded decision | Exact baseline behavior | Stage-0 result |
|---|---|---|---|
| Target identity | Amaze GO! 1.26.0 / App Store `6758326278` / `com.oakever.arrows` | Catalog title only; no versioned target manifest | FAIL |
| Game family | Ordered arrow extraction from a board | Single avatar walks a fixed wall maze | FAIL |
| Topology | Many distinct orthogonal arrow polylines; bounded clean-room level decision | One 6 × 6 cell grid with five static wall edges | FAIL |
| Start / destination | No avatar, start or destination is visible or described | Avatar starts `[0,0]`, destination `[5,5]` | FAIL |
| Core input | Tap one arrow; long-press Guidance exists | Tap only adjacent cell or use directions | FAIL |
| Legal action | Arrow can leave only when its forward path to the edge is free | Orthogonal avatar step succeeds unless a wall/edge blocks it | FAIL |
| State mutation | Legal arrow is removed and opens lanes for others | Marks destination cell painted; revisits remain legal | FAIL |
| Illegal action | Wrong tap costs one heart | Wall/edge reject is entirely non-mutating | FAIL |
| Backtrack / revisit | Not applicable after atomic arrow removal; removed arrow stays absent | Avatar can immediately walk back and revisit cells | FAIL |
| Completion | Clearing all arrows wins | Reaching one fixed bottom-right cell wins | FAIL |
| Failure | One-heart cost is proven; zero-heart behavior remains bounded local decision | No hearts or loss state | FAIL |
| Terminal freeze | Bounded model must reject extraction after `won`/`over` | Top-level path method freezes only by status, but wrong terminal is reached | PARTIAL |
| Hint / Guidance | First-party feature fact; bounded deterministic algorithm is local | Directional hint aims at fixed target and ignores walls | FAIL |
| Restart | Deterministic fresh bounded level | Restarts the incorrect wall maze | FAIL |
| Recovery | Strict validated model snapshot | Periodically writes generic state but never restores it | FAIL |
| Input parity | Shared pointer/touch hit owner plus accessible keyboard selection | Pointer/touch adjacent cells plus unrelated avatar direction keys | FAIL |
| Reduced effects | Preserve arrow occupancy/hearts/focus while suppressing displacement/shake/haptic | No Amaze GO-specific reduced-effects contract | FAIL |
| GAG eligibility | Mechanics-specific model and integration probes must pass first | v2 art smoke validates and celebrates the wrong maze-walk loop | CLOSED |

Stage-0 verdict: **material identity and mechanics contradiction**. All GAG,
art-reuse and presentation claims remain closed until a renderer-free arrow
extraction model and runtime integration probes replace the current maze walk.
