# Amaze v3 target manifest

Date: 2026-08-20

## Baseline and isolation

- Exact public baseline: `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae`
- Isolated worktree: `/home/ubuntu/worktrees/offline-games-amaze-fidelity-v3`
- Isolated branch: `codex/align-amaze-v3`
- Prior candidate reviewed as input: `codex/art-amaze-gag-v2@5815bb8b3736763da821548352bf49440985aa87`
- Prior mechanics input: `96bcf5170e1fd916aa1e78927d14534ecbd20c58`

The prior commits are not acceptance evidence for this branch. Their code and
art are re-tested against the current baseline. The 2048 Balls, Meowdoku, and
all other catalog entries remain outside the change boundary.

## Legal first-party reference target

The target is the observable Classic loop of CrazyLabs' **AMAZE!!!**, not its
Time Rush, Limited Moves, multiplayer, economy, advertisement, or live-service
layers.

- CrazyLabs product page: <https://www.crazylabs.com/games-console/amaze/>
- Apple App Store page: <https://apps.apple.com/us/app/amaze/id1452526406?platform=ipad>
- Nintendo US page: <https://www.nintendo.com/us/store/products/amaze-switch/>
- Nintendo UK page: <https://www.nintendo.com/en-gb/Games/Nintendo-Switch-download-software/AMAZE--2375941.html>

On 2026-08-20 the App Store page identified Crazy Labs and version `6.2.2`.
Nintendo's publisher copy explicitly described filling every square and listed
Classic, Time Rush, and Limited Moves. Only observable behavior is used; no
source code, extracted level data, reference pixels, or reference audio ships.

## Private evidence manifest

Raw media is retained outside Git at
`/home/ubuntu/private-evidence/offline-games/amaze-stage0/`. The hashes were
recomputed for v3; committed audit images contain only this project's runtime.

| Private artifact | Measurement | SHA-256 |
|---|---:|---|
| `app-store.html` | official page capture | `039b0148ef97c969b71cd61e22216560ddf7d0511cf5d8f2e23e1023d5e3051f` |
| `appstore-iphone-01.jpg` | 1290×2796 | `328a4e9d7d9c2fb1b4eb8778aef542c729f05ff06818c94bdedc8d597937e283` |
| `appstore-iphone-02.jpg` | 1290×2796 | `6a01ed0f325ff596ea9fe1be2283912fbcd154bbf77453cc072e15faf5ecf4b7` |
| `appstore-iphone-03.jpg` | 1290×2796 | `f1f5f2d802e73f0823b355a6a1e088f1a37438fdb03d1645ee9dd1322d3b9a0b` |
| `appstore-iphone-04.jpg` | 1290×2796 | `704832da26aff7c26edada252c4014689c876a1f6f9daa9481dda2e185d11f20` |
| `nintendo-store.html` | official page capture | `82da8e9fb97c9035ee5b44c8c546db54886a62cec49f82a72caab683ffea5d62` |
| `nintendo-official-trailer.mp4` | 1280×720, 43.109733 s, 30000/1001 fps | `192606aa114755ec8b3c53c5f6bdfc4db6cc9520a2f2adb2201bfb6be3d00483` |
| `nintendo-3a6438cc.jpg` | 1280×720 | `333f8f29f1bdb6f1e3927776e67d6752ea773b3f5800bed9c379df9b53d603c6` |
| `nintendo-45706891.jpg` | 1280×720 | `f73709ea2ce3800b82617634bb98612f1e4c42135c6603b0d1a49b6e705d5f8c` |
| `nintendo-48e95c0b.jpg` | 1280×720 | `420cc8e564fc5472aec9a8d95a315532f076b528a4c8564554d3c28012cb73f9` |
| `nintendo-4bcb8daa.jpg` | 1280×720 | `f150a37833cec64710ad1b542f2df503b918eb0c9ab7cccf60092c566489ac5e` |
| `nintendo-ca4fc2f4.jpg` | 1280×720 | `5e483ef0daf3269bcc9e25e9b54aa3fbaf1ef84ccffd560e376ce99fb8e9a266` |
| `nintendo-edf59ff0.jpg` | 1280×720 | `2d46c58062a918dd51b195deaef0aa879e0ee629cd6e55bb368f384e96908c18` |

## Claim boundary

This candidate may claim only renderer-independent Classic-loop alignment and
internal presentation strengthening when its gates pass. Exact original level
content, complete progression/economy, scoring, timing, other modes, and
commercial superiority remain `NOT_CLAIMED`.
