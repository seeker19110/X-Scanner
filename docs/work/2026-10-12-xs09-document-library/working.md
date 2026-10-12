# Công việc: XS-09: thư viện nhiều tài liệu và migration P1 (PR-1..PR-3)

- Work ID: 2026-10-12-xs09-document-library
- Yêu cầu / outcome: `/auto-complete` lần 8 (2026-10-12): hiện thực XS-09 PR-1..PR-3 theo spec Approved (#30 `508f057`) — mô hình + codec schema 2, `DocumentStore`/`LibraryStore`, migration P1 có nhật ký + tiêm lỗi; không nối vào app.
- Trạng thái: In progress — PR-1 (mô hình + codec) đang làm.
- Chủ trì / writer: phiên chính (kế hoạch, review, tích hợp, cổng); mỗi PR một worker `complex-implementer`, tuần tự.
- Mức rủi ro / số PR: L (spec XS-09); 3 PR tuần tự vì cùng lớp `core`/`storage` (spec §17). PR-4 (nối app, migration dữ liệu thật) BLOCKED chờ chủ repo.
- Scope / non-goal: AC-1..AC-10, AC-14 của spec. Non-goal: UI thư viện, `main.dart`, chạy migration trên dữ liệu thật (PR-4); xoá tài liệu/thùng rác (XS-10).
- Spec / goal / issue: `docs/specs/2026-10-12-document-library-migration.md` · ADR-0011 · hợp đồng XS-08/ADR-0004 · hồ sơ spec `docs/work/2026-10-12-xs09-document-library-spec/done.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `d691d68` · 2026-10-12T13:32:15Z

## Kế hoạch và phân công

- PR-1 `route: complex`: `ScanPage.revision`, `lib/core/scan_document.dart`, codec schema 2 trong `session_manifest.dart` (AC-1, AC-2, AC-3, AC-5; phần codec của AC-4). Brief PLAN qua `subagent-dispatch.sh --check-plan` (exit 0).
- PR-2 (sau PR-1 merge): `DocumentStore` + `LibraryStore` (AC-4, AC-10).
- PR-3 (sau PR-2 merge): migration + nhật ký + phục hồi + tiêm lỗi (AC-6..AC-9, AC-14).
- Nhánh duy nhất `claude/admiring-mccarthy-5b360i`, mỗi PR mở sau khi PR trước merge.

## Quyết định và bằng chứng

- PR-1 giao một worker `complex-implementer` cho cả T1+T2 · loại hai worker · bậc 2 (T2 phụ thuộc T1, cùng lớp `core`; một PR).
- Đọc schema 1 thành tài liệu không thêm hàm (`decodeManifest` + constructor `ScanDocument`) · loại `decodeSchema1Document(...)` · bậc 2 (thang §3.4 nấc 2: dùng lại).
- `ScanDocument` kiểm trùng id trang qua `ScanSession(pages:)` · loại viết lại kiểm trùng · bậc 2.
- Không `copyWith`/`==` ở PR-1 · loại thêm sẵn · bậc 2 (chưa có caller; PR-2 thêm khi cần).
- Giữ hai lựa chọn worker thêm ngoài brief: đọc thời điểm kiểm lịch chặt (`DateTime.tryParse` lăn `02-30` thành `03-02`) và `encodeDocument` từ chối năm ngoài 0000–9999 · loại bỏ đi cho đúng brief · bậc 1 (đọc ngày sai thành ngày khác là sai dữ liệu; ghi file không đọc lại được vi phạm "unreadable manifest is never written").
- Ca AC-3 title 121 rune dùng `'SECRET-TITLE' + 'x'*109` thay mẫu brief (mẫu brief kết thúc bằng dấu cách nên rơi vào luật trim, không thử luật độ dài) · bậc 3 (test chứng minh đúng luật).
- PR-1 worker: đỏ-trước có output (T1 `+48 -19`, T2 `+45 -38` với stub; compile đỏ trước đó), xanh `flutter test test/core/ test/ui/session_controller_test.dart` +191; gate worker PASS (+349) trên `d691d68` + diff; log ở scratchpad phiên.

## Lần thử / blocker

- PR-4 BLOCKED (§3d): bật migration trên dữ liệu thật + giả định "P1 chưa phân phối" chờ chủ repo.

## Bàn giao / bước tiếp theo

- PR-1: worker đang sửa `apps/mobile/lib/core/` + `test/core/`, `test/ui/session_controller_test.dart` (chưa commit, trong cây làm việc). Xong → review diff, `reviewer`, gate, commit `feat:`, PR, CI, merge; rồi brief PR-2.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
