## Summary

The current scanner workflow gains clearer Material 3 Dark/Light layouts, a labelled export action, larger bounded previews and tap controls for crop corners. Capture, import, retake, reorder, delete, restore, crop/rotate, undo/redo and PDF/JPG/PNG sharing remain available.

JPEG previews use reduced raster decoding while preserving original aspect, effective EXIF orientation and original pixel limits. Queued operations no longer begin after controller disposal, and cancellation at final-page progress stops before PDF packaging.

## Issue / Goal

- Work ID: 2026-10-23-scanner-experience
- Goal: improve quality, performance and usability while preserving existing features and originals.

## Research / Spec

- Research: `docs/research/2026-10-23-scanner-experience.md`
- Spec: `docs/specs/2026-10-23-scanner-experience.md`
- Approval: root under repository §3d delegation, 2026-10-23, before implementation.
- Deviation: approved correctness refinement chooses a smaller decode scale when rounding would make a non-square original square; recorded in the spec.

## Change type

- [x] feat
- [x] fix
- [x] docs/spec
- [x] test

## Validation

- [x] `bash scripts/dev-task.sh gate`: Android debug APK, merged release-manifest guard, analyze 0 issues, format 62 files unchanged, adoption and hook checks, 808 Flutter tests and 11 rerun Android JVM tests.
- [x] Meaningful assertion RED before logic changes; independent review findings have regression tests and are resolved.
- [x] Existing accessibility tests and added 320 dp / 200% text / short landscape tests pass.
- [x] Synthetic widget screenshots visually reviewed; host AOT benchmark and fidelity probe rerun on final source.
- [x] Original caps, permission/privacy guards and dependencies preserved; normal commit secret/size hook used.
- [ ] New physical-device camera/share UAT and iOS build were not performed.

### Evidence

`docs/work/2026-10-23-scanner-experience/working.md` records commands, RED/GREEN evidence, review and artifact details. `host-thumbnail-benchmark.json` contains all 10 raw samples plus base/source/binary/corpus hashes.

Final synthetic 4000×3000 JPEG benchmark: 5 fresh processes/version, alternating order. Median thumbnail time 578.921→461.563 ms (20.27% lower); median process peak RSS 48443392→22474752 bytes (53.61% lower). This is host AOT evidence with uncontrolled I/O cache, not device/p95/UI-jank evidence. Export still decodes originals at full resolution; preview bytes are lossy and differ.

## Risk, rollout and rollback

- Risk: medium; existing scan review/edit/export workflow and JPEG thumbnail geometry.
- Privacy: no new network calls, permissions, data collection or real-document fixtures.
- Data/migration/compatibility: no schema, dependency/lockfile or app wiring changes; original bytes remain intact.
- Rollout: draft PR for review; merge/deployment are outside this task's authorization.
- Rollback: revert commit; no migration or reconciliation required.
- Residual limits: physical-device and long-document performance remain unmeasured.

## Definition of Done

- [x] Feature research/spec approved before source changes.
- [x] Implementation matches reviewed scope and acceptance evidence.
- [x] Targeted and full local gates pass.
- [x] Errors/privacy/concurrency/cancellation and original preservation covered.
- [x] Documentation, code map, feature map, traps and work record updated.
- [x] Independent source review findings resolved.
- [ ] Remote required CI and final merge review remain pending.

## Reviewer focus

JPEG scale selection and aspect/orientation under near-square or conflicting metadata; crop tap controls with existing drag/undo semantics; post-dispose queue and final-progress cancellation boundaries.
