# Vita Mahjong v3 Stage-0 gap matrix

Baseline inspected: `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae`.

| Contract area | Frozen evidence / bounded decision | Exact baseline behavior | Stage-0 result |
|---|---|---|---|
| Target identity | Vita Mahjong 3.34.0 / App Store `6468921495` / `com.vitastudio.mahjong` | Catalog title only; no versioned target manifest | FAIL |
| Game family | Mahjong Solitaire pair removal, not traditional Mahjong | Generic pair matching | PARTIAL |
| Tile identity/count | Distinct face identities; bounded board decision requires 18 exact pairs | Integers 1–10 duplicated once in a flat array | FAIL |
| Layout | Screenshot-proven overlap/layers; local auditable layer geometry | Flat 5 × 4 grid | FAIL |
| Eligibility | Target says not concealed/blocked; local no-cover + one-open-side rule | Every unremoved tile is selectable | FAIL |
| Hit resolution | Topmost visible tile must own overlapping input | Cell arithmetic cannot represent overlap | FAIL |
| Legal match | Two free tiles with equal identity are removed | Any equal values anywhere are removed | FAIL |
| Illegal blocked select | Must preserve rule state and expose blocked reason | No blocked state exists | FAIL |
| Unequal select | Must not remove either tile | Preserves tiles but selection/penalty are undocumented local behavior | PARTIAL |
| Deadlock | Detect no available free equal pair; behavior remains local decision | No deadlock detection | FAIL |
| Hint / shuffle / undo | First-party feature fact; bounded algorithms must be labeled local | None | FAIL |
| Completion | Clearing all live tiles succeeds and freezes tile input | Flat board reaches `won`; generic top-level tap guard freezes | PARTIAL |
| Loss | No first-party core loss rule proven; do not invent alignment | No loss | HONEST UNKNOWN |
| Restart | Deterministic fresh board | Resets flat board | PARTIAL |
| Recovery | Strictly validate and restore a saved bounded-model snapshot | Writes snapshots but never restores them | FAIL |
| Input parity | Same resolver for mouse/touch; accessible keyboard route | Mouse/touch only for Mahjong tiles | FAIL |
| Reduced effects | Preserve blocked/selected/removed authority; suppress travel/shake/haptic | No Mahjong setting | FAIL |
| CJK/glyph role | Dynamic Chinese uses the CJK UI font; suit geometry remains code-native | Existing faces use UI font but no v3 coverage probe | PARTIAL |
| GAG eligibility | Mechanics-specific probes must pass first | Old v2 art smoke validates the wrong flat mechanics | CLOSED |

Stage-0 verdict: **material contradiction**. Presentation work and reuse claims
remain gated off until a renderer-free model and runtime integration probes
replace the flat-board rule path.
