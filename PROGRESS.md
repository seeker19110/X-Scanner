# PROGRESS.md — X-Scanner

> Giai đoạn hiện tại: P1 + XS-09 thư viện đã merge (#62); hoàn thiện P1 đóng (#63); harness autopilot (#64) và khoá gate F-077 (#65) đã merge; đang làm backlog MUST blueprint · Cập nhật: 2026-10-24 · Nhánh: `claude/serene-ramanujan-h6674j`
> Lịch sử đến 2026-10-24: `docs/changelog/2026-10-progress-history.md` · CHANGELOG: `CHANGELOG.md` · Goal đang chờ: `docs/goals/2026-10-18-upgrade-completion.md` (WAITING)

## Đang làm
- Backlog MUST blueprint ("làm hết các việc còn lại", 24/10): D (#66), B (#67), C (#69) đã merge; lát cuối `docs/work/2026-10-24-backlog-final/working.md` (PR này). Blueprint: 189 đạt · 166 không áp dụng · 47 còn mở, tất cả là việc của chủ repo (`docs/autopilot/GO-NO-GO.md`)

## Tiếp theo
1. Chủ repo chạy APK có thư viện (CI của #62/`main`) trên emulator/thiết bị có tăng tốc: cài đè lên dữ liệu P1 đã giữ từ lần UAT 18/10, kiểm migration → một tài liệu, bản gốc trùng byte, mở lại app (W-602 / F-078).
2. 4 điểm mở còn lại của #57 (F-077 đã đóng ở #65).
3. 47 MUST còn mở là việc của chủ repo, gom theo việc trong `docs/autopilot/GO-NO-GO.md` (LICENSE, bật báo lỗ hổng riêng, ruleset, phát hành, iOS, thiết bị, pháp lý). PR Dependabot #68 (Gradle) cần cập nhật lockfile.
4. Tính năng tiếp theo (XS-10 xoá/thùng rác, khôi phục ảnh bị giữ riêng…) cần chủ repo duyệt spec; roadmap `docs/plans/` vẫn ADVISORY.

## Quyết định
- 2026-10-23 PR-4b.2 contract C1–C6 (spec XS-09) — tinh chỉnh C5 không khoá việc chụp vĩnh viễn, ảnh bị giữ riêng không xoá — lý do: P1 AC-7, không mất byte — hồ sơ `docs/work/2026-10-18-xs09-pr4b-integration/done.md`
- 2026-10-23 Merge #61, #57, #62, #63 sau CI xanh trên head cuối — theo yêu cầu chủ repo "merge các PR đang mở"
- 2026-10-24 D-001/D-002 (autopilot, `docs/autopilot/DECISIONS.md`): không mở tính năng mới khi chưa có yêu cầu; lỗi doctor `..` là báo nhầm của khung
- 2026-10-24 F-077 đóng bằng `flock` trong `scripts/dev-task.sh` (#65), chủ repo duyệt "làm hết các việc còn lại"; chủ repo cấp toàn quyền, không hỏi lại (24/10)
- 2026-10-24 D-007 chấp nhận ngoại lệ OSV có hạn cho công cụ build Gradle (không vào APK); F-080 gate đỏ ngẫu nhiên do SIGPIPE ở test hook, đã sửa; ngân sách APK đo nội dung chưa nén (nén đổi theo build gia tăng)
- 2026-10-24 D-005 ID tính năng `FT-NN` (F-NNN là ID audit); D-006 chuẩn bảo mật OWASP MASVS MAS-L1 (không server) — `docs/autopilot/DECISIONS.md`
- Nợ kỹ thuật chấp nhận: ảnh picker bị từ chối giữ riêng chưa có UI khôi phục (`DEBT:` ở `pending_pick_store.dart`, tới XS-10); khe plugin xoá kết quả trước khi Dart ghi nhật ký (`DEBT:` ở `pick_import.dart`) — hạn trả: trước khi phân phối

## Bàn giao phiên
- Commit cuối trên nhánh chính: `a99493def4e76824641abcf3529e965fb52afd36` (#69) · CI: xanh — 4 check trên head PR trước merge
- Lệnh kiểm nhanh: `bash scripts/dev-task.sh gate` → PASS 4/4, 843 Flutter (coverage 96.33% dòng) + JVM, 2026-10-24 (gói B+C)
- Đang chặn: không (W-602, F-077 là việc chờ người, không chặn vòng)
- Việc dở chưa commit: không
- Câu hỏi cần người: không (đang làm backlog theo "làm hết các việc còn lại", 24/10)
