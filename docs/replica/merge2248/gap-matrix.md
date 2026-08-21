# Merge 2248 gap matrix

This is the concise view. The authority for evidence classes and entry gates is
`stage0-fidelity-v4.md`.

| Area | Current candidate | Evidence-aligned requirement | Status |
|---|---|---|---|
| Core identity | Dedicated 5-column path game | 2248 / Number Connect in Offline Games | PASS |
| Board modes | UI exposes Easy 5 x 8 and Hard 5 x 6; uncertain 7/5-row mappings remain hidden compatibility constants | Easy 5 x 8 and Hard 5 x 6 are directly observed; other labels remain uncertain | PASS for observed modes |
| Path | Continuous eight-neighbor, same-first then same/double | Compatible with historical measurement, not yet a reproducible action trace | PARTIAL |
| Result | Exact exponent-domain sum then ceil-power-of-two | Exact long-chain transform unresolved; official image is a branching composite | COMPATIBILITY, probed |
| Refill | Deterministic dense gravity/refill with adaptive ceiling | Exact spawn set and probability curve unresolved | COMPATIBILITY, probed |
| Progression | 2048 is non-terminal; exponent tiles and arbitrary-length exact score continue beyond int64 | Endless beyond 2048, compact huge-number display, long-run-safe storage | PASS |
| Persistence | Versioned board/score/all-time/mode/RNG/undo round trip with corrupt-save recovery | Restore active board, score, all-time, difficulty and continuation state | PASS |
| Undo | One exact local undo restores board, score and RNG while preserving all-time | Undo visible in secondary runtime captures; original depth/monetization unknown | PARTIAL |
| Loss/recovery | No equal neighbor means over | Exact original boundary/recovery is unresolved | UNKNOWN |
| Art | Seven unchanged real GAG derivatives are runtime-bound and visible in stable/peak play | Preserve unchanged while fixing rules | REVIEWED CANDIDATE |
| Feedback/accessibility | Four semantic grades plus a matched reduced-effects path; normal Web haptics and reduced suppression captured | Same state semantics with bounded/reduced visual, haptic and camera channels | PASS internally |
| Delivery | Clean fingerprinted Web passes real drag/undo/reload/restart/mode/reduced gates | Public review remains on 2048 Balls | LOCAL PASS / NOT DEPLOYED |

No reference bitmap, prefab, source audio, APK, or extracted implementation is
committed.
