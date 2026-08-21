# Snakes v3 target manifest

| Field | Frozen value |
|---|---|
| title | `Offline Games - No Wifi Games` / `Snakes` |
| first-party target | Apple App Store track `6448104157`, seller `Jindoblu Limited` |
| version | iOS `3.14.1`, released `2026-08-07T15:42:11Z` |
| bundle ID | `com.JindoBlu.OfflineGamesIOS` |
| corroborating Android identity | Google Play package `com.JindoBlu.OfflineGames`, developer `JindoBlu` |
| introduced lineage | App Store version history names `New game: Snakes` in `3.7.2` (2026-01-06) and `3.7.3` (2026-01-22) |
| internal resource ID | unknown; historical repository label `136_SNAKES` is not supported by an acquired package or first-party public resource catalog |
| package SHA-256 | unavailable: no distributable package was acquired; claims are bounded to first-party listings, version history, screenshots/video, and a dated first-party Google Play promotional event |
| research date | `2026-08-20` |
| lawful basis | public first-party store listings, promotional media, and developer-published Google Play event copy; no reference binary, code, art, audio, or data copied |
| replica starting HEAD | `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae` |
| private evidence root | `/home/ubuntu/private-evidence/offline-games/snakes-stage0` |
| included flows | offline entry, continuous steer, optional local boost decision, eat/grow, collision/death, bot respawn, rank/biggest objective, restart, reload recovery, pointer/keyboard parity |
| non-goals | online multiplayer/service parity, accounts, ads, currencies, skins/progression, invented terminal win, exact hidden collision/boost/AI tuning, copying protected content |

## Immutable captured inputs

| Artifact | Type | SHA-256 | Observation boundary |
|---|---|---|---|
| `apple/app-store.html` | first-party App Store listing and version history | `23f4a82a05cf7b9b760ce92781603ea61e86f3f8fad88052b3b0b7fdede3a324` | proves identity/version lineage; current promotional stills do not show Snakes gameplay |
| `apple/itunes-lookup.json` | first-party Apple metadata response | `e66f5f8e8e336a67d78aece631c7c93b80c0f3699c6bee10c5b70cb663cee99d` | proves track, bundle, seller, current version and date |
| `apple/largebanners-iphone.png` | first-party screenshot contact sheet | `334701f09048fced2d3871c989e1e2a84468fc347365689b47d177f057fdda82` | no Snakes play state observed |
| `apple/minibanners-iphone.png` | first-party screenshot contact sheet | `fe0a13946626f407c8c06801e7550371bcfe282935dc20d81c6466a30335a815` | catalog art only; no mechanics inference |
| `google-play/page.html` | first-party Google Play app listing capture | `f95d65928fdb458640e4c09bddc5668236080a4352ef982c1e359e599e95fae9` | proves Android identity/offline collection; current stills do not expose the arena |
| `google-play/official-trailer.mp4` | first-party Google Play trailer, 1280x720, 6.95 s | `99a2c739eb3b513a99d8fa044fecd81279465cacf81dc233179ea37b8e0ce746` | inspected frame sequence contains catalog/Color Cards, not Snakes gameplay |
| `google-play/official-trailer-contact.jpg` | derived trailer contact sheet | `08b1207c2f047ba0047189808ad48b7fa82f60d9af43a943f7b7b4f4e698657c` | measurement aid only |
| `google-play/screens-contact.jpg` | derived current screenshot contact sheet | `cbc999816c65eae7931d57f271a362d7dec356b149facd508df8b7af4c1628f1` | no Snakes gameplay observed |

Source URLs:

- <https://apps.apple.com/us/app/offline-games-no-wifi-games/id6448104157>
- <https://itunes.apple.com/lookup?id=6448104157&country=us>
- <https://play.google.com/store/apps/details?id=com.JindoBlu.OfflineGames&hl=en-US>
- <https://play.google.com/store/games?hl=en_NZ&id=NKKRAAAAIAAJ>

The last URL is a dated Google Play promotional-event surface cached by public
search on the research date. Its developer-published copy calls Snakes an
arcade `.io` challenge, says to eat food, avoid other snakes, become the
biggest, and says both online multiplayer and offline play are available. The
event is strong first-party promotional evidence, but it is not an immutable
package inspection and does not establish hidden control, collision, boost,
death, respawn, rank, win, restart, or persistence rules.
