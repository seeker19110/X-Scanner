# Công việc: Nháp spec XS-08: hợp đồng tài liệu, revision và xuất

- Work ID: 2026-10-12-xs08-document-contract-spec
- Yêu cầu / outcome: chủ repo yêu cầu 2026-10-12 "viết nháp spec XS-08" (kế hoạch #23 §4.2, §13). Outcome: spec Draft `docs/specs/2026-10-12-document-revision-export-contract.md` chờ chủ repo duyệt.
- Trạng thái: Done — spec Approved 2026-10-12 theo ủy quyền §3d, D-1 = A (ADR-0004); không code.
- Chủ trì / writer: phiên chính, một writer.
- Mức rủi ro / số PR: S cho PR này (chỉ tài liệu); hợp đồng chạm dữ liệu bền nên consumer XS-09 là mức L.
- Scope / non-goal: hợp đồng tài liệu/trang/revision/tác vụ xuất + schema 2. Non-goal: code, UI thư viện, migration thật, OCR, camera, bộ lọc.
- Spec / goal / issue: `docs/specs/2026-10-12-document-revision-export-contract.md` · XS-08 trong `docs/plans/2026-10-12-comprehensive-development-plan.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `7f562f5` · 2026-10-12T09:51:44Z

## Kế hoạch và phân công

Một PR tài liệu: spec Draft + hồ sơ này; kèm ghi chú mở rộng W-104 ở hồ sơ P1 completion (chủ repo duyệt cùng lượt) — #26 `f227a4d`.
PR thứ hai (`/auto-complete`): duyệt spec + ADR-0004, đóng hồ sơ.

## Quyết định và bằng chứng

- Spec chỉ chốt 3 hợp đồng có consumer gần (tài liệu/trang, revision, tác vụ xuất) · loại chốt đủ 5 hợp đồng §4.2 (QualityReport, OcrResult, depth) · bậc 2 (spec sau chốt khi có dữ liệu; bắt buộc tuân quy tắc khoá revision §12.3).
- Đề xuất phương án A (code đi cùng consumer đầu tiên) · loại B (kiểu + codec ngay) · bậc 2 (không code chết); để chủ repo chọn ở D-1.
- Bỏ khỏi schema 2: `source`, `addedAt`, `filter`, `renderVersion` · bậc 2 (chưa có người đọc; thêm sau là trường tuỳ chọn cùng schema theo FR-7).
- Không hash bản gốc trong hợp đồng: `dart:core` không có SHA-256, thêm `package:crypto` vượt D2 · để mở D-3 cho XS-09.
- Đối chiếu code `main` @ `7f562f5`: `ScanPage` không revision; `thumbnailFor` cache theo `page.id`; `decodeManifest` ném `FormatException` khi `schemaVersion` ≠ 1 và `SessionStore._load` cách ly (dòng 153/173); chụp lại = id mới (`retake` → `replaced`).
- Duyệt spec XS-08 theo ủy quyền §3d (`/auto-complete`, 2026-10-12) · loại chờ chủ repo · bậc 1 ngang nhau (spec không đổi hành vi, không code); việc được giao trong lượt.
- D-1 = A, ghi ADR-0004 · loại B (kiểu + codec + contract test ngay) · bậc 2 (không code chưa ai gọi; spec XS-09 đổi bố cục lưu trữ thì không phải sửa codec đã merge).
- FR-7 chấp nhận, vào PR đầu tiên chạm `SessionStore` · loại giữ cách ly schema lạ · bậc 1 (không đổi tên/không xoá manifest của bản app mới hơn).
- D-2, D-3 để mở cho XS-09 · loại chốt ngay · bậc 2 (D-3 cần dependency ngoài D2; D-2 cần UI đặt tên chưa có).
- Không mở XS-09 trong lượt này · loại tự viết spec XS-09 · ngoài scope đã giao (kế hoạch M0–M5 DRAFT; CLAUDE.md: roadmap không cho phép triển khai).

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- Không còn việc ở hồ sơ này. Consumer đầu tiên (XS-09) cần spec riêng được chủ repo giao + duyệt; spec đó trích ADR-0004 và mang AC-1..AC-5 + FR-7, chốt D-2/D-3.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Outcome: spec XS-08 Approved for implementation (phiên chính theo ủy quyền §3d, 2026-10-12) + ADR-0004.
- PR: #26 `f227a4d` (spec Draft) · PR duyệt — SHA ghi ở `PROGRESS.md`/CHANGELOG sau khi merge.
- Bằng chứng: `scripts/spec-compiler.sh --trace` không BROKEN; gate xanh trên PR duyệt (chỉ tài liệu).
- Giới hạn còn lại: AC-1..AC-8 "chưa có" tới khi consumer đầu tiên merge (ADR-0004 Hệ quả).
