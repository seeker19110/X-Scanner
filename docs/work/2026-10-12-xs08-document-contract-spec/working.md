# Công việc: Nháp spec XS-08: hợp đồng tài liệu, revision và xuất

- Work ID: 2026-10-12-xs08-document-contract-spec
- Yêu cầu / outcome: chủ repo yêu cầu 2026-10-12 "viết nháp spec XS-08" (kế hoạch #23 §4.2, §13). Outcome: spec Draft `docs/specs/2026-10-12-document-revision-export-contract.md` chờ chủ repo duyệt.
- Trạng thái: In review — spec Draft, chưa Approved; không code.
- Chủ trì / writer: phiên chính, một writer.
- Mức rủi ro / số PR: S cho PR này (chỉ tài liệu); hợp đồng chạm dữ liệu bền nên consumer XS-09 là mức L.
- Scope / non-goal: hợp đồng tài liệu/trang/revision/tác vụ xuất + schema 2. Non-goal: code, UI thư viện, migration thật, OCR, camera, bộ lọc.
- Spec / goal / issue: `docs/specs/2026-10-12-document-revision-export-contract.md` · XS-08 trong `docs/plans/2026-10-12-comprehensive-development-plan.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `7f562f5` · 2026-10-12T09:51:44Z

## Kế hoạch và phân công

Một PR tài liệu: spec Draft + hồ sơ này; kèm ghi chú mở rộng W-104 ở hồ sơ P1 completion (chủ repo duyệt cùng lượt).

## Quyết định và bằng chứng

- Spec chỉ chốt 3 hợp đồng có consumer gần (tài liệu/trang, revision, tác vụ xuất) · loại chốt đủ 5 hợp đồng §4.2 (QualityReport, OcrResult, depth) · bậc 2 (spec sau chốt khi có dữ liệu; bắt buộc tuân quy tắc khoá revision §12.3).
- Đề xuất phương án A (code đi cùng consumer đầu tiên) · loại B (kiểu + codec ngay) · bậc 2 (không code chết); để chủ repo chọn ở D-1.
- Bỏ khỏi schema 2: `source`, `addedAt`, `filter`, `renderVersion` · bậc 2 (chưa có người đọc; thêm sau là trường tuỳ chọn cùng schema theo FR-7).
- Không hash bản gốc trong hợp đồng: `dart:core` không có SHA-256, thêm `package:crypto` vượt D2 · để mở D-3 cho XS-09.
- Đối chiếu code `main` @ `7f562f5`: `ScanPage` không revision; `thumbnailFor` cache theo `page.id`; `decodeManifest` ném `FormatException` khi `schemaVersion` ≠ 1 và `SessionStore._load` cách ly (dòng 153/173); chụp lại = id mới (`retake` → `replaced`).

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- Chờ chủ repo đọc spec và chốt D-1 (A/B). Duyệt → ghi "Approved for implementation" + người duyệt + ngày vào spec, viết ADR hợp đồng; phương án B thì mở PR-1 code. PR tài liệu này merge xong thì đổi hồ sơ thành `done.md` (outcome là bản nháp đã nộp; việc duyệt theo dõi ở spec).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
