# Công việc: XS09 Android capacity foundation

- Work ID: 2026-10-18-xs09-android-capacity
- Outcome: fulfill missing Storage.freeBytes for approved PR4b without activating migration yet.
- Trạng thái: VERIFY; source integrated on actualmainc50670a, spec approved before source.
- Risk: M leaf of L data integration; one PR then app wiring separately.
- Scope: exact files in approved capacity spec; no main.dart/schema/permission/runtime dependency change.
- Spec: docs/specs/2026-10-18-xs09-android-capacity.md; parent XS09 explicit owner18Oct approval.
- Base: design checkout314a296; worker starts fresh561a5cf, final integration after W104 actualmerge.

## Kế hoạch và phân công
Root owns approval/PLAN/docs/dispatcher config/review/gates/PR/merge. Worker on separate worktree owns Dart leaf/test, Kotlin handler/test/MainActivity, app build.gradle.kts and own work record only. Tests + compiling stub first, actual behavior RED before implementation; pause root GREENLIGHT. No compiler until root CPU window, no shared root edits/commit/push/merge/subagents.

## Quyết định và bằng chứng
- Native fixed filesDir, no arbitrary path payload; Dart binds exact supportroot; simpler trust boundary, same filesystem proven by installed path_provider code.
- JUnit test-only enables meaningful native branch/error tests; no runtime dependency. Existing Flutter gate broadened only to run new JVM tests.
- Split leaf from app switching for review and TDD; parent approval preserved, no extra owner question.

## Lần thử / blocker
No source/tests/gate yet. W104 fullgate/hook uses CPU now; worker static file editing only until notified.

## Bàn giao
Finalize PLAN, delegate disjoint worker. Root inspect actual RED and dependency artefacts before GREENLIGHT. No Done before all ACs and merge proof.

### Supply-chain verification before implementation

Root queried official Maven Central and release API18Oct: JUnit4.13.2 release2021-02-13, jarSHA2568e495b634469d64fb8acfa3495a065cbacc8a0fff55ce1e31007be4c16dc57d3; Hamcrest-core1.3 jarSHA25666fdef91e9739348df7a096aa384a5685f4e875584cce89386a7a47251c4d8e9. Both match official repository digest; POM/license checked EPL1.0 and BSD3clause. POM runtime edge only Hamcrest1.3 for JUnit test runner, hamcrest-library is JUnit's own test scope and not requested by app. LiveOSV2Mavenpackages/2results,0advisories (not bug-free proof). Rawpackages/POMs/checksums/OSV retained outside repo capacity-dependency-evidence-20261018.

Actual installed path_provider_android2.3.1 lib/src/path_provider_android_real.dart28–31 maps getApplicationSupportPath to _applicationContext.filesDir via generated JNI binding; no old Java plugin path assumed. Native fixedfilesDir therefore measures the support root volume.

Root dispatcher now appends :app:testDebugUnitTest to existing test command; test selector execution still awaiting actual RED output. No migration activation. UAT24boundedboot failed memoryguard; CPUwindow ended and root resumed compile after worker reported the window ended.


## Root integration checkpoint — 2026-10-18

Sau nối tiếp phiên, root kiểm SHA256 cả6 frozenfiles khớp bảng worker, đọc actualsource/tests/spec/REDlogs. Freshfetchmainc50670a/clean; capacitybranch ff-only561→c506 giữ nguyên6files, không ghép khi worker đang ghi. Review độc lập trên worktree snapshot riêng findings=[],7hashes gồm dispatcher giữ nguyên, không compiler/edit. Source app trên main mới dùngimage4.12; targeted19/11 của worker trênbase561 chỉ là lịch sử, root phải chạy integrated fullgate.

W104bactualmerge58/tree/proofs đã reconcile Done và EX1/F004đóng trong cùngPRcapacity. ParentP1 vẫn working vì AC9, giữ lịch sử; ownerPR4b/P1notdistributed18Oct được ghi rõspec. Windowsacceleratedsetupđượcusergiao tựcài, chưaclaimUAT. NativeGradlebaseline deprecationwarnings tồn tại ởRED trướcleaf, không nhận0Gradlewarnings. Không đi rộng sangAGPmigration trong slice này.


### Root gate / native execution refinement

First integrated dispatcher gate4/4 PASS (config3a1ec4baa525de0c1401ceb53b84995514198931/snapshote34e6a21453c509cdadd5022c8e67e0be8759e8a),658FlutterPASS/analyze0/format0/freshAPK+releaseguard. Its quiet Gradle task may reuse up-to-date outputs; do not call its old XML a new JVM execution. Root queried installed Gradle9.3.1 task help and verified `--rerun` means re-run task even if up-to-date. Added that task-local flag to dispatcher to execute native tests in every gate, without rebuilding every dependency. Pure configuration change; TDD exemption config-only, allruntimefiles/tests unchanged. Finalprofile gate must rerun after flag/docs refinement.

FreshOSV10:48Z query86Pub+2Maven/88results returned0advisories, retained capacity-osv-final.json; no full-audit claim. Root actualWindowsaccel proof exit0/WHPXusable and verifiedCI58bundlehash are available outside repo; UAT notyetperformed.
