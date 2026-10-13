# Công việc: Thêm Dependabot cho pub và github-actions

- Work ID: 2026-10-13-dependabot
- Yêu cầu / outcome: chủ repo 2026-10-13: "có, duyệt thêm Dependabot" (đề xuất 2 của `docs/research/2026-10-13-goi-y-nang-cap.md`, F-009): `.github/dependabot.yml` cho `pub` và `github-actions`, cooldown 7 ngày.
- Trạng thái: Active — PR mở
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

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- CI xanh → merge → kiểm tab Insights › Dependency graph › Dependabot không báo lỗi cấu hình → đóng hồ sơ.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
