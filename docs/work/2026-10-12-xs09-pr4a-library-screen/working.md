# Công việc: XS-09 PR-4a — màn thư viện (chưa nối vào app)

- Work ID: 2026-10-12-xs09-pr4a-library-screen
- Yêu cầu / outcome: chủ repo 2026-10-12: "chỉ làm PR đóng hồ sơ XS-12a và PR-4a" — màn thư viện XS-09 (AC-11, AC-12, phần UI của AC-8/AC-9), chưa nối vào app.
- Trạng thái: In progress — spec cập nhật duyệt PR-4a; code đang làm.
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

## Lần thử / blocker

<Failure, số lần cùng failure, giả thuyết đã bác bỏ, blocker và cách kiểm tiếp.>

## Bàn giao / bước tiếp theo

- Merge PR spec; review kết quả worker (worktree), chép vào nhánh, `/gate`, mở PR-4a.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
