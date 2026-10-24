# Công việc: autopilot-harness

- Work ID: 2026-10-24-autopilot-harness
- Yêu cầu / outcome: chủ repo gõ `/autopilot` (skill X-Templates từ #57) không đối số, sau khi #62/#63 merge. Outcome: harness của vòng autopilot đúng luật và blueprint được phân loại có bằng chứng; không mở tính năng mới (D-001).
- Trạng thái: In progress — `docs/autopilot/PLAN.md` T-001, T-002, T-004 xanh; T-003 đang phân loại.
- Chủ trì / writer: phiên chính; 4 subagent chỉ đọc phân loại blueprint (trả JSON, phiên chính áp và kiểm).
- Mức rủi ro / số PR: S; một PR (tài liệu/harness, không đổi app).
- Scope / non-goal: PROGRESS, `xt.yaml`, BLUEPRINT, phản hồi khung. Không sửa hook/settings (F-077 chờ chủ repo), không chạy thiết bị (W-602).
- Spec / goal / issue: `docs/autopilot/PLAN.md`, `docs/autopilot/DECISIONS.md`; goal `docs/goals/2026-10-18-upgrade-completion.md`.
- Nhánh / base SHA / thời điểm reconcile: `claude/serene-ramanujan-h6674j` @ `547642a` (base `main` `3edef8b`) · 2026-10-24T02:00:46Z

## Kế hoạch và phân công

Một PR. T-001 PROGRESS 4 mục ≤ 8 KB; T-002 `xt.yaml` khớp `.claude/project-commands.sh` + `scripts/check-xt-yaml-sync.sh`; T-003 phân loại 402 MUST (4 agent chỉ đọc, mỗi agent ~100 mục, trả `met/na/open` + bằng chứng); T-004 `feedback add` FB-001..003.

## Quyết định và bằng chứng

- `doctor --fix` thêm `@AGENTS.md` vào `CLAUDE.md` — bước 0 của skill chủ repo gọi.
- D-001 không mở tính năng mới; D-002 lỗi doctor `..` là báo nhầm (mọi đường dẫn `../..` trong `.claude/hooks/*.sh` tồn tại).
- T-001: `xt.py loop record --task T-001 -- python3 .xtemplates/scripts/xt.py progress-check PROGRESS.md` exit 0; lịch sử chép nguyên văn sang `docs/changelog/2026-10-progress-history.md`.
- T-002: `scripts/check-xt-yaml-sync.sh` chạy đỏ trước (`LỆCH [test]`, thiếu JVM), sửa `xt.yaml`, `loop record` exit 0. Không nối script vào gate/CI (đổi cổng là điểm dừng).
- T-004: FB-001 doctor `..`, FB-002 hai gate song song (F-077), FB-003 guard thiếu `flutter pub add`; `feedback collect` exit 0.
- Commit `547642a` qua hook commit: PASS 4/4, 805 Flutter + JVM, sau một lần build đỏ vì F-077 (lần 2 cùng lỗi → đổi cách: chạy gate ấm trước commit, ghi PROGRESS).

## Lần thử / blocker

F-077 (hai gate song song ở hook commit) đỏ 2 lần trong phiên 23–24/10, đều PASS khi chạy lại sau build ấm. Không sửa hook: chờ chủ repo.

## Bàn giao / bước tiếp theo

Áp kết quả phân loại `out1..4.json` vào `BLUEPRINT.md`, `loop defer` các MUST còn mở, chạy Gate T-003, `loop verify`, PR.
