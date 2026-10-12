# Công việc: XS-12a — tác vụ xuất có tiến độ và huỷ (F-033)

- Work ID: 2026-10-12-xs12a-export-progress
- Yêu cầu / outcome: `/auto-complete` (2026-10-12): sau XS-13, làm việc kế tiếp không bị chặn của kế hoạch M1 — XS-12 phần tiến độ/huỷ xuất (F-033).
- Trạng thái: Done — spec #39 `484cd1a`, PR-1 #40 `614b5b4`.
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
- Spec merged #39 `484cd1a` (CI xanh trên `b93d63c`). PR-1 giao `complex-implementer` theo brief đã qua `subagent-dispatch.sh --check-plan` (OK).
- PR-1 worker: đỏ-trước trên stub chỉ có API `+70 -29` (export/controller/a11y) và `+6 -3` (UI), xanh `test/export/ test/ui/` +158, gate worker PASS +512 trên `b93d63c` + diff. Test cũ của `export` chuyển sang `run` (assert tên file giữ nguyên; "ném lỗi" → `failed(renderFailed|writeFailed)`); bỏ ca "danh sách rỗng" ở exporter vì `ExportJob` đã từ chối (có ở `export_job_test`).
- Worker tự quyết (giữ): `ExportFormat` chuyển sang `export_job.dart`, `page_exporter.dart` export lại · bậc 2 (import cũ không đổi); `succeed` đòi `done == total`, `fail(cancelled)` ném · bậc 1 (chặn trạng thái sai); hàng "Đang xuất" `minHeight: 48` cùng `SafeArea`/`Padding` · bậc 1 (không nhảy bố cục).
- Tầng 1 đổi: `exportJob` về null ngay khi job kết thúc, trước khi chia sẻ (test đỏ → xanh "the job is gone while sharing") · loại giữ tới `finally` như brief · bậc 1 (worker báo: khi share sheet mở vẫn hiện nút "Huỷ" bấm không có tác dụng).
- Review PR-1 (`reviewer`, 159 test): 0 Cao. Sửa đỏ-trước (3 test đỏ → xanh, `test/export/ test/ui/` +161): F1 `run` lại job đã chạy xoá file của nó trước khi ném → kiểm trạng thái trước khi xoá · bậc 1 (không mất dữ liệu); F2 bấm "Huỷ" không phản hồi tới hết trang → "Đang huỷ…" + tắt nút · bậc 1; F3 `dispose` không huỷ tác vụ, share sheet mở sau khi màn đóng → `dispose` huỷ · bậc 1. F4 ca AC-5 ở controller chỉ chứng minh hàng đợi → sửa ghi chú bảng AC, bằng chứng chính là test exporter · bậc 3. Không làm: F5 nhãn trợ năng trùng giữa thanh tiến độ và chữ (spec không đòi; xem lại ở XS-20 a11y) · bậc 2; gom `HeldRenderer` ba file test, view chỉ-đọc cho `ExportJob` · bậc 2 (ít code hơn, spec §11 chấp nhận hợp đồng).
- PR-1 merged #40 `614b5b4` (CI xanh trên `30ad806`; gate trước commit PASS +515).

## Lần thử / blocker

<Failure, số lần cùng failure, giả thuyết đã bác bỏ, blocker và cách kiểm tiếp.>

## Bàn giao / bước tiếp theo

- Hồ sơ xong. Phần còn lại của XS-12 (tiếp tục sau khi app đóng, vòng đời file chia sẻ, writer theo luồng) chờ XS-11/corpus XS-06; nhãn trợ năng trùng giữa thanh tiến độ và chữ → XS-20.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Outcome đạt: F-033 đóng; spec XS-12a AC-1..AC-7 có test (`spec-compiler --trace`: TRACE COMPLETE), hợp đồng XS-08 §9 tiêu chí 7, 8 có bằng chứng. Spec #39 `484cd1a`, PR-1 #40 `614b5b4`, mỗi PR CI "Framework and Android app gate" xanh trước khi merge. `main` đã đối chiếu 2026-10-12T17:10Z.
- Giới hạn còn lại: huỷ trong lúc dựng PDF trong isolate chỉ có hiệu lực sau khi dựng xong (non-goal); chưa chạy trên thiết bị/TalkBack.
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-12.
