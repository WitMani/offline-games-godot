# Sudoku v3 target manifest

| Field | Frozen value |
|---|---|
| title | `Offline Games - No Wifi Games` / Sudoku |
| first-party target | Apple App Store track `6448104157`, seller `Jindoblu Limited` |
| version | iOS `3.14.1`, released `2026-08-07T15:42:11Z` |
| bundle ID | `com.JindoBlu.OfflineGamesIOS` |
| corroborating Android identity | Google Play package `com.JindoBlu.OfflineGames`, developer `JindoBlu` |
| package SHA-256 | unavailable: no distributable package was acquired; claims are bounded to the first-party listing/changelog/screenshots and separately labelled public gameplay capture |
| research date | `2026-08-20` |
| lawful basis | public first-party store listing, promotional screenshots, and developer site; public player-submitted gameplay is observation only |
| research environment | App Store lookup API and listing; Google Play public listing; static screenshot inspection at source resolution |
| replica starting HEAD | `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae` |
| private evidence root | `/home/ubuntu/private-evidence/offline-games/sudoku-stage0` |
| included flows | entry, puzzle validity, selection, given protection, place, erase, notes, hint, error, completion, restart, Web recovery, pointer/keyboard parity |
| non-goals | account/currency/ads, catalog progression, online services, difficulty system beyond the bounded puzzle fixture, copying reference code/art/audio/text/data |
| prohibited carry-over | reference binaries, code, artwork, audio, puzzle data, or generated text baked into raster assets |

## Immutable reference inputs

| Artifact | Type | SHA-256 |
|---|---|---|
| `itunes-lookup.json` | first-party Apple metadata response | `5b9203dfd9d2f7fcac6a8966b91db022ab262bdfa69f54da1d64e76a4c49786f` |
| `appstore-sudoku-iphone.png` | first-party App Store screenshot, 1242×2208 RGBA | `15bc66963ef82a9ad60876a07c08a4f03c42dd4effe23199df1285b7e5898731` |
| `appstore-sudoku-ipad.png` | first-party App Store screenshot, 2048×2732 RGBA | `c4554fe5ea52e9f0b5f13fc91ed6bcab9e9d064c8402d3457d6d31042f7b13f5` |
| `google-play.html` | first-party Google Play listing capture | `dd6026f96cc922dc186a6c06577d5007837af02368fa23dd3d0f6c43e721ea0a` |
| `jindoblu-home.html` | first-party developer-site capture | `75f3f6ebf99e8a847c54a053429149ece6c51e48676a6330566e8a50408f935c` |
| `speedrun-maxresdefault.jpg` | public player-run thumbnail, older build, 1280×720 | `78d9ad974f2d7766e4f5447854a64c99f498e9d5df52bce3ff7cc1e13b847106` |
| `rutube-2024-gameplay.mp4` | public third-party catalog capture; no Sudoku play segment observed | `285ea60f493eaeb1e0d51f76d14a161e6b6bd03cd30fa1813123467ede9099c6` |

Source URLs:

- <https://apps.apple.com/us/app/offline-games-no-wifi-games/id6448104157>
- <https://itunes.apple.com/lookup?id=6448104157&country=us>
- <https://play.google.com/store/apps/details?id=com.JindoBlu.OfflineGames&hl=en-US>
- <https://www.jindoblu.com/>
- <https://www.speedrun.com/ognwg/runs/ywx182pm>

The two screenshots are promotional stills, not a complete-loop recording. They
may establish visible objects and one displayed state, but not hidden rules or
timings. The player-run thumbnail is from an older build and is never promoted
to a `3.14.1` fact.
