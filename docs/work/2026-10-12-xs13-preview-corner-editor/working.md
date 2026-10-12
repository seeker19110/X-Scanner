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
- Spec merged #35 `29e868f` (CI xanh trên `2a9c88c`).
- PR-1 worker: đỏ-trước (compile đỏ `+29 -5`: thiếu `croppedPreview`/`previewer`/`croppedPreviewFor`), xanh `test/ui/ test/imaging/` +155, gate worker PASS +466 trên `f5218a2` + diff. AC-2 (cùng hình học) xanh cả trên code cũ vì chỉ dùng `renderPageSync`/`thumbnailSync` có sẵn — nó chứng minh tính chất, phần đỏ-trước nằm ở AC-1/AC-3/AC-4.
- PR-1: một mục cache mỗi id, chỉ giữ revision đang có trong phiên; yêu cầu cho revision cũ được dựng riêng cho caller, không vào cache · loại map `(id, revision)` nhiều mục · bậc 2 (không cần dọn mục cũ; chỉ một nhánh).
- PR-1: nút "Chỉnh góc" lấy thumbnail chưa cắt từ `FutureBuilder` ngoài, ô 72×72 là `FutureBuilder` lồng · loại await khi bấm · bậc 2 (giữ hành vi tắt nút khi chưa có thumbnail).
- PR-1: ảnh xem trước lỗi mà thumbnail ổn vẫn cho "Chỉnh góc" · bậc 1 (FR-4: trình chỉnh dùng thumbnail, không phụ thuộc ảnh cắt).
- Review PR-1 (`reviewer`): 0 Cao. F1 Trung bình — `FutureBuilder` của ô không khoá theo revision nên có thể giữ ảnh revision cũ khi chờ ảnh mới: test widget mới `the preview of an older revision is not shown while the new one renders (XS-13 AC-3)` **không đỏ** trên code worker (in debug: ô hiện spinner) vì mỗi thao tác bật/tắt `busy` đổi tay kéo của `ReorderableListView` nên ô được dựng lại từ đầu — lỗi không xảy ra hôm nay; vẫn thêm `key: ValueKey((page.id, page.revision))` để không dựa vào chi tiết ngẫu nhiên đó, test giữ làm hồi quy · bậc 1. F2 — `updatePage` xoá mục cache cũ không có test chứng minh và thừa (mục cũ bị thay khi hỏi revision mới) → gỡ · bậc 2. F3 Thấp — trang đã xoá giải mã lại cả ảnh gốc mỗi lần hỏi → trả `StateError`, không giải mã (test sửa trước, đỏ rồi xanh) · bậc 1 + 2. F4 (quét O(n) mỗi ô) giữ: số trang nhỏ; F5 (gộp mẫu `catchError`) không làm: chỉ hai chỗ.
- Sau sửa: `flutter test test/ui/ test/imaging/` +156, `flutter analyze --fatal-infos` sạch.
- PR-1 merged #36 `f7dc45c` (CI xanh trên `1338cc5`).
- PR-2 worker: đỏ-trước `+166 -5` (thiếu `edit_history.dart`, `toDisplay`/`fromDisplay`, nút "Hoàn tác"), xanh nhóm nhanh +203; gate worker PASS +489 trên `ebddd74` + diff (lần chạy đầu BLOCKED vì HEAD đổi khi Tầng 1 merge `main`, chạy lại PASS). Test cũ sửa: "rejects an invalid drag…" — "Lưu" khi không đổi giờ trả `null` (FR-7).
- PR-2 lựa chọn của worker (giữ): kính lúp 96 dp, ×2, cách góc 96 dp; đang kéo cũng tính là "có thay đổi" khi Back · bậc 2/3 (đơn giản, kiểm được). Hai lựa chọn khác (dịch góc chỉ bị kẹp và "Đặt lại" trên khung đầy vẫn là một bước) bị review đổi, xem dòng dưới.
- Review PR-2 (`reviewer`, chạy 203 test): 0 Cao, 0 Trung bình. Sửa đỏ-trước (2 test đỏ → xanh, nhóm nhanh +206): F1/F2 Thấp — bước không đổi gì (dịch góc chỉ bị kẹp ở mép, "Đặt lại" khi đã là khung đầy) vẫn vào lịch sử nên "Hoàn tác" sáng mà bấm không có gì → `_commit` bỏ qua trang trông như trang hiện tại · bậc 1; F3 Thấp — "Lưu" bằng ngón thứ hai giữa lúc kéo trả trang chưa có nét kéo dở → trả trang đang hiện · bậc 1. F4 — chưa có test buộc phép xoay hiển thị với `img.copyRotate` của file xuất → thêm `display mapping matches the export rotation` (xanh ngay: chứng minh tính chất, như AC-2). Không làm: F5 (test vị trí kính lúp, ngắt kéo bằng hoàn tác — code đã xử lý, chi phí test cao hơn lợi), F6 (gộp `setState`, chỉ là gọn).

## Lần thử / blocker

<Failure, số lần cùng failure, giả thuyết đã bác bỏ, blocker và cách kiểm tiếp.>

## Bàn giao / bước tiếp theo

<Một hành động cụ thể, file/lệnh cần đọc/chạy; thay đổi chưa commit và nơi giữ;
điều kiện có thể tiếp tục. Cập nhật trước nén/chuyển phiên/giao việc.>

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
