# Amaze v3 claim ledger

| Statement | Class | Confidence | Runtime consequence |
|---|---|---:|---|
| A direction/swipe sends the ball across multiple axial cells until the next cell is void or outside the board | observed fact | high | `AmazeModel.command()` traces to the last legal cell |
| Traversed cells become painted in travel order | observed fact | high | ordered `traversed`, `newly_painted`, and `paint_order` outputs |
| The ball does not automatically turn at a junction | observed fact | high | one cardinal command creates one straight leg |
| Completion requires every playable square, while void cells are excluded | official copy + observed fact | high | `painted_count == walkable_count` wins |
| Restart and numbered challenges exist | observed fact | high | same-level restart and a separate next-level action are exposed |
| Re-entering painted cells is legal | conservative inference | medium | revisit changes position and move count, but not paint count or score |
| One accepted command counts as one move | local interpretation | medium | move count increments per accepted direction, not per crossed cell |
| Three deterministic topologies and their order | product decision | high | clean-room fixtures; no claim of copied or complete reference levels |
| Five points per new cell plus 100 on completion | shell decision | high | shared catalog score field only; not claimed as original scoring |
| Accepted command history is replay-validated on reload | reliability decision | high | malformed/cross-level/tampered checkpoints reject atomically |

## Explicit unknowns

- Exact current mobile topology data, level order, unlock pacing, difficulty
  curve, scoring, move semantics, transition timing, and economy.
- Whether current Classic mode limits revisits in any special late level.
- Exact behavior of Time Rush, Limited Moves, multiplayer, and console-only
  variations.

These unknowns cannot be promoted from inference to fact by presentation
similarity or by passing local tests.
