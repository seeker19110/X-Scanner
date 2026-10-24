# Công việc: gate-lock (F-077)

- Work ID: 2026-10-24-gate-lock
- Yêu cầu / outcome: chủ repo 24/10 "merge 64 đi, rồi làm hết các việc còn lại"; việc đầu: F-077 — hai hook commit chạy gate song song làm build đỏ ngẫu nhiên.
- Trạng thái: Implemented — chờ PR/CI.
- Chủ trì / writer: phiên chính.
- Mức rủi ro / số PR: S; một PR (script cổng + test).
- Scope / non-goal: `scripts/dev-task.sh` (khoá), test mới, nối test + `check-xt-yaml-sync.sh` vào bước test của gate. Không sửa hook vendored của khung.
- Nhánh / base SHA: `claude/serene-ramanujan-h6674j` từ `main` `22707f3`.

## Quyết định và bằng chứng

- Khoá `flock` trong `dev-task.sh gate` · loại sửa `pre-bash-guard.sh` (file khung có hash trong `.xtemplates/harness.sha256.json`, doctor sẽ báo lệch) và loại bỏ hook cũ (mất chặn bí mật/nhánh chính) · bậc 1+2.
- `scripts/test-dev-task-gate-lock.sh`: lần đầu lỗi fixture (thiếu lệnh/no-op) — không tính RED; sau đó RED thật `start start end end`; sau sửa `start end start end`.
- Nối test khoá và `check-xt-yaml-sync.sh` vào bước `test` của gate (đổi cổng: được chủ repo cho "làm hết"); đóng XC-DOCAI-003.
