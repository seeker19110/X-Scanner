# PROGRESS.md — X-Scanner

> Giai đoạn hiện tại: P1 + XS-09 thư viện đã merge (app mở vào thư viện, #62); kế hoạch hoàn thiện P1 đóng (#63); autopilot dọn harness/blueprint · Cập nhật: 2026-10-24 · Nhánh: `claude/serene-ramanujan-h6674j`
> Lịch sử đến 2026-10-24: `docs/changelog/2026-10-progress-history.md` · CHANGELOG: `CHANGELOG.md` · Goal đang chờ: `docs/goals/2026-10-18-upgrade-completion.md` (WAITING)

## Đang làm
- `T-001`..`T-004` của `docs/autopilot/PLAN.md` (autopilot 24/10, D-001): PROGRESS đúng luật, `xt.yaml` khớp cổng thật, phân loại `BLUEPRINT.md` có bằng chứng, phản hồi khung — trạng thái: đang làm

## Tiếp theo
1. Chủ repo chạy APK có thư viện (CI của #62/`main`) trên emulator/thiết bị có tăng tốc: cài đè lên dữ liệu P1 đã giữ từ lần UAT 18/10, kiểm migration → một tài liệu, bản gốc trùng byte, mở lại app (W-602 / F-078).
2. Chủ repo quyết F-077: tắt gate trong `pre-bash-guard` (giữ hook commit cũ) để hai gate không chạy song song mỗi commit; cùng 4 điểm mở khác của #57.
3. Tính năng tiếp theo (XS-10 xoá/thùng rác, khôi phục ảnh bị giữ riêng…) cần chủ repo duyệt spec; roadmap `docs/plans/` vẫn ADVISORY.

## Quyết định
- 2026-10-23 PR-4b.2 contract C1–C6 (spec XS-09) — tinh chỉnh C5 không khoá việc chụp vĩnh viễn, ảnh bị giữ riêng không xoá — lý do: P1 AC-7, không mất byte — hồ sơ `docs/work/2026-10-18-xs09-pr4b-integration/done.md`
- 2026-10-23 Merge #61, #57, #62, #63 sau CI xanh trên head cuối — theo yêu cầu chủ repo "merge các PR đang mở"
- 2026-10-24 D-001/D-002 (autopilot, `docs/autopilot/DECISIONS.md`): không mở tính năng mới khi chưa có yêu cầu; lỗi doctor `..` là báo nhầm của khung
- 2026-10-24 Đổi cách cho F-077 (lần 2 cùng lỗi build ở hook commit): chạy `scripts/dev-task.sh gate` một lần trước `git commit` để build ấm; không sửa hook (điểm dừng cấu hình cổng)
- Nợ kỹ thuật chấp nhận: ảnh picker bị từ chối giữ riêng chưa có UI khôi phục (`DEBT:` ở `pending_pick_store.dart`, tới XS-10); khe plugin xoá kết quả trước khi Dart ghi nhật ký (`DEBT:` ở `pick_import.dart`) — hạn trả: trước khi phân phối

## Bàn giao phiên
- Commit cuối trên nhánh chính: `3edef8b23d115fa1a437b6bc433dde932ddebc8b` (#63) · CI: xanh — run 40042667524 (head PR) trước merge
- Lệnh kiểm nhanh: `bash scripts/dev-task.sh gate` → PASS 4/4, 805 Flutter + JVM, lúc 2026-10-24 00:xx UTC (hook commit #63)
- Đang chặn: không (W-602, F-077 là việc chờ người, không chặn vòng)
- Việc dở chưa commit: theo `docs/autopilot/PLAN.md`
- Câu hỏi cần người: cho phép tắt gate trong `pre-bash-guard` (F-077)? — chủ repo
