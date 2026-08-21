# GB Snake v3 direction package

Status: approved pillars retained; rules corrected to the `79_SNAKE2` target.

## Target and boundary

This slice targets Offline Games `3.14.1 (3204)` resource `79_SNAKE2` medium
mode. The authoritative contract is frozen in
`docs/replica/gb-snake/target-manifest.md`: `15 × 23`, length four, rightward
automatic entry, `7.5` steps/s, two live foods, two queued growth segments per
food, wall/self loss, and endless progression.

The reference is modern cartoon Snake. The LCD field-recorder treatment is a
local presentation decision; it is not asserted as recovered original art.
The v2 claims of one food, `+1` growth, and terminal length 120 are superseded.

## Retained pillars

### Read a living signal

The head must remain the strongest moving silhouette, both food lures must read
as equally valid targets in an ordinary frame, and every body cell must stay
legible against the LCD. Motion is sampled phosphor memory, not soft neon.

### Feel hardware answer

Turns should feel like a physical contact closing a circuit. A valid turn,
rejected reverse, forage, log entry, crash, and field record each answer the
specific object and input that caused them. The hardware shell and HUD stay
stable while the LCD carries local response.

### Growth is earned

One forage means two future body segments. The pickup says `+2`; the next two
ticks materialize length `4 → 5 → 6`. Decade logs and the length-120 field
record acknowledge progress without stopping the endless run.

## Stable composition

- GAG snake head: the live head on every ordinary frame.
- GAG seed-beetle lure: both authoritative food slots on every ordinary frame.
- GAG brass field seal: persistent hardware identity above the LCD.
- Body: restrained dark phosphor cells with sparse scale marks.
- HUD: current length, `FIELD 120` as a nonterminal record marker, and step
  telemetry. No target-clear language.
- Dynamic Chinese: `NotoSansCJKsc-Subset.otf` through the CJK/UI role.
- Instrument labels and digits: Latin/number font role. Symbol font remains
  reserved for symbol glyphs; dynamic Chinese must never fall through to it.

## Semantic intensity

The grades describe perceptual intent, not a fixed checklist of effects.

| Grade | Event | Intent → anticipation → impact → settle |
|---:|---|---|
| 1 | accepted turn | contact closes → directional bracket focuses the head → key click and pressed direction register → next automatic tick applies the turn |
| 1 | rejected turn | invalid intent is preserved → rejected direction ghosts briefly → dry reject click and local kick → snake and score remain unchanged |
| 2 | forage | either lure is already readable → local lock contracts around the eaten slot → GAG pickup, `+2`, scan ring, bounded haptic → replacement lure is visible and two later ticks materialize growth |
| 3 | decade log | a growth tick reaches a multiple of ten → register begins at the tail → scan sweep, notch, seal response, layered collect/key cue → live play remains unobscured |
| 4 | crash | head approaches the actual wall/body contact → impact point compresses → directional smear, bounded board shake, crash cue, terminal state → stable game-over plate names wall or self |
| 4 | field record | growth reaches 120 → recorder arms at the semantic event → brass seal and GAG register cue acknowledge the record → sweep clears and the same run continues |

Continuous-event audits must include the event's intent, anticipation, impact,
and settle/recovery. A flattering single peak is insufficient.

## Reduced-effects contract

When `prefers-reduced-motion: reduce` is active, or the acceptance harness sets
the equivalent runtime flag:

- authoritative state and final visual consequence are identical;
- camera/LCD shake is zero;
- particle emission is zero;
- vibration requests are suppressed, not merely shortened;
- forage, crash, log, and record use short bounded envelopes;
- food and hardware ambient pulses become stable;
- movement resolves to the current cell without phosphor interpolation.

Reduced effects never changes collision, food placement, timing, growth, score,
or progression.

## GAG decision

Fresh HOME-WSL MCP search and master/runtime hash verification are recorded in
`docs/replica/gb-snake/gag-ledger-v3.json`. Existing head, lure, seal, forage
audio, and field-record audio fill all high-value roles. No v3 generation is
authorized because there is no role gap; adding another asset would introduce
variance rather than improve ordinary-state identity or semantic response.

## Acceptance boundaries

- Mechanics alignment may be claimed only from renderer-free and shell probes.
- Stable art acceptance requires two visible lures, the live GAG head, and the
  field seal in a normal opening frame.
- Event acceptance requires full turn, forage, decade, crash, and nonterminal
  record sequences plus continuous-peak performance evidence.
- Web acceptance requires clean fingerprinted PCK, real touch swipe before
  release, keyboard, D-pad, restart, local-storage reload recovery, headers,
  and complete transfer verification.
- Visual superiority is `NOT_CLAIMED`: no matched original event recording is
  available, and the local metaphor intentionally diverges from the original.
