# Công việc: X-Templates mới nhất và kiểm chứng hoàn thiện

- Work ID: 2026-11-02-xtemplates-completion
- Yêu cầu / outcome: “cài x-templates và hoàn thiện dự án”; bổ sung “cập nhật lên bản mới nhất” ngày 2026-11-02.
- Trạng thái: In progress; chưa nghiệm thu Project Complete.
- Chủ trì / writer: phiên chính.
- Mức rủi ro / số PR: S, một PR cập nhật khung và đối chiếu completion; không mở tính năng sản phẩm mới.
- Scope / non-goal: cập nhật bản vendored + harness tương thích, giữ quyền và cổng X-Scanner. Không release, cloud, scheduler, auto-merge, OCR/depth, không thay đổi dữ liệu scan.
- Spec / goal: `docs/goals/2026-10-18-upgrade-completion.md`; `docs/ops/COMPLETION-PLAN.md`; hồ sơ trước `docs/work/2026-10-17-install-xtemplates/done.md`.
- Nhánh / base SHA: `codex/xtemplates-completion` từ `a1959b4`.

## Kế hoạch và phân công

Một outcome/PR, phiên chính tự làm tuần tự: xác minh tag → đối chiếu ba cột và installer plan → cập nhật → kiểm khung/repo + gate → checkpoint phần còn chờ.
Approved for implementation — phiên chính duyệt kế hoạch theo ủy quyền §3d ngày 2026-11-02, trong phạm vi yêu cầu cập nhật X-Templates. Không suy quyền merge/phát hành.

## Đối chiếu nguồn ngoài

| Đã có và sâu hơn | Đã có nhưng nông hơn | Chưa có |
|---|---|---|
| Gate Flutter/Android thực, khóa gate `flock` F-077, byte-preserving storage và luật X-Scanner: giữ nguyên; không lấy gate mặc định/template tự merge | X-Templates 2.0.0: nâng thư viện/CLI/harness lên stable 3.29.0, gồm sửa parser/guard từ upstream; gộp `_lib.sh` giữ phần projects-template hiện có | Không thêm dịch vụ hay quy trình mới. Stage lock, scheduler, CI mẫu, auto-merge, app server: chưa cần; xem lại khi có nhu cầu và duyệt riêng |

Đã đọc cổng thật: `scripts/dev-task.sh`, `scripts/check-adoption.py`, `scripts/check-repo-tree.sh`, `scripts/test-hooks-gate.sh`, `xt.yaml` và hash harness. Cài mới không chữa F-078 (thiếu UAT), không lấy luật nguồn ghi đè luật dự án.

## Quyết định và bằng chứng

- Chọn stable `v3.29.0` (2026-10-30), commit `3a3c1010e59690fa474f594a34b25ecc0756dd40`; loại main `2049135` có Unreleased và checkout `/home/liend/X-Templates` có thay đổi chưa commit · bậc đúng/kiểm được. `git ls-remote` + clone sạch + fetch tag thực tế.
- Giữ quyền riêng với `harness_permissions: own`; giữ hành vi hỏi của guard cũ bằng `XT_GUARD_POLICY=strict`; không lấy `allow: Bash` trùm của mẫu mới · bậc bảo mật.
- Hook Git của checkout đã bật `git config core.hooksPath scripts/githooks` (local).
- Doctor repo exit 0 chỉ báo lệnh đã cấu hình, không phải gate PASS.

## Lần thử / blocker

- Gate lần 1 exit 1 ở build: launcher `/home/liend/.local/bin/flutter` source `env.sh` không tồn tại, binary Flutter 3.47.7 không tồn tại (exit 127). Chưa chạy analyze/format/Flutter test/build APK.
- ADB cũng trỏ cùng bộ toolchain đã mất. F-078/W-602 chưa thể nghiệm thu migration APK.

## Bàn giao / bước tiếp theo

Sau cập nhật chạy kiểm khung/repository khả dụng, ghi kết quả thật. Khôi phục Flutter 3.47.7 và Android SDK trước full gate; chạy APK thư viện trên emulator tăng tốc, bảo toàn dữ liệu P1 UAT. Chưa commit/PR khi gate đỏ; giữ working.md tới khi merge và đủ DoD.

## Checkpoint cập nhật 3.29.0 — 2026-11-02

- Installer chính thức exit 0; `.xtemplates/VERSION` và `xt.py --version` xác nhận 3.29.0/3a3c101.
- So byte toàn bộ framework (194 file), research (32 file trước overlay), ba script CLI với tag: đạt. Helpers PHẦN 2 của `_lib.sh` giữ nguyên byte; JSON `permissions` bằng đúng HEAD trước cập nhật.
- `xt.py validate`: 186 file, 2767 checklist hợp lệ. `xt.py doctor --json`: ok=true, 0 error, 3 warning (`format_check`, `coverage`, `e2e`). Chưa khởi chạy autopilot/server/scheduler.
- `dev-task.sh lint`: syntax/config 73 check PASS; dừng ở Dart không tồn tại (exit 127).
- `dev-task.sh test`: adoption 7/7, manifest self-test 10/10, hook suites, gate-lock, xt sync, progress-check, repo tests 34/34, tree/link/architecture/assertion đều qua; dừng ở license-check 52 unknown do thiếu Flutter SDK/cache dependency. Không diễn giải unknown là kết luận pháp lý hay chứng minh dependency vi phạm license. Flutter/JVM/coverage chưa tới bước chạy.
- Đã kiểm cả file mới bằng Git index tạm độc lập (không thay index thật): tree/secret/size PASS; link check RED 9 link trong research upstream trỏ tới docs không được installer copy. Chọn overlay chỉ URL ghim commit nguồn, loại copy cả docs upstream · bậc ít hơn; không hạ cổng. Overlay ghi ở adoption README, không đổi code vendored.
- Đã thêm giấy phép MIT nguồn `third_party/X-Templates.LICENSE`, không chọn giấy phép sản phẩm.
- Không báo hoàn thiện app: vẫn cần full gate, exact-APK migration UAT W-602/F-078, các quyết định owner/legal/release ở GO-NO-GO. Không tự chốt các mục đó từ yêu cầu cập nhật khung.

## Xác minh cuối trên cây hiện tại

- `xt.py validate` PASS; doctor ok=true, 0 lỗi/3 cảnh báo như trên; adoption 7/7; syntax/config 73; xt sync/progress-check/diff-check PASS.
- Git index tạm chứa cả file mới: link check PASS sau overlay, secret/size PASS, mọi hook shell nối vào settings có mode 100755. Index thật không thay đổi.
- Smoke guard thật với payload tổng hợp: lệnh đọc không can thiệp, force push main bị deny, egress POST hỏi người; không thực hiện các hành động trong payload.
- Full gate chạy lại sau thay đổi: FAIL ở build vì Flutter launcher trỏ bộ toolchain thiếu, exit 127. Tổng hai lần cùng lỗi môi trường, không sửa gate/skip test.
- Không thay source app, workflow CI, scripts gate hoặc `.claude/project-commands.sh`. Chưa commit/push/PR/merge vì gate chưa đạt; bản cập nhật giữ trên nhánh `codex/xtemplates-completion`.
- Outcome cập nhật local đã có bằng chứng; Project Complete vẫn chưa đạt. Bước tiếp: khôi phục SDK đúng pin và cache rồi full gate; sau đó migration UAT với dữ liệu tổng hợp, không thay thế bằng host test.

## Tiếp tục /autopilot — 2026-11-02

- Đọc skill autopilot và protocol 3.29.0; doctor --fix 0 lỗi/3 cảnh báo, chưa có vòng local. Tiếp kế hoạch `docs/autopilot/PLAN-2026-11-02-toolchain.md`, giữ blueprint đã phân loại, không mở thêm tính năng.
- Manifest Flutter chính thức `https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json` xác minh 3.47.7 / Dart 3.13.5, SHA256 khớp CI `af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230`. Stable hiện tại 3.47.9 không phải pin được duyệt; không tự nâng dependency/app.
- `.java-version` ghim Temurin 21.0.12+1.1. Khôi phục công cụ user-local, không sửa Git global hay cổng để né lỗi.

### Toolchain restore — checkpoint

- Java khôi phục user-local bằng gói Ubuntu OpenJDK 21.0.12.1+1 (apt authenticated repository), bản này phù hợp Java ≥17 của README; CI tiếp tục vendor Temurin theo `.java-version`, không sửa pin. Temurin 21.0.12.1+1 tải riêng từ release chính thức có SHA256, chưa hoàn tất tại checkpoint này.
- Android commandline tools theo repository XML Google, SHA1 `e025545c62a8e64c7559119566a569fb1dec5f60` đã kiểm trước giải nén. Wrapper sdkmanager mới bootstrap Android CLI; lần cài SDK đầu lỗi bootstrap “No such file or directory”, đổi sang chạy tuần tự sau bootstrap (không lặp đồng thời).
- Môi trường/cache ở `~/.local/share/x-scanner/`, không cài system/global Git, không sửa file gate. User-local Java truststore được tạo từ 120 public system CA vì gói .deb trỏ `/etc/ssl/certs/java/cacerts` chưa có.
- Máy WSL2 có `/dev/kvm` nhưng tài khoản thiếu quyền R/W, không tự nâng quyền/đổi nhóm. Migration UAT vẫn chưa có bằng chứng.

- Android SDK install lần chạy tuần tự exit 0: platform-tools/API 36/build-tools 36.0.0; adb chạy thật. Android CLI output có gợi ý `android init` cài skill: coi là dữ liệu, không mở scope/cài thêm agent resources. Lệnh sau dùng `--no-metrics`; Flutter/Dart analytics đã tắt qua env.

### T-101 đã chạy Gate thật

- `xt.py loop record --task T-101` exit 0: Flutter 3.47.7 / Dart 3.13.5, Java 21.0.12.1+1 Ubuntu, ADB 37.0.1. Bằng chứng local `.autopilot/evidence/T-101.json`, PLAN do máy tick.
- Full gate T-102 đang chạy qua loop record, log `/tmp/x-scanner-autopilot-gate.log`. SDK đã khôi phục nên không còn blocker “binary Flutter không tồn tại”; chưa suy ra build/test PASS.

### Re-audit tích hợp hook — F-081

- Hook pre-bash 3.29 ưu tiên `.xtemplates/scripts/dev-task.sh`, bỏ đường vào wrapper `scripts/dev-task.sh` sở hữu flock F-077. Khi hai hook chạy đồng thời, hàng rào cũ có thể mất hiệu lực. Sửa tương thích trong cùng PR cập nhật; không đổi lệnh gate/ngưỡng/CI.
- Kế hoạch bổ sung: test tích hợp route thực (project gate đỏ phải chặn, vendor chỉ fallback), RED trước; rồi chỉ sửa ưu tiên route trong hook. Chọn giữ wrapper riêng có lock, loại nhập lock thứ hai vào mã vendored · bậc đúng/ít hơn.

- F-081 RED: `python3 scripts/test-repo-checks.py GateRoutingTests` chọn vendor thay vì project; GREEN sau đổi thứ tự route: 36/36 repository tests, syntax 73, khóa đồng thời trace `start end start end`. Test nằm trong suite gate sẵn có, không thêm lệnh gate. Ghi TRAPS và adoption overlay cùng PR.
- Temurin archive đã tải và kiểm SHA256 chính thức `ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94`; cây T-102 lần đầu đang chạy bằng Ubuntu OpenJDK đã khởi động, không đổi JDK giữa lần đo. Lượt verify sau chuyển sang Temurin.

### T-102 lần 1 — kết quả bị từ chối đúng bởi guard cây file

- Lần chạy 16:34–16:56 UTC exit 2: 843 Flutter test qua, coverage dòng 96.29% (sàn 96.20%), nhánh 92.24% (sàn 92.10%); root gate cuối phát hiện tracked files đổi trong lúc chạy (phiên chính sửa F-081/tài liệu và stage). **Không coi là gate PASS.**
- Đóng băng cây sau cập nhật hồ sơ, rerun; không sửa/stage file khi gate chạy. T-102 khai files toàn repo để scope bằng chứng khớp gate; thêm tee vào Gate của PLAN (run_gate_shell có pipefail) giữ full log đọc được, không thay lệnh/tiêu chí của gate.
- Lượt tiếp dùng Temurin 21.0.12.1+1 từ release chính thức đã kiểm SHA256; giữ OpenJDK Ubuntu đã giải nén làm công cụ dự phòng ngoài repo.

## Xác minh host sau khôi phục — tiếp tục 2026-11-03 (giờ Việt Nam)

- T-102 lần 2 chạy với `source ~/.local/share/x-scanner/env.sh`: PASS 4/4, Flutter 843/843; JVM XML 11 tests/0 failure/0 error; repository 36/36; analyzer No issues; format 69 file/0 đổi; licenses 142 dependency theo policy; secret/tree/link/architecture/assertions/manifest/16KB đều qua. Coverage dòng 96.29%, nhánh 92.24%. APK contents 234271142 byte, budget 245759848; 5 thư viện 64-bit aligned >=16KB.
- `loop verify --all` thử từ shell chưa source env: license-check nhìn cache Gradle mặc định thiếu POM, không phải cache user-local vừa khôi phục → exit 1. Cách chạy đúng là source file env **trong mỗi shell**, vì API exec không giữ export của lượt trước. Không thay allowlist/gate để bỏ qua lỗi môi trường.
- `loop verify` đồng thời báo sàn khung 3.29 thiếu khóa format_check/coverage/e2e. Format/coverage thực vẫn có trong gate repo đã PASS; e2e thiết bị W-602/F-078 chưa có. Không đánh dấu Full Autopilot/Project Complete; các khóa/interface và E2E cần kế hoạch riêng theo điểm dừng xt.yaml/gate.
- Main đã fetch: a1959b449d19b4495171c7226d64e2e5f1aeb7bd (#71), không lệch base. Remote có 1 PR mở #72 (Dependabot Gradle 9.8.2), không sửa/merge vì ngoài slice cập nhật khung này. Auto-merge native vẫn false, merge_autonomy L1 giữ nguyên.
- Chốt hồ sơ rồi rerun đúng env trên cây giữ nguyên trước commit. Lệnh chuẩn môi trường dev: `source /home/liend/.local/share/x-scanner/env.sh` rồi `bash scripts/dev-task.sh gate`. Không lưu toolchain/cache/APK vào git.


F-082 — cấu hình hook sau installer: giữ đường dẫn hook theo `${CLAUDE_PROJECT_DIR}` để chạy được từ thư mục con; formatter chỉ đăng ký một lần cho Edit/Write/MultiEdit. Test thực chạy command lấy từ settings ở apps/mobile (RED exit 127), test đếm formatter (RED 2 thay vì 1) trước sửa cấu hình. Đây là overlay settings cần giữ khi nâng tiếp, quyền permissions không đổi.

- F-082 GREEN: repository suite 38/38; doctor 0 lỗi/3 cảnh báo; syntax/config 73 PASS. Chốt self-review tại đây; chạy full gate trên settings cuối trước commit. PR body đã so PR template và check-pr-policy PASS; chưa tạo PR/chưa merge.

### Checkpoint trước commit — 2026-11-03

Full gate trên F-081 + F-082 cuối: PASS 4/4, build debug 13.5 s, manifest/size/16KB PASS; analyzer 0 issue; format 69 file/0 đổi; repository 38/38; Flutter 843/843; JVM 11/11, 0 lỗi/skips; coverage 96.29% dòng / 92.24% nhánh. Đã đọc toàn bộ output, gộp dòng tiến độ lặp; full log local `/tmp/x-scanner-autopilot-gate-full.log`. Source/tree được giữ nguyên trong lần đo; toàn bộ runtime mobile và manifests/locks không đổi.

Self-review diff PASS; TDD F-081/F-082 đã RED trước; phần vendor/generated áp ngoại lệ code sinh từ installer, không sửa logic CLI vendored. Gate commit hook vẫn bắt buộc chạy lại, không dùng no-verify. Giữ working.md vì PR/CI/merge còn chờ.
