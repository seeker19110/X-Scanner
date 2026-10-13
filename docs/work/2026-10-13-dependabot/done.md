# Công việc: Thêm Dependabot cho pub và github-actions

- Work ID: 2026-10-13-dependabot
- Yêu cầu / outcome: chủ repo 2026-10-13: "có, duyệt thêm Dependabot" (đề xuất 2 của `docs/research/2026-10-13-goi-y-nang-cap.md`, F-009): `.github/dependabot.yml` cho `pub` và `github-actions`, cooldown 7 ngày.
- Trạng thái: Done — #47 `81cae78`
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S, 1 PR (một file cấu hình + tài liệu; không đổi code app)
- Scope / non-goal: version updates cho `apps/mobile` (pub) và `.github/workflows` (actions). Non-goal: bật Dependency graph/alerts và security updates (repository settings, chủ repo — EX-2 còn mở); `dependency-review.yml`; auto-merge PR bot.
- Spec / goal / issue: `docs/research/2026-10-13-goi-y-nang-cap.md` mục 2 · F-009 (`docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`) · EX-2 (`docs/ops/supply-chain-exceptions.md`)
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `e482cd0` · 2026-10-13T04:22:23Z

## Kế hoạch và phân công

- Một PR: `.github/dependabot.yml` (mới), EX-2, F-009, đề xuất 2 của research #45, CHANGELOG.

## Quyết định và bằng chứng

- Viết file riêng cho repo · loại chép `deferred-dropins/.github/dependabot.yml.example` (theo dõi npm/pip, không có ở repo này; `multi-ecosystem-groups` mới hơn) · bậc 1 + 2.
- `cooldown.default-days: 7` cho cả hai hệ sinh thái · cùng luật 7 ngày của EX-1 · bậc 1. Cú pháp và hỗ trợ (`pub` và `github-actions` đều nhận `default-days`; giá trị `pub`) đối chiếu docs.github.com "Dependabot options reference" 2026-10-13.
- Bỏ qua bản major (`version-update:semver-major`) · major đi qua `/deps-upgrade` · bậc 1 (đọc changelog, sửa điểm chạm).
- Một nhóm mỗi hệ sinh thái (`patterns: ["*"]`) · loại mỗi gói một PR · bậc 2 (tối đa 2 PR bot/tuần, giữ trần WIP 5).
- PR bot `image` 4.12.0 có thể tới trước W-104b (18/10) · W-104b vẫn là nơi thêm test hồi quy 2 ảnh tổng hợp và đóng EX-1; PR bot không merge thay W-104b · bậc 1.
- Ngoại lệ test-trước số 3 (config thuần, không nhánh logic). YAML parse bằng `python3 yaml.safe_load`.
- #47 merged squash `81cae78` sau CI xanh: "Framework and Android app gate" success và check ".github/dependabot.yml" của Dependabot success (cấu hình hợp lệ); 0 review thread.

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- Xong. PR bot đầu tiên theo lịch tuần; mỗi PR bot qua CI và chủ repo/phiên merge như PR thường. Chủ repo còn bật Dependency graph/alerts (EX-2).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- DoD: chủ repo duyệt (2026-10-13); `.github/dependabot.yml` trên `main` @ `81cae78`; Dependabot tự kiểm cấu hình hợp lệ trên PR; gate và CI xanh.
- Giới hạn còn lại: chưa có cảnh báo lỗ hổng/PR vá bảo mật (cần chủ repo bật alerts, EX-2); PR bot `image` có thể tới trước W-104b.
- Nghiệm thu: phiên chính theo duyệt của chủ repo, 2026-10-13.
