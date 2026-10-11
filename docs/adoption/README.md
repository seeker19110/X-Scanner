# Áp dụng projects-template

Nguồn: https://github.com/seeker19110/projects-template
Commit: `aab9f887ec4acc4480da852cc300978979087f6b`. Ngày: 2026-10-11. Dùng copy-framework.sh chính thức.

## Áp dụng

Docs framework/ops, spec/ADR, hooks/agents/commands, cầu nối agent, engine/scripts chất lượng,
FRAMEWORK-VERSION, Git conventions, PR/issue templates, CODEOWNERS và brief/tiến độ riêng.
License nguồn giữ nguyên ở third_party/projects-template.LICENSE, không chọn license sản phẩm.

## Điều chỉnh

Giữ research ADVISORY; không app scaffold, .nvmrc ép Node, model/context 500k mặc định; giữ Context7 của khung chỉ để tra tài liệu phát triển.
Giữ hooks an toàn; developer cần jq và hooksPath cục bộ. Gate chỉ cho adoption;
build/typecheck N/A có lý do, phải thay trước khi code app.

## Hoãn, không coi là hoàn tất

`deferred-dropins/` giữ .example của CI target, release, maintenance, auto-merge,
CodeQL, Scorecard, secret/dependency scan, Dependabot và ruleset để review theo stack/quyền thực.
Chưa nhập ruleset, xác minh branch protection, chạy security gates theo stack hoặc bật lịch định kỳ.
Repository CI không đại diện chất lượng app hoặc readiness phát hành.

## Nâng cấp

Review commit nguồn mới rồi chạy copy-framework.sh --upgrade, soát manifest/diff/overlay và gate.
Không chạy lại importer một lần trên repo đã có framework.
