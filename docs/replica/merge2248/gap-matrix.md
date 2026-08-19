# Merge 2248 gap matrix

| Area | Previous state | Current state | Remaining gap |
|---|---|---|---|
| Core mechanic | 4×4 directional 2048 clone | 5×8 eight-direction Number Connect | Verify result rounding against a recorded long chain |
| Input | Swipe in four directions | Continuous pointer/touch path | Add backtracking-over-last-node if runtime evidence confirms it |
| Progression | Sparse 2048 spawning | Dense board, gravity, refill, expanding range | Exact probability curve remains an approximation |
| Win/loss | Score 2248 / no 2048 moves | 2048 tile / no equal adjacent pair | Validate difficulty-specific terminal presentation |
| Art | Dark teal energy matrix | Flat circular number nodes using measured palette | Particle, piano-scale audio, and 0.16 s fall animation remain |
| Layout | 4×4 board plus D-pad | 5×8 board with no false D-pad | Difficulty selector and undo are not exposed |

No reference bitmap, prefab, audio, or extracted implementation is committed.
