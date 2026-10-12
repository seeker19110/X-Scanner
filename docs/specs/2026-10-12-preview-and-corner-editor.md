# Feature spec: XS-13 — xem trước đã cắt và trình chỉnh góc

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | XS-13 của `docs/plans/2026-10-12-comprehensive-development-plan.md` (§6.3, §13) · Work ID `2026-10-12-xs13-preview-corner-editor` |
| Spec owner | Phiên chính (Claude Code) |
| State | **Approved for implementation** — PR-1, PR-2 (§17) |
| Approver / date | Phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12 |
| Last updated | 2026-10-12 |

> Mức **M**: chỉ giao diện và ảnh xem trước dựng từ thumbnail đã có. Không đổi dữ liệu lưu, schema, quyền, dependency hay
> đường xuất file. Là consumer đầu tiên của quy tắc "kết quả dẫn xuất khoá theo `(pageId, revision)`" của hợp đồng XS-08
> (`docs/specs/2026-10-12-document-revision-export-contract.md` FR-4, AC-6; ADR-0004).

## 1. Problem, user và evidence

- **F-026** (`docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`): danh sách trang hiện ảnh gốc chỉ xoay, **không cắt**; người dùng chỉ
  thấy kết quả cắt khi mở file xuất. `ReviewScreen._thumbnail` dùng `RotatedBox` trên `thumbnailFor(page)` (ảnh gốc thu nhỏ),
  cache khoá theo `page.id` (`lib/ui/session_controller.dart`).
- **F-032**: trình chỉnh góc hiện ảnh **chưa xoay** (trang đã xoay 90° vẫn hiện nằm ngang), Back **bỏ thay đổi không hỏi**,
  không hoàn tác; ngón tay che đúng góc đang kéo nên khó đặt chính xác (`lib/ui/quad_editor_screen.dart`).
- Dấu `DEBT:` trong `quad_editor_screen.dart`: góc chỉ chỉnh được bằng kéo; người dùng trình đọc màn hình chỉ "Đặt lại".

## 2. Outcome, baseline, target và guardrails

- Baseline: xem trước khác file xuất; trình chỉnh góc hiện ảnh lệch hướng, mất thay đổi khi lỡ bấm Back.
- Target: ô xem trước trong danh sách là **cùng phép cắt + xoay** như file xuất (chỉ khác độ phân giải); trình chỉnh góc hiện
  đúng hướng trang, có hoàn tác/làm lại, hỏi trước khi bỏ thay đổi, có kính lúp khi kéo, chỉnh được góc không cần kéo qua
  thao tác trợ năng.
- Guardrails: không đọc/giải mã thêm ảnh gốc (xem trước dựng từ thumbnail ≤ 1024 px đã cache); không ghi file; không thêm
  dependency; không log; mọi giải mã vẫn qua `DecodeGate` một-việc-một-lúc; bản gốc và manifest không đổi.

## 5. Scope / non-goals

- Trong phạm vi: F-026 (PR-1), F-032 + điều chỉnh góc qua thao tác trợ năng (PR-2).
- Non-goal:
  - **Phóng to bằng hai ngón** trong trình chỉnh góc (kế hoạch §6.3 có nêu): kính lúp khi kéo giải quyết độ chính xác; phóng
    to cần đổi cách quy đổi toạ độ tay kéo và tranh chấp cử chỉ với tay kéo. Xem lại khi UAT trên thiết bị (XS-04/XS-24) cho
    thấy kính lúp không đủ, hoặc ở XS-20.
  - Bộ lọc, preview toàn màn hình, tiến độ/huỷ xuất (F-033 → XS-12), Việt hoá chuỗi framework (F-031 → XS-20).
  - Phương án chỉnh góc bằng **một lần chạm** cho mọi người dùng (WCAG 2.2 2.5.7 đầy đủ): PR-2 chỉ thêm thao tác trợ năng;
    dấu `DEBT:` được thu hẹp, xem lại ở XS-20.

## 7. Functional requirements

- **FR-1 Xem trước đã cắt.** Ô trang trong danh sách hiện kết quả của `renderPageSync(thumbnail, quad, quarterTurns)` —
  cùng hàm `rectify` + xoay mà file xuất dùng — trên thumbnail đã cache của trang (ảnh gốc đã áp EXIF, thu nhỏ đồng đều).
  Chạy trong isolate nền với `decodeBudget`, xếp hàng qua cùng `DecodeGate` với mọi giải mã khác.
- **FR-2 Khoá theo revision (XS-08 FR-4, AC-6).** Ảnh xem trước đã cắt được cache theo `(pageId, revision)`. Kết quả hoàn tất
  với revision khác revision hiện tại của trang **không được hiển thị và không giữ trong cache**. Khi trang được lưu với
  revision mới, các mục cache của revision cũ của trang đó bị bỏ. Xoá trang/xoá hết/khôi phục phiên bỏ cache như thumbnail.
- **FR-3 Lỗi.** Thumbnail hoặc ảnh xem trước lỗi → ô lỗi có nút tải lại như hiện nay; tải lại làm lại cả thumbnail lẫn ảnh
  xem trước của trang đó. Lỗi không mang đường dẫn/nội dung, không log.
- **FR-4 Trình chỉnh góc vẫn nhận thumbnail chưa cắt** (`thumbnailFor`), như hiện nay.
- **FR-5 Hiện đúng hướng.** Trình chỉnh góc vẽ thumbnail đã xoay theo `quarterTurns` hiện tại (đổi ngay khi bấm "Xoay 90°").
  Vị trí tay kéo trên màn hình được quy đổi về toạ độ chuẩn hoá của ảnh gốc chưa xoay bằng hàm thuần, và ngược lại; quy đổi
  đi rồi về là đồng nhất cho cả 4 hướng. Nhãn trợ năng của tay kéo theo **vị trí hiển thị** ("Góc trên trái" là góc đang nằm
  ở trên trái màn hình).
- **FR-6 Hoàn tác/làm lại.** Mỗi lần kéo xong (một cử chỉ), mỗi lần "Xoay 90°", "Đặt lại" và mỗi thao tác trợ năng là **một**
  bước. Nút "Hoàn tác"/"Làm lại" tắt khi không còn bước. Bước mới sau khi hoàn tác xoá nhánh làm lại. Lịch sử giới hạn
  100 bước (bỏ bước cũ nhất).
- **FR-7 Rời màn khi có thay đổi.** Trạng thái hiện tại khác trạng thái lúc mở (quad hoặc `quarterTurns`) → Back (nút app bar,
  nút/cử chỉ hệ thống) hỏi "Bỏ thay đổi?" với "Tiếp tục sửa" (ở lại, giữ nguyên) và "Bỏ thay đổi" (đóng, trả `null`). Không
  có thay đổi → đóng ngay, trả `null`. "Lưu" khi không có thay đổi trả `null` (không ghi, không tăng revision).
- **FR-8 Kính lúp.** Trong lúc kéo một góc, một kính lúp tròn phóng to vùng quanh góc đó, đặt lệch khỏi ngón tay (phía trên,
  hoặc phía dưới khi góc ở sát mép trên), biến mất khi thả tay. Dùng widget có sẵn của Flutter (`RawMagnifier`).
- **FR-9 Chỉnh góc không cần kéo.** Mỗi tay kéo có 4 thao tác trợ năng "Dịch lên", "Dịch xuống", "Dịch sang trái",
  "Dịch sang phải", mỗi lần dịch 1 % chiều tương ứng **theo hướng hiển thị**; vị trí làm khung không hợp lệ bị từ chối với
  cùng thông báo như khi kéo.
- **FR-10 Bất biến revision.** Trang trả về từ "Lưu" có nội dung khác trang lúc mở thì có revision lớn hơn revision lúc mở
  (kể cả sau hoàn tác rồi sửa tiếp), nên một `(pageId, revision)` đã lưu không bao giờ mang hai nội dung khác nhau.

## 8. Non-functional requirements

- Không thêm dependency, không đổi `pubspec.lock`.
- A11y: nút mới có nhãn tiếng Việt, vùng chạm ≥ 48 dp, màu từ `ColorScheme` (Dark/Light), kính lúp không là mục trợ năng.
- Hiệu năng: ảnh xem trước ≤ 1024 px cạnh dài; không có hai ảnh gốc giải mã cùng lúc (giữ spec P1 §8).

## 9. Acceptance criteria

- **AC-1** Given trang có quad Q và `quarterTurns` t, when danh sách hiện trang, then ô xem trước là ảnh do
  `renderPageSync(thumbnail, Q, t)` tạo (không còn `RotatedBox` trên ảnh chưa cắt).
- **AC-2** Given ảnh gốc W×H và thumbnail thu nhỏ của nó, when dựng xem trước và render xuất cùng (Q, t) với t = 0..3, then tỉ
  lệ khung lệch ≤ 1 px ở cỡ xem trước và màu ở bốn góc ảnh khớp nhau (cùng hình học).
- **AC-3** Given ảnh xem trước của `(id, n)` còn đang dựng, when trang thành revision n + 1 rồi kết quả cũ hoàn tất, then kết
  quả đó không được trả cho trang revision n + 1 và không còn trong cache (XS-08 AC-6).
- **AC-4** Given ảnh gốc không giải mã được, then ô lỗi có nút tải lại; when bấm tải lại, then thumbnail và ảnh xem trước được
  dựng lại; ảnh xem trước lỗi được cache như thumbnail (dựng lại danh sách không giải mã lại).
- **AC-5** Given trang xoay t lần, when mở trình chỉnh góc, then ảnh hiện xoay t × 90° và `fromDisplay(toDisplay(p, t), t) == p`
  cho mọi t; kéo tay kéo hiển thị ở trên trái di chuyển đúng góc tương ứng của quad gốc.
- **AC-6** Given ba thao tác (kéo, xoay, đặt lại), when hoàn tác ba lần rồi làm lại một lần, then trạng thái khớp từng bước;
  thao tác mới sau hoàn tác xoá làm lại; nút tắt đúng lúc; lịch sử giữ tối đa 100 bước.
- **AC-7** Given có thay đổi, when Back, then hỏi; "Tiếp tục sửa" giữ màn và trạng thái; "Bỏ thay đổi" đóng trả `null`. Given
  không thay đổi (kể cả sửa rồi hoàn tác về đầu), when Back hoặc "Lưu", then đóng trả `null` không hỏi.
- **AC-8** Given đang kéo một góc, then kính lúp hiện; when thả tay, then kính lúp biến mất.
- **AC-9** Given tay kéo trên trái hiển thị, when chạy thao tác trợ năng "Dịch sang phải", then góc đó dịch +1 % theo chiều ngang
  hiển thị (đúng cả khi trang đã xoay); vị trí không hợp lệ bị từ chối, trạng thái giữ nguyên.
- **AC-10** Given trang revision n, when sửa, hoàn tác, sửa khác rồi "Lưu", then trang trả về có revision > n (FR-10).

## 11. Architecture và code touchpoints

- PR-1 (F-026, FR-1..FR-4):
  - `apps/mobile/lib/ui/session_controller.dart`: `croppedPreviewFor(ScanPage)` cache theo `(id, revision)`; tham số tiêm
    `previewer` (mặc định: isolate + `renderPageSync` trên bytes thumbnail); `retryThumbnail` làm lại cả hai.
  - `apps/mobile/lib/imaging/page_render.dart`: hàm nền `croppedPreview(Uint8List thumbnail, PageQuad, int)` nếu cần (dùng lại
    `renderPageSync`, `runWithinBudget`).
  - `apps/mobile/lib/ui/review_screen.dart`: ô trang dùng `croppedPreviewFor`; nút "Chỉnh góc" vẫn chờ `thumbnailFor`.
- PR-2 (F-032, FR-5..FR-10):
  - `apps/mobile/lib/core/quad_editing.dart`: `toDisplay`/`fromDisplay`, ánh xạ góc hiển thị ↔ góc gốc.
  - `apps/mobile/lib/core/edit_history.dart` (mới): lịch sử hoàn tác/làm lại có giới hạn.
  - `apps/mobile/lib/ui/quad_editor_screen.dart`: hiển thị xoay, lịch sử, `PopScope`, kính lúp, thao tác trợ năng.
- Không đổi: `ScanPage`, manifest, `SessionStore`, `PageExporter`, `DocumentStore`, `LibraryStore`, `P1Migration`.

## 16. Test/eval plan

Đỏ-trước cho mọi hàm/nhánh mới (ADR-0005). Unit cho hàm thuần (`toDisplay`/`fromDisplay`, `EditHistory`, hình học xem
trước); test controller với `previewer` giả có `Completer` (AC-3); widget test cho màn danh sách và trình chỉnh góc.

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | `apps/mobile/test/ui/session_controller_test.dart::cropped preview renders the thumbnail with the page's quad and` | + `apps/mobile/test/ui/review_screen_test.dart` "list shows the cropped preview (XS-13 AC-1)" (không `RotatedBox`, trình chỉnh nhận thumbnail chưa cắt) |
| AC-2 | `apps/mobile/test/imaging/page_render_test.dart::preview matches export geometry (XS-13 AC-2)` | t = 0..3; + `croppedPreview renders like renderPageSync (XS-13 FR-1)` |
| AC-3 | `apps/mobile/test/ui/session_controller_test.dart::stale preview of an older revision is dropped (AC-3)` | `Completer` giữ kết quả cũ tới sau `updatePage` |
| AC-4 | `apps/mobile/test/ui/session_controller_test.dart::failed preview is cached until retried (AC-4): thumbnail fails` | + ca previewer lỗi; widget `a failed cropped preview shows the error tile` |
| AC-5 | `apps/mobile/test/core/quad_editing_test.dart::display mapping round-trips for every turn` | + widget `rotated page is shown upright and drags move the right corner` |
| AC-6 | `apps/mobile/test/ui/quad_editor_screen_test.dart::undo and redo buttons follow the history (XS-13 AC-6)` | + `one drag with many moves is one undo step`; `test/core/edit_history_test.dart` (giới hạn 100) |
| AC-7 | `apps/mobile/test/ui/quad_editor_screen_test.dart::back with changes asks before discarding (XS-13 AC-7)` | + `no changes closes without asking`, `saving without changes returns null` |
| AC-8 | `apps/mobile/test/ui/quad_editor_screen_test.dart::loupe shows only while dragging (XS-13 AC-8)` | |
| AC-9 | `apps/mobile/test/ui/quad_editor_screen_test.dart::semantic nudge moves the shown corner` | t = 0 và 1; + `an invalid semantic nudge is rejected (XS-13 AC-9)` |
| AC-10 | `apps/mobile/test/ui/quad_editor_screen_test.dart::saved page has a higher revision after undo and a new edit` | |

## 17. Slice/PR plan

| PR | Nội dung | Phụ thuộc |
| --- | --- | --- |
| PR-1 | F-026: xem trước đã cắt, cache theo revision (FR-1..FR-4, AC-1..AC-4) | spec này |
| PR-2 | F-032: trình chỉnh góc (FR-5..FR-10, AC-5..AC-10) | PR-1 merge (tuần tự: cùng màn danh sách mở trình chỉnh) |

Rollback: revert từng PR; không có dữ liệu hay định dạng nào đổi.
