# Amaze GO v3 target manifest

## Frozen target

| Field | Frozen value |
|---|---|
| Product | Amaze GO! |
| Target platform | Apple App Store, United States storefront |
| App Store resource ID | `6758326278` |
| Bundle / Android package ID | `com.oakever.arrows` |
| Version | `1.26.0` |
| Version release time | `2026-08-16T01:07:51Z` |
| Developer / seller | Oakever Games / `OAKEVER GAMES PTE. LTD.` |
| Evidence acquired | `2026-08-21` UTC |
| Exact implementation baseline | `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae` |
| Candidate branch | `codex/align-amaze-go-v3` |
| Candidate worktree | `/home/ubuntu/worktrees/offline-games-amaze-go-fidelity-v3` |
| Private evidence root | `/home/ubuntu/private-evidence/offline-games/amaze-go-v3/official` |

The Apple US lookup feed is the version anchor because it exposes a
reproducible version, release timestamp, bundle ID, seller, description and six
phone screenshot URLs. The Google Play page for `com.oakever.arrows` is a
second first-party rules source and reports an update on 2026-08-14, but the
captured page does not expose an Android version code.

No target executable or level data was acquired. The target binary digest,
internal level resource IDs, exact level generator, collision tolerances,
economy and persistence format are unknown. Store media remains private
evidence and must never enter a runtime asset, Web export or PCK.

## Evidence inventory

| Artifact | Role | SHA-256 |
|---|---|---|
| `apple-lookup-us.json` | Apple first-party identity, version, description and screenshot URLs | `11c9adadd9de369c419424166cc2a6d03891c8bcbdfe6a0c2611b53ea9846a5c` |
| `apple-store-us.html` | Apple US storefront capture | `5dcdebee97bf60eb199025f7def2012f78153881474907cc494e9a65a0ce0878` |
| `google-play-en-us.html` | Google Play first-party product page capture | `9a8aee0c2f8beb0300a0b42eada20e8cdabd51456938cdfcc0914b8023e8fe7d` |
| `apple-01.jpg` … `apple-06.jpg` | Current first-party phone screenshots, returned at 444 × 960 | hashes from `sha256sum` under the private evidence root |
| `google-play-01.png` … `google-play-05.png` | Current first-party Android screenshots, returned at 288 × 512 | hashes from `sha256sum` under the private evidence root |

Acquisition commands:

```bash
curl -L --compressed 'https://itunes.apple.com/lookup?id=6758326278&country=us'
curl -L --compressed 'https://apps.apple.com/us/app/amaze-go/id6758326278'
curl -L --compressed 'https://play.google.com/store/apps/details?id=com.oakever.arrows&hl=en_US&gl=US'
sha256sum /home/ubuntu/private-evidence/offline-games/amaze-go-v3/official/*
```

## Reproducible observation procedure

1. Verify `trackId`, `bundleId`, `version`, release timestamp and seller in
   `apple-lookup-us.json`.
2. Read the Apple and Google descriptions independently; use only developer
   statements as target facts, not store reviews or third-party summaries.
3. Inspect `apple-01.jpg` through `apple-05.jpg` in order and record only
   visible topology, live-arrow state, hearts and controls.
4. Compare the evidence against baseline commit `3e561fb3…`; do not treat the
   existing local smoke tests or clockwork presentation documents as proof of
   the target.

## Authorization and claim boundary

Public Apple and Google store metadata is lawful first-party reference evidence
for clean-room behavior study. No target art, screenshot, font, audio, binary
or level resource is copied into the candidate. Production authorization is
limited to this isolated branch; merge, push and deployment remain false.

“Aligned” may describe only the evidence-bounded extraction loop. It cannot
claim parity with 10,000+ levels, target level generation, zoom, events,
economy, advertising, timing, scoring or persistence.
