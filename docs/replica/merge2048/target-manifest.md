# Classic 2048 target manifest · fidelity v4

| Field | Frozen value |
|---|---|
| title | `2048` by Gabriele Cirulli |
| version | official GitHub `master` at `478b6ec346e3787f589e4af751378d06ded4cbbc` |
| platform | original Web implementation |
| package SHA-256 | deterministic `git archive` tar: `b518a4bf1d6e3dd2e018c0e9d1c778bd8e745dd5be1327ab68efa736298f2754` |
| acquired at | `2026-08-20T21:00:00Z` (existing private, clean pinned clone revalidated) |
| rights basis | public first-party repository under the MIT license; user-authorized clean-room comparison |
| research environment | read-only source inspection on EC2; original runtime code and distributable files remain outside this product repository |
| replica starting HEAD | `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae` |
| replica source | `/home/ubuntu/worktrees/offline-games-2048balls-visible`, branch `codex/art-2048balls-visible-v3`, clean at acquisition |
| implementation worktree | `/home/ubuntu/worktrees/offline-games-merge2048-fidelity-v4`, branch `codex/align-merge2048-v4` |
| private evidence root | `/home/ubuntu/private-evidence/offline-games/merge2048-stage0/original-2048` |
| included flows | new game; four-direction keyboard/button/swipe input; legal and ineffective moves; ordered merge; random spawn; score/best; 2048 pause; keep playing; no-moves loss; restart; active-run recovery |
| non-goals | current commercial `play2048.co` power-ups, tutorial, advertising, app-store metagame, exact CSS, and reuse of original art/audio/text |
| prohibited carry-over | original JavaScript, HTML, CSS, images, strings, and other distributable data; the source is evidence only |

Primary first-party identity sources:

- <https://github.com/gabrielecirulli/2048>
- <https://gabrielecirulli.github.io/2048/>
- <https://github.com/gabrielecirulli/2048/blob/478b6ec346e3787f589e4af751378d06ded4cbbc/LICENSE.txt>

The official site identifies itself as the original version. The repository
describes itself as the source code for 2048 and provides the MIT license. The
pinned commit, not a moving website snapshot, is the rules oracle for this
slice. A later upstream change requires a new manifest.

## Reference-file integrity

| Private reference file | SHA-256 |
|---|---|
| `README.md` | `3b624490f45eb6315b00bcaac65cefa713678401c42971b0e65cad8d8ff0ccfc` |
| `index.html` | `7a76f74c23aeb8ee6af73ff796343834b82f75271a610b7174a8ea6707cc8c77` |
| `js/application.js` | `5fc43863225b371c458615ef431fac73003546f437aa32026641de48817bd27a` |
| `js/game_manager.js` | `b02baa6b75f8c8cad8606e680b6f73b7c843c61e3a643ee48410022499a649f0` |
| `js/grid.js` | `169428f5ff7f726c38112fcf1c918028cbca3a1d9f9239838fbc7eb4396b9f9a` |
| `js/tile.js` | `13699e51d62179a6d36874108831a29901a98d6e11329918e64cfb5ee82d58e3` |
| `js/keyboard_input_manager.js` | `7d579ab5b67dddf339cf28a7d06e4e24eca08b0187204ce352d67c49ae1e48de` |
| `js/local_storage_manager.js` | `8e12c6a9aa34097c0b634b1f6690da091b1b4ac158ff914097a8ac83c86b5bc6` |
| `LICENSE.txt` | `57e12c39a6ad9d98b2e451065bfdfbd15fc9e0c2ed3bf4dc1d09acab41ff02fc` |

Private clone state was clean at the pinned commit when revalidated. The
archive hash was recomputed from `git archive --format=tar HEAD`.

## Rule contract: facts and measurements

The following are facts observable in the pinned first-party source:

- a new run constructs an empty `4 × 4` grid and adds exactly two random tiles;
- a direction is resolved by traversing cells from the far edge back toward
  the input edge, so every tile travels as far as legal in that direction;
- equal neighbors merge at most once during a move because a just-created tile
  is marked as already merged for that traversal;
- each merge adds the resulting tile value to score;
- only a state-changing move creates one random tile; an ineffective direction
  changes no board/score state and creates nothing;
- the random tile is `2` at threshold `Math.random() < 0.9`, otherwise `4`;
- creating a `2048` tile raises a win pause; the explicit keep-playing action
  resumes the same board and permits values beyond 2048;
- loss is set after a legal move and spawn when no empty cell and no
  orthogonally adjacent equal pair remain;
- restart clears the active run and makes a fresh two-tile board while the best
  score remains; a non-lost active run serializes board, score, win, and
  keep-playing state for recovery;
- arrow keys, WASD, HJKL, and a dominant-axis single-touch swipe map to the same
  four directions; `R`, retry, and new-game controls restart.

Measured source constants are `startTiles = 2`, the `0.9` spawn threshold,
and a swipe displacement strictly greater than `10` CSS pixels. The replica
uses the same strict threshold in its logical portrait coordinate space.

## Clean-room decisions and unresolved visual claim

The replica may use independently authored Godot code, deterministic seeded
fixtures, bundled CJK/UI fonts, original cartoon workshop art, and stronger
semantic feedback. Those are decisions. No claim of
pixel or presentation equivalence is made, and “surpasses the original” remains
`NOT_CLAIMED` until matched original/candidate runtime review exists.
