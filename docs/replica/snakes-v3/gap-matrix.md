# Snakes v3 Stage-0 gap matrix

| Area | Starting state at `3e561fb3` | Evidence boundary | Stage-0 status | Required gate |
|---|---|---|---|---|
| Identity | `snake_io` is a distinct arena game, separate from GB Snake; model commentary no longer treats `136_SNAKES` as authoritative. | first-party App Store history names `Snakes`; developer Google Play event describes `.io` arena play | pass | preserve evidence boundary |
| Entry/offline | Local game starts with one player, five bots and food without network. | first-party event explicitly promises offline play | pass-local | dedicated probe plus clean Chrome PCK/WASM transfer PASS |
| Aim/steer | Pointer and keyboard feed a continuously bounded heading model. | free steering is inferred from `.io`/“slither”; exact control scheme and turn rate unknown | plausible local decision | renderer-free continuous steer plus pointer/keyboard parity probes |
| Boost | Hold boost increases speed, drains mass and sheds food; low mass rejects. | no acquired first-party evidence | enhancement only | keep semantics stable and independently probed; do not claim reference parity |
| Eat/grow | Food pickup increases mass and refills a bounded food field. | explicitly first-party-supported | aligned contract | deterministic eat/grow probe |
| Collision | Rival body/head and boundary can kill; own body does not. | “avoid other snakes” establishes danger, not exact collision ownership/details | local decision | atomic body/head/boundary/own-body probes and explicit claim fence |
| Death | Player death ends the run and drops edible debris. | exact death/debris consequence unknown | local decision | deterministic death/debris and delayed-result shell probe |
| Respawn | Bots respawn after 2.6 s; player does not auto-respawn. | unknown | local decision | bot-respawn/player-terminal probe |
| Rank/biggest | Living snakes are mass-sorted; player may reach rank 1 while play continues. | “become the biggest” is explicit; exact leaderboard and win terminal are unknown | aligned objective, local presentation | prove rank reorder and prove rank 1 does not invent terminal win |
| Restart | Shell creates a fresh deterministic arena after result. | original prompt/seed semantics unknown | local decision | restart probe and later browser action |
| Recovery | Versioned snapshots preserve complete renderer-free state; strict restore rejects schema, identity, bounds and terminal corruption atomically; Web binding stores only live runs and resumes input-neutral. | original recovery unknown; this is an offline quality decision | pass-local | model contract 10/10, runtime 4/4 and real-browser collect/restart reload recovery PASS |
| Input parity | Arena pointer, cardinal keyboard aim, keyboard/button boost are covered by existing shell smoke. | reference exact input unknown | pass-local | preserve all 8 shell input cases |
| Art/GAG | Historical gummy family was selectively migrated only after the mechanics gate; runtime derivatives were freshly hashed and four live semantic role searches found no stronger compatible candidate or missing role. | historical source-master path/hash provenance is ledger-recorded but its archive bytes were not freshly exposed; old evidence is not reused as v3 runtime proof | pass-bounded-reuse | ordinary/stable, actual action, peak, continuous death/knockout, reduced-effects and CJK gates PASS |
| Delivery | Clean archive of implementation commit `4fa7bd1` exported fresh fingerprinted PCK `index.741a66a81973.pck`; real Chrome steer/boost/collect/death/restart/reload, headers and 206 transfer pass. | local internal candidate only; Aliyun still serves the separate 2048 Balls release | pass-local / not deployed | public rollout and external user acceptance remain closed |

## Stage-0 verdict

There is no first-party evidence that materially contradicts the verified core
eat/grow/avoid/biggest loop. Mechanics commit `27417dd` corrects the resource-ID
overclaim, adds strict snapshot recovery, and passes the dedicated contract and
shell probes. Every unknown original rule remains fenced.

The subsequent isolated presentation candidate at `4fa7bd1` passes native,
continuous, reduced-effects, comparative-performance, clean-export and local
real-browser delivery gates. This authorizes an internal sequential review
candidate only. It is not merged, pushed, deployed or user-accepted, and it
does not change the evidence boundary for the original hidden rules.

Baseline commands after ignored `.godot` import initialization:

```text
/home/ubuntu/stage/godot --headless --path . --script res://tools/snakes_arena_model_smoke.gd
SNAKES_ARENA_MODEL_CASES=18
SNAKES_ARENA_MODEL_RESULT=PASS

/home/ubuntu/stage/godot --headless --path . --script res://tools/snake_input_smoke.gd
SNAKE_INPUT_SMOKE_CASES=8
SNAKE_INPUT_SMOKE_RESULT=PASS

/home/ubuntu/stage/godot --headless --path . --script res://tools/snake_modes_integration_smoke.gd
SNAKE_MODES_INTEGRATION_CASES=5
SNAKE_MODES_INTEGRATION_RESULT=PASS

/home/ubuntu/stage/godot --headless --path . --script res://tools/smoke.gd
SMOKE_GAMES=14
SMOKE_RESULT=PASS
```
