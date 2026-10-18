# PLAN — XS09 capacity

## Bối cảnh & mục tiêu
Approved leaf spec docs/specs/2026-10-18-xs09-android-capacity.md; one PR before app wiring, no migration activation.

## Đặc tả dùng chung
Exact contract in spec. Worker writes only six source/test/build files + own record; root owns dispatcher/docs/gates/PR. TDD compiling stub actualRED then root verify/GREENLIGHT, no tests expectations weakening. No compiler until CPU window and no app main/schema/permission/runtime deps.

## Nhóm PR (đơn vị mở PR)
- **PR-1**: gồm việc T1; final root integration depends W104b actual main merge.

## Danh sách việc
### T1 — Fixed-volume capacity adapter `route: complex`
- Điểm chạm: android_storage.dart/test; StorageHandler.kt/Test, MainActivity.kt, app/build.gradle.kts; worker ownrecord.
- Đặc tả: specFR1..4/AC1..2, mock result + pure JVM injected supplier, testonlyJUnit4.13.2.
- Phụ thuộc: root compiler slot.
- Tiêu chí chấp nhận: actual tests-onlyRED on compiling stub, root verifies before logic; unchangedtestsGREEN; freeze exacthashes; no commit/gate/push/merge.

## Thứ tự tích hợp
Spec→workerstatic→rootCPUgrant→RED→rootverify→GREENLIGHT→workerlogic/targeted→freeze→rootfreshmainintegration/docs/fullgate/hook/CI/review→merge→appintegration.
