# Công việc: X-Scanner P1 /completion — hết lỗi đã biết, Definition of Complete

- Work ID: 2026-10-12-p1-completion
- Yêu cầu / outcome: `/auto-complete` lần 4, bước 2: `/completion` (`docs/framework/project-completion.md` Pha 0–4) sau khi P1 PR-0..4 merged (#6..#10). Outcome: Definition of Complete có bằng chứng hoặc BLOCKED/WAITING đúng §8.
- Trạng thái: In progress — Pha 0–2 + W-201 merged (#11 `97deb76`); W-101 PR mở; W-301, W-401 đã sẵn trong worktree (commit cục bộ `5cc5154`, `afcc67a`).
- Chủ trì / writer: phiên chính (kế hoạch, duyệt, tích hợp); audit giao 3 subagent chỉ đọc; sửa giao worker theo số PR.
- Mức rủi ro / số PR: M; PR-A tài liệu Pha 0–2, rồi một PR mỗi việc W-xxx theo kế hoạch.
- Scope / non-goal: app `apps/mobile` P1 + tài liệu dự án. Non-goal: tự nhận mép, OCR, depth, iOS, cloud, release, bật branch protection/auto-merge (cần quyền chủ repo).
- Spec / goal / issue: `docs/specs/2026-10-11-p1-scan-export.md` · `docs/goals/2026-10-11-p1-scan-export.md` · `docs/ops/COMPLETION-PLAN.md` (Pha 2)
- Nhánh / base SHA / thời điểm reconcile: `claude/upbeat-ramanujan-mwmwtt` @ `6177e29` · 2026-10-12T02:03:07Z

## Kế hoạch và phân công

- Pha 0 (phiên chính): `CODEMAP.md`, `docs/FEATURE-MAP.md`, `docs/CONVENTIONS.md`.
- Pha 1 (3 subagent chỉ đọc, song song): A nhóm 1/3/10/12; B nhóm 2/7/11; C nhóm 4/5/6/8/9 → `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`, ID F-xxx.
- Pha 2 (phiên chính): `docs/ops/COMPLETION-PLAN.md` + DoC, tự duyệt theo §3d.
- Pha 3–4: một PR mỗi W-xxx, re-audit nhóm bị ảnh hưởng.

## Quyết định và bằng chứng

- Pha 0 không dừng chờ người dùng xác nhận Hồ sơ/FEATURE-MAP · loại hỏi · ủy quyền `/auto-complete` (§3d): phiên chính tự duyệt cổng và ghi căn cứ.
- Audit chia 3 cụm nhóm cho 3 subagent chỉ đọc · loại 12 subagent hoặc phiên chính tự quét · bậc 2 (≤ 5 subagent, ít ngữ cảnh phiên chính) và bậc 4.
- Pha 1: 3 auditor trả 53 phát hiện thô (A 15, B 9, C 29) → gộp trùng còn 42 (3 Cao, 14 Trung, 25 Thấp), `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`. Phiên chính lần lại F-001 trên code (`session_store.dart` `_load`/`_save`, `session_controller.dart` `restore`) và grep xác nhận F-002, F-003, F-006, F-007, F-034.
- F-001 sửa ở store (từ chối `save` khi manifest còn mà `load` chưa xong) · loại cách ly manifest khi lỗi I/O (rename cũng có thể lỗi) và chặn ở controller · bậc 1 (chặn ở lớp sở hữu dữ liệu, mọi caller đều an toàn) rồi bậc 2 (controller đã map `StateError` → `saveFailed`).
- F-004 `image` 4.10.1: exception EX-1 tới 2026-10-18 rồi nâng (W-104) · loại nâng ngay 4.12.0 (1 ngày tuổi) và loại tự chặn PNG/EXIF bằng code riêng · bậc 1 (app chưa phân phối nên rủi ro treo/OOM ≈ 0 trong 6 ngày, còn bản phát hành 1 ngày có rủi ro chuỗi cung ứng với quyền đọc mọi tài liệu) rồi bậc 2.
- Không giới hạn định dạng ảnh nhập về JPEG/PNG · loại · bậc 2 (đổi hành vi ngoài spec, không chặn được PNG bom).
- Dời F-026, F-030, F-031, F-032, F-033, F-036, F-038 sang P2/trước release (lý do ở kế hoạch) · loại làm trong P1 · bậc 2 (tính năng/dependency ngoài spec P1 hoặc cần thiết bị/quyết định sản phẩm).
- F-014 branch protection, F-009 bật dependency review: WAITING chủ repo · loại tự bật · CLAUDE.md header (không tự bật auto-merge/dịch vụ; cần quyền repo settings).
- W-201 gộp vào PR kế hoạch · loại PR tài liệu riêng · bậc 4 (cùng loại thay đổi tài liệu, bớt một vòng CI).
- Mỗi W một PR, tích hợp tuần tự trên một nhánh push; worker song song trong worktree khi file không giao nhau (W-101 ∥ W-301 ∥ W-401) · loại song song nhiều nhánh · chỉ được push `claude/upbeat-ramanujan-mwmwtt`.
- Brief `PLAN-c1.md` (scratchpad) `--check-plan` OK: 3 việc, mỗi việc một PR.
- PR kế hoạch + W-201 https://github.com/seeker19110/X-Scanner/pull/11 merged squash `97deb76` sau CI xanh (job 114636563159); 0 review thread.
- W-101 (worker, báo cáo `REPORT-w101.md`): đỏ 5 test (3 store F-001, F-019, controller F-001) → xanh; `flutter test` 211/211. Nhận lệch 1 (save thành công cũng đánh dấu store biết manifest — store vừa tự ghi nó) · bậc 1 (giữ hành vi AC-1). Nhận lệch 2 (load trả Empty/Unrecoverable thì quên danh sách bản gốc cũ) · bậc 1 (cùng khuôn mất bản gốc của phiên bị cách ly, có test đỏ).
- W-301: giữ kiểm thêm `uses-permission-sdk-23` và `activity-alias` (chặt hơn brief) · loại gỡ cho đúng nguyên văn · bậc 1 (cùng là đường cấp quyền/mở component).
- W-401: nhận nhánh phòng vệ khi công thức thu nhỏ vẫn vượt trần (cạnh 1 px) · bậc 1 (không vượt trần bộ nhớ); `buildPdf` qua `Isolate.run` không có test đỏ riêng · ngoại lệ (2) §3.6 (chỉ đổi nơi chạy, hành vi giữ nguyên, test PDF/PdfException cũ bảo vệ).
- Worker không ghi được file báo cáo (harness chặn); phiên chính ghi `REPORT-w101/w301/w401.md` + patch vào scratchpad.

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- Merge PR kế hoạch (Pha 0–2 + W-201). Tích hợp W-101 → W-301 → W-401 từ worktree (báo cáo `REPORT-w101.md`, `REPORT-w301.md`, `REPORT-w401.md` ở scratchpad), mỗi W một PR; rồi W-102 → W-103 → W-302 → W-402 → W-403; W-104 từ 2026-10-18.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
