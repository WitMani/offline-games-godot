# Amaze GO v3 cartoon direction package

## Decision header

```text
Game / slice: Amaze GO v3 arrow-extraction fidelity candidate
Reference target: Oakever Games Amaze GO!, Apple App Store id6758326278 / com.oakever.arrows
Starting commit: 3e561fb3c55f3b0b813da2b9ee9468cd4d290bae
Mechanics commit: 6da260f299fe3168e02e7a49278d02ef9b57e43b
Runtime / platform: Godot 4.6, Web / desktop
Viewport and device class: 540 × 960 portrait, pointer / touch / keyboard
Direction status: approved-by-command
Prepared at: 2026-08-21
```

## Baseline and invariants

The exact baseline rendered a six-by-six avatar-and-wall maze. Stage 0 proved that the target instead presents disconnected orthogonal polyline arrows: tap a clear arrow to slide it off, lose one heart for a blocked tap, and win by clearing the board. The renderer-free model and 242 model assertions plus 76 runtime mechanics assertions are the presentation boundary.

| Probe | Frozen behavior | Presentation consequence |
|---|---|---|
| Entry | 12-arrow bounded clean-room level; three hearts; deterministic focus | show every live path and both non-authoritative signature stations on the ordinary first frame |
| Legal extraction | forward head ray contains no other live path cell; removal is immediate and atomic | animate a presentation ghost only after the authoritative arrow disappears |
| Blocked attempt | arrow stays; exactly one heart is lost at the first blocking contact | originate recoil/correction at the live arrow and blocker contact; never fake a different obstruction |
| Progress | every third removal is a waypoint; last two are near-clear; final removal wins | promote the same extraction grammar by shape, duration, sound and seal |
| Terminal / recovery | win or zero hearts freezes input; restart and strict recovery remain model-owned | result plaque may cover the board only after the local consequence reads |
| Input | pointer, touch, directional focus, Enter/Space, H and R | no presentation code branches the rule result by input type |

The official target does not establish the exact clean-room level, generator, collision tolerance, starting heart count, zero-heart flow, Guidance economy, scoring, zoom, or persistence. Those remain explicit local decisions rather than parity claims.

## Pillars

### Experience pillars

| Pillar | Production consequence | Observable proof |
|---|---|---|
| Read the clearance | legal heads use an outbound clearance bead; blocked heads use a crossbar and a contact-origin correction | stable, hint and rejection captures plus renderer-free blockers |
| Feel the extraction | the acted-on polyline lifts, slides toward its real edge, impacts the survey register, then leaves the next choice clean | continuous ordinary extraction sequence |
| Earn the seal | routine removals stay restrained; waypoint, near-clear and final clear promote the progress seal without constant spectacle | grade 1/2/3/4 smoke and continuous final sequence |

### Art pillars

| Pillar | Shape / material / motion rule | Observable proof |
|---|---|---|
| Inked paper arrows | code-native multicolor ink paths carry all live topology, with paper grain, contact shadow, highlight and riveted board corners | title-hidden stable frame remains identifiable as arrow extraction |
| Brass survey register | the GAG surveyor is a non-playable clearance-station emblem and the GAG beacon is a progress/certificate seal, never a player or destination | both assets are visible on the untouched opening frame and listed in Web state roles |
| Edge-bound motion | extraction travel follows the authoritative terminal direction to the actual nearest board edge; rejection recoils against that direction | object FX contain the source path, head, direction and blocker contact |

### Anti-pillars

| Reject | Reason | Counterexample |
|---|---|---|
| Avatar-maze residue | contradicts the identified target | no player, target, wall or painted-grid keys in the Amaze GO v3 runtime state |
| Generated playable arrows or UI | can disagree with topology, legal state, language and input | GAG images remain two isolated decorative instruments; arrows, hearts, progress and copy are code-native |
| Constant translation and vibration | erases semantic hierarchy and violates reduced-effects intent | grade 1 has no shake; reduced mode keeps state/audio/local opacity while suppressing translation, shake and haptic |

## Fantasy, tone, and signature

Fantasy: a cheerful pocket cartography bureau where tangled ink arrows are cleared from a paper survey sheet. Tone: precise, tactile, encouraging. Signature motif: the clearance-station lens on the left and a brass progress seal on the right, both outside the authoritative board.

Style words: paper-cut, brass, inked, friendly. Anti-words: neon, photoreal, militaristic, generic compass maze.

## References and GAG decision

- First-party identity, description and screenshot observations: `docs/replica/amaze-go-v3/target-manifest.md` and private evidence recorded there.
- Approved catalog material principles: `docs/art-direction/catalog-cartoon-v1.md`.
- Historical GAG provenance: `docs/art-direction/amaze-go-v2.gag-asset-ledger.json`.
- Fresh v3 re-audit: `docs/art-direction/amaze-go-v3.gag-asset-ledger.json`.

Fresh unrestricted semantic searches rejected generic VFX, coin, 2048, logic-game, combat and long-form music results. The historical Amaze GO archive is not currently covered by the semantic index, so exact-name/path searches did not return its masters. No role gap justified generation: the existing fal.ai + Remove.bg surveyor/beacon family remains compatible once reinterpreted outside the playable board, and the existing ElevenLabs ratchet/seal pair fits ordinary extraction and terminal certification. Runtime hashes are freshly verified; source-master hashes remain transparently bounded to the historical ledger because the masters could not be re-downloaded from the read-only search endpoint.

## Hero-event grammar

```text
Trigger: the model accepts the final live arrow.
Authoritative delta: remaining becomes zero, status becomes won, score/moves update, and input freezes immediately.
Next legal choice: restart/home only; presentation never delays the terminal state.
```

| Beat | Object motion | Light / VFX | Audio / haptic / camera | State evidence |
|---|---|---|---|---|
| Intent | final code-native path is retained as a short presentation ghost at its original cells | focused head and local clearance mark | no pre-result sound | model already reports `remaining: 0`, `status: won` |
| Impact | ghost travels in its real terminal direction to the board edge | gold head ring and progress-station contact | GAG destination seal; grade-4 haptic and short shake in normal mode | all 12 IDs are in `removed_ids` |
| Settle | ghost clears the play area; beacon certifies the now-empty paper | restrained brass rays collapse into a centered seal | no looping audio | board stays empty and terminal |
| Result | paper certificate plaque enters after the local beat | runtime GAG beacon plus code-native CJK result copy | controls remain home/restart | no hidden mutation |

Ordinary extraction uses the same intent → edge travel → impact → settle structure with a short GAG ratchet, no shake and a smaller local ring. Blocked input keeps the authoritative arrow, marks the model’s first contact cell, recoils only the acted-on rendering, spends one droplet and settles back into the same path.

## Production system

- Shape/material: code-native arrow paths, legal markers, droplets, progress arc and text; GAG raster only for clearance-station and certificate roles.
- Palette/value: warm paper and brass frame; distinct ink families with shape cues so legality is not hue-only.
- Type: all dynamic Chinese labels, buttons and result copy bind `NotoSansCJKsc-Subset.otf` through the `ui_cjk` role.
- Runtime ownership: `models/amaze_go_model.gd` owns occupancy, blockers, hearts, score, terminal and recovery; `main.gd` consumes its event/snapshot.
- Audio: GAG ratchet for extract/waypoint/near/hint; GAG seal for win; existing correction sound for reject/loss.
- Reduced effects: query parameter `?reduced=1` or OS preference enables the same authoritative state with zero arrow translation/recoil, zero camera shake, zero haptic and a fixed local marker; audio and state copy remain.
- Performance: the ordinary board, repeated grade-4 normal event and matched reduced event are compared under Xvfb/llvmpipe; this is a regression trace, not a device-FPS claim.

## Delivery and validation plan

The bounded implementation slice contains only Amaze GO v3 presentation, its dedicated tests/audits, evidence and Web/PCK export records. No sibling mechanics, generated source master, GAG repository, server deployment or public release is in scope.

Required gates: Stage-0 claim ledger; renderer-free mechanics; game/runtime/sibling smoke; GAG hash/provenance; stable/ordinary/reject/waypoint/near/win/reduced frames; continuous extraction/reject/win sequences; CJK coverage; llvmpipe comparison; clean commit archive export; PCK source-master/full-font scan; real Chrome pointer/keyboard/reject/reload/restart/reduced loop; headers, byte range and full-transfer integrity.

## Approval record

```text
Approved by: project owner through the Amaze GO v3 execution instruction
Approved scope: cartoon presentation after the dedicated mechanics gate passed
Approved exceptions: local bounded level/hearts/recovery decisions remain non-parity claims
Direction commit: the implementation-stage commit containing this package
```
