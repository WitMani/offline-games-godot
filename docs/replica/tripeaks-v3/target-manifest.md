# TriPeaks v3 target manifest

| Field | Frozen value |
|---|---|
| user-selected target | `Solitaire Tripeaks` mapping in the private source inventory |
| first-party target | Google Play package `pfreecell.pyramid.klondike.solitaire.tripeaks.solitaire` |
| current public title | `Solitaire Farm: TriPeaks` |
| developer | `Forever Software` |
| Android version | `1.0.53` (embedded first-party Google Play metadata) |
| listing update date | `2026-08-02` |
| target resource ID | package ID above; no finer internal level/resource ID is available |
| package SHA-256 | unavailable; no target APK was acquired |
| evidence date | `2026-08-20` |
| lawful basis | user-provided target mapping plus public first-party Google Play listing/media; no target binary, code, art, audio, or data copied |
| exact replica baseline | `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae` |
| isolated candidate | branch `codex/align-tripeaks-v3`, worktree `/home/ubuntu/worktrees/offline-games-tripeaks-fidelity-v3` |
| private evidence root | `/home/ubuntu/work/offline-games-private/reverse/tripeaks-v3/google-play` |
| evidence verdict | `PARTIAL_EVIDENCE`: identity/version are frozen; target-specific mechanics and reproducible action states are not |
| release boundary | local candidate only; do not merge, push, deploy, or change Aliyun |

## Frozen evidence inventory

| Artifact | Kind | SHA-256 | What it can establish |
|---|---|---|---|
| `No WIFI Game 游戏选择.md` | user-provided target mapping | `d00ebed74b52a90db57c34f4a0e4ed8d8a788eeded4ad71ab9819b74c0b44756` | maps the requested `Solitaire Tripeaks` slot to the exact package URL |
| `listing.html` | first-party Google Play listing capture | `c20bfe90815fb3cbf5f449511805baa099e70e1c06ed668130756598ef095014` | package, title, developer, version `1.0.53`, update date, offline/classic marketing claims |
| `listing.headers` | first-party response headers | `6d77552a6c8fdb09d2bf1de6db9c9d4fa49098da37ee33a0c84a5bfd8d06cb2f` | capture transport context only |
| `screenshot-01.webp` | first-party promotional image, 1920x1080 | `7e820495c6f05a091e667c8c6a656d79c59d3f82a40bf37743cf5a98b172df92` | card/back/wild/booster visual vocabulary; not a reproducible play state |
| `screenshot-02.webp` | first-party promotional image, 1920x1080 | `d5906dbe3c576df7fe3fcaab71ecf99c8949bfb9597b8320f16128e64d31a56e` | branding and card/back-grid composition; not a reproducible play state |
| `screenshot-03.webp` | first-party promotional image, 1920x1080 | `43d9944fd159c26b212d7ff97720f1dcc0d4cf159145f62df641a4f5970a7dad` | farm-story event styling; not rule-bearing evidence |
| `screenshot-04.webp` | first-party promotional image, 1920x1080 | `851f47d47c7a537b26dcd5865c9b46b0a47220a551e3cc3be4fd6d39d63a328c` | farm-meta styling only |
| `screenshot-05.webp` | first-party promotional image, 1920x1080 | `9e591697597cb6cebefb10d9072038145bfbf09477a882aba05c068862dc23d6` | reward-wheel styling only |

Source URL:

- <https://play.google.com/store/apps/details?id=pfreecell.pyramid.klondike.solitaire.tripeaks.solitaire&hl=en>

## Reproducibility and action-evidence boundary

The first-party listing says `Classic Gameplay`, names a `solitaire three
peaks` challenge, advertises offline play, and describes many layouts. It does
not publish a deterministic deal, input trace, tutorial sequence, rule text,
or video belonging to this exact package. The five current store images are
marketing composites rather than source-resolution runtime frames. They cannot
support a matched-state or matched-action replay.

Consequently, the listing does **not** establish the exact 28-card topology,
deck order, blocker graph, Ace/King wrapping, score, streak tuning, stock
exhaustion, win/loss transitions, terminal freeze, restart, recovery, or input
parity. Those behaviors must not be described as package-version facts.

## Clean-room local contract

For this isolated candidate, the requested full TriPeaks rules are implemented
as a local product decision: 52 unique cards, a canonical 28-card three-peak
tableau, one initial waste card, 23 stock cards, exposed-card-only clearing,
and rank-adjacent moves. The baseline already told users that Ace and King are
adjacent, so wrap remains enabled as an explicit local compatibility choice,
not a target observation. Existing score/streak values remain local tuning.

This contract may be proven by renderer-free and shell/browser probes. It can
raise local implementation quality, but cannot raise the target-version claim
above `PARTIAL` without stronger lawful evidence.
