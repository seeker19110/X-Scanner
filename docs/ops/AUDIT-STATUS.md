# AUDIT-STATUS — X-Scanner

> 2026-11-03 · Báo cáo: `docs/ops/AUDIT-REPORT-2026-11-03.md`; lịch sử F001–F083 giữ ở COMPREHENSIVE-AUDIT-STATUS.md.
## Nhóm
| # | Mã | Nhóm | Trạng thái | SHA | Ngày | Ghi chú |
|---|---|---|---|---|---|---|
| 1 | ARCH | Kiến trúc | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 2 | SEC | Bảo mật | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 3 | CODE | Mã | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 4 | TEST | Kiểm thử | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 5 | PERF | Hiệu năng | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0; chưa đo thiết bị |
| 6 | A11Y | Trợ năng/UX | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0; chưa đo thiết bị |
| 7 | DEP | Phụ thuộc | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 8 | CI | CI/CD | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 9 | DOC | Tài liệu | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 10 | DATA | Filesystem/migration | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0; override N/A SQL heuristic, có migration filesystem |
| 11 | CFG | Cấu hình | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 12 | XFEAT | Chéo tính năng | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
| 13 | HAR | Harness | đã quét | d22e622e421fc0656d46ea5aff93b0200b29e4b8 | 2026-11-03 | candidate976c71d có tree trùng main; root đối chiếu git diff exit0 |
## Phát hiện
| ID | Mức | Trạng thái | Tóm tắt | Bằng chứng | Gate | Ghi chú |
|---|---|---|---|---|---|---|
| AUD-DATA-001 | 🔴 | mở | Hai editor có thể lưu snapshot cũ và xoá ảnh mới | đo được: widget duplicate activation exit1, opened2 thay1; Dart stale-store B true→false | `cd apps/mobile && flutter test test/ui/library_screen_test.dart` | product tìm/đo UI; security xác minh storage; PR#76 prepared; main vẫn mở |
| AUD-PERF-001 | 🟠 | mở | Controller/cache của mọi tài liệu đã đóng còn được giữ | suy luận: main.dart _last strong refs; SessionController.dispose không giải phóng map owner | `cd apps/mobile && flutter test test/app_test.dart` | code tìm, product xác minh graph; không đo heap/OOM; PR#77 prepared |
| AUD-DATA-002 | 🟠 | mở | Migration công bố manifest vượt cap app đọc | đo được: schema1 4194269≤4194304, target4535227, MigrationDone nhưng LibraryUnreadable | `cd apps/mobile && flutter test test/storage/p1_migration_test.dart` | code full VM repro; product độc lập size proof; rollback còn; PR#78 prepared |
| AUD-CODE-001 | 🟢 | mở | NaN corner bị clamp thành tọa độ hợp lệ | đo được: NaN.clamp=1, TR/BR accepted | `cd apps/mobile && flutter test test/core/quad_editing_test.dart` | code tìm, root VM xác minh; PR#78 prepared, cùng slice boundary validation |
| AUD-HAR-001 | 🟠 | mở | E2E thiết bị chưa có cổng/bằng chứng | đo được: floor thiếu e2e; ADB rỗng, ổ C2573086720 bytes | `python3 .xtemplates/scripts/xt.py floor --run --strict` | Không thay bằng widget tests; W-602/F-078; owner cấp tài nguyên |
| AUD-DOC-001 | 🟢 | mở | Mô tả logging/gitleaks/màn hình/AC9 đã cũ | đo được: FEATURE-MAP, THREAT-MODEL, BLUEPRINT lệch source/CI/AC9 receipt | `python3 scripts/check-links.py` | phase docs sửa văn bản; link gate không chứng minh ngữ nghĩa |
