# Vita Mahjong v3 target manifest

## Frozen target

| Field | Frozen value |
|---|---|
| Product | Vita Mahjong |
| Target platform | Apple App Store, United States storefront |
| App Store resource ID | `6468921495` |
| Bundle ID | `com.vitastudio.mahjong` |
| Version | `3.34.0` |
| Version release time | `2026-08-19T01:58:06Z` |
| Developer / seller | Vita Studio / `VITA STUDIO PTE. LTD.` |
| Evidence acquired | `2026-08-20` UTC |
| Exact implementation baseline | `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae` |
| Candidate branch | `codex/align-mahjong-v3` |
| Candidate worktree | `/home/ubuntu/worktrees/offline-games-mahjong-fidelity-v3` |
| Private evidence root | `/home/ubuntu/private-evidence/offline-games/mahjong-fidelity-v3/stage0` |

The Apple US listing is the version anchor because its first-party lookup feed
provides a reproducible version, release timestamp, bundle ID, description and
six iPhone plus six iPad screenshots. The current Google Play listing for
`com.vitastudio.mahjong` is identity and rules corroboration only; it does not
publish a reproducible Android version code in the captured page.

No app binary was acquired. Consequently the target binary digest, internal
level resource ID, RNG, exact board generator and exact tool economy are
unknown. Store media stays outside the repository and must not ship in a Web
bundle or PCK.

## Evidence inventory

| Artifact | Role | SHA-256 |
|---|---|---|
| `apple-lookup-us.json` | Apple first-party version, identity, description and screenshot URLs | `bf724e91d5824cb4ec5177062c5cc95bf8cabdf437ae9091f0d9000ba0c5ebb6` |
| `apple-store-us.html` | Apple US storefront capture | `72568feb72c6ea09708830d4db1bc8b1c4d8577ae78854794d9ba8484f8dcafb` |
| `google-play-en-us.html` | Google Play first-party product page capture | `3b7edaa6392f07add21b6e78ef4cd7a97bf8ba8b2230604fd7e7aa95ce6cb6f8` |
| `apple-iphone-1.jpg` … `apple-iphone-6.jpg` | Current first-party phone screenshots, 1179 × 2096 | hashes in `apple-screenshots.sha256` |
| `apple-ipad-1.jpg` … `apple-ipad-6.jpg` | Current first-party tablet screenshots, 2048 × 2732 | hashes in `apple-screenshots.sha256` |

Acquisition commands:

```bash
curl -L --compressed 'https://itunes.apple.com/lookup?id=6468921495&country=us'
curl -L --compressed 'https://apps.apple.com/us/app/vita-mahjong/id6468921495'
curl -L --compressed 'https://play.google.com/store/apps/details?id=com.vitastudio.mahjong&hl=en_US&gl=US'
sha256sum /home/ubuntu/private-evidence/offline-games/mahjong-fidelity-v3/stage0/*
```

## Reproducible observation procedure

1. Read `apple-lookup-us.json` and verify `trackId`, `bundleId`, `version`,
   `currentVersionReleaseDate`, seller and the twelve screenshot URLs.
2. Inspect the six iPhone screenshots in numerical order at native resolution.
3. Record only visible state: foreground/background tile brightness, overlap,
   paired-tile rail and the three circular tool icons.
4. Read the Apple and Google descriptions separately. Do not use reviews as
   target facts and do not infer an exact rule from the word “blocked.”
5. Compare those facts to the implementation at the exact baseline commit,
   not to later art-direction claims or presentation tests.

## Authorization and claim boundary

Public App Store and Google Play metadata are lawful first-party reference
evidence for clean-room behavior study. No target artwork, screenshot, font,
audio or executable is copied into the candidate. Production authorization,
merge, push and deployment remain false. “Aligned” can only mean the bounded
core contract below; it cannot imply parity with every one of the advertised
10,000+ levels, daily challenges, special tiles, ads or economy.
