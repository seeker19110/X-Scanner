# XS-07b — preserve gray-alpha pixels through crop and rotation

| Attribute | Value |
| --- | --- |
| Work ID | 2026-10-17-xs07b-gray-alpha-render |
| State | **Approved for implementation** |
| Approver / date | Main session under the owner's 2026-10-07 §3d delegation; approved 2026-10-17, after review/merge55 |
| Risk | M conservative; one existing-core correction, no public API, schema or dependency change |

## 1. Problem and primary evidence

PR55 fixes exact identity only. Its generic gray-alpha DEBT records an existing defect: in pinned `image 4.10.1`, `PixelUint8.g` returns gray for two channels, while `Image.setPixel` passes logical RGBA to `ImageDataUint8.setPixelRgba`, which writes g into storage byte1. The bilinear sampler returns RGBA, so crop/downsize replaces alpha with gray. `copyRotate` at 90/180/270 degrees uses the same setter. PNG decoding/encoding preserves two channels. The cached library implementations were read before this decision; tests must reproduce pixel failures before production edits.

## 2. Outcome and non-goals

Preserve independent gray/alpha through generic crop, cap, skew and render quarter turns. Keep rectify output uint8 with the same channel count, independent storage and stripped metadata. Keep the existing two-channel JPEG encoder policy (discard alpha; no new background composition).

No decoder/SDK/lock/dependency/ceiling/budget/isolate, UI, schema, migration, filter, OCR, PDF-engine or release changes. No real documents, scan uploads, paid APIs or device acceptance claims.

## 3. Research and smallest suitable implementation

| Comparison | Evidence | Decision |
| --- | --- | --- |
| Already deeper | DecodeGate, time/pixel caps, normalize/palette, geometry, identity copy and gates | Reuse all of them |
| Present but shallower | Existing generic/rotation setters confuse logical RGBA and two-channel storage | Correct only that mapping |
| Missing, tied to a real defect | Independent gray-alpha crop/cap/skew/rotation regression | Add tiny raw fixtures and analytical/manual expectations |

Write the interpolated sample with storage g=sample.a for two channels. Other channels use the same values as before.

Use a private two-channel byte rotation helper. RGBA promotion preserves alpha, but conversion plus rotation creates two four-channel buffers. It also changes JPEG behavior because the pinned encoder composes alpha only when pixel length>3. The helper uses one two-channel output as the existing rotation does, with byte views and integer coordinates. Other channels retain installed `copyRotate`.

## 7. Requirements

- FR-1: Keep homography, pixel centers, clamp and bilinear sampling. For two channels write sample.r/sample.a into gray/alpha storage; channels1/3/4 keep their prior mapping. Identity, normalization and cap ordering remain unchanged.
- FR-2: Only two-channel render rotation uses the private byte helper. Normalize quarter turns modulo4; keep channel count/pixel count and swap dimensions on odd turns. Allocate one rotation output, no full-size conversion. Other channels retain existing rotation and all public signatures stay unchanged.
- FR-3: Preserve source pixels, metadata and encoded originals. Output owns its pixels. Create fixtures by raw channel storage, never the buggy RGBA setter.
- NFR-1: No new dependencies, per-pixel Point/record objects, full-size intermediate buffers or timing thresholds. No p95, RAM, device or release claims from host tests.

## 9. Acceptance criteria

- AC-1: Crop/cap/skew tests use independent analytical gray/alpha expectations with unequal channels and alpha0/partial/255. Baseline fails on actual pixel assertions; fixed output remains two channels and obeys existing size caps.
- AC-2: Verify source preservation, output ownership/metadata and 16-bit gray-alpha normalization. Existing gray/RGB/RGBA/palette/border/identity cases remain green.
- AC-3: PNG full-frame and crop at turns0..3 preserve exact gray/alpha/dimensions using manual non-square matrices. Include single pixel/row/column and negative/repeated turns modulo4. Expected values must not come from production transforms or `copyRotate`.
- AC-4: JPEG rotation retains the existing two-channel encoder behavior using manually rotated fixtures; existing async preview/export/PDF/tool tests remain green.
- AC-5: Root independently verifies RED before logic, then targeted/full gate, normal hook, AOT smoke and final-head CI. Maps/TRAPS/work records and actual55 reconciliation share this PR. New PR stays OPEN pending merge authorization (continued by the owner's18Oct request below).

## 11. Architecture và code touchpoints

- `apps/mobile/lib/imaging/page_render.dart`: generic storage mapping, private two-channel quarter-turn helper and render call site; public signatures unchanged.
- `apps/mobile/test/imaging/page_render_test.dart`: independent regressions and integrations.
- `CODEMAP.md`, `docs/FEATURE-MAP.md`, `TRAPS.md`, `CHANGELOG.md`, `PROGRESS.md`: root maintains maps and evidence in the same PR.

## 16. Test/eval and evidence

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `apps/mobile/test/imaging/page_render_test.dart` |
| AC-2 | `apps/mobile/test/imaging/page_render_test.dart` |
| AC-3 | `apps/mobile/test/imaging/page_render_test.dart` |
| AC-4 | `apps/mobile/test/imaging/page_render_test.dart`, `apps/mobile/test/export/page_exporter_test.dart`, `apps/mobile/test/tool/scanner_benchmark_test.dart` |
| AC-5 | `docs/work/2026-10-17-xs07b-gray-alpha-render/working.md`, `docs/work/2026-10-17-xs07b-gray-alpha-render/PLAN.md` and execution evidence on the PR with this Work ID |

Tests-only RED → root rerun/approval → production GREEN. Preserve tests and expectations through implementation; no golden changes. Android debug/analyze/format/unit/widget gates do not prove device camera/OCR/iOS/release quality.

## 17. Approval, delivery and rollback

Approved for implementation — main session under owner delegation dated2026-10-07 §3d; actual approval2026-10-17. One outcome/PR after55 merge. Worker writes three contracted files in a separate worktree; root owns docs/gates/PR. Merge authority covers55 only; new PR stays OPEN. No auto-merge, release or migration. Roll back through a revert PR; originals remain untouched.

18Oct continuation: the owner's “tiếp cho đến khi hoàn thiện” continues the existing review/repair/gate/guarded-merge workflow for the assigned scope. Root reviews56 afresh and merges only after current-head checks, strict native protection, clean review and full gates. The17Oct OPEN checkpoint above is historical; no auto-merge/deploy or PR-4b data activation is authorized by it.
