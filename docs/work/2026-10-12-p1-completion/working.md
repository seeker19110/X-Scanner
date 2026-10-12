# Công việc: X-Scanner P1 /completion — hết lỗi đã biết, Definition of Complete

- Work ID: 2026-10-12-p1-completion
- Yêu cầu / outcome: `/auto-complete` lần 4, bước 2: `/completion` (`docs/framework/project-completion.md` Pha 0–4) sau khi P1 PR-0..4 merged (#6..#10). Outcome: Definition of Complete có bằng chứng hoặc BLOCKED/WAITING đúng §8.
- Trạng thái: In progress — Pha 0 (CODEMAP xong; FEATURE-MAP, CONVENTIONS chờ audit) song song Pha 1 (3 auditor chỉ đọc).
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

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- Đọc báo cáo audit ở scratchpad (`AUDIT-A.md`, `AUDIT-B.md`, `AUDIT-C.md`) → kiểm từng phát hiện bằng code thật → `COMPREHENSIVE-AUDIT-STATUS.md`, FEATURE-MAP, CONVENTIONS, COMPLETION-PLAN.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
