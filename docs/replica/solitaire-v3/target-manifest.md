# Solitaire v3 target manifest

| Field | Frozen value |
|---|---|
| catalog product | `Offline Games - No Wifi Games` |
| minigame name | `Solitaire` |
| first-party iOS target | Apple App Store track `6448104157`, seller `Jindoblu Limited` |
| iOS version | `3.14.1`, released `2026-08-07T15:42:11Z` |
| iOS bundle ID | `com.JindoBlu.OfflineGamesIOS` |
| corroborating Android identity | Google Play package `com.JindoBlu.OfflineGames`, developer `JindoBlu`, listing updated `2026-08-05` |
| internal target resource ID | **unknown**; no package or first-party resource catalog was acquired |
| local implementation ID | `solitaire` (a repository identifier, not a target resource ID) |
| package SHA-256 | unavailable; no target package was acquired |
| evidence date | `2026-08-20` |
| lawful basis | public first-party store listings and promotional media; one public generic rules source; no target code, binary, art, audio, or data copied |
| exact replica baseline | `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae` |
| isolated candidate | branch `codex/align-solitaire-v3`, worktree `/home/ubuntu/worktrees/offline-games-solitaire-fidelity-v3` |
| private evidence root | `/home/ubuntu/private-evidence/offline-games/solitaire-stage0` |
| current evidence verdict | `PARTIAL_EVIDENCE`: catalog identity and version are frozen; target-specific gameplay is not demonstrated |
| release boundary | local candidate only; do not merge, push, deploy, or describe as publicly visible |

## Frozen evidence inventory

| Artifact | Kind | SHA-256 | What it can establish |
|---|---|---|---|
| `apple/app-store.html` | first-party App Store listing capture | `23f4a82a05cf7b9b760ce92781603ea61e86f3f8fad88052b3b0b7fdede3a324` | product identity and public listing context |
| `apple/itunes-lookup.json` | first-party Apple metadata response | `e66f5f8e8e336a67d78aece631c7c93b80c0f3699c6bee10c5b70cb663cee99d` | track, bundle, seller, version and release date |
| `apple/largebanners-iphone.png` | first-party screenshot contact sheet | `334701f09048fced2d3871c989e1e2a84468fc347365689b47d177f057fdda82` | inspected catalog/promo frames; no Solitaire play state |
| `apple/minibanners-iphone.png` | first-party screenshot contact sheet | `fe0a13946626f407c8c06801e7550371bcfe282935dc20d81c6466a30335a815` | catalog imagery only; no rule-bearing play state |
| `google-play/page.html` | first-party Google Play listing capture | `f95d65928fdb458640e4c09bddc5668236080a4352ef982c1e359e599e95fae9` | Android product/developer identity, offline promise, and inclusion of Solitaire |
| `google-play/official-trailer.mp4` | first-party Google Play trailer, 1280x720, 6.95 s | `99a2c739eb3b513a99d8fa044fecd81279465cacf81dc233179ea37b8e0ce746` | inspected sequence does not show Solitaire gameplay |
| `google-play/official-trailer-contact.jpg` | derived trailer contact sheet | `08b1207c2f047ba0047189808ad48b7fa82f60d9af43a943f7b7b4f4e698657c` | visual measurement aid only |
| `google-play/screens-contact.jpg` | derived current screenshot contact sheet | `cbc999816c65eae7931d57f271a362d7dec356b149facd508df8b7af4c1628f1` | no Solitaire gameplay observed |
| `generic-rules/bicycle-klondike.html` | public Bicycle Klondike rules | `25c744584e3e89c23278862799c963b5525078d8a9720a42cbd79e0874c86a95` | generic Klondike family only; never target-version truth |

Source URLs:

- <https://apps.apple.com/us/app/offline-games-no-wifi-games/id6448104157>
- <https://itunes.apple.com/lookup?id=6448104157&country=us>
- <https://play.google.com/store/apps/details?id=com.JindoBlu.OfflineGames&hl=en-US>
- <https://bicyclecards.com/how-to-play/klondike>

## Contract boundary

The first-party listings explicitly include a minigame named `Solitaire` and
promise offline play. The captured first-party screenshots and trailer do not
show its board, controls, settings, tutorial, draw policy, recycle policy,
legal-move rules, auto behavior, completion, restart, or persistence. The exact
internal resource ID therefore remains unknown.

For this isolated local candidate, the user-requested seven-pile Klondike
contract is implemented as an explicit clean-room product decision. Generic
Klondike rules support the family shape, not a claim that version `3.14.1` uses
the same hidden tuning. The runtime default will be draw-one with unlimited
recycle for accessibility; the renderer-free model must also support draw-three
and a finite recycle limit so both policies are deterministic and testable.
Auto-foundation and snapshot recovery are local enhancements unless stronger
lawful target evidence is obtained.
