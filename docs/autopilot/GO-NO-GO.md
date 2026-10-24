# GO-NO-GO — autopilot 2026-10-24 (X-Scanner)

> Kết cục vòng: **done-pending-human** (`xt.py loop status`). Kế hoạch: `docs/autopilot/PLAN.md` · quyết định tự duyệt: `docs/autopilot/DECISIONS.md` (D-001..D-003) · bằng chứng máy: `.autopilot/evidence/T-00{1..4}.json` (không commit, `.gitignore`).
> Đây **không** phải quyết định phát hành: app chưa ký/phân phối, chưa chạy bản có thư viện trên thiết bị.

## Đã làm (Gate xanh qua `xt.py loop record`)

| Task | Kết quả | Gate |
|---|---|---|
| T-001 | `PROGRESS.md` 4 mục, < 3 KB; lịch sử nguyên văn ở `docs/changelog/2026-10-progress-history.md` | `xt.py progress-check PROGRESS.md` |
| T-002 | `xt.yaml` thêm JVM test cho khớp cổng thật; `scripts/check-xt-yaml-sync.sh` (đỏ trước khi sửa) | `bash scripts/check-xt-yaml-sync.sh` |
| T-003 | 402 MUST của `BLUEPRINT.md` (`mobile-app`, M) có kết cục: **94 đạt** kèm bằng chứng, **160 không áp dụng** kèm điều kiện, **148 chờ người** đã `loop defer` (ghi `— Thiếu:` từng dòng). Tự sửa 2 mục an toàn: `.gitignore` `*.pem`/`*.key`, test UTF-8 tiêu đề tiếng Việt + emoji | `python3 scripts/check-blueprint-triage.py` (D-003) |
| T-004 | Phản hồi khung FB-001..003 (`docs/xtemplates-feedback/`) | `xt.py feedback collect` |

Phân loại do 4 subagent chỉ đọc làm; phiên chính kiểm độ phủ (402/402 ID, mỗi ID một lần) và đối chiếu ngẫu nhiên 10 mục "đạt" với file thật.

## Chờ người (148 MUST, xem dòng `— Thiếu:` trong `BLUEPRINT.md`)

| Nhóm | Vì sao cần người | ID |
|---|---|---|
| Cổng/CI/ruleset/hook (điểm dừng cấu hình cổng) | thêm job gitleaks/OSV theo lịch/link check/commitlint/coverage, review bắt buộc, guard | BASE-GATE-006/009/019, BASE-REPO-005, BASE-SEC-002, WF-CI-001/005, WF-GIT-002/003/010, WF-REVIEW-002/007, SEC-SECRET-001, SEC-SUPPLY-001/006, QA-COV-001/002/004/008, QA-STRAT-005, LOOP-ORCH-001, LOOP-CI-001, LOOP-STOP-003, STD-PROC-004, XC-DOCAI-003, ARC-MOD-004/005, ARC-ADR-003/004, FE-TEST-003/006, WF-DOC-002, BASE-DOC-005/006/008, OPS-MAINT-001/003/004/005, BASE-DEP-001..007, SEC-SUPPLY-003, XC-DX-001/003/006, XC-GREEN-002, XC-PERF-003 |
| Giấy phép, chính sách mở | chủ repo chọn LICENSE, SLA bảo mật, kênh báo | BASE-REPO-004, CMP-LIC-001..004, XC-OSS-001/004/005, BASE-SEC-009, BASE-DOC-001 |
| Phát hành/ký/store/iOS | chưa có quyết định phát hành | WF-REL-001/003/004, OPS-DEPLOY-001, PRF-MOB-001..005/008..010, QA-PERF-006 |
| Pháp lý, quyền riêng tư, chuẩn nhắm tới | chủ repo chọn khung pháp lý/chuẩn (WCAG, MASVS, ISO 25010, PDPL) | STD-PRIV-001, STD-SEC-001, STD-A11Y-001, STD-PROC-001, CMP-PRIV-001, BASE-SEC-013, PM-RISK-007, PM-REQ-009, QA-DATA-001/002 |
| Thiết bị/kiểm tay | cần thiết bị, TalkBack (container không KVM) | STD-A11Y-002/004, PRF-MOB-011, QA-E2E-001, UX-A11Y-001/002/003 |
| Thay đổi hành vi app (cần spec duyệt) | chuẩn hoá NFC tên, bắt lỗi toàn cục, giảm chuyển động, i18n/ARB, dialog xoá nêu hậu quả, trần đọc `document.json` | BASE-DATA-002, UX-CONTENT-002, XC-I18N-001/003/005/009, BASE-ERR-002, UX-VISUAL-001, UX-STATE-008, UX-DS-003/006, UX-RESP-001, XC-PERF-006, XC-UNITS-009 |
| Tài liệu quản trị dự án | threat model, sổ rủi ro, runbook, MoSCoW, spec dạng Given/When/Then | SEC-TM-001/003/005/006, SEC-SECRET-011, OPS-IR-001/010, CMP-AUDIT-010, PM-REQ-001/007, PM-HANDOVER-002/005, PM-PRIO-001/003/004, PM-RISK-001/003/006, PM-SPEC-001/003/004/020, WF-SDD-002/003, WF-TEAM-003/004, WF-DOC-008, ARC-STYLE-001, ARC-MOD-008, BASE-DOC-003, BASE-REPO-007/013, XC-DOCAI-001/004/005, XC-PERF-001/004, XC-GREEN-001/005/007, QA-STATIC-005 |

Cùng việc chờ ngoài blueprint: **W-602** chạy APK có thư viện trên emulator/thiết bị; **F-077** hai gate song song ở hook commit (`docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`).

## Đề xuất thứ tự cho chủ repo

1. F-077 + nhóm cổng/CI (một quyết định mở khoá nhiều mục).
2. LICENSE + khung pháp lý/chuẩn nhắm tới (đổi được thành ghi PROJECT.md trong một PR).
3. W-602 trên máy có tăng tốc.
4. Duyệt spec nhỏ cho nhóm "thay đổi hành vi app" (NFC tên, bắt lỗi toàn cục) trước XS-10.
