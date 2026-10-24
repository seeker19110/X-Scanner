# Công việc: backlog-final

- Work ID: 2026-10-24-backlog-final
- Yêu cầu / outcome: chủ repo 24/10 "làm hết các việc còn lại" + toàn quyền; sau gói B/C/D còn 50 MUST mở. Lát cuối: các mục phiên tự làm được; còn lại ghi rõ việc của chủ repo.
- Trạng thái: Ready — chờ PR/CI.
- Chủ trì / writer: phiên chính.
- Mức rủi ro / số PR: S (script kiểm + quy tắc PR, không đổi app); một PR.
- Scope / non-goal: PRF-MOB-002 (căn chỉnh 16 KB `.so` 64-bit), BASE-DEP-006 (PR đổi manifest phụ thuộc phải có mục Dependencies), BASE-DOC-008 (`xt.py progress-check` trong gate). Không: LICENSE, ruleset/review bắt buộc, phát hành/ký, iOS, thiết bị, pháp lý (chủ repo).
- Nhánh / base SHA: `claude/serene-ramanujan-h6674j` từ `main` `a99493d` (#69).

## Quyết định và bằng chứng

- RED trước: `test-repo-checks.py` 3 failures (manifest không có mục Dependencies vẫn PASS; `check-16kb-pages.py` chưa tồn tại); GREEN 34/34. APK debug thật: 5 thư viện 64-bit, LOAD ≥ 16 KB → PASS.
- Căn chỉnh zip 16 KB của gói release không kiểm (gate chỉ build debug); ghi trong docstring script.
- Mẫu PR không chứa sẵn tiêu đề `## Dependencies` (nếu có thì quy tắc luôn đạt): chỉ có chú thích hướng dẫn.

## Bàn giao / bước tiếp theo

Mở PR, CI xanh thì squash. Sau đó xử lý PR Dependabot #68 theo `docs/ops/dependency-updates.md` (cần cập nhật lockfile Gradle).
