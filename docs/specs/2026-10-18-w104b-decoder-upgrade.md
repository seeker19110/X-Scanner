# W-104b — bounded decoder upgrade

| Attribute | Value |
| --- | --- |
| Work ID | 2026-10-18-w104b-decoder-upgrade |
| State | **Approved for implementation** |
| Approver / date | Root under owner7Oct §3d delegation; actual18Oct2026, before production edits |
| Risk | M conservative; existing W104b/F004 security maintenance, one PR |
| Goal | P1 completion / COMPLETION-PLAN W104b; AC9 remains separate |

## 1. Evidence and scope

Official Pub API18Oct01:20Z identifies image4.12.0 as latest, published11Oct00:28:00.512637Z, archiveSHA25689ed75b2f8231fe676808c5564f9590d728024ded7ac782a7ed8474f1c95b72a; seven-day condition passed. SDK^3.0.0 fits pinnedDart3.13.5/Flutter3.47.7. Publisher loki3d.com/MIT unchanged. New archive^4.5.0 accepts existing locked4.5.1; use Pub to preserve other packages and verify exact final lock/hash.

Primary source: [Pub metadata](https://pub.dev/api/packages/image/versions/4.12.0), [changelog](https://pub.dev/packages/image/changelog), [upstream v4.12.0](https://github.com/brendan-duncan/image/tree/d9e495c7c3bed862ef7d52698e64e25932877ecf). Verified archives/diff/review retained outside repo in w104b-research-evidence-20261018; execution evidence belongs on this Work ID PR.

## 3. Research and alternatives

| Comparison | Existing evidence | Decision |
| --- | --- | --- |
| Already deeper | Content-onlyJPEG/PNG/staticWebP,64MiB,50MP,DecodeGate,60s kill/onExit and original-preservation tests | Reuse all guards; no second sandbox/framework |
| Present but shallower | Old decoder allocates before app checks in some paths; EXIF only stops selfloop; PNG eagerly inflates surplus data | Pin reviewed4.12.0, pass instance caps before startDecode, retain app header cap |
| Missing, real F004 | CyclicEXIF and boundedPNG-consumption regressions; instancecap wiring | Tiny synthetic tests, actualRED before dependency/core changes |

Choose dependency fix over hand-written EXIF/PNG parser or changing process-wide limits (correctness/security, then fewer maintained lines). Upstream now fixes two-channel storage/rotation; remove56 workaround only when existing21regressions remain exact, keeping JPEG policy. No scaled JPEG, new dependency, SDK, schema, app UI, PDF engine, migration, OCR, device acceptance or release change.

## 7. Requirements

- FR-1: Pin image4.12.0; generate lock with Pub; only image version/hash may change. Check age/hash/license/publisher/SDK and packaged source; no fabricated CVE or upstream performance claim.
- FR-2: Supply caller maxPixels before any startDecode: JPEG/Png constructors; WebP property before parsing (never constructor bytes then set). Reject nonpositive app limit before upstream can disable it. Keep original header width×height ceiling and validate decoded dimensions against cap before returning. No production static-limit mutation.
- FR-3: Continue first-frame PNG and refuse every animatedWebP before decode; retain byte cap, content allowlist, errors without content/path, kill budget/exit wait, originals and metadata policy. Library maxPixels/lazy inflate is not a process RAM quota; native inflater may read ahead one compressed chunk.
- FR-4: imageSizeOf keeps nullable rejected-header behavior under new decoder ImageException. Do not expose raw exception/path to UI. Existing preview/export geometry and JPEG two-channel alpha-discard policy remain.

## 9. Acceptance criteria

- AC-1: Tests-only on unchanged4.10.1: tiny validJPEG with EXIF two-IFD cycle cannot complete before a bounded isolate budget; assertion expects successful intact raster and is RED. Kill runaway child and wait for exit. Same test GREEN4.12 without relying on wall-time/RSS benchmark thresholds.
- AC-2: Finite~64KiB malformed-unused-tail PNG canary:1×1 gray17, zlib stored blockLEN65535 with firstbytes filter0/gray17, filler and reservedBTYPE after compressed64KiB boundary, valid PNGchunkCRCs. Old eager inflate reaches poison and fails; new row-limited decode returns declared raster. Label this a bounded-consumption oracle, never valid-PNG conformance or a precise peak-memory bound. Also a finite PNG container with a complete zlib stream plus unused decoded data and truncated/no-row cases protect success/error/original-preservation. No decompression OOM payload.
- AC-3: After pin but BEFORE core wiring, tests set library defaultMaxPixels=1 temporarily, request6px on tiny JPEG/PNG/WebP, expect exact6px success and default unchanged; restore static in finally. Real behavioralRED then explicit-instanceGREEN. Include exact cap/one-over, nonpositive limits, oversized malformed headers, error sanitization and imageSizeOf rejectedheader→null; no compile/setup failure counted asRED.
- AC-4: Old imaging/export/controller/tool tests and all21XS07b pixel/PNG/JPEG regressions remain GREEN; remove redundant two-channel workaround only after patched library proves equivalent. Preserve source/metadata/original bytes, formatallowlist/animation/byte/pixel/time guards and EXIF orientations.
- AC-5: Root independently reruns each RED phase before corresponding GREENLIGHT. Targeted checks, full dispatcher gate + normal hook, final-headCI, native rules/requiredapp/no bypass/threads/base/head/dependency graph compare and synthetic realCLI/AOT smoke all pass before guardedmerge.
- AC-6: Document package/diff/RED/GREEN/residual limits; maps/TRAPS/changelog/spec/PROGRESS/completion/exceptions reconciled in samePR. EX1 closes only after actual main merge and proofs; AC9/PR4b remain independently gated.

## 11. Architecture và code touchpoints

- `apps/mobile/pubspec.yaml`, `apps/mobile/pubspec.lock` — exact reviewed pin, generated lock.
- `apps/mobile/lib/imaging/page_render.dart` — decoder factory/start/read boundary and redundant2channel workaround removal only.
- `apps/mobile/test/imaging/decoder_security_test.dart` — synthetic regression/cap boundaries.
- `docs/work/2026-10-18-w104b-decoder-upgrade/done.md` — root decisions/evidence; worker ownrecord separate.
- `docs/ops/COMPLETION-PLAN.md`, `docs/ops/supply-chain-exceptions.md`, `CODEMAP.md`, `docs/FEATURE-MAP.md`, `PROGRESS.md`, `TRAPS.md`, `CHANGELOG.md` — current state/evidence, root only.

## 16. Test/eval and evidence

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `apps/mobile/test/imaging/decoder_security_test.dart` |
| AC-2 | `apps/mobile/test/imaging/decoder_security_test.dart` |
| AC-3 | `apps/mobile/test/imaging/decoder_security_test.dart` |
| AC-4 | `apps/mobile/test/imaging/page_render_test.dart`; `apps/mobile/test/export/page_exporter_test.dart`; `apps/mobile/test/ui/session_controller_test.dart`; `apps/mobile/test/tool/scanner_benchmark_test.dart` |
| AC-5 | `docs/work/2026-10-18-w104b-decoder-upgrade/done.md` and PR execution evidence |
| AC-6 | `docs/ops/COMPLETION-PLAN.md`; `docs/ops/supply-chain-exceptions.md` and PR actualmerge readback |

Paths to newtest must exist before contract compiler acceptance; mapping is not test acceptance. REDA baseline→rootverify→pin→REDB wiring→rootverify→coreGREEN. No golden updates. Debuggate/AOT are not device/iOS/camera/OCR/release evidence.

## 17. Rollout, rollback and approval

One PR after56actualmerge/reconcile. This fulfills separately reviewed /deps-upgrade for image; do not use bot patch/minor shortcut. Root reviews all security-relevant source and exact lock graph, then guarded squash on exact green head under existing P1 goal merge authority plus18Octcontinuation. No auto-merge/deploy. Revert via PR if needed, reopening EX1 and preserving prior data. No source data migration.
