# Công việc: Cài khung X-Templates 2.0.0 (guard PreToolUse)

- Work ID: 2026-10-17-install-xtemplates
- Yêu cầu / outcome: chủ repo yêu cầu cài khung X-Templates vào repo (2026-10-17) — hook PreToolUse (guard egress/phụ thuộc/container), skill, `xt.yaml`; không đổi mã app.
- Trạng thái: In review (PR)
- Chủ trì / writer: phiên chính (cài bằng executor, phiên chính review + mở PR)
- Mức rủi ro / số PR: S (chore harness, 1 PR); chạm `.claude/` nên người merge (`merge_autonomy: L1`).
- Scope / non-goal: `.xtemplates/`, `.claude/` (hook/skill/agent mới, `_lib.sh` hợp, `settings.json`), `xt.yaml`, `.gitignore`, sửa regex mục 14 `scripts/test-hooks-gate.sh`. Non-goal: AGENTS/CLAUDE/PROGRESS, bỏ hook cũ, đổi CI.
- Spec / goal / issue: không cần spec (mức S).
- Nhánh / base SHA / thời điểm reconcile: `claude/install-xtemplates` @ `37ad268` · 2026-10-17T02:34:09Z

## Kế hoạch và phân công

<Một outcome/PR; owner/cấp năng lực, input/output, file được ghi, dependency,
test/AC và nhánh/worktree. Từ 2 PR giao subagent; tối đa 5 subagent chạy toàn cây.
Song song nếu độc lập, tuần tự nếu phụ thuộc hoặc ghi chung.>

## Quyết định và bằng chứng

- lint/typecheck/test chạy cục bộ với Flutter 3.47.7 (bản CI ghim): `dart format` 0 thay đổi, `flutter analyze` sạch, 587 test Flutter + check-adoption + check-release-manifest self-test + test-hooks-gate(+guard) xanh.
- Build APK chưa chạy cục bộ (container không có Android SDK) → chờ CI.
- `bash scripts/dev-task.sh doctor` exit 0.
- Guard thử trực tiếp: `git push --force` deny, `ssh` máy khác / `pnpm add` / `pip install` / `curl -d` / `docker run --privileged` / `npm publish` ask, `ls` qua.

## Lần thử / blocker

- `test-hooks-gate.sh` mục 14 đỏ oan với hook dạng `bash \"…\"` (dính `\`): sửa regex `[^"\\ ]+`, thêm ca âm tính; đỏ trước, xanh sau.

## Bàn giao / bước tiếp theo

Chờ CI + chủ repo quyết các mục "Cần người quyết" trong PR, rồi merge.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
