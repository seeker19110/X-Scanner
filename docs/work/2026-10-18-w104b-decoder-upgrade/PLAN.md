# PLAN — W104b bounded decoder upgrade

## Bối cảnh & mục tiêu
F004/W104b at seven-day eligibility. Approved spec docs/specs/2026-10-18-w104b-decoder-upgrade.md, one outcome/PR after56merge; keep P1guardrails and closeEX1 only on actualmain evidence.

## Đặc tả dùng chung
Root owns spec/plan/docs/maps/gates/PR/merge. Worker owns only pubspec.yaml/lock, page_render.dart, new decoder_security_test.dart and ownwork record. No changes to existing tests/expectedgoldens, UI/SDK/schema/budget/other modules. Tests-only REDA may use reviewed314a296 before56merge because decoder code/lock remain baseline; production/pin wait for actual56merge and root verification. REDA4.10.1 beforepin; REDB4.12 beforewiring; root reruns each before GREENLIGHT. Use official verifiedarchive/API, firstframe and format/byte/pixel/time limits; no globalmutation except test withfinallyrestore. Package lock onlyimage version/hash. ExistingXS07b regressions guard helper removal after patchedlibrary equivalence; keepJPEGpolicy.

## Nhóm PR (đơn vị mở PR)
- **PR-1** (W104b): gồm việc T1; depends on56actualmerge and rootreconcile. Root integrates frozen exactfiles then fullgate/hook/AOT/finalCI/native and guardedmerge.

## Danh sách việc
### T1 — Security regression and instance bounded decoder   `route: complex`
- Điểm chạm: apps/mobile/pubspec.yaml, apps/mobile/pubspec.lock, apps/mobile/lib/imaging/page_render.dart, apps/mobile/test/imaging/decoder_security_test.dart, docs/work/2026-10-18-w104b-decoder-core/done.md.
- Đặc tả: ApprovedspecAC1..4, rawsyntheticEXIFcycle/finitepoisonPNG, independent expected raster/bounds, typed fixtureCRC viainstalledlibrary/stdlib. No OOM, performance threshold, realdocument or contentlogging. Actualtests-onlyRED thenpause; root independentlyverifies beforepin. Afterpin append new-APIdefaultcap tests; REDB thenpause beforecore. Explicitcapsbeforeparse, nonpositivebeforeupstreamdisable, header+outputcap, nullableimageSizeOf; reuse upstream2chfix onlyafterequivalence. No scaleddecodefeature.
- Phụ thuộc: none
- Tiêu chí chấp nhận: RED is actual assertion/decodefailure, not compile/setup; testexactcontentsretainedRED→GREEN; allold/newtargetedimaging/export/ui-controller/toolPASS, analyze0/format0, fullsource/lockdiffselfreview and exactfrozenhashes/logs. No commit/push/merge/fullgate/AOT/CI/nativechanges/subagents. RootAC5..6.

## Thứ tự tích hợp
56merge→ff-onlymain/tree→exactbaseworker→REDA/rootverify→pin→REDB/rootverify→coreGREEN/targeted→freeze/review/rootintegration→docs/gates/hook/AOT/CI/native→guardedmerge→re-audit/reconcileEX1. No migration/release.
