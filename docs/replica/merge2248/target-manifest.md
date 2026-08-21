# Merge 2248 target manifest

## Locked target

- Product: `Offline Games - No Wifi Games`
- Target minigame: `2248`, presented as `NUMBER CONNECT`
- Publisher identity: JindoBlu / Jindoblu Limited; the Apple storefront also
  identifies developer Moreno Maio
- Apple app id: `6448104157`
- Apple bundle id: `com.JindoBlu.OfflineGamesIOS`
- Android package: `com.JindoBlu.OfflineGames`
- Observed current Apple version: `3.14.1`
- Observed current Apple release date: `2026-08-07T15:42:11Z`
- Evidence capture date: `2026-08-20`
- Product implementation: `merge2248`

The public target is locked to these first-party pages:

- Apple App Store:
  `https://apps.apple.com/us/app/offline-games-no-wifi-games/id6448104157`
- Apple iTunes lookup API:
  `https://itunes.apple.com/lookup?id=6448104157&country=us`
- Google Play:
  `https://play.google.com/store/apps/details?hl=en_US&id=com.JindoBlu.OfflineGames`

Apple's current listing explicitly names both 2048 and 2248 among its number
games. Its current official 2248 iPhone and iPad promotional images are the
ninth entries in the respective screenshot arrays returned by the lookup API.
The current Google Play screenshot set establishes the Android product identity
but does not show Number Connect, so it is not used as a mechanics source.

## Private evidence index

Reference captures remain outside this repository. Only immutable hashes and
observations are committed.

| Capture | Role | SHA-256 |
|---|---|---|
| `app-store.html` | first-party Apple listing | `a7defc567766e850472d6f3e461142d4b29169faa6364561bf5e89570529583b` |
| `itunes-lookup.json` | first-party version, identity and screenshot URLs | `5b9203dfd9d2f7fcac6a8966b91db022ab262bdfa69f54da1d64e76a4c49786f` |
| `appstore-2248-iphone.png` | official 1242 x 2208 promotional image | `e6ae71c23c52ff7cde80c85ed019613400403abdc7926d62064818e23097b97c` |
| `appstore-2248-ipad.png` | official 2048 x 2732 promotional image | `56abc2a964ca4bd3146b5794b842ea0d15b643820da58c40a82640064821d863` |
| `reddit-high-score.jpeg` | secondary easy-mode runtime observation | `02add9651a2684ad6498f51724df6d5eecd5663b894ee653192e1a9ebd02d124` |
| `reddit-hard-mode.jpeg` | secondary hard-mode runtime observation | `330b79f64ddb81e3088bc1290028c65d210871a99a81459f9d0e78a4be5a3061` |

The two secondary images were linked from:
`https://www.reddit.com/r/puzzlevideogames/comments/1itufra/number_connect_offline_games_high_score/`.
They are useful runtime observations, not first-party specifications.

## Historical local measurements

Earlier clean-room notes identify build `3204`, minigame id `83_2248`, and
runtime family `JungleFrog.Games.Z248`. The extracted reference material that
produced those measurements is no longer present on EC2 or HOME-WSL, so those
values are retained as historical measurements rather than newly reproducible
facts. They must not silently promote an uncertain rule to an original-fidelity
claim.

No reference bitmap, prefab, source audio, APK, or extracted implementation is
committed or shipped.
