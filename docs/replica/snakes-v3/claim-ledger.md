# Snakes v3 claim ledger

Fact, measurement, inference, and local decision are deliberately separate.
No local implementation choice is promoted to an original-game fact.

| ID | Claim | Type | Evidence | Confidence | Consequence / probe | Status |
|---|---|---|---|---|---|---|
| SNK-REF-001 | App Store track `6448104157` is `Offline Games - No Wifi Games`, bundle `com.JindoBlu.OfflineGamesIOS`, current version `3.14.1`, seller Jindoblu Limited. | fact | Apple listing and lookup capture | high | freeze target identity | verified |
| SNK-REF-002 | The first-party version history added a distinct game called `Snakes` in the 3.7.x lineage. | fact | App Store listing, versions 3.7.2/3.7.3 | high | map catalog `snake_io` to this target, separate from GB Snake | verified |
| SNK-REF-003 | Developer-published Google Play event copy describes Snakes as an arcade `.io` challenge: eat food, avoid other snakes, become the biggest, playable online or offline. | fact | dated Google Play promotional-event surface | high for stated product promise; medium for current-build persistence | define minimum contract without inventing hidden rules | verified-bounded |
| SNK-OBS-001 | Current App Store and Google Play promotional screenshots plus the 6.95 s Google Play trailer do not show a Snakes gameplay loop. | measurement | source-resolution still/contact-sheet inspection | high | cannot infer controls, HUD, collision details, timing, or visual identity | verified |
| SNK-UNK-001 | Exact steering input, turn rate, boost availability/cost, collision ownership, own-body behavior, head-head resolution, arena boundary, death/debris, respawn, leaderboard, terminal win, restart, and recovery semantics are not demonstrated by acquired first-party gameplay evidence. | fact about evidence coverage | evidence inventory | high | remain explicit unknowns | open |
| SNK-ID-001 | `136_SNAKES` is a historical repository label, not a verified current public/internal resource ID. | measurement | repository search; no package/resource catalog acquired | high | remove it from authoritative model commentary | resolved-local |
| SNK-RULE-001 | Renderer-free simulation uses continuous bounded free-direction steering. | inference + decision | `.io`/“slither” wording plus local input quality | medium | dedicated steer and input-parity probes | verified-local |
| SNK-RULE-002 | Eating food increases mass; living competitors are ranked by mass; rank 1 satisfies “become the biggest” without fabricating a terminal win. | fact + decision boundary | first-party event plus local endless-arena decision | high/medium | eat/grow, reorder, rank-1/nonterminal probes | verified-local |
| SNK-RULE-003 | Rival-body/head and boundary contacts may kill; own body is nonlethal; death drops edible debris. | decision | no acquired first-party detail | medium | atomic collision/debris probes; never claim exact alignment | verified-local |
| SNK-RULE-004 | Boost trades mass for speed and emits trail food, with a low-mass cutoff. | enhancement decision | no acquired first-party evidence | medium | boost/cost/reject probes; do not claim reference parity | verified-local |
| SNK-RULE-005 | Dead bots respawn after a bounded delay; player death is terminal until explicit restart. | decision | local offline loop | medium | death/respawn/restart probes | verified-local |
| SNK-RULE-006 | A valid in-progress offline snapshot may restore after reload; invalid/corrupt snapshots must be rejected and explicit restart clears recovery. | decision | offline-first quality requirement; original behavior unknown | medium | strict restore and browser reload probes | verified-local-model-and-shell |
| SNK-BASE-001 | Exact starting HEAD's renderer-free arena smoke passes 18 cases; shell input 8, integration 5, and catalog 14 pass after generating only the ignored Godot import cache. | measurement | commands in Stage-0 gap matrix | high | preserve while adding dedicated contract/recovery probes | verified |
| SNK-ART-001 | Existing branch `codex/art-snakes-gag-v2@6d4ca114` is only a local candidate and predates this fidelity audit. | fact | Git history and branch inspection | high | GAG stays closed until mechanics PASS; re-audit provenance and runtime roles before reuse | verified |
| SNK-REL-001 | This branch is isolated and has not been merged, pushed, deployed, or observed on the public runtime. | fact | task boundary and Git/worktree state | high | prohibit online-visible wording | verified |

## Stage-0 claim boundary

The evidence supports the product identity and only the minimal promise “eat
food, grow, avoid other snakes, become the biggest, offline-capable.” It does
not support saying that the current local boost, collision, death, respawn,
rank UI, win, restart, or recovery details exactly reproduce version 3.14.1.
Those are isolated clean-room decisions until stronger lawful evidence exists.
At mechanics commit `27417dd`, renderer-free contract cases `10/10`, existing
arena cases `18/18`, runtime recovery cases `4/4`, input cases `8/8`, mode
integration cases `5/5`, and the 14-game catalog smoke pass. This authorizes
local presentation work only; it does not upgrade any unknown reference rule.
