# Tile Club v3 target manifest

Date: 2026-08-20

## Baseline and isolation

- Exact public baseline: `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae`
- Isolated worktree: `/home/ubuntu/worktrees/offline-games-tileclub-fidelity-v3`
- Isolated branch: `codex/align-tileclub-v3`
- Product implementation: `tileclub`

The starting implementation was a flat, freely selectable 7×7 grid. Its prior
presentation smoke and screenshots are not evidence of reference fidelity.
2048 Balls and every other catalog game are outside this change boundary.

## Lawful first-party reference target

The bounded target is the observable core puzzle loop of GamoVation's **Tile
Club**, not its clubs, chat, tournaments, advertisements, boosters, economy, or
complete level catalog.

- Publisher product page: <https://www.gamovation.com/>
- Google Play resource: <https://play.google.com/store/apps/details?id=com.gamovation.tileclub>
- Apple resource: <https://apps.apple.com/app/id1640075364>
- Android package / Apple ID: `com.gamovation.tileclub` / `1640075364`
- Apple observed version: `3.5.2`, released `2026-07-01`
- Google Play observed update date: `2026-07-28`

The publisher page links those exact store resources. The App Store lookup
identifies `GamoVation` / `Gamovation B.V.`. Only public, observable behavior is
used. No first-party code, extracted level data, art, audio, copy, or screenshots
ship in this repository.

## Private evidence manifest

Raw first-party captures remain outside Git at
`/home/ubuntu/private-evidence/offline-games/tileclub-stage0/`. Committed audit
images show only this project's runtime.

| Private artifact | Measurement | SHA-256 |
|---|---|---|
| `gamovation-home.html` | publisher page and store links | `11275e786ef01c6c3337a7cffb8e9648f3f680c052c00a9729f3274dd3d4094d` |
| `google-play/page.html` | official store capture | `c1440339c003690ceecf663b951bb9b50d9344773fc8bce3d78c12c0d1ad6ebd` |
| `app-store/page.html` | official store capture | `b2cd38d1304c46914b7a41ee63889d0f46a5f85151bac584b2802ad1e766816c` |
| `app-store/lookup-us.json` | Apple resource/version metadata | `a04d39ed507006c1ee5b016f8516c1f66a69fb7214e8ccd47c796b8228fb53db` |
| `google-play/trailer-e9row3CAEGk.mp4` | 1280×720, 6.950 s, 20 fps, 139 frames | `e7ea3ed6ef2ee085e2a1fed2b10cd33664b62b3fdc838d1fca5aa500a8dd06f3` |
| `google-play/trailer-contact.png` | 28-frame contact sheet | `7d0ac52023ef37d0dba88cb331ee06449ede632f2282f32f3a6dd75e7a3ce2ff` |
| `google-play/screenshots-contact.png` | 14 official screenshots | `d9bb4fb4efa4e741afa675f5ee31e18956f20741d19b0355dcc4604f82f20a28` |
| `app-store/screenshots-contact.png` | 12 official screenshots | `78af41d979c125537f1c94c8a50f5b7c442c7badd97079ef6645d944f25e94be` |

The trailer resource ID is `e9row3CAEGk`. Original downloaded screenshot files,
normalized review copies, and their hashes remain beside the listed contact
sheets in the private evidence directory.

## Claim boundary

This candidate may claim only bounded core-loop alignment after Stage 0 passes,
and internal presentation strengthening after the later runtime gates pass.
Exact current levels, layout ordering, goal variants, difficulty/progression,
boosters, failure presentation/timing, score semantics, economy, and commercial
superiority remain `NOT_CLAIMED`.
