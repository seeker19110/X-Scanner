# Áp dụng projects-template

Nguồn: https://github.com/seeker19110/projects-template
Commit: `aab9f887ec4acc4480da852cc300978979087f6b`. Ngày: 2026-10-11. Dùng copy-framework.sh chính thức.

## Áp dụng

Docs framework/ops, spec/ADR, hooks/agents/commands, cầu nối agent, engine/scripts chất lượng,
FRAMEWORK-VERSION, Git conventions, PR/issue templates, CODEOWNERS và brief/tiến độ riêng.
License nguồn giữ nguyên ở third_party/projects-template.LICENSE, không chọn license sản phẩm.

## Điều chỉnh

Giữ research ADVISORY; không app scaffold, .nvmrc ép Node, model/context 500k mặc định; giữ Context7 của khung chỉ để tra tài liệu phát triển.
Giữ hooks an toàn; developer cần jq và hooksPath cục bộ. Từ P0 (#2) gate là cổng thật của app:
build APK debug, `flutter analyze --fatal-infos`, `dart format`, `flutter test` (`.claude/project-commands.sh`).

## Hoãn, không coi là hoàn tất

`deferred-dropins/` giữ .example của CI target, release, maintenance, auto-merge,
CodeQL, Scorecard, secret/dependency scan, Dependabot và ruleset để review theo stack/quyền thực.
Chưa nhập ruleset, xác minh branch protection, chạy security gates theo stack hoặc bật lịch định kỳ.
Repository CI không đại diện chất lượng app hoặc readiness phát hành.

## Nâng cấp

Review commit nguồn mới rồi chạy copy-framework.sh --upgrade, soát manifest/diff/overlay và gate.
Không chạy lại importer một lần trên repo đã có framework.

## Bằng chứng repository settings của X-Scanner

Bảng Evidence trong `docs/ops/repository-settings.md` là của repo khung (file ghim hash), không phải của repo này.

| Setting/control | Giá trị | Owner | Kiểm ngày | Bằng chứng | Xem lại |
| --- | --- | --- | --- | --- | --- |
| Ruleset/branch protection `main` | chưa nhập, chưa xác minh | chủ repo | 2026-10-12 | không có `.github/rulesets/`; chỉ có `.example` trong `deferred-dropins/` | khi chủ repo bật; required check phải đúng tên job `Framework and Android app gate` |
| Required status check | job `framework-gate` ("Framework and Android app gate") trong `ci.yml` | chủ repo | 2026-10-12 | chạy trên PR #6–#10, xanh trước mỗi lần merge | khi đổi `ci.yml` |
| Auto-merge, pr-policy, progress-freshness, protection-guard | chưa bật | chủ repo | 2026-10-12 | `.github/workflows/` chỉ có `ci.yml`, `adopt-projects-template.yml` | khi chủ repo duyệt |
| Dependency review / cảnh báo lỗ hổng | chưa bật | chủ repo | 2026-10-12 | exception EX-2 ở `docs/ops/supply-chain-exceptions.md` | trước release |
