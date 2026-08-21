# Merge 2248 acceptance probes

> Stage 0 v4 failed the pre-existing tree. Candidate commit `46cd36b` now
> satisfies every evidence-backed correction and implementation gate from that
> audit. Exact chain rounding, refill probability, backtracking, undo depth and
> loss/recovery remain labelled compatibility behavior rather than recovered
> original rules. `stage0-fidelity-v4.md` supersedes every earlier claim that
> 2048 is a win.

- Opening the cartridge produces a 5×8 dense Easy board with Home, Restart,
  difficulty and one-level Undo controls.
- A two-node chain is accepted only when both numbers match.
- Every later node must be adjacent in one of eight directions and equal to or
  twice the previous node.
- Repeated cells and non-adjacent cells are rejected.
- Releasing a valid path increments score and move count once, creates one
  power-of-two result, applies gravity, and refills the board.
- A board without an equal adjacent pair is terminal only as an explicitly
  labelled local compatibility boundary; the original recovery path is open.
- Creating 2048 does **not** end the run; the old win assertion must be removed.
- Easy and Hard exercise distinct observed 5 x 8 and 5 x 6 boards.
- A versioned round trip restores board, score, all-time, moves, difficulty and
  deterministic continuation state.
- Undo restores the preceding authoritative move state without reproducing ads.
- Long-run tile and score fixtures exceed 64-bit presentation needs without
  overflow or scientific-notation drift.
- The separate `merge2048` cartridge retains its four-direction behavior.
- A 2-, 3-, 5-, and 8-node fixture resolves to feedback grades 1–4
  respectively without changing score, move count, result value, gravity, or
  refill rules.
- Every higher grade increases at least four independent runtime channels:
  haptic pattern, directional shake, property-animation amplitude/duration,
  and visible ring/particle density. Labels and color are supporting channels,
  not the only distinction.
- System `prefers-reduced-motion` keeps the exact model transition, result and
  semantic callout while suppressing haptics, shake, board transform, travel
  echoes, burst rings and crumbs; a short static local ring remains.

Automated probes live in `tools/merge2248_model_smoke.gd`,
`tools/merge2248_integration_smoke.gd` and
`tools/merge2248_persistence_smoke.gd`; visual checkpoints live in
`tools/merge2248_visual_audit.gd`; the four-grade event proof lives in
`tools/merge2248_juice_visual_audit.gd`; matched accessibility evidence lives
in `tools/merge2248_reduced_effects_visual_audit.gd`; and the bounded normal /
reduced grade-4 busy-event traces live in
`tools/merge2248_performance_audit.gd`. `tools/merge2248_web_acceptance.py`
performs a real browser drag, undo, deterministic replay, reload recovery,
restart, mode switch and haptic interception. `tools/merge2248_pack_gate.py`
checks the exact fingerprinted pack shipping boundary.

These probes make the isolated candidate internally reviewable. They do not
close the remaining original-evidence gaps or authorize an original-parity,
commercial-art-superiority, merge, push or public-deployment claim.
