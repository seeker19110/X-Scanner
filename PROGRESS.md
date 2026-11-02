# PROGRESS.md — X-Scanner

> Giai đoạn hiện tại: P1 + XS-09 thư viện đã merge (#62); hoàn thiện P1 đóng (#63); harness autopilot (#64) và khoá gate F-077 (#65) đã merge; đang làm backlog MUST blueprint · Cập nhật: 2026-11-03 · Nhánh: `codex/xtemplates-completion`
> Lịch sử đến 2026-10-24: `docs/changelog/2026-10-progress-history.md` · CHANGELOG: `CHANGELOG.md` · Goal đang chờ: `docs/goals/2026-10-18-upgrade-completion.md` (WAITING)

## Đang làm
- XS-09 Android UAT: `docs/work/2026-11-03-xs09-android-uat/working.md`; WHPX usable nhưng 2 lần boot thiếu chỗ (cần 7.37 GB), chưa chạy migration; cần ≥8 GB trống trên ổ Windows hoặc Android test.
- Goal hai slice khung + security CI: `docs/goals/2026-11-03-autopilot-hardening.md`; Guava [PR #74](https://github.com/seeker19110/X-Scanner/pull/74) đã squash merge tại `5a8ecada2ecb6b0b86807fb2b5f2d09ee9e1d8de`; gate/OSV/CI xanh, runtime app không đổi. Hồ sơ: `docs/work/2026-11-03-guava-security/working.md`.
- Cập nhật X-Templates 3.29.0 và kiểm chứng completion: `docs/work/2026-11-02-xtemplates-completion/working.md`; toolchain đã khôi phục; gate PASS 4/4 (843 Flutter + 11 JVM), PR #73 đang đồng bộ với main sau #74 theo lệnh merge và chuyển /complete của chủ repo; verify-all đỏ do 3 khóa sàn khung còn thiếu; theo kế hoạch `docs/autopilot/PLAN-2026-11-02-toolchain.md`.
- Backlog MUST blueprint ("làm hết các việc còn lại", 24/10): D (#66), B (#67), C (#69) đã merge; lát cuối `docs/work/2026-10-24-backlog-final/working.md` (PR này). Blueprint: 189 đạt · 166 không áp dụng · 47 còn mở, tất cả là việc của chủ repo (`docs/autopilot/GO-NO-GO.md`)

## Tiếp theo
1. Sau khi có ≥8 GB trống trên ổ emulator Windows hoặc Android test, chạy APK có thư viện trên dữ liệu P1 tổng hợp đã giữ: cài đè lên dữ liệu P1 đã giữ từ lần UAT 18/10, kiểm migration → một tài liệu, bản gốc trùng byte, mở lại app (W-602 / F-078).
2. 4 điểm mở còn lại của #57 (F-077 đã đóng ở #65).
3. 47 MUST còn mở là việc của chủ repo, gom theo việc trong `docs/autopilot/GO-NO-GO.md` (LICENSE, bật báo lỗ hổng riêng, ruleset, phát hành, iOS, thiết bị, pháp lý). Lockfile Gradle đã cập nhật ở #71; PR Dependabot #72 đang mở, chưa đánh giá trong slice này.
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
- Default branch đã fetch: `5a8ecada2ecb6b0b86807fb2b5f2d09ee9e1d8de` (#74), đang tích hợp vào #73
- Lệnh kiểm nhanh: `bash scripts/dev-task.sh gate` → PASS 4/4, 843 Flutter (coverage 96.33% dòng) + JVM, 2026-10-24 (gói B+C)
- Chủ repo đã duyệt merge #74/#73 và chuyển /complete trong phiên 03/11; UAT W-602/F-078 vẫn thiếu chỗ Windows/thiết bị. Không bật auto-merge.
- Hồ sơ đang mở: khung #73, Guava security và XS-09 UAT (xem mục Đang làm).
- Cần operator: dung lượng/thiết bị UAT, quyết định pháp lý/release còn mở; không coi là Project Complete.
