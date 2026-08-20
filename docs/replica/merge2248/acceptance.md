# Merge 2248 acceptance probes

- Opening the cartridge produces a 5×8 dense board and only Home/Restart controls.
- A two-node chain is accepted only when both numbers match.
- Every later node must be adjacent in one of eight directions and equal to or
  twice the previous node.
- Repeated cells and non-adjacent cells are rejected.
- Releasing a valid path increments score and move count once, creates one
  power-of-two result, applies gravity, and refills the board.
- A board without an equal adjacent pair is terminal.
- A 2048 result is a win.
- The separate `merge2048` cartridge retains its four-direction behavior.

Automated probes live in `tools/merge2248_model_smoke.gd` and
`tools/merge2248_integration_smoke.gd`; visual checkpoints live in
`tools/merge2248_visual_audit.gd`, and the bounded busy-event trace lives in
`tools/merge2248_performance_audit.gd`.
