# Solitaire v3 Stage-0 gap matrix

| Area | Exact baseline `3e561fb3` | Evidence boundary | Stage-0 gate | Required closure |
|---|---|---|---|---|
| Identity/version | local item `solitaire`; current first-party product/version frozen | first-party listing proves name and version, not internal resource ID | `PARTIAL_EVIDENCE` | retain unknown ID/package SHA fence |
| Seven-pile deal | integer counts `[5,4,3,2,1,0,0]`; no 52-card deck | generic Klondike and user-required probe contract, not target fact | `FAIL` | deterministic 1..7 topology, 28 tableau + 24 stock, all 52 unique |
| Face state | renderer paints decorative backs/fronts not backed by card state | generic Klondike/local decision | `FAIL` | every tableau card stores identity and face-up state; only initial pile tops face-up |
| Stock/waste | integer decrement/increment; synthetic rank/suit; recycle only counts | target draw/recycle behavior unknown | `FAIL` | real card order, configurable draw-one/draw-three, exact recycle ordering/limit/reject |
| Tableau legality | moves one count between arbitrary non-empty columns | generic Klondike/local decision | `FAIL` | alternating-color descending face-up stack validation and atomic moves |
| Empty column | baseline starts empty columns and accepts arbitrary cards | generic Klondike/local decision | `FAIL` | King-led stack only; non-King reject without mutation |
| Foundation | numeric counters accept any tableau count into any suit | generic Klondike/local decision | `FAIL` | Ace-to-King same-suit order from eligible exposed cards only |
| Stack moves | no card stack representation | user-required probe contract | `FAIL` | selected sequence remains ordered and moves atomically; invalid suffix rejects |
| Auto | removes first non-empty count and increments a foundation | target auto unknown; local enhancement only | `FAIL` | at most one legal foundation move, deterministic priority, safe no-op |
| Reject semantics | only empty-column decorative reject exists | local quality requirement | `FAIL` | illegal commands return typed rejects and leave serialized state byte-equivalent |
| Win/freeze | wins at 8 foundation counts | generic/local contract requires 52 cards | `FAIL` | all four K foundations, `won`, no later mutation |
| Restart/recovery | global reset exists; generic file is saved but never restored | target behavior unknown; local offline quality decision | `FAIL` | fresh restart, strict versioned restore, corrupt/wrong-game/terminal rejection |
| Input parity | pointer/touch share a tap path; no Solitaire keyboard contract | target controls unknown | `FAIL` | mouse/touch/keyboard actions resolve to identical model commands |
| Existing tests | 67 presentation assertions freeze the simplified counter behavior | local regression only | `PASS_BUT_IRRELEVANT_TO_FIDELITY` | replace mechanics assertions with renderer-free contract probes; retain visual regression separately |
| GAG assets | card back/audio preload and historical v2 ledger exist | not freshly audited after mechanics | `CLOSED` | only after mechanics PASS: live endpoint/provider/master/runtime SHA and semantic/ordinary visibility audit |
| Presentation | attractive emerald table paints a fictitious 5/4/3/2/1/0/0 state and says win at 8 | no target visual gameplay evidence | `BLOCKED` | bind actual cards first; then object-level stable→intent→impact→settle→result grammar |
| Delivery | no v3 export or browser evidence | this branch is local only | `NOT_STARTED` | clean fingerprinted Web/PCK, real browser action/reload/headers/transfers, no deployment |

## Stage-0 verdict

- Target identity: `PARTIAL_EVIDENCE` because the internal resource ID and
  target gameplay are not lawfully established.
- Baseline regression health after import: `PASS_BOUNDED` (67 Solitaire
  presentation assertions, 14 catalog entries, 6 shared rule cases, 65 font
  checks). Godot reports inherited resource-leak warnings at test shutdown.
- Mechanics fidelity: `FAIL` because the baseline is a decorative count model,
  not a legal Klondike implementation.
- GAG/presentation gate: `CLOSED` until a renderer-free mechanics commit passes.
- Production authorization: `false`; no merge, push, or deployment permitted.

Baseline command note: a fresh isolated worktree initially had no generated
`.godot/imported` cache, so early scene loads reported missing imports. Running
`/home/ubuntu/stage/godot --headless --path . --import` imported 94 resources;
the bounded regression suites then exited 0. This import-cache issue is not
reported as a gameplay failure, and the generated cache remains ignored.

## Local mechanics closure

At commit `c26616e`, the isolated clean-room model and shell close the requested
local contract without changing the Stage-0 evidence boundary:

| Gate | Evidence | Result |
|---|---|---|
| renderer-free contract | `tools/solitaire_v3_contract_smoke.gd` — 13 deterministic cases | `PASS` |
| shell/recovery/input parity | `tools/solitaire_v3_runtime_smoke.gd` — 8 cases; identical mouse/touch/keyboard draw and stack-move snapshots | `PASS` |
| presentation semantic binding | `tools/solitaire_presentation_smoke.gd` — 84 assertions using legal fixtures | `PASS` |
| catalog/rules/fonts/home | 14 games / 6 shared rules / 65 glyph checks / 14 routes | `PASS` |
| browser reload and real browser actions | not yet run on this candidate | `PENDING` |
| GAG provenance/runtime visibility | not yet freshly audited for v3 | `ELIGIBLE_FOR_AUDIT` |

`PASS` here means the explicitly declared local Klondike contract passes. It
does not establish that target version `3.14.1` uses draw-one, unlimited
recycle, this auto policy, these controls, or this persistence behavior.
