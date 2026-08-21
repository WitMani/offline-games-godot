# TriPeaks v3 claim ledger

Facts, observations, inferences, and local decisions are kept separate. A
local probe can verify our implementation but cannot turn an unknown target
behavior into first-party truth.

| ID | Claim | Type | Evidence | Confidence | Consequence / probe | Stage-0 status |
|---|---|---|---|---|---|---|
| TRI-REF-001 | The user-selected TriPeaks target is Google Play package `pfreecell.pyramid.klondike.solitaire.tripeaks.solitaire`. | fact | private source inventory and exact URL | high | freeze package/resource identity | verified |
| TRI-REF-002 | The current first-party page identifies version `1.0.53`, title `Solitaire Farm: TriPeaks`, developer `Forever Software`, updated `2026-08-02`. | fact | captured Google Play HTML/metadata | high | freeze versioned public listing identity | verified |
| TRI-REF-003 | The listing markets classic three-peaks gameplay and offline play. | fact | first-party description | high | establish product family only | verified-bounded |
| TRI-OBS-001 | Five current store images are 1920x1080 promotional composites, not deterministic runtime screenshots. | observation | source-resolution visual inspection | high | do not derive exact layout, transitions, dimensions, or timing | verified |
| TRI-OBS-002 | No exact-package first-party gameplay video, deterministic deal, tutorial trace, or action sequence was found on the listing. | observation | listing/media inventory | high | no matched-action target evidence | verified |
| TRI-UNK-001 | Exact target topology, stock/waste semantics, A/K wrapping, score/streak, win/loss, restart, recovery, and controls remain unknown. | fact about evidence coverage | evidence inventory | high | keep outside parity claims | open |
| TRI-ID-001 | Package ID is the only target resource ID; no internal level ID or APK SHA is available. | observation | no target package/catalog acquired | high | target gate remains `PARTIAL_EVIDENCE` | open |
| TRI-BASE-001 | Baseline models only 15 integer ranks, uses a non-three-peak blocker shortcut, synthesizes stock ranks, resets streak on an illegal rank, and wins after 15 clears. | measurement | `main.gd@3e561fb3` | high | existing presentation smoke is not mechanics evidence | verified-gap |
| TRI-BASE-002 | Baseline dedicated presentation smoke passes 62 assertions; shared rules 6, catalog 10, font coverage 65, home routing 14, and full catalog 14 pass after import. | measurement | Stage-0 test commands | high | preserve regression coverage, but do not infer target parity | verified-bounded |
| TRI-RULE-001 | Local model uses all 52 unique cards: 28 canonical tableau, one initial waste, 23 stock. | local decision | requested quality contract / standard family geometry | high as local behavior | identity, deal, partition probes | verified-local at `35d129e` |
| TRI-RULE-002 | A tableau card clears only when uncovered and one rank above/below waste. | local decision | requested contract; target detail unknown | high as local behavior | blocker/reveal/legal/illegal atomic probes | verified-local at `35d129e` |
| TRI-RULE-003 | Ace and King wrap is enabled to preserve the baseline user-facing rule. | local compatibility decision | baseline UI; no target evidence | high as local behavior, none for target | explicit wrap-on/off probes and claim label | verified-local at `35d129e` |
| TRI-RULE-004 | A legal clear scores 30 and extends streak; stock draw resets streak; illegal input is atomic and does not reset streak. | local tuning decision | baseline score value plus atomicity requirement | high as local behavior | score/streak/illegal snapshots | verified-local at `35d129e` |
| TRI-RULE-005 | Clearing all 28 tableau cards wins; empty stock with no legal tableau move loses; terminal states freeze commands. | local decision | requested complete state contract | high as local behavior | win/loss/freeze probes | verified-local at `35d129e`; shell at `a516b82` |
| TRI-RULE-006 | Restart replays the deterministic deal; valid versioned live snapshots restore; corrupt, duplicate-card, terminal, or wrong-game snapshots reject atomically. | offline-quality decision | requested strict recovery; target unknown | high as local requirement | restart/recovery probes | verified model/shell and real Chrome reload/restart |
| TRI-RULE-007 | Mouse, touch, and keyboard paths resolve to identical model commands. | accessibility decision | requested parity; target unknown | high as local requirement | shell and real-browser parity probes | verified shell and real Chrome for stock/legal clear; locked rejection also touch-verified |
| TRI-ART-001 | The moon-three-peak back and streak audio are historical GAG pure-API products, freshly rediscovered and hash-verified through HOME-WSL for v3. | fact | endpoint health, semantic queries, provider/master/runtime hashes, PCK mount and browser report | high | reuse exact FAL.ai and ElevenLabs derivatives; no new generation | verified at `bb4497d` |
| TRI-ART-002 | The GAG card back is visible on 18 locked tableau cards plus stock in the ordinary entry state; it is not preload-only. | runtime measurement | 540x960 stable capture, presentation probe, clean PCK and Chrome opening frame | high | stable/frequent signature role passes | verified |
| TRI-ART-003 | Stock, legal clear, exact reveal, locked/rank reject, graded streak, peak, win and loss responses are routed from authoritative semantic results; reduced mode preserves state while suppressing displacement, shake and haptics. | runtime measurement | phase captures, continuous peak, shell probes and real Chrome actions | high | internal feedback strengthening supported | verified |
| TRI-WEB-001 | The clean fingerprinted Web bundle contains the two runtime GAG derivatives and no source master, private evidence, tools/docs, or full CJK master. | package measurement | empty-path PCK mount enumeration plus real Chrome full transfer | high | local archive gate passes for PCK `9dc94333…` | verified |
| TRI-REL-001 | Candidate starts at exact baseline and is not merged, pushed, deployed, or reflected on Aliyun. | fact | Git/worktree inspection and task boundary | high | prohibit public/release claims | verified |
| TRI-CLAIM-001 | Exact target-version mechanics alignment is not established. | claim boundary | missing reproducible target gameplay evidence | high | final fidelity verdict cannot exceed `PARTIAL` | enforced |
| TRI-CLAIM-002 | Surpassing the authorized target is not claimed. | claim boundary | no lawful matched reference sequence or user acceptance | high | final presentation verdict is `NOT_CLAIMED` | enforced |

## Stage-0 gate

Identity/version evidence is strong enough to name the target but remains
insufficient to reproduce its hidden mechanics. The renderer-free contract
passes `13/13`, shell/input/recovery passes `9/9`, TriPeaks presentation passes
`166` assertions, and all 30 repository smoke scripts pass at runtime commit
`bb4497df73ae33c2cbd5ada598c7793158b9cc8a`. Fresh HOME-WSL GAG search and
hash review, stable/phase/continuous/reduced/performance evidence, a clean
fingerprinted PCK, and 26 real-Chrome checks also pass. These results support
the local clean-room contract and internal art/feedback strengthening only.
Exact target-version fidelity remains `PARTIAL`; superiority remains
`NOT_CLAIMED`; no merge, push, deployment, or Aliyun change was performed.
