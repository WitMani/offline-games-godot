# Amaze GO v3 claim ledger

This ledger prevents the baseline clean-room maze walk, generic arrow-puzzle
conventions and screenshot interpretation from being reported as Amaze GO!
facts.

| Class | Statement | Evidence / boundary |
|---|---|---|
| First-party fact | The frozen product is Oakever Games’ Amaze GO! 1.26.0, App Store ID `6758326278`, bundle/package `com.oakever.arrows`. | Apple US lookup JSON; Google Play product page. |
| First-party fact | Each arrow has a direction; the player chooses an order. | Apple and Google first-party descriptions. |
| First-party fact | An arrow whose path to the edge is free can be tapped and slides out of the grid. | Both store descriptions, “How to Play.” |
| First-party fact | A wrong tap costs one heart. | Both store descriptions. The initial/capacity rules are not stated. |
| First-party fact | Clearing the board finishes the level. | Both store descriptions. |
| First-party fact | Long-press Guidance and hints are advertised. | Both store descriptions. Their exact selection, cost and limits are unknown. |
| Screenshot observation | Current promotional boards consist of many disconnected thin orthogonal polylines ending in arrowheads; there is no player avatar, start cell, destination cell or wall maze. | Apple screenshots 1–5 and Google screenshots 1–5. |
| Screenshot observation | Screenshots show varied board silhouettes and densities at Levels 10, 27, 40, 99 and 199. | Same first-party screenshots. |
| Screenshot observation | Three to five droplet icons appear near the top, and a grid button and light-bulb button appear below the board. | Same screenshots. This does not prove the heart-capacity algorithm. |
| Screenshot observation | Screenshot Level 40 shows a red highlighted polyline and one blue droplet with four dim droplets. | First-party screenshot 3. The trigger and duration are not observable. |
| Inference | Each visible polyline is one arrow body and the terminal arrowhead defines its exit direction. | Strong screenshot inference; not stated as geometry in store copy. |
| Local decision | A bounded arrow is an ID plus a non-self-intersecting orthogonal cell polyline; the head is the final point and direction is the final segment. | Auditable clean-room topology, not copied target level data. |
| Local decision | An arrow is legal when the forward ray from its head to the board edge intersects no live cell belonging to another arrow. | Operational interpretation of “free path to the edge”; target pixel collision tolerances are unknown. |
| Local decision | Legal extraction removes the entire arrow atomically; removed arrows cannot return or be revisited. | Keeps the verified ordering loop authoritative. The target animation path is unknown. |
| Local decision | The bounded level starts with three hearts; a blocked selection loses one, and zero hearts produces `over`. | Store proves a one-heart cost only. Capacity and zero-heart transition remain unclaimed target behavior. |
| Local decision | Hint selects the first legal arrow in deterministic ID order without spending currency. | Accessibility/testability decision, not target economy. |
| Local decision | Mouse and touch share the same hit resolver; keyboard focus uses arrows/WASD and Enter/Space, H requests a hint and R restarts. | Catalog accessibility enhancement; no keyboard support is claimed for the mobile target. |
| Local decision | Strict recovery accepts only a fully validated snapshot for the exact bounded level; invalid or terminal-inconsistent payloads are rejected. | Local reliability requirement, not an original persistence claim. |

## Explicit unknowns

- exact target level resources, generator and difficulty progression;
- whether an arrow body translates rigidly or follows its own curve while
  leaving the board, and exact collision/hit tolerances;
- starting/maximum hearts, bonuses and the exact zero-heart flow;
- Guidance gesture timing, hint selection, cost, availability and highlight;
- scoring, timing, stars, combo, zoom, haptics and audio routing;
- restart, background/reload recovery and event-mode rules.

These unknowns keep complete-original-parity and “surpasses the original”
claims closed. The candidate may claim an evidence-bounded extraction core and
locally stronger presentation only after every gate passes.
