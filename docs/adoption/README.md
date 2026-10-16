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
XS-05 bổ sung ruleset và dependency review riêng cho X-Scanner; trạng thái native/CI ở bảng dưới và [runbook](../ops/x-scanner-repository-guards.md). Không nhập các workflow mẫu hoặc bật lịch định kỳ.
Repository CI không đại diện chất lượng app hoặc readiness phát hành.

## Nâng cấp

Review commit nguồn mới rồi chạy copy-framework.sh --upgrade, soát manifest/diff/overlay và gate.
Không chạy lại importer một lần trên repo đã có framework.

## Bằng chứng repository settings của X-Scanner

Bảng Evidence trong `docs/ops/repository-settings.md` là của repo khung (file ghim hash), không phải của repo này.

| Setting/control | Giá trị | Owner | Kiểm ngày | Bằng chứng | Xem lại |
| --- | --- | --- | --- | --- | --- |
| Ruleset/branch protection `main` | active, main protected=true, bypass=[]/owner cannot bypass, 5 rules khớp JSON | chủ repo / phiên chính theo ủy quyền | 2026-10-16 | [ruleset 25250032](https://github.com/seeker19110/X-Scanner/rules/25250032), [readback](../ops/evidence/2026-10-16-xs05-native.json) | khi đổi rule/check; [PR #53](https://github.com/seeker19110/X-Scanner/pull/53) giữ kết quả final-head |
| Required status check | `Framework and Android app gate`, GitHub Actions integration15368, strict=true; cùng job gồm dependency review trên PR | chủ repo / phiên chính | 2026-10-16 | ruleset readback và check-runs PR #52 khớp app 15368; run 38925328599 check app 15368 cancelled và PR BLOCKED; CI head cuối xem PR #53 | khi đổi ci.yml/check/app |
| Auto-merge, pr-policy, progress-freshness, protection-guard | chưa bật | chủ repo | 2026-10-12 | `.github/workflows/` chỉ có `ci.yml`, `adopt-projects-template.yml` | khi chủ repo duyệt |
| Dependency alerts/graph và review | alerts GET 204; graph 86/86 Pub khớp lockfile; review step SUCCESS head51af8e0, workflow đã merge main3f49039 | chủ repo / phiên chính | 2026-10-16 | [readback](../ops/evidence/2026-10-16-xs05-native.json), EX-2 đóng sau merge53; final CI38930758793 và compare f753933...51af8e0 HTTP200/no-warning | khi đổi workflow; snapshot warning hoặc trước release |
| Native secret controls / quyền workflow | secret scanning + push protection enabled; default GITHUB_TOKEN read, không approve PR | chủ repo | 2026-10-16 | GET repository security_and_analysis và actions/permissions/workflow, [readback](../ops/evidence/2026-10-16-xs05-native.json) | khi đổi quyền/settings |
