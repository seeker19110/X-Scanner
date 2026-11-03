# AUDIT-STATUS — X-Scanner

> 2026-11-03 · Báo cáo: `docs/ops/AUDIT-REPORT-2026-11-03.md`; lịch sử F001–F083 giữ ở COMPREHENSIVE-AUDIT-STATUS.md.
## Nhóm
| # | Mã | Nhóm | Trạng thái | SHA | Ngày | Ghi chú |
|---|---|---|---|---|---|---|
| 1 | ARCH | Kiến trúc | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Rà diff module và chiều phụ thuộc, architecture check trong full gate. |
| 2 | SEC | Bảo mật | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Rà quyền sở hữu editor, giới hạn input và toàn vẹn byte. CI OSV và gate xanh. |
| 3 | CODE | Mã | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Rà guard route, vòng đời controller, cap UTF8 và finite xy cùng các test. |
| 4 | TEST | Kiểm thử | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Full gate tích hợp 851 Flutter, 11 JVM, 38 repository. |
| 5 | PERF | Hiệu năng | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Rà strong reference và cap đọc. Đo heap thiết bị còn mở. |
| 6 | A11Y | Trợ năng/UX | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Rà duplicate Semantics và keyboard readiness. TalkBack thiết bị còn mở. |
| 7 | DEP | Phụ thuộc | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 8 | CI | CI/CD | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 9 | DOC | Tài liệu | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Đối chiếu CODEMAP, TRAPS, PROGRESS và ba hồ sơ sửa lỗi trên main. |
| 10 | DATA | Filesystem/migration | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Rà ownership, prewrite cap và rollback. Migration trên Android chờ UAT. |
| 11 | CFG | Cấu hình | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 12 | XFEAT | Chéo tính năng | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Rà handoff route và controller cùng smoke giữ pending save. |
| 13 | HAR | Harness | đã quét | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd | 2026-11-03 | Rà CI và hồ sơ đối chiếu main. E2E thiết bị đang chờ APK. |
## Phát hiện
| ID | Mức | Trạng thái | Tóm tắt | Bằng chứng | Gate | Ghi chú |
|---|---|---|---|---|---|---|
| AUD-DATA-001 | 🔴 | đã sửa | Hai editor có thể lưu snapshot cũ và xoá ảnh mới | đo được: widget duplicate activation exit1, opened2 thay1; Dart stale-store B true→false | `cd apps/mobile && flutter test test/ui/library_screen_test.dart` | #76 đã merge tại `90b07c6f53864a70225e1b9662890016fb221e3a`. Hồi quy duplicate activation qua gate tích hợp. |
| AUD-PERF-001 | 🟠 | đã sửa | Controller/cache của mọi tài liệu đã đóng còn được giữ | suy luận: main.dart _last strong refs; SessionController.dispose không giải phóng map owner | `cd apps/mobile && flutter test test/app_test.dart` | #77 đã merge tại `b9a3f192b10e9d6163dc93b2136a30a23df92613`. Handoff qua gate tích hợp, đo heap thiết bị còn mở. |
| AUD-DATA-002 | 🟠 | đã sửa | Migration công bố manifest vượt cap app đọc | đo được: schema1 4194269≤4194304, target4535227, MigrationDone nhưng LibraryUnreadable | `cd apps/mobile && flutter test test/storage/p1_migration_test.dart` | #78 đã merge tại `2f9eb53e810b84ef71b13ea76830a8ffd999edbd`. Tripwire trước ghi và recovery qua gate tích hợp. |
| AUD-CODE-001 | 🟢 | đã sửa | NaN corner bị clamp thành tọa độ hợp lệ | đo được: NaN.clamp=1, TR/BR accepted | `cd apps/mobile && flutter test test/core/quad_editing_test.dart` | #78 đã merge tại `2f9eb53e810b84ef71b13ea76830a8ffd999edbd`. Hồi quy NaN và ±Infinity qua gate tích hợp. |
| AUD-HAR-001 | 🟠 | mở | E2E thiết bị chưa có cổng/bằng chứng | đo được: floor thiếu e2e. Emulator WHPX API 36 đã boot và ADB đã nhận | `python3 .xtemplates/scripts/xt.py floor --run --strict` | W-602/F-078: chờ APK từ main và chạy UAT. |
| AUD-DOC-001 | 🟢 | mở | Mô tả logging/gitleaks/màn hình/AC9 đã cũ | đo được: FEATURE-MAP, THREAT-MODEL, BLUEPRINT lệch source/CI/AC9 receipt | `python3 scripts/check-links.py` | phase docs sửa văn bản; link gate không chứng minh ngữ nghĩa |
