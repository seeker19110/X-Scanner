# Feature spec: XS-12a — tác vụ xuất có tiến độ và huỷ

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | XS-12 (phần tiến độ/huỷ) của `docs/plans/2026-10-12-comprehensive-development-plan.md` (§6.2, §6.3, §13) · Work ID `2026-10-12-xs12a-export-progress` |
| Spec owner | Phiên chính (Claude Code) |
| State | **Approved for implementation** — PR-1 (§17) |
| Approver / date | Phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12 |
| Last updated | 2026-10-12 |

> Mức **M**: đổi cách chạy xuất và thêm giao diện tiến độ/huỷ. Không đổi dữ liệu lưu, manifest, định dạng/tên file xuất,
> writer PDF hay dependency. Là consumer đầu tiên của hợp đồng tác vụ xuất XS-08 (FR-5, §12.2, §9 tiêu chí 7 và 8;
> `docs/specs/2026-10-12-document-revision-export-contract.md`, ADR-0004).

## 1. Problem, user và evidence

- **F-033** (`docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`): xuất nhiều trang không có tiến độ i/N, không huỷ được — người dùng
  tưởng app treo. `SessionController.exportAndShare` chỉ bật `busy` (thanh chạy không xác định 4 px) cho tới khi chia sẻ.
- `PageExporter.export(pages, originalOf, format)` render tuần tự từng trang rồi ghi; không có điểm kiểm huỷ, không báo
  tiến độ (`lib/export/page_exporter.dart`).

## 2. Outcome, baseline, target và guardrails

- Baseline: xuất "tất cả hoặc không", không tiến độ, không huỷ.
- Target: người dùng thấy "Đang xuất trang i/N" + thanh tiến độ xác định, bấm "Huỷ" thì dừng ở ranh giới trang kế tiếp,
  không để lại file dở và được báo "Đã huỷ xuất."; tác vụ đi đúng vòng đời XS-08 FR-5.
- Guardrails: bản gốc chỉ được đọc; file chỉ được công bố (chia sẻ) khi tác vụ `succeeded`; huỷ/lỗi → thư mục xuất rỗng;
  lỗi không mang đường dẫn/nội dung; không log; mọi render vẫn qua cùng `DecodeGate`.

## 5. Scope / non-goals

- Trong phạm vi: kiểu `ExportJob` theo XS-08 §12.2; `PageExporter` chạy một `ExportJob`; controller giữ tác vụ đang chạy,
  cho huỷ; màn danh sách hiện tiến độ + nút Huỷ + thông báo huỷ.
- Non-goal (phần còn lại của XS-12 và XS-11): tiếp tục sau khi app bị đóng; vòng đời file chia sẻ/cache có hạn dùng; chọn
  nơi lưu khác; profile/khổ giấy/chọn trang/tên file; writer PDF theo luồng (XS-11). Huỷ **trong** lúc dựng PDF trong isolate
  không ngắt isolate: yêu cầu huỷ được tôn trọng ngay sau khi dựng xong, trước khi công bố.

## 7. Functional requirements

- **FR-1 Tác vụ (XS-08 FR-5).** `ExportJob` chụp snapshot lúc tạo: danh sách trang (không sửa được) và định dạng. Trạng thái
  `queued → running → {succeeded | failed | cancelled}`; ba trạng thái cuối không đổi được; chuyển sai thứ tự → `StateError`.
  `done` 0..`total`, chỉ tăng; `total` = số trang ≥ 1 (danh sách rỗng → `ArgumentError`). `failure` chỉ có ở
  `failed`/`cancelled` (`renderFailed | writeFailed | cancelled`); `files` chỉ có ở `succeeded`. `cancel()` idempotent, không
  tác dụng khi đã ở trạng thái cuối.
- **FR-2 Chạy tác vụ.** `PageExporter` chạy tác vụ: xoá thư mục xuất, `running`, render từng trang theo thứ tự; sau mỗi trang
  `done + 1` và báo tiến độ; kiểm yêu cầu huỷ **trước mỗi trang** và **trước khi công bố** (sau khi ghi PDF/ảnh cuối). Lỗi
  render → `failed(renderFailed)`; lỗi ghi file/dựng PDF → `failed(writeFailed)`; huỷ → `cancelled(cancelled)`; ba trường
  hợp đều xoá thư mục xuất. Tên file và định dạng giữ nguyên quy ước P1.
- **FR-3 Snapshot (XS-08 §9 tiêu chí 7).** File xuất phản ánh các trang lúc tạo tác vụ, kể cả khi phiên bị sửa trong lúc chạy.
- **FR-4 Controller.** `exportAndShare(format)` tạo tác vụ từ trang hiện tại, cho UI đọc tác vụ đang chạy (`exportJob`:
  trạng thái, `done`, `total`) và báo thay đổi mỗi khi tiến độ/trạng thái đổi; `cancelExport()` huỷ tác vụ đang chạy (không
  có thì không làm gì). `succeeded` → chia sẻ rồi dọn như hiện nay; `failed` → `SessionNotice.exportFailed` như hiện nay;
  `cancelled` → `SessionNotice.exportCancelled` ("Đã huỷ xuất."). Xong (mọi trạng thái cuối) → không còn tác vụ đang chạy.
- **FR-5 Giao diện.** Khi có tác vụ đang chạy: thanh 4 px hiện tiến độ **xác định** `done/total` (nhãn trợ năng
  "Đang xuất trang i/N"), thanh dưới thay các nút nguồn bằng chữ "Đang xuất trang i/N" và nút "Huỷ" (≥ 48 dp, bật kể cả khi
  `busy`). i = `min(done + 1, total)`. Không nhảy bố cục khi bắt đầu/kết thúc xuất. Mọi nút khác giữ hành vi tắt khi `busy`.

## 8. Non-functional requirements

- Không thêm dependency; không đổi `pubspec.lock`, tên file xuất, MIME, nội dung PDF.
- A11y: nhãn tiếng Việt; nút Huỷ 48 dp; màu từ `ColorScheme` (Dark/Light).
- Bộ nhớ: không giữ thêm ảnh so với hiện nay (DEBT PDF giữ mọi trang trong RAM giữ nguyên, thuộc XS-11).

## 9. Acceptance criteria

- **AC-1** Given tác vụ mới, then `queued`, `done` 0, `total` = số trang; `files`/`failure` null; danh sách trang không sửa
  được; danh sách rỗng ném `ArgumentError`; chuyển trạng thái sai thứ tự ném `StateError`; trạng thái cuối không đổi được
  (kể cả `cancel()` sau `succeeded`).
- **AC-2** Given 3 trang, when chạy xong (PDF và JPG), then `succeeded`, `done` 3, file như quy ước P1, tiến độ quan sát được
  là 0→1→2→3 (không giảm).
- **AC-3** Given renderer giả chặn ở trang 2, when huỷ rồi thả, then `cancelled(cancelled)`, `done` ≤ 2, thư mục xuất không
  còn file, renderer không được gọi cho trang 3; huỷ ngay trước khi công bố (sau trang cuối) cũng ra `cancelled` không file.
- **AC-4** Given trang 2 render lỗi, then `failed(renderFailed)`, thư mục xuất rỗng; given ghi file/dựng PDF lỗi, then
  `failed(writeFailed)`, thư mục rỗng (XS-08 §9 tiêu chí 8).
- **AC-5** Given tác vụ đang chạy, when phiên bị sửa (xoay/xoá một trang qua controller), then file xuất phản ánh snapshot
  lúc tạo (XS-08 §9 tiêu chí 7).
- **AC-6** Given controller đang xuất, then `exportJob` có `done/total` và listener được báo theo tiến độ; `cancelExport()` →
  không chia sẻ, `SessionNotice.exportCancelled`, phiên/bản gốc không đổi, sau đó `exportJob` null; lỗi → `exportFailed`.
- **AC-7** Given màn danh sách đang xuất 3 trang, then hiện "Đang xuất trang i/3" và thanh tiến độ xác định; bấm "Huỷ" →
  thông báo "Đã huỷ xuất." và các nút trở lại; nút Huỷ ≥ 48 dp và có nhãn (a11y cả Dark/Light).

## 11. Architecture và code touchpoints

- `apps/mobile/lib/export/export_job.dart` (mới): `ExportState`, `ExportFailure`, `ExportJob`.
- `apps/mobile/lib/export/page_exporter.dart`: chạy `ExportJob` (thay `export`), kiểm huỷ, báo tiến độ.
- `apps/mobile/lib/ui/session_controller.dart`: `exportJob`, `cancelExport`, `SessionNotice.exportCancelled`.
- `apps/mobile/lib/ui/review_screen.dart`: thanh tiến độ xác định, dòng "Đang xuất trang i/N" + "Huỷ", thông báo huỷ.
- Lệch hợp đồng XS-08 §12.2 (ghi để consumer sau theo): snapshot dùng chính `ScanPage` bất biến (đúng 5 trường
  `id, revision, originalPath, quad, quarterTurns`), không thêm `ExportPageSnapshot`; `documentId` chưa có vì phiên P1 chưa
  có id tài liệu — thêm khi XS-09 PR-4 nối thư viện.

## 16. Test/eval plan

Đỏ-trước cho mọi nhánh mới (ADR-0005). Renderer giả có `Completer` theo trang để chặn/làm lỗi (XS-08 §16).

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | `apps/mobile/test/export/export_job_test.dart::new job is queued with a frozen snapshot (AC-1)` | + `illegal transitions throw`, `final states do not change` (huỷ khi `queued` kết thúc ngay; khi `running` chờ runner) |
| AC-2 | `apps/mobile/test/export/page_exporter_test.dart::job reports progress page by page (AC-2)` | PDF và JPG; test tên file P1 cũ chuyển sang `run`, assert giữ nguyên |
| AC-3 | `apps/mobile/test/export/page_exporter_test.dart::cancel stops at the next page (AC-3)` | + `cancel before publishing leaves no files (AC-3)`, `a job cancelled while queued is not run` |
| AC-4 | `apps/mobile/test/export/page_exporter_test.dart::render failure fails the job (AC-4)` | + các ca `write failure fails the job` (PDF hỏng, thư mục không tạo được, file trang không ghi được) |
| AC-5 | `apps/mobile/test/export/page_exporter_test.dart::export uses the snapshot taken when the job was created (AC-5)` | bằng chứng snapshot thật (đổi danh sách trang giữa lúc chạy); ca cùng tên ở `session_controller_test.dart` chỉ chứng minh sửa qua controller xếp hàng sau tác vụ xuất (xanh cả trên code cũ) |
| AC-6 | `apps/mobile/test/ui/session_controller_test.dart::cancelling an export shares nothing (AC-6)` | + `export job reports progress (AC-6)`, `… the job is gone while sharing`, `cancelExport without an export does nothing` |
| AC-7 | `apps/mobile/test/ui/review_screen_test.dart::export shows page progress and can be cancelled (AC-7)` | + `accessibility_test.dart` "review screen while exporting meets the a11y guidelines in … theme (XS-12a AC-7)" Dark/Light |

## 17. Slice/PR plan

| PR | Nội dung | Phụ thuộc |
| --- | --- | --- |
| PR-1 | `ExportJob` + exporter + controller + màn danh sách (FR-1..FR-5, AC-1..AC-7) | spec này |

Rollback: revert; không có dữ liệu hay định dạng nào đổi.
