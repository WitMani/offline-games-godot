# Vita Mahjong v3 claim ledger

This ledger prevents generic Shanghai-solitaire convention, screenshot reading
and local quality decisions from being reported as Vita Mahjong facts.

| Class | Statement | Evidence / boundary |
|---|---|---|
| First-party fact | The frozen product is Vita Mahjong 3.34.0, App Store ID `6468921495`, bundle `com.vitastudio.mahjong`. | Apple lookup JSON. |
| First-party fact | It is a Mahjong Solitaire-style pair-matching puzzle, not traditional multiplayer Mahjong. | Current Google Play description explicitly states this distinction; Apple calls it Mahjong Solitaire. |
| First-party fact | The core action is tapping matching tiles; matching pairs are removed and clearing the board succeeds. | Apple “How to Play”; Google Play additionally says tap or slide. |
| First-party fact | Eligible target tiles are not concealed or blocked. | Current Google Play description. It does not define the geometry precisely. |
| First-party fact | Hints, undo and shuffle are advertised helpful tools; offline play is advertised. | Current first-party store descriptions. Exact costs, limits and transformations are unknown. |
| First-party fact | The Apple listing says no time limits; Google describes play without timer or score pressure. | First-party descriptions. This does not prove there is never another loss mode. |
| Screenshot observation | Boards visibly contain overlapping layers; foreground tiles are bright and background/occluded tiles are dim. | Apple iPhone screenshots 1–6 and iPad screenshots 1–6. |
| Screenshot observation | A wood-framed rail at the top holds zero or more recently paired tiles. | Same first-party screenshots. Its precise lifecycle is not observable. |
| Screenshot observation | Shuffle, light-bulb and curved-back-arrow controls are visible below the board. | Same first-party screenshots. |
| Screenshot observation | Standard suits/honors and flower/season-like faces appear; several board silhouettes are shown. | Same screenshots. Pair equivalence rules for special faces are not observable. |
| Inference | Bright tiles are currently selectable and dim tiles are blocked. | Strong visual inference, not confirmed by an interaction recording. |
| Inference | Higher layers cover lower tiles and horizontal neighbors can block a tile. | Consistent with screenshot state and the Mahjong Solitaire label; the store does not publish collision tolerances. |
| Local decision | A tile is free when no live higher-layer footprint overlaps it and at least one horizontal side on its own layer is open. | Auditable traditional Shanghai-compatible rule chosen for the bounded clone. Never report as exact Vita geometry. |
| Local decision | The bounded board uses 36 deterministic tiles, 18 exact pairs and a provably peelable layered layout. | Keeps the full loop testable at 540 × 960; it is not a copied Vita level. |
| Local decision | Match score is +50, mismatch switches selection, hint is free, undo restores one pair and shuffle is deterministic. | Compatibility choices. Vita scoring, tool allowance/economy and mismatch selection are unknown. |
| Local decision | A board with remaining tiles but no available equal free pair is `stuck`; shuffle or restart can recover it. | No first-party loss/reshuffle transition recording exists. Do not call this an original loss rule. |
| Local decision | Mouse and touch share the same topmost hit resolver; keyboard focus uses arrows plus Enter/Space, with H/S/U aliases for hint/shuffle/undo. | Accessibility parity for this catalog. No keyboard support is claimed for the mobile original. |

## Explicit unknowns

- exact Vita board generator, layouts, tile count and difficulty progression;
- whether every board is guaranteed solvable and when automatic reshuffle runs;
- exact free-tile footprint, tolerance and treatment of special tiles;
- slide gesture recognition, hint choice, undo depth, shuffle algorithm and
  tool limits or advertising economy;
- combo, scoring, sound, haptics, terminal timing and reload persistence;
- daily challenge and Active Mind rules.

These unknowns keep any final “surpasses the original” claim closed. The
candidate may claim a mechanically coherent, evidence-bounded core with a
stronger local presentation only after all gates pass.
