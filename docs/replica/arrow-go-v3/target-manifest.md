# Arrow GO v3 target manifest

## Immutable identity

| Field | Frozen value |
|---|---|
| Catalog entry | `arrow_go` / “Arrow GO” |
| Authorized target | `Arrow GO: Logic Puzzle Game` |
| Platform | Android / Google Play |
| Package ID | `com.reda.arrow` |
| Version | `1.0` (current first-party page structured field) |
| Updated | `2026-08-11` |
| Developer | `chouikh.app` / Chouikh Essaid |
| Internal level/resource ID | unknown |
| Package SHA-256 | unknown; no target APK was acquired |
| Starting replica HEAD | `3e561fb3c55f3b0b813da2b9ee9468cd4d290bae` |
| Research date | `2026-08-21` |
| Rights basis | user-selected public first-party listing; clean-room observation only |
| Private evidence root | `/home/ubuntu/work/offline-games-private/reverse/arrow-go-v3/google-play` |

The catalog mapping is explicit in the user-maintained private source selection:
`Arrow Go` points to `https://play.google.com/store/apps/details?id=com.reda.arrow`.
The adjacent `Amaze GO` row points to `com.oakever.arrows`; Offline Games resource
`141_ARROWS` is also a different target. Neither may be silently substituted.

## First-party capture inventory

- `listing.html`: SHA-256
  `0abd7d201d1eeeb45fdc16872b6dc9628c217b37d66ae48577270d085a3d4115`
- `listing.headers`: SHA-256
  `ad034efc554492e20f7f133622a27224e3fac21b37883616e84bc6a3f893f145`
- current store screenshots, served as PNG payloads at 333×592 despite the local
  `.webp` suffix:

| Screenshot | SHA-256 |
|---|---|
| `screenshot-01.webp` | `de0860d6635adf40dfde98a1210700dd5f7a339af3706c933086f33e2b3e668b` |
| `screenshot-02.webp` | `74dd56eaea2108a8b9f0925d0ed3c693395ac53d0d9c37bff9b03b387c49ef49` |
| `screenshot-03.webp` | `df888748a10986b4679e4e67dcd037bd9277e2df2077b89569240a31a92aec6f` |
| `screenshot-04.webp` | `8ba8b20947dba5607540f6672c86657bcf820ae8e1b56701a7b66c2dff0d952a` |
| `screenshot-05.webp` | `b79d7b5b6bff03b91216b4a69cff3f0cb6550ef4c36da91f349c994332e153a6` |
| `screenshot-06.webp` | `e6d4efda90fbe695d27ce7c48d7f1f6b49311da028ad4f049b690110fd4d1c84` |
| `screenshot-07.webp` | `9f420e2c6a8c9a480e16882fe760396e130159a518b7f02ba34fd4abcaf25db2` |
| `screenshot-08.webp` | `46b01b03cc317fd021d615c91db7d583576803fc521b3225a316a8b874afec4e` |

The first-party page links trailer `https://www.youtube.com/watch?v=fo01WjXkzmo`.
The current research environment receives YouTube's login/bot gate, so the
trailer is recorded as an unavailable lead, not as observed action evidence.

## Included evidence-bounded flow

- square-board entry;
- tap/select one connected orthogonal arrow;
- clear-path success versus blocked atomic rejection;
- removing arrows in an order that unlocks others;
- progress, last-arrows state, clear-all and animal reveal;
- deterministic restart, strict active-run recovery and equivalent
  mouse/touch/keyboard adapters as local offline-quality requirements.

## Non-goals and prohibited carry-over

- circle/triangle generation, exact target level layouts, scoring, timer,
  hint/shuffle inventory, ads, language greeting, progression economy, or
  hidden-animal catalog are not claimed in this slice;
- no target APK, code, level data, text, image, audio, or extracted asset enters
  the product repository;
- Google Play promotional frames are evidence only and are not copied as art;
- the existing courier/harbor route mechanic is neither target evidence nor a
  permitted compatibility shortcut.

## Evidence boundary

The listing directly states that the player taps an arrow, it launches in its
pointing direction, arrows can block one another, order matters, all arrows are
cleared, and a hidden animal is revealed. Screenshots visibly support dense
straight/bent arrow forms on square, circular, and triangular dotted boards,
center animals, partial-clear states and a completion modal.

The screenshots are promotional composites and do not form one deterministic
action sequence. Exact shape occupancy, collision sweep, blocked-tap penalty,
score/timer formulas, failure, hint/shuffle behavior, level seed, restart and
recovery remain unknown. Target-version fidelity therefore cannot exceed
`PARTIAL_EVIDENCE`.
