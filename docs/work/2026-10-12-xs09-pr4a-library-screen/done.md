# Công việc: XS-09 PR-4a — màn thư viện (chưa nối vào app)

- Work ID: 2026-10-12-xs09-pr4a-library-screen
- Yêu cầu / outcome: chủ repo 2026-10-12: "chỉ làm PR đóng hồ sơ XS-12a và PR-4a" — màn thư viện XS-09 (AC-11, AC-12, phần UI của AC-8/AC-9), chưa nối vào app.
- Trạng thái: Done — spec #42 `ec5db8d`, code #43 `26d3d39`; PR-4b chờ chủ repo.
- Chủ trì / writer: phiên chính (spec, review, tích hợp, cổng); code một worker `complex-implementer` trong worktree riêng.
- Mức rủi ro / số PR: M cho PR-4a (UI mới, không nối app, không chạm dữ liệu thật/dependency); 1 PR spec + 1 PR code.
- Scope / non-goal: `LibraryController`, `LibraryScreen` + test. Non-goal (PR-4b, **chờ chủ repo**): nối `main.dart`, chạy migration trên dữ liệu thật, `SessionController`/`ReviewScreen` trên `DocumentStore`, gỡ `SessionStore`. Ngoài phạm vi lượt này: XS-20 (`flutter_localizations` chưa được duyệt).
- Spec / goal / issue: `docs/specs/2026-10-12-document-library-migration.md` §6, §10, §12, §17 · ADR-0011 · kế hoạch §6.1 XS-09
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `0d25ede` · 2026-10-12T23:17:14Z

## Kế hoạch và phân công

- PR spec: cập nhật §17 tách PR-4 thành PR-4a (duyệt) / PR-4b (chờ chủ repo) + hồ sơ này.
- PR-4a `route: complex`: `lib/ui/library_controller.dart`, `lib/ui/library_screen.dart` (mới) + test; màn tài liệu và migration tiêm từ ngoài.

## Quyết định và bằng chứng

- Phạm vi: chủ repo chọn "chỉ làm PR đóng hồ sơ XS-12a và PR-4a" (2026-10-12) sau khi lượt trước bị chặn vì phiên chính coi "làm hết đi" là duyệt PR-4 trên dữ liệu thật · PR-4b và XS-20 giữ chờ chủ repo · bậc 1 (§3d: không tự quyết dữ liệu thật/dependency mới).
- Tách PR-4 thành PR-4a/PR-4b · loại một PR như spec cũ · bậc 1 (PR-4a không đổi hành vi app nên làm được ngay; công tắc dữ liệu thật tách riêng).
- Màn tài liệu và migration là tham số tiêm (`DocumentScreenBuilder`, `migrate`) · loại import `ReviewScreen`/`P1Migration` trực tiếp · bậc 1 + 3 (không nối được dữ liệu thật; test dùng giả).
- Worker chạy trong worktree riêng · loại cùng thư mục với nhánh PR đang mở · bậc 3 (commit spec qua cổng không lẫn code dở).
- Giữ tên `session_manifest.dart` · loại đổi tên theo §11 · bậc 2 (chỉ churn; xem lại ở PR-4b).
- Spec PR merged #42 `ec5db8d` (CI xanh trên `12df6af`).
- PR-4a worker (worktree): đỏ-trước trên stub đúng chữ ký `+13 -26`, xanh 3 file +39, gate worker PASS +542 trên `614b5b4` + diff; không sửa test cũ. Lựa chọn giữ: `start`/`refresh` xếp hàng FIFO, `refresh` không liệt kê khi migration lỗi, `refresh` không về `loading` (không nháy), `storeOf(docId)`, FAB "Tài liệu mới" chỉ ở trạng thái ready, đổi tên chỉ trên mục `LibraryDocument` (load mục hỏng sẽ cách ly manifest) · bậc 1/2. Hằng 120 lặp trong `titleErrorOf` vì hằng ở `core` là private và PR này không sửa `core` · bậc 2 (xem lại khi `core` mở hằng). Ca "liệt kê lỗi" dùng `LibraryStore` con ném `FileSystemException` (root là file thường không gây lỗi: `list()` trả rỗng) · bậc 3.
- Tầng 1 sửa đỏ-trước: `migrate` ném lỗi bất ngờ → kẹt `loading` → coi như `MigrationFailed(io)` (1 test đỏ → xanh) · bậc 1.
- Review PR-4a (`reviewer`, 40 test): F1 Cao — đổi tên tài liệu đọc được nhưng thiếu bản gốc gọi `load()` → `DocumentStore` cách ly manifest, tài liệu thành "Không mở được" chỉ vì đổi tên → kiểm mọi bản gốc tồn tại trước khi `load`, thiếu thì `saveFailed` không chạm đĩa · bậc 1. F2 Trung bình — chạm một tài liệu trong lúc "Tài liệu mới" đang ghi mở hai màn chồng nhau → màn bỏ qua mở khi đang tạo (chạm hai lần cùng một hàng không tái hiện: route mới chặn chạm) · bậc 1. F5 Thấp — `createDocument` chạy được trước/sau migration lỗi (ghi cùng `documents/`) → `saveFailed` khi thư viện chưa mở · bậc 1. Ba test đỏ → xanh; test cũ "new document converts a local clock to UTC" thêm `start()` vì tạo giờ cần thư viện đã mở. Không làm: F3 `didUpdateWidget` đổi controller không `start` (chưa có đường gọi) · bậc 2; F4 bấm "Thử lại" hai lần chạy migration hai lần (migration lặp lại an toàn) · bậc 2; gom `_formatLocal` với `defaultDocumentTitle` (không sửa `core` ở PR này) · bậc 2.
- Sau sửa: 3 file test +43, `flutter analyze --fatal-infos` sạch.
- PR-4a merged #43 `26d3d39` (squash; CI "Framework and Android app gate" xanh trên `76a0aff`; gate pre-commit PASS +546).

## Lần thử / blocker

- Không có failure lặp lại. Blocker còn lại thuộc chủ repo: PR-4b (nối `main.dart`, migration dữ liệu P1 thật, gỡ `SessionStore`, AC-13) và XS-20 (`flutter_localizations`).

## Bàn giao / bước tiếp theo

- PR-4a xong. Tiếp theo: PR-4b — chỉ bắt đầu khi chủ repo duyệt rõ trong phiên (spec §17, Approval).
- Kiểm thiết bị AC-9 (đọc màn hình thật) đi cùng PR-4b khi màn đã nối vào app.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- DoD PR-4a: spec Approved trước code (#42); AC-11, AC-12 và phần UI của AC-8/AC-9 có test (spec trace); gate và CI xanh;
  review F1, F2, F5 đã sửa đỏ-trước; F3, F4 ghi ở trên kèm lý do không làm.
- PR đã merge: #42 `ec5db8d` (spec), #43 `26d3d39` (code); `main` đã đối chiếu tại `26d3d39`.
- Giới hạn còn lại: màn chưa nối vào app (PR-4b); kiểm đổi tên tồn tại bản gốc trước `load` không chặn file bị xoá giữa hai bước;
  "Thử lại" hai lần chạy migration hai lần (an toàn, migration tiếp tục từ journal); chưa chạy thiết bị thật.
- Nghiệm thu: phiên chính theo ủy quyền §3d trong phạm vi chủ repo giao ("chỉ làm PR đóng hồ sơ XS-12a và PR-4a"), 2026-10-12.
