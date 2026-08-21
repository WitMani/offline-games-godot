# GB Snake fidelity target manifest

## Exact target

- Product: **Offline Games — No Wifi Games**
- Android package: `com.JindoBlu.OfflineGames`
- Package version: `3.14.1` (`versionCode 3204`)
- Unity resource key: `79_snake2`
- Serialized root object: `79_SNAKE2`
- `ResourceManager` GameObject path ID: `40489`
- Player-facing title in the package metadata: `Snake`
- Local implementation route: `snake_classic` / `SnakeGbModel`
- Evidence freeze date: 2026-08-20

`79_SNAKE2` is the grid-based classic Snake target. It is not `136_SNAKES`,
the separate continuous arena game that the local catalog exposes as
`snake_io`.

## Authority and clean-room boundary

The target identity and rules below come from a user-authorized copy of the
first-party Android package and independently recorded observations of its
serialized data and IL2CPP metadata. The private package and extracted
materials remain outside this repository and are evidence only. No original
bitmap, audio, prefab, or implementation source is shipped in this product
tree.

| Evidence | Location outside product repository | SHA-256 | Supports |
|---|---|---|---|
| User-authorized XAPK | `/home/ubuntu/work/offline-games-private/reverse/sources/com.JindoBlu.OfflineGames.xapk` | `e326ffe825804249e816d5750ab22493fb6f3f8a36364968d0a0cf4ff65ccb6b` | Package identity and version |
| Base APK | private XAPK extraction | `c83e2bf9d5bcfb34109466cc758648dd799fd900b87ea88c6e87aead28ace32a` | First-party binary identity |
| Configuration split | private XAPK extraction | `23cb512a5dc392bbcc2d9f9723ebef6cef0e73cd1af2aa0d96c304ebb96eb600` | Package composition |
| SNAKE2 forensic notebook | `/home/ubuntu/work/offline-games-private/reverse/SNAKE2_FORENSICS.md` | `c38a20d42940e6ca4d72104bf6e7a6caba5425338759b4940853a66b63335b66` | Resource identity, serialized rules, input behavior |
| IL2CPP metadata excerpt | `/home/ubuntu/work/offline-games-private/reverse/sources/79_SNAKE2_il2cpp_dump.cs` | `d2ff8dcc4594b5f64267c975618a2e53f1456ce0497c1615f444e453dc407b14` | State and input method semantics |
| Serialized prefab | `/home/ubuntu/work/offline-games-private/reverse/merge2248-work/assetripper-out/ExportedProject/Assets/Resources/79_SNAKE2.prefab` | `d87686ca2b33cd8e0b1997e79213b693b224e3b4f9944fd5c6a28ef4337fe838` | Board, speed, food count, input thresholds |
| Catalog metadata | `/home/ubuntu/work/offline-games-private/reverse/merge2248-work/assetripper-out/ExportedProject/Assets/MonoBehaviour/79_SNAKE2.asset` | `4cf2660c30e09228ace6b7f2f0e51ff29b58f8194a1eecd3031190abea83f0e6` | ID, title, description |
| Compact reference capture | `/home/ubuntu/work/offline-games-private/reverse/sources/79_SNAKE2_banner_reference.png` | `cd81e510c886e0733393a39d7cf5fe5f34f118b304e336433db878a42627391c` | Composition and color-family reference only |

## Frozen medium-mode contract

The following are collection-specific facts supported by the package evidence:

- The board is `15 × 23` cells.
- The snake enters at length `4`, facing right, and advances automatically.
- Medium speed is `7.5` moves per second.
- Two food objects are simultaneously active.
- Eating queues two body segments; visible length progresses `4 → 5 → 6` over
  subsequent automatic ticks.
- A wall hit or a hit on the snake's own body ends the run.
- This mode is endless. It has no length-120 victory and no terminal completion
  target. `Infinite Snake` is a different wrapping mode.
- Swipe capture covers the play surface and accepts a direction before finger
  release. The serialized base distance threshold is `40 px`, the time
  threshold is `0.3 s`, and a repeated held-finger swipe within `0.17 s` uses a
  `1.25×` distance threshold.
- A turn is judged against the currently applied direction. A future corner is
  not buffered while a turn is pending.
- The serialized motion smoothing value is `0.65`.

Classic Snake conventions alone are not evidence for a collection-specific
value. They are used only as orientation for wall/self collision terminology.

## Explicit unknowns

- The original runtime's exact random seed and first two food coordinates were
  not recovered.
- The original desktop keyboard or D-pad affordance is not established; the
  package evidence establishes swipe input.
- A serialized mid-run persistence format and exact app-background behavior are
  not established.
- The compact reference capture is not a complete matched event sequence, so it
  cannot substantiate a claim of visual superiority.

## Local product decisions

- The LCD field-recorder metaphor is an intentional presentation
  strengthening, not recovered original art direction.
- Keyboard and on-screen D-pad controls remain as accessibility/input-parity
  additions while touch swipe behavior is matched independently.
- A deterministic seed and validated local run snapshot provide reproducible
  tests and Web reload recovery. They are product robustness decisions, not
  assertions about the original save format.
- Length milestones, including a field-record acknowledgement at `120`, are
  nonterminal telemetry only. Play continues.
- GAG-authored head, lure, field seal, and event audio may be reused only after
  mechanics probes pass and their provenance/runtime hashes are freshly
  verified.
