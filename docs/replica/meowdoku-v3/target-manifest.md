# Meowdoku v3 target manifest

## Frozen target

- Product selected by the owner: Oakever `Meowdoku`, not the numeric Sudoku
  minigame previously shipped under this cartridge id.
- Android package: `com.oakever.meowdoku`
- Store title: `Meowdoku: Brain Puzzle Games`
- Target platform/version: Android `1.14.0`
- Target store page:
  <https://play.google.com/store/apps/details?id=com.oakever.meowdoku&hl=en_SG&gl=SG>
- Evidence freeze date: 2026-08-20 UTC
- Product baseline: `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae`
- Package SHA-256: `unknown` — no APK was acquired, and the first-party
  storefront does not publish a package digest.

The target version is intentionally Android `1.14.0`: the owner's external
selection record points to the Android package. The official iOS listing for
`com.oakever.meowdoku`, version `1.13.1`, is corroboration only and is not
silently treated as the same build.

## First-party evidence inventory

The captured pages and screenshots stay outside the repository at
`/home/ubuntu/private-evidence/offline-games/meowdoku-stage0/oakever`. This
repository stores only independent observations, measurements, decisions, and
code.

| Evidence | Role | SHA-256 |
|---|---|---|
| Google Play page capture | Android identity, version, description, official screenshot URLs | `b412787622be5018ddcf8d2a3a72d97e5195173af6ef8c29955aaed05c284c42` |
| Google Play screenshot 01 | 5×5 promotional completion scene | `a09567b8f06bb9675f32ba5ab3398956d99d55d6e447aa9447c59da2bfa2e25d` |
| Google Play screenshot 02 | Level 1, 5×5, `1/5`, three hearts | `dbebfaee9e0a5cc221845e1a414e8371c5ef03eba0d2f6972c44b883b8ca528f` |
| Google Play screenshot 03 | Level 1, row/column rule card, X marks | `6395f77033ba8cb086f71b7ead5c16f4167863e4634550b1ae6899686ce4f264` |
| Google Play screenshot 04 | Level 1, non-touching rule card | `c970b6a24458c62dd219686559e86ba66cfbd2a81ef7b69ebab45f3f858d22f3` |
| Google Play screenshot 05 | Level 1 complete, `5/5` | `7647e5a4d79bfce6b41bca62b4b85c54aaa04634d5fd0bc3844dc0728a585202` |
| Google Play screenshot 06 | Level 24, 7×7, `5/7`, question cells | `4b5173071de6eac46fbfccf7358cd106fef39f4c469a948878ff8f5e61f1411a` |
| Google Play screenshot 07 | In-game controls in a phone composition | `76c8aad0df3a93722759cd2c721dc358d39250557b337f30488b09848fabd044` |
| Google Play screenshot 08 | Multiple level/board-size compositions | `5818603b4f9cab2bc7449807b9c6a8dea1dcc787ba2e816cd8a9e52ed926062a` |
| Apple lookup JSON | Official cross-platform identity, rules text, iOS version | `1fbc23ad74b95cbb8aa9189d14b0ddd8fd59a363c6bf56e9e50549ee74299108` |
| Apple screenshots 01–06 | Cross-platform visual corroboration | `231b09d10aa055d901aac2baa52888d1388c58b5e3b01f089ae97601c5a2a396`, `4dd775cc903461710c30c5102443d50cca88ed81458472806ef429caf78178cb`, `ad0e80a767851932789c9ea6f8f86d404864a8a9f9bac2cbcc49b25ed333ea17`, `3239a09ef2a9140f149facb0550108d60fd0bf1a511231c3370a9be80e17a5c6`, `2e1857b9fdc36ac8b5a7bb47a52a78123d727692066faa41319c8352e747bb6e`, `a02ffb6b2d499693793bd1c7baefa4bfd16f278f8e107059e458648543f37a1e` |

No first-party gameplay recording was present on the frozen store pages. Motion
timing, intermediate gesture handling, and terminal-screen choreography are
therefore outside the current factual claim boundary.

## Included replica slice

- Deterministic independently-authored 5×5, 6×6, and 7×7 region puzzles.
- Exactly one cat in each row, column, and colored region.
- Cats cannot touch diagonally.
- Selection, exclusion marks, double-action cat placement, three-heart error
  budget, loss, completion, restart, and checkpoint recovery.
- Pointer/touch semantics plus explicit desktop keyboard parity.
- A cat-stationery presentation with readable CJK text and reduced-effects
  behavior after the renderer-free mechanics gate passes.

## Explicit non-goals

- Daily puzzles, leaderboards, ads, purchases, account services, and network
  features.
- Extracting or redistributing the original package, levels, graphics, audio,
  fonts, or implementation.
- Claiming exact parity for question-cell semantics, hint/locate behavior,
  progression generation, terminal overlays, or animation timing without
  stronger evidence.
