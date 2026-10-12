# Công việc: Nháp spec XS-09: thư viện nhiều tài liệu và migration P1

- Work ID: 2026-10-12-xs09-document-library-spec
- Yêu cầu / outcome: `/auto-complete` lần 7 (2026-10-12) — phiên chính chọn viết **nháp** spec XS-09 (kế hoạch #23 §6.1, §13; consumer đầu tiên của hợp đồng XS-08/ADR-0004). Outcome: spec Draft `docs/specs/2026-10-12-document-library-migration.md` chờ chủ repo duyệt.
- Trạng thái: Done — nháp #29 `ed06e58`, duyệt PR-1..PR-3 #30 `508f057`; PR-4 chờ chủ repo.
- Chủ trì / writer: phiên chính, một writer.
- Mức rủi ro / số PR: S cho PR này (chỉ tài liệu); XS-09 là mức L (migration dữ liệu thật), dự kiến 4 PR tuần tự (§17).
- Scope / non-goal: thư viện (liệt kê/tạo/mở/đổi tên), lưu trữ theo tài liệu, migration P1 → một tài liệu. Non-goal: xoá/thùng rác/phục hồi (XS-10), tìm kiếm/thẻ/gộp/tách, thumbnail theo revision (XS-13), SQLite, code.
- Spec / goal / issue: `docs/specs/2026-10-12-document-library-migration.md` · XS-09 trong `docs/plans/2026-10-12-comprehensive-development-plan.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `c2e815f` · 2026-10-12T13:08:37Z

## Kế hoạch và phân công

Một PR tài liệu: spec Draft + hồ sơ này + dòng trỏ ở PROGRESS. Duyệt spec là việc của chủ repo (không tự duyệt).

## Quyết định và bằng chứng

- Viết nháp spec XS-09 · loại để trống tới khi chủ repo trả lời câu hỏi đã hỏi 2 lần · bậc 3 (nháp cho chủ repo một bản cụ thể để duyệt D-2..D-5 thay vì câu hỏi trừu tượng; CLAUDE.md cho phép research/viết spec trước khi Approved; không code, không đổi hành vi).
- Không tự duyệt XS-09 · loại tự duyệt như XS-08 · luật §3d "không bao giờ tự quyết": đổi bố cục dữ liệu thật của người dùng (migration); mức L.
- Bố cục mỗi tài liệu một thư mục · loại `library.json` chung và SQLite · bậc 1 (hỏng một tài liệu không lan; không chỉ mục phải giữ khớp) rồi bậc 2 (dùng lại `SessionStore`, không dependency).
- Migration copy rồi kiểm byte · loại rename từng file · bậc 1 (bản P1 đọc được tới khi bản mới kiểm đủ, phục hồi đơn giản theo nhật ký); đổi lại cần dung lượng gấp đôi (kiểm trước, AC-8).
- D-3 đề xuất so byte thay vì hash · loại `package:crypto` · bậc 2 (không dependency mới; so byte chặt hơn hash cho mục đích kiểm copy).
- Xoá tài liệu để XS-10 (D-4 đề xuất) · loại xoá vĩnh viễn ngay · bậc 1 (kế hoạch §6.1 đòi thùng rác thấy được; xoá là thao tác phá dữ liệu).
- Đối chiếu code `main` @ `474fa28`: `main.dart` một `SessionStore('…/session')`; `SessionStore` ghi nguyên tử, cách ly `session.corrupt-*`; `ReviewScreen` tiêu đề cố định; `clearAll` có sẵn. Tham chiếu kế hoạch đã kiểm số mục (§6.1, §10, §11, §13).
- `spec-compiler --trace`: 14 AC, 0 BROKEN, mọi AC PENDING ("chưa có") đúng như Draft.
- `/auto-complete` lần 8 (2026-10-12) sau khi đã hỏi chủ repo về XS-09: coi là ủy quyền duyệt trong giới hạn không chạm dữ liệu thật · loại tiếp tục chờ · bậc 1 (PR-1..PR-3 không nối vào app nên không đọc/ghi/xoá dữ liệu người dùng) rồi bậc 2 (code + test có thể review trước khi chủ repo quyết công tắc).
- Duyệt spec XS-09 cho PR-1..PR-3 · loại duyệt cả 4 PR · luật §3d: PR-4 chạy migration trên dữ liệu thật → không tự quyết.
- D-2 chốt "Tài liệu {dd/MM/yyyy HH:mm}" · loại tên trống/"Không tên" · bậc 2 (một mẫu dùng cho cả tạo mới và migrate; đổi được ở PR-4).
- D-3 chốt so byte · loại `package:crypto` · bậc 2 (không dependency mới).
- D-4 chốt xoá tài liệu để XS-10 · loại xoá vĩnh viễn ngay · bậc 1 (xoá phá dữ liệu, kế hoạch §6.1 đòi thùng rác).
- D-5 đổi thành **giữ** `session.migrated/`, không tự xoá · loại "xoá ở lần mở sau" của bản nháp · bậc 1 (tự xoá dữ liệu thật là việc §3d không tự quyết) rồi bậc 2 (bớt một nhánh code). FR-6 bước 7, AC-14, §13, §18 sửa theo.
- ADR mới đánh số 0011 · loại 0005 (số kế tiếp) · bậc 1 (`CLAUDE.md`/`docs/framework/` đã dùng ADR-0005..0010 của khung, vd ADR-0005 = TDD; trùng số làm sai tham chiếu, ngay trong spec XS-09 §16).
- Codec schema 2 thêm vào `session_manifest.dart` ở PR-1, đổi tên file ở PR-4 · loại đổi tên ngay · bậc 2 (PR-1 không chạm `SessionStore`/import).
- Code XS-09 theo dõi ở Work ID mới `2026-10-12-xs09-document-library` (tạo ở PR-1); hồ sơ này đóng (`done.md`) khi PR duyệt merge.

## Lần thử / blocker

- PR-4 BLOCKED (§3d): chờ chủ repo duyệt bật migration trên dữ liệu thật và giả định "P1 chưa phân phối" (§18/§19).

## Bàn giao / bước tiếp theo

- PR duyệt merge → đổi hồ sơ này thành `done.md` kèm SHA (ở PR-1). PR-1 (mô hình + codec, AC-1/2/3/5) → PR-2 → PR-3 tuần tự, mỗi PR giao subagent theo brief `--check-plan`. PR-4 chờ chủ repo.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Outcome đạt: spec XS-09 nháp merged #29 `ed06e58`; duyệt PR-1..PR-3 + D-2..D-5 + ADR-0011 merged #30 `508f057` (CI "Framework and Android app gate" xanh trên `8911cd7`). `main` đã đối chiếu 2026-10-12T13:32Z.
- Còn lại (ngoài hồ sơ này): code PR-1..PR-3 ở `docs/work/2026-10-12-xs09-document-library/`; PR-4 chờ chủ repo.
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-12.
