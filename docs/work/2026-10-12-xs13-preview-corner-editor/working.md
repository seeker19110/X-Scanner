# Công việc: XS-13: xem trước đã cắt và trình chỉnh góc

- Work ID: 2026-10-12-xs13-preview-corner-editor
- Yêu cầu / outcome: `/auto-complete` lần 9 (2026-10-12): XS-09 PR-4 BLOCKED chờ chủ repo → làm việc kế tiếp không bị chặn của kế hoạch M1: XS-13 (F-026, F-032).
- Trạng thái: In progress — spec Approved (PR spec đang mở).
- Chủ trì / writer: phiên chính (spec, review, tích hợp, cổng); mỗi PR code một worker `complex-implementer`, tuần tự.
- Mức rủi ro / số PR: M (chỉ UI + ảnh xem trước từ thumbnail; không đổi dữ liệu/dependency); 1 PR spec + 2 PR code tuần tự (PR-2 mở trình chỉnh từ màn danh sách PR-1 sửa).
- Scope / non-goal: FR-1..FR-10, AC-1..AC-10 của spec. Non-goal: phóng to hai ngón, bộ lọc, F-033 (XS-12), F-031 (XS-20), chỉnh góc một-chạm cho mọi người dùng.
- Spec / goal / issue: `docs/specs/2026-10-12-preview-and-corner-editor.md` · kế hoạch §6.3/§13 XS-13 · hợp đồng XS-08 FR-4/AC-6
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `989112b` · 2026-10-12T15:00:31Z

## Kế hoạch và phân công

- PR spec: `docs/specs/2026-10-12-preview-and-corner-editor.md` + hồ sơ này.
- PR-1 `route: complex`: F-026 — `croppedPreviewFor` cache `(id, revision)` trong `session_controller.dart`, ô danh sách trong `review_screen.dart` (AC-1..AC-4).
- PR-2 `route: complex` (sau PR-1 merge): F-032 — `quad_editing.dart`, `core/edit_history.dart`, `quad_editor_screen.dart` (AC-5..AC-10).
- Nhánh duy nhất `claude/admiring-mccarthy-5b360i`; mỗi PR mở sau khi PR trước merge.

## Quyết định và bằng chứng

- Chọn XS-13 làm việc kế tiếp · loại XS-10 (xoá dữ liệu thật + phụ thuộc PR-4), XS-11/XS-21 (cần corpus XS-06, quyền dữ liệu), XS-14/15 (cần thiết bị) · bậc 1 (việc duy nhất của M1 không chạm dữ liệu thật/thiết bị/quyền; XS-08 đã chỉ định XS-13 là consumer của AC-6).
- Mức M, spec gọn tự duyệt §3d · loại chờ chủ repo · bậc 1 (không đổi dữ liệu/schema/dependency/quyền — ngoài danh sách "không bao giờ tự quyết").
- Xem trước dựng từ thumbnail đã cache bằng `renderPageSync` · loại render từ ảnh gốc · bậc 1 + 2 (cùng hàm với xuất nên cùng hình học; không giải mã thêm ảnh gốc, dùng lại code).
- Xem trước xếp hàng qua cùng `DecodeGate` · loại hàng đợi riêng · bậc 2 (không thêm cơ chế; ảnh ≤ 1024 px nên chờ ngắn).
- Kính lúp bằng `RawMagnifier` có sẵn · loại tự vẽ · bậc 2 (đã kiểm có trong SDK Flutter 3.47.7: `widgets/magnifier.dart`).
- Không làm phóng to hai ngón · loại làm luôn · bậc 2 (kính lúp đủ cho độ chính xác; xem lại khi UAT thiết bị/XS-20).
- Chỉnh góc không cần kéo qua thao tác trợ năng, thu hẹp `DEBT:` · loại bảng nút dịch hiển thị cho mọi người · bậc 2 (XS-20 làm a11y đầy đủ).

## Lần thử / blocker

<Failure, số lần cùng failure, giả thuyết đã bác bỏ, blocker và cách kiểm tiếp.>

## Bàn giao / bước tiếp theo

<Một hành động cụ thể, file/lệnh cần đọc/chạy; thay đổi chưa commit và nơi giữ;
điều kiện có thể tiếp tục. Cập nhật trước nén/chuyển phiên/giao việc.>

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
