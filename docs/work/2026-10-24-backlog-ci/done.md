# Công việc: backlog-ci

- Work ID: 2026-10-24-backlog-ci
- Yêu cầu / outcome: chủ repo 24/10 "merge 64 đi, rồi làm hết các việc còn lại" + cấp toàn quyền; gói B = các MUST blueprint về CI, chuỗi cung ứng, kiểm repo.
- Trạng thái: Done — merge #67 (squash `d04bb80`) 2026-10-24; CI 4 check xanh trên head `afa3201` (gate, OSV, PR hygiene; EOL bỏ qua trên PR theo thiết kế).
- Chủ trì / writer: subagent gói B (worktree `/home/user/xs-b`, nhánh cục bộ `local/backlog-b`); phiên chính review, tích hợp, sửa F-080, chạy cổng.
- Mức rủi ro / số PR: S/M (CI + script kiểm, không đổi hành vi app); một PR.
- Scope / non-goal: gitleaks toàn lịch sử, OSV/EOL hằng tuần + ngoại lệ có hạn, khoá Gradle + JDK, license allow-list + SBOM, link nội bộ, coverage ratchet, test-có-assert, kiến trúc import, ADR bất biến, PR hygiene, nguồn phiên bản Flutter duy nhất, ngân sách APK. Không đổi ruleset (cần admin).
- Spec / goal / issue: BLUEPRINT.md (dòng `— Bằng chứng:` của 39 ID); `docs/autopilot/GO-NO-GO.md`.
- Nhánh / base SHA: `claude/serene-ramanujan-h6674j` từ `main` `9c813bd` (#66).

## Quyết định và bằng chứng

- Mọi script kiểm mới có fixture đỏ + xanh trong `scripts/test-repo-checks.py` (30 ca; đỏ trước khi có script: 30 failures). Khoá Gradle: thêm hamcrest → build đỏ "not part of the dependency lock state".
- gitleaks 8.30.1 và OSV-Scanner 2.7.0 ghim sha256 (kiểm 24/10); mọi `uses:` có chú thích phiên bản.
- D-007 (phiên chính, theo toàn quyền 24/10): chấp nhận EXC-OSV-1 (hết hạn 2027-01-22) và EXC-OSV-2 (2026-11-23) trong `osv-scanner.toml`: mọi phát hiện nằm ở cấu hình test-platform nội bộ của AGP / classpath plugin Gradle, không vào APK; hết hạn thì OSV đỏ lại → nâng AGP/KGP.
- F-080 (phiên chính): gate đỏ ngẫu nhiên ở `test-hooks-gate.sh` mục 9 (exit 141) — gặp 2 lần 24/10 (commit #66 và gói B). Nguyên nhân: pipe + `pipefail` vào hook thoát trước khi đọc stdin. Tái hiện chắc chắn bằng writer trễ → 141; sửa bằng here-string; TRAPS.md.

## Lần thử / blocker

- Chưa chứng minh trên CI thật trước PR: setup-java phân giải đúng `21.0.12+1.1`, license check với cache Gradle sạch, gitleaks trên merge ref → PR CI là bằng chứng.

## Bàn giao / bước tiếp theo

Mở PR, CI xanh thì squash; sau đó tích hợp gói C (`local/backlog-c`).
