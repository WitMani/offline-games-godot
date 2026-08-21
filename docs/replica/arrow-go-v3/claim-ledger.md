# Arrow GO v3 claim ledger

Facts, observations, inferences and local decisions remain separate. Passing a
local model probe cannot convert an unsupported target behavior into fact.

| ID | Claim | Type | Evidence | Confidence | Implementation consequence | Status |
|---|---|---|---|---|---|---|
| AGO-ID-001 | Catalog `arrow_go` maps to package `com.reda.arrow`; `com.oakever.arrows` belongs to the separate Amaze GO row. | fact | private user-selected source list | high | freeze target identity; prohibit cross-title substitution | verified |
| AGO-ID-002 | The current first-party product is `Arrow GO: Logic Puzzle Game`, version `1.0`, by `chouikh.app`, updated 2026-08-11. | fact | captured Google Play page and structured data | high | freeze title/version/package | verified |
| AGO-RULE-001 | A player taps an arrow and it launches in the direction it points. | fact | first-party listing description | high | replace directional courier movement with arrow selection | verified-bounded |
| AGO-RULE-002 | Other arrows can block the selected arrow; order matters because successful arrows clear space for later arrows. | fact | first-party listing description | high | implement clear-path legality and atomic blocked rejection | verified-bounded |
| AGO-RULE-003 | Clearing all arrows completes the level and reveals the hidden animal. | fact | first-party listing plus completion/animal screenshots | high | clear-all win and central animal consequence | verified-bounded |
| AGO-RULE-004 | Square, circle and triangle board modes exist. | fact | first-party listing and screenshots | high | square-only v3 slice; other shapes explicit non-goal | verified-bounded |
| AGO-OBS-001 | Current screenshots show many connected orthogonal straight/bent line arrows over a dotted board with an animal centered beneath them. | observation | eight captured store screenshots | high | local topology uses connected orthogonal arrow paths and a center reveal layer | verified-bounded |
| AGO-OBS-002 | Current screenshots show a running time/points readout, hint and shuffle counters, a partial-clear state, and a completion modal. | observation | screenshots 01, 05 and 06 | high | preserve as target inventory only; formulas/actions unknown | verified-bounded |
| AGO-FACT-001 | The listing says there is no time pressure. | fact | first-party description | high | do not implement timer-expiry failure | verified-bounded |
| AGO-UNK-001 | Exact level/resource ID, APK SHA, collision kernel, shape translation, penalty/lives, score/timer, failure, restart, recovery and input details are unknown. | fact about evidence coverage | target inventory; unavailable trailer | high | exact target-version claim stays PARTIAL | open |
| AGO-BASE-001 | Baseline is a fixed 9×9 player route: one courier moves right across a row then down a column to a harbor. | measurement | `main.gd@3e561fb3`; dedicated baseline smoke | high | current mechanics are a material mismatch | verified-gap |
| AGO-BASE-002 | Baseline broad smoke passes 28/28, Arrow GO mechanics 175 assertions and art 189 assertions after clean import. | measurement | Godot 4.6 baseline run | high | proves internal stability only, not fidelity | verified-bounded |
| AGO-BASE-003 | Baseline wind plates, courier, harbor, kite-step and harbor-dock assets encode the false route/destination metaphor. | measurement | runtime source, v2 ledger and stable/step captures | high | close GAG; every historical asset must be re-reviewed after mechanics | verified-gap |
| AGO-DEC-001 | The local square slice uses connected orthogonal arrow bodies, a cardinal head direction and deterministic sweep-to-edge collision. | local decision | `models/arrow_go_model.gd`; 129-assertion contract suite | medium for target, high for local behavior | renderer-free topology/legal probes; label as local | verified |
| AGO-DEC-002 | A synthetic no-legal-arrow deadlock is a local terminal-loss/recovery test; it is not asserted as target behavior. | local decision | contract suite plus `docs/audit/arrow-go-v3/visual/local-loss.png` | high as local test | loss freezes state and never reuses the animal-reveal result | verified |
| AGO-DEC-003 | Restart and strict active-run recovery plus mouse/touch/keyboard parity are local quality requirements. | local decision | runtime suite and `docs/audit/arrow-go-v3/web/web-acceptance.json` | high as local behavior | dedicated model/runtime/browser probes | verified |
| AGO-CLAIM-001 | Exact target-version mechanics alignment is not established. | claim boundary | missing target package and reproducible action trace | high | final result cannot exceed `PARTIAL` | enforced |
| AGO-CLAIM-002 | Surpassing the target is not claimed. | claim boundary | no matched original/candidate action review | high | final result `NOT_CLAIMED` | enforced |

## Stage-0 decision

The target identity and core action family are sufficiently bounded to replace
the false courier-route substitute with an independently specified local
arrow-clear contract. At that historical gate the starting implementation
failed the contract, so GAG and art production remained closed until the
renderer-free mechanics, strict recovery and runtime input probes passed.
Those gates later closed at `e465934`, `5f5ed61`, `d8c477c` and `ce78c57`.
Missing target detail still blocks exact fidelity and superiority claims, not
the bounded repair.
