# Solitaire v3 claim ledger

Facts, measurements, inferences, and local decisions are intentionally
separate. No generic Klondike rule or local quality choice is promoted to a
target-version fact.

| ID | Claim | Type | Evidence | Confidence | Consequence / probe | Stage-0 status |
|---|---|---|---|---|---|---|
| SOL-REF-001 | App Store track `6448104157` is `Offline Games - No Wifi Games`, bundle `com.JindoBlu.OfflineGamesIOS`, version `3.14.1`, seller Jindoblu Limited. | fact | Apple listing and lookup capture | high | freeze target identity/version | verified |
| SOL-REF-002 | The first-party Apple and Google Play descriptions list `Solitaire` as one of the offline games. | fact | captured first-party listings | high | map local catalog item `solitaire` to the named minigame | verified-bounded |
| SOL-OBS-001 | The captured current first-party screenshots and 6.95 s trailer contain no Solitaire gameplay state. | measurement | source-resolution contact sheets and trailer inspection | high | no target rule or visual-layout inference | verified |
| SOL-UNK-001 | Target-specific deal, draw count, recycle limit, legal moves, auto, win, restart, input, and persistence behavior are not established. | fact about evidence coverage | evidence inventory | high | keep every listed behavior outside alignment claims | open |
| SOL-ID-001 | No exact target internal resource ID or package SHA is available. `solitaire` is only the local repository ID. | measurement | no package/resource catalog acquired | high | mark target identity `PARTIAL_EVIDENCE` | open |
| SOL-GEN-001 | Generic Klondike uses 52 cards, seven tableau piles of heights 1–7, only each pile's top card face-up, alternating-color descending tableau, same-suit ascending foundations, movable exposed sequences, and Kings in empty columns. | generic rule, not target fact | Bicycle Klondike rules | high for generic family, none for target parity | define clean-room local contract and probes | adopted-local |
| SOL-GEN-002 | The consulted Bicycle variant draws three cards. | generic rule, not target fact | Bicycle Klondike rules | high for that published variant | ensure model can support draw-three; do not infer target default | adopted-local-option |
| SOL-RULE-001 | Local runtime defaults to draw-one and unlimited recycle; model accepts draw-one/draw-three and finite/unlimited recycle configurations. | decision | accessibility and deterministic test coverage | high as local behavior | draw order, recycle order, limit and reject probes | verified-local at `c26616e` |
| SOL-RULE-002 | Legal tableau moves are face-up alternating-color descending stacks; only a King-led stack enters an empty column. | decision grounded in generic Klondike | user-requested contract plus generic rules | high as local behavior | positive and negative stack probes | verified-local at `c26616e` |
| SOL-RULE-003 | Foundations accept only the next same-suit rank from Ace through King; completion requires all 52 cards in foundations and freezes further model mutations. | decision grounded in generic Klondike | user-requested contract plus generic rules | high as local behavior | foundation/reject/win/freeze probes | verified-local at `c26616e` |
| SOL-RULE-004 | Revealing a tableau top after a move flips it face-up atomically. | decision grounded in generic Klondike | generic rules | high as local behavior | expose/flip probe | verified-local at `c26616e` |
| SOL-RULE-005 | `自动整理` performs at most one currently legal card-to-foundation move per activation. | enhancement decision | target behavior unknown; baseline already exposes a button | medium | legal-only/no-op/terminal probes; never alignment claim | verified-local at `c26616e` |
| SOL-RULE-006 | Valid live state restores from a versioned local snapshot; corrupt, duplicate-card, terminal, or wrong-game snapshots are rejected atomically; explicit restart starts fresh. | offline-quality decision | product's offline promise, not target persistence evidence | medium | snapshot/restore/restart/browser reload probes | model/shell verified; browser pending |
| SOL-RULE-007 | Mouse/touch hit paths and keyboard selection/actions resolve to the same model commands. | accessibility decision | target controls unknown | high as local requirement | parity probes at shell and real-browser levels | shell verified; browser pending |
| SOL-BASE-001 | Baseline uses only integer counts (`stock=24`, tableau `[5,4,3,2,1,0,0]`) and permits arbitrary count transfers; it synthesizes card identity while drawing and declares win after 8 foundation counts. | measurement | `main.gd@3e561fb3` and current presentation smoke | high | mechanics gate is FAIL despite smoke passing | verified-gap |
| SOL-BASE-002 | After a local import pass, baseline smoke suites pass: Solitaire presentation 67, catalog 14, rules 6, font coverage 65; initial clean-worktree execution lacked generated import cache. | measurement | Stage-0 commands | high | preserve broad regression coverage; do not treat as target proof | verified-bounded |
| SOL-ART-001 | Existing card-back and settle-audio assets are historical local GAG candidates; their provenance, source master, hashes, ordinary visibility, and runtime semantic routing have not yet been freshly audited for v3. | fact | repository inventory | high | mechanics is now locally PASS; fresh GAG audit may begin, with no generation absent a role gap | eligible-for-audit |
| SOL-REL-001 | This worktree begins at exact public baseline `3e561fb3` and is not merged, pushed, deployed, or publicly visible. | fact | Git/worktree inspection and task boundary | high | prohibit online-visible or surpass claims | verified |
| SOL-CLAIM-001 | Exact target-version rule alignment is not established. | decision boundary | missing first-party gameplay evidence | high | final original-fidelity verdict cannot exceed `PARTIAL` | enforced |
| SOL-CLAIM-002 | Surpassing the authorized reference is not claimed. | decision boundary | no authorized matched reference sequence or acceptance | high | use `NOT_CLAIMED` even if local presentation improves | enforced |

## Stage-0 claim boundary

The lawful evidence freezes product identity, current iOS version, and the fact
that the catalog contains an offline minigame called Solitaire. It does not
freeze the hidden rules. The requested Klondike contract is therefore a local
clean-room quality decision, independently probed and explicitly separated
from target-version facts. Mechanics must pass before any GAG or presentation
reuse can be authorized. Renderer-free cases `13/13`, shell/recovery/input cases
`8/8`, presentation semantics `84`, catalog `14`, shared rules `6`, font
coverage `65`, and home routing `14` pass at mechanics commit `c26616e`. This
opens only the fresh GAG audit; target-version fidelity remains `PARTIAL`.
