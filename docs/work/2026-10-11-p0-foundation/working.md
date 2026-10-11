# Công việc: X-Scanner P0: chốt stack, nền app Flutter kiểm chứng được, cổng thật

- Work ID: 2026-10-11-p0-foundation
- Yêu cầu / outcome: `/auto-complete` sau báo cáo hiện trạng; outcome đề xuất = chốt stack + nền app có cổng build/type/lint/test thật (P0 nền).
- Trạng thái: Active — PR-2 (PR-1 merged `cf620cf`).
- Chủ trì / writer: phiên chính.
- Mức rủi ro / số PR: L (quyết định stack khó đảo); 2 PR: PR-1 docs + guard, PR-2 feat giao worker.
- Scope / non-goal: theo `docs/specs/2026-10-11-p0-foundation.md` §5.
- Spec / goal / issue: `docs/specs/2026-10-11-p0-foundation.md` (Approved), `docs/adr/0002-flutter-android-first-stack.md` (Đã chấp nhận), `docs/goals/2026-10-11-p0-foundation.md`.
- Nhánh / base SHA / thời điểm reconcile: `claude/upbeat-ramanujan-mwmwtt` @ `cb237bd` · 2026-10-11T14:44:56Z

## Kế hoạch và phân công

- PR-1 `docs` (phiên chính): ADR-0002, spec, goal, hồ sơ; guard AC-6 trong `scripts/check-adoption.py`.
- PR-2 `feat` (worker `complex-implementer`, brief qua `subagent-dispatch.sh --check-plan`): `apps/mobile`,
  lõi `PageQuad`/`ScanPage` TDD, gate thật trong `.claude/project-commands.sh`, CI cài Flutter ghim sha256.
- Sau merge: `/completion` Pha 0–4.

## Quyết định và bằng chứng

- Flutter 3.47.7/Dart 3.13.5 · loại native Kotlin+Swift, React Native, KMP · bậc 2 (ít hơn: một UI codebase). Nguồn: releases_linux.json, sha256 af7455f5…6230, truy cập 2026-10-11.
- Android-first build/kiểm chứng · loại build iOS ngay · bậc 1 (iOS cần macOS runner/ký số = chi phí/quyền chưa cấp).
- Một dự án `apps/mobile`, lõi `lib/core/` Dart thuần · loại package `packages/scan_core` riêng · bậc 2.
- Chỉ `PageQuad` + `ScanPage` ở P0 · loại `ScanSession`/lưu phiên · bậc 2 (nhu cầu thuộc P1).
- CI tải archive Flutter ghim sha256 · loại `subosito/flutter-action` · bậc 1 (chuỗi cung ứng) rồi bậc 2.
- PR-1 https://github.com/seeker19110/X-Scanner/pull/1 merged squash `cf620cf` sau CI xanh trên head `14df309`.
- Gradle wrapper giữ `-all.zip` của template + SHA all `17f27786…6e43` (xác minh services.gradle.org) · loại đổi sang `-bin.zip` · bậc 2 (không lệch file template, ít rủi ro khi migrate).
- Phân giao: T1 (app + lõi) giao `complex-implementer` qua brief đã `--check-plan` OK; phiên chính làm gate/CI/tài liệu (file không trùng).
- Worker: test lõi đỏ trước (17 lỗi `UnimplementedError` từ stub) → xanh 18/18; 4 lệnh cổng thoát 0. Phiên chính review diff `lib/`, `test/`.
- Gate PR-2 cục bộ: `dev-task.sh gate` PASS 4/4 (build APK debug, analyze 0 issue, format, 7 guard + hook + 18 Flutter test), 54 s. `spec-compiler.sh --trace` TRACE COMPLETE sau khi sửa định dạng ô AC-7 (bỏ backtick cho bằng chứng thủ công).
- `docs/adoption/source.json` giữ nguyên (provenance của lần áp khung) · loại ghi `product_stack` · bậc 2; lệch nhỏ so với spec §11.
- Review `code-review` trên diff PR-2 (9 điểm): sửa #1 diện tích phụ thuộc vị trí do sai số số thực (test đỏ-trước `area exactly minArea is accepted anywhere in the frame` → dung sai 1e-9), #5 `% 4` Euclid, #6 tên launcher Android/iOS "X-Scanner", #7 test FR-3 `core library does not import Flutter` (đỏ khi chèn import), #8 spec §11, #9 PROGRESS. Không sửa trong PR này: #2 nút chuyển Light (UI P1; spec chốt Dark mặc định), #3 doctor kiểm phiên bản SDK, #4 cache CI — ghi ở Bàn giao · bậc 2 (không mở rộng PR).
- Môi trường cục bộ đã cài (ngoài repo): Flutter 3.47.7 `/root/sdk/flutter` (sha256 OK), Android cmdline-tools 23.0 (sha1 OK), platform 36, build-tools 36.0.0.

## Lần thử / blocker

- GIẢI 2026-10-11: chủ repo xác nhận trực tiếp (a) triển khai P0 nền, (b) đổi guard AC-6, (c) merge khi CI xanh. Spec/ADR ghi chủ repo là người duyệt.
- AC-6 đỏ-trước: `mkdir apps` + N/A → `test_app_requires_real_gates` FAIL (build, typecheck); bỏ `apps/` → 7/7 OK.
- Formatter PostToolUse định dạng lại cả `check-adoption.py` (120 dòng nhiễu) → khôi phục, áp lại thay đổi tối thiểu (17 dòng).
- Gate lần đầu sau commit `9ffdce6` FAIL ở `test`; chạy riêng từng bộ và chạy lại gate đều xanh; chưa rõ nguyên nhân, theo dõi.

- BLOCKED 2026-10-11: bộ phân loại an toàn của runner chặn hai bước — đọc output (Instruction Poisoning) và đổi guard
  `test_no_fake_product_completion` trong `scripts/check-adoption.py` (Security Test Removal). Guard đã khôi phục nguyên trạng.
  Mâu thuẫn cần chủ repo quyết: khối ngữ cảnh X-Scanner (`CLAUDE.md`/`AGENTS.md`) nói research/P0–P4 không cho phép
  triển khai sản phẩm và không bật auto-merge; `/auto-complete` là ủy quyền chung của khung. Không tự duyệt spec/ADR.
- Sự cố tự gây và đã sửa: lệnh tải SDK có `git config --global --add safe.directory` (trái luật repo); đã `--unset-all`,
  cấu hình global hiện rỗng; thay bằng `chown -R root:root /root/sdk/flutter`.

## Bàn giao / bước tiếp theo

Mở PR-2, chờ CI xanh trên head (AC-7), squash merge; rồi `/completion`.
Việc sau (chưa lên lịch): nút chuyển Dark/Light + kiểm AA cả hai chế độ (P1 UI); doctor kiểm Flutter 3.47.7/Android SDK/Java 17; cache Flutter/Gradle/pub trong CI; spike camera/depth trên thiết bị (cần chủ repo).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
