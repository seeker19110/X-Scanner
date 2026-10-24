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

## Checkpoint 2026-10-24 — PR Dependabot #68 (Gradle)

- #70 đã merge (`ff3c97d`). CI đỏ duy nhất: #68 (AGP 9.1.0→9.4.1, KGP 2.4.0→2.4.21, Gradle 9.3.1→9.8.1) — build đỏ vì lockfile Gradle còn ghim bản cũ (`Dependency version enforced by Dependency Locking`).
- Nhánh `claude/stoic-albattani-yv4krl` từ `main` `ff3c97d`: áp thay đổi của #68 + sinh lại `gradle.lockfile`/`settings-gradle.lockfile` theo `docs/ops/dependency-updates.md`. Runtime APK chỉ đổi `kotlin-stdlib` 2.4.0→2.4.21; còn lại là công cụ build (cấu hình mới `androidLintTool` của AGP 9.4).
- OSV 2.7.0 trên lock mới: BouncyCastle 1.80.2 (classpath AGP + `androidLintTool`, 4 advisory) → thêm vào EXC-OSV-2 (hạn 2026-11-23, như jose4j/jdom2, chủ repo xác nhận); bỏ GHSA-r937-wjx7-w2jp (đã sửa ở Kotlin 2.4.21). OSV: No issues found.
- Môi trường: Maven Central giới hạn IP của container (429/404) → init script Gradle cục bộ (`~/.gradle/init.d`, ngoài repo) đi qua mirror Google; lockfile chỉ ghi toạ độ.
- Chưa merge #68: chưa kiểm bước 1 (tuổi ≥ 7 ngày) và bước 3 (changelog) của `dependency-updates.md`; CI cần chạy trên PR.
