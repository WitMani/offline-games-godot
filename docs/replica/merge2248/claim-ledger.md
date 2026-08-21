# Merge 2248 claim ledger

| Claim | Kind | Confidence | Product consequence |
|---|---|---:|---|
| The target is 2248 / Number Connect inside Offline Games, not classic four-direction 2048 | first-party fact | high | Keep a dedicated `merge2248` model |
| The current official presentation uses a five-column board and visibly includes a seven-row layout | first-party observation | high | Width is frozen at five; seven rows exists but is not assigned a difficulty without further evidence |
| The target exposes Score, All Time, a next/result display, reset/settings navigation and colorful power-of-two tiles | first-party observation | high | Preserve these information roles; visual treatment may be original |
| The official yellow connection line represents one valid action | rejected inference | high | Do not use it as mechanics evidence: it visibly branches and is promotional compositing |
| Easy Mode uses 5 x 8 and Hard Mode uses 5 x 6 | secondary runtime observation | high | Implement those two explicit mode mappings |
| The target continues far beyond a 2048 tile and supports very long-running scores | secondary runtime observation | high | Remove the 2048 win, support large tiles/scores, and persist the active run |
| The target exposes Undo | secondary runtime observation | high | Implement gameplay undo; rewarded-ad monetization is excluded |
| The first two values match and later values may equal or double the previous value | historical measurement | medium-high | Preserve as compatibility behavior while seeking reproducible action evidence |
| A released chain becomes the next power of two above its sum | local compatibility decision | medium | Keep temporarily, label explicitly, and do not claim original alignment |
| Paths accept all eight neighboring directions | historical measurement plus visual consistency | medium-high | Preserve temporarily; add a real action trace and input parity probe |
| Medium/Extra Hard use seven/five rows | hypothesis | medium/low | Do not expose as verified target mappings yet |
| No equal adjacent pair is the exact terminal rule | hypothesis | low | Keep only as a compatibility fallback until loss/recovery evidence exists |
| Four semantic feedback grades strengthen hard chains without changing rule state | presentation decision | high | Retain existing GAG/juice work after the mechanics gate reopens |

`First-party observation` means visible in an official asset; it does not turn a
promotional still into a transition trace. `Historical measurement` means prior
clean-room evidence is no longer independently reproducible. `Local
compatibility decision` and `presentation decision` are never assertions about
the original implementation.
