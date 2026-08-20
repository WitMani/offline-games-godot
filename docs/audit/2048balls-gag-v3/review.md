# 2048 Balls GAG v3 · runtime review

## Outcome

Internal review result: **PASS as a sequential user-review candidate**.

This slice repairs the prior fidelity failure and makes GAG use perceptible in
ordinary play. It is not yet called user-accepted or commercially superior.
The public review boundary remains 2048 Balls only.

Implementation commit: `7d98923b18147cac96964da28534522dfca581bb`.

## Original-alignment result

The target is Voodoo's exact-title `2048 Balls 3D`. Official Apple screenshots
are held only in the private evidence root. They directly show a continuous
aim guide, a numbered top ball, an irregular free pile, power-of-two values,
side/floor containment, a danger marker, contact spectacle, and 256/2048 target
progression. The remaining motion/failure details are conservative inferences,
not mislabeled as directly observed facts.

The shipped candidate now uses continuous horizontal aim, visible falling
circles, wall/floor/ball contacts, equal-contact merges, sustained danger-line
failure, open 256→2048 progression, and restart with retained best. It has no
seven-column state, tier-five cap, or score-1000 hard win.

## GAG visibility result

HOME-WSL GAG 1.29.0 ran in pure-API mode. Four semantic searches preceded
generation; generic frames, unrelated atlases, magic VFX, and non-semantic
audio were rejected. fal.ai Flux Pro v1.1 generated the orchard tray source;
GAG crop, Remove.bg, and auto-trim produced the selected derivative. The source
master remains in the GAG archive. Only a 20,606-byte WebP derivative ships.

Stable state visibly contains:

- the full-width honey-wood GAG recipe tray;
- five GAG fruit objects as live free-physics balls;
- a GAG fruit in the continuous aim preview, next pod, and header mark;
- code-native numeric medallions preserving original rule readability.

The inherited GAG juice burst is no longer peak-only: grade 2/3/4 use visibly
distinct scale, opacity, halo, object deformation, ring, callout, sound, haptic,
and bounded shake envelopes. A landing uses real model travel plus only a local
contact squash, avoiding a duplicated fake fall.

## Evidence reviewed

- `candidate/00-stable-family-and-tray.webp`: all stable GAG identities visible.
- `candidate/10-continuous-aim.webp`, `12-visible-fall.webp`,
  `13-physics-contact.webp`: action consequence is visible through model state.
- `candidate/21-grade2-impact.webp`, `25-grade3-chain.webp`,
  `31-grade4-cascade.webp`: hierarchy is materially separated.
- `candidate/continuous-grade4-cascade.webm`: complete 24-frame peak envelope,
  not a selected still only.
- `candidate/40-blocked-rejection.webp`: localized corrective feedback with no
  move/state mutation.
- `candidate/50-target-open-progress.webp`: 256 promotes to 2048 while status
  remains playing.
- `candidate/10-web-merge.png`: exact clean PCK in Chrome/SwiftShader after two
  real pointer releases and an equal-contact merge.
- `candidate/public/10-web-merge.png` and
  `candidate/public/web-acceptance.json`: the fingerprinted Aliyun release
  after the same real pointer sequence.

Manual frame review found the five values and power-of-two labels readable, the
tray continuously visible, the aim/fall/contact sequence coherent, and grades
2/3/4 distinguishable without relying on text alone. The grade-four burst is
large but retains the surviving numbered ball and clears within its bounded
envelope.

## Gates

- Watermelon model: 34 assertions PASS.
- Runtime integration: 30 assertions PASS.
- Presentation/GAG: 9 scenario groups PASS.
- Entire repository: 28/28 smoke scripts PASS; all 14 games open/reset/input.
- Rules 6, catalog art 10, font coverage 65 PASS.
- CJK subset: 3,879 required glyphs / 1,816,916 bytes PASS.
- Standalone llvmpipe busy trace, 180 frames: average 17.532 ms, P95 21.372 ms,
  max 26.952 ms. Comparative host trace only, not a device FPS claim.
- Clean Git-archive Web export PASS: PCK `index.185c0986ccda.pck`, canonical
  engine `index.2b558bdb3c3a.wasm`; all seven runtime visual paths are present
  and source-master/intermediate identifiers are absent.
- Localhost secure-context Chrome PASS: real pointer aim/release, visible
  falling phase, floor contact, second-ball merge, restart/best persistence,
  PCK/WASM responses, and zero console/page/request errors.
- Aliyun secure-context Chrome PASS on release
  `20260820T191125Z-185c0986ccda`: the served PCK/WASM hashes match the clean
  local acceptance bundle exactly; the same two-release merge and restart path
  passed with zero console/page/request errors.

## Honest limitations

- Exact commercial coefficients, random distribution, danger grace, scoring,
  and post-2048 target cadence remain unavailable; current values are explicit
  conservative choices.
- Headless audio proves routing and asset loading, not subjective loudness on a
  physical device. Browser vibration and device performance remain unclaimed.
- The EC2-to-Aliyun cold path exceeded 180 seconds before a retry passed within
  a 300-second limit. This is a real cold-start latency limitation, not hidden
  as a runtime pass/fail issue; a warm client cache is expected to be faster.
- No matched external user review has accepted “surpasses original.”
- This branch is not merged or pushed. Only the exact clean review artifact is
  deployed to the private Tailscale Aliyun endpoint.
