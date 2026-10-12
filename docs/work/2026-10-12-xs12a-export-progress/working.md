# Công việc: XS-12a — tác vụ xuất có tiến độ và huỷ (F-033)

- Work ID: 2026-10-12-xs12a-export-progress
- Yêu cầu / outcome: `/auto-complete` (2026-10-12): sau XS-13, làm việc kế tiếp không bị chặn của kế hoạch M1 — XS-12 phần tiến độ/huỷ xuất (F-033).
- Trạng thái: In progress — spec viết xong, chờ PR spec.
- Chủ trì / writer: phiên chính (spec, review, tích hợp, cổng); PR code một worker `complex-implementer`.
- Mức rủi ro / số PR: M (đổi cách chạy xuất + UI; không đổi dữ liệu lưu/định dạng/dependency); 1 PR spec + 1 PR code.
- Scope / non-goal: FR-1..FR-5, AC-1..AC-7 của spec. Non-goal: tiếp tục sau khi app đóng, vòng đời file chia sẻ, chọn nơi lưu, profile/khổ giấy/chọn trang/tên file, writer PDF theo luồng (XS-11), ngắt isolate dựng PDF.
- Spec / goal / issue: `docs/specs/2026-10-12-export-progress-cancel.md` · kế hoạch §6.2/§6.3/§13 XS-12 · hợp đồng XS-08 FR-5, §12.2, AC-7, AC-8 · audit F-033
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `f21e94c` · 2026-10-12T15:55:38Z

## Kế hoạch và phân công

- PR spec: `docs/specs/2026-10-12-export-progress-cancel.md` + hồ sơ này.
- PR-1 `route: complex`: `lib/export/export_job.dart` (mới), `page_exporter.dart`, `session_controller.dart`, `review_screen.dart` + test (AC-1..AC-7).
- Nhánh duy nhất `claude/admiring-mccarthy-5b360i`; PR-1 mở sau khi PR spec merge.

## Quyết định và bằng chứng

- Chọn XS-12a (tiến độ/huỷ) làm việc kế tiếp · loại XS-20 (cần dependency `flutter_localizations` ngoài bộ D2 đã duyệt), XS-11/XS-12 writer/XS-21 (cần corpus XS-06, quyền dữ liệu), XS-10/XS-09 PR-4 (dữ liệu thật, chờ chủ repo), XS-14/15 (thiết bị) · bậc 1 (việc duy nhất còn lại không chạm dữ liệu thật/dependency mới/thiết bị).
- Tách XS-12 thành XS-12a (tiến độ/huỷ) · loại làm trọn XS-12 · bậc 1 + 2 (phần còn lại phụ thuộc writer XS-11/corpus; F-033 tự đứng được).
- Mức M, spec gọn tự duyệt §3d · loại chờ chủ repo · bậc 1 (không đổi dữ liệu/schema/dependency/quyền).
- Snapshot dùng chính `ScanPage` bất biến, chưa có `documentId` · loại thêm `ExportPageSnapshot` · bậc 2 (đúng 5 trường XS-08 cần; ghi lệch hợp đồng trong spec §11).
- Huỷ ở ranh giới trang và trước khi công bố, không ngắt isolate PDF · loại ngắt `Isolate` · bậc 2 + 3 (`Isolate.run` không có API huỷ; kết quả vẫn bị bỏ trước khi chia sẻ).
- `cancelExport()` không qua hàng đợi `_enqueue` · bậc 1 (hàng đợi đang bận chính tác vụ xuất, xếp hàng thì huỷ chỉ chạy sau khi xuất xong).

## Lần thử / blocker

<Failure, số lần cùng failure, giả thuyết đã bác bỏ, blocker và cách kiểm tiếp.>

## Bàn giao / bước tiếp theo

- Sau khi #38 merge: commit spec + hồ sơ qua cổng, mở PR spec; merge xong thì viết brief PR-1 (`route: complex`) và giao worker.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
