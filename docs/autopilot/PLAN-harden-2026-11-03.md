# PLAN-harden — X-Scanner · 2026-11-03
> Duyệt: chủ repo yêu cầu merge→/complete 03/11; D-009 root tự duyệt §3d, Work ID2026-11-03-complete-harden. Không stage ledger; không production grants.
## Outcome
Merge74/73 đã đạt; explicit harden, audit13 nhóm, sửa lỗi tái hiện. Không release/signing/real-data/license decision; giữ P1/XS09 scope. Gate timeout1800s, một Flutter/Gradle trên host; vòng single-session.
### Lát 1 — phase và audit
- [x] `T-201` Khai harden/format/coverage: Given gate cũ, When khai alias, Then cùng thresholds và commands; edge E2E thiếu vẫn đỏ (files: .) — Gate: `bash scripts/dev-task.sh gate`
- [x] `T-202` Ghi audit13 nhóm: Given source main, When kiểm sổ, Then schema đủ và lỗi mở còn nguyên; edge DATA native không N/A (files: docs/ops/) — Gate: `python3 .xtemplates/scripts/xt.py audit check docs/ops/AUDIT-STATUS.md`
### Lát 2 — repair và nghiệm thu
- [ ] `T-203` AUD-DATA-001 một editor: Given duplicate callbacks, When open/create, Then một route và giữ byte; edge dispose/refresh (files: apps/mobile/lib/ui/library_screen.dart, apps/mobile/test/ui/library_screen_test.dart) — Gate: `cd apps/mobile && flutter test test/ui/library_screen_test.dart`
- [ ] `T-204` AUD-PERF-001 release closed owner: Given late writes, When close/reopen, Then chờ đúng idle và không xoá successor; edge old completion (files: apps/mobile/lib/main.dart, apps/mobile/test/app_test.dart) — Gate: `cd apps/mobile && flutter test test/app_test.dart`
- [ ] `T-205` AUD-DATA-002/CODE-001 input bounds: Given schema expansion/nonfinite, When migrate/edit, Then fail trước ghi/giữ quad; edge recovery,finite clamp (files: apps/mobile/lib/storage/p1_migration.dart, apps/mobile/lib/core/quad_editing.dart) — Gate: `cd apps/mobile && flutter test test/storage/p1_migration_test.dart test/core/quad_editing_test.dart`
- [ ] `T-206` E2E thật: Given dedicated Android và≥8GB, When chạy exact APK, Then migration/byte/reopen có bằng chứng; edge signer mismatch giữ originals (files: docs/ops/evidence/) — Gate: `python3 .xtemplates/scripts/xt.py floor --run --strict`
- [ ] `T-207` Signoff: Given code merge và owner decisions, When release check, Then GO thật; edge thiếu license/UAT không giả xanh (files: docs/autopilot/) — Gate: `python3 .xtemplates/scripts/xt.py release-check --json`
