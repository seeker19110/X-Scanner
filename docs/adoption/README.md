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

## X-Templates — cập nhật 2026-11-02

Bản stable mới nhất xác minh qua remote tags: **3.29.0**, tag `v3.29.0`, commit
`3a3c1010e59690fa474f594a34b25ecc0756dd40` (2026-10-30).
Cài bằng `scripts/install.py` chính thức từ clone sạch, không lấy thay đổi Unreleased trên main.
Bản thư viện/CLI nằm ở `.xtemplates/`; harness `.claude/` được cập nhật và gộp `_lib.sh` giữ helpers projects-template.
Giấy phép nguồn: `third_party/X-Templates.LICENSE`; không chọn giấy phép sản phẩm.

Quy định X-Scanner trong CLAUDE/AGENTS tiếp tục chi phối: quyền riêng `harness_permissions: own`,
`merge_autonomy: L1`, guard `XT_GUARD_POLICY=strict`. Không cài CI/ruleset mẫu, không bật scheduler/cloud/auto-merge.
Cổng thật vẫn là `bash scripts/dev-task.sh gate` với khóa flock.
Giữ formatter và reviewer riêng khi giải các bản `.xtemplates-new`; không giữ file đề xuất dư.

Kiểm thư viện: `xt.py validate` và `xt.py doctor` — không thay thế gate app.
Doctor 3.29.0 còn cảnh báo các khóa `format_check`, `coverage`, `e2e`:
format/coverage đã nằm trong cổng X-Scanner, chưa khai riêng theo giao thức khung mới;
E2E APK thư viện W-602/F-078 chưa nghiệm thu. Không dùng cảnh báo này làm lý do hạ cổng hay tick completion.
Bằng chứng và giới hạn hiện tại: `docs/work/2026-11-02-xtemplates-completion/working.md`.

Overlay tài liệu duy nhất: 9 liên kết `../docs/…` trong
`.xtemplates/research/2026-10-26-autopilot-complete-optimize.md` trỏ tới tài liệu không được installer đóng gói;
đổi thành URL GitHub ghim commit nguồn ở trên, giữ nội dung nghiên cứu. Khi nâng bản, kiểm lại overlay bằng
`python3 scripts/check-links.py` với cả file mới trong index. Thư viện framework và mã CLI giữ đúng byte nguồn.

Overlay hook: `.claude/hooks/pre-bash-guard.sh` ưu tiên `scripts/dev-task.sh` của X-Scanner trước dispatcher vendored,
để cả hai hook đi qua khóa flock F-077. Test tích hợp ở `scripts/test-repo-checks.py` (`GateRoutingTests`)
đã tái hiện đỏ trước khi sửa (F-081); không đổi lệnh/ngưỡng gate. Giữ overlay này khi cập nhật installer.


F-082 — cấu hình hook sau installer: giữ đường dẫn hook theo `${CLAUDE_PROJECT_DIR}` để chạy được từ thư mục con; formatter chỉ đăng ký một lần cho Edit/Write/MultiEdit. Test thực chạy command lấy từ settings ở apps/mobile (RED exit 127), test đếm formatter (RED 2 thay vì 1) trước sửa cấu hình. Đây là overlay settings cần giữ khi nâng tiếp, quyền permissions không đổi.
