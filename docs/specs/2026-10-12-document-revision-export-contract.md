# Feature spec: XS-08 — hợp đồng tài liệu, revision trang và tác vụ xuất

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | XS-08 của `docs/plans/2026-10-12-comprehensive-development-plan.md` (§4.2, §13) · Work ID `2026-10-12-xs08-document-contract-spec` |
| Spec owner | Phiên chính (Claude Code) |
| State | **Approved for implementation** — phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12; phương án A (ADR-0004): không PR code riêng, code đi cùng consumer đầu tiên |
| Approver / date | Phiên chính theo ủy quyền §3d (`/auto-complete` của chủ repo) · 2026-10-12 |
| Last updated | 2026-10-12 |

> Kế hoạch M0–M5 là DRAFT; spec này không cho phép triển khai XS-09..XS-23. Nó chỉ chốt **hợp đồng chung** mà các
> spec đó phải tuân theo, để chúng chia việc được mà không mỗi nơi tự định nghĩa trang/revision/xuất theo một kiểu.

## 1. Problem, user và evidence

P1 lưu đúng **một phiên** (`session/session.json`, `schemaVersion` 1): danh sách trang, mỗi trang = bản gốc bất biến +
tham số chỉnh (`quad`, `quarterTurns`). Các việc kế tiếp trong kế hoạch đều cần thêm thứ mà schema 1 không có:

| Việc kế tiếp | Cần gì từ hợp đồng chung |
| --- | --- |
| XS-09 thư viện nhiều tài liệu + migration | định danh và metadata tài liệu; quy tắc chuyển schema 1 → 2 không mất bản gốc |
| XS-11/XS-12 PDF dài, tiến độ/huỷ | tác vụ xuất có snapshot, trạng thái, tiến độ, huỷ, lỗi không lộ nội dung |
| XS-13 xem trước đã cắt | khoá cache theo **revision** (hôm nay thumbnail khoá theo `page.id` và là ảnh gốc chưa cắt, F-026) |
| XS-21/XS-22 OCR theo revision | quy tắc "kết quả của revision cũ không gắn vào trang đã sửa" |

Bằng chứng trong code (`main` @ `7f562f5`): `ScanPage` không có revision (`lib/core/scan_page.dart`);
`thumbnailFor` cache theo `page.id` (`lib/ui/session_controller.dart`); `PageExporter.export` nhận `List<ScanPage>` và chỉ
trả file hoặc ném lỗi, không có tiến độ/huỷ (`lib/export/page_exporter.dart`); `decodeManifest` coi mọi
`schemaVersion` khác 1 là hỏng và cách ly manifest (`lib/core/session_manifest.dart`).

## 2. Outcome, baseline, target và guardrails

- Baseline: một phiên, không revision, xuất "tất cả hoặc không" không tiến độ.
- Target: một hợp đồng được duyệt (mô hình + schema 2 + quy tắc revision + vòng đời tác vụ xuất) mà XS-09, XS-12, XS-13,
  XS-22 trích dẫn thay vì tự định nghĩa.
- Guardrails (kế thừa P1, không được nới): bản gốc không bị ghi đè hay xoá khi chưa có manifest đã lưu không còn tham chiếu
  nó; không log/hiển thị tiêu đề, đường dẫn hay nội dung trang trong lỗi; không mạng; không thêm dependency.

## 3. Research current state

- Mô hình: `ScanPage` (id 32 hex, `originalPath` = `originals/{id}.{ext}`, `PageQuad` chuẩn hoá `[0,1]` trên ảnh gốc
  chưa xoay, `quarterTurns` 0..3), `ScanSession` bất biến, id duy nhất. Chụp lại = trang **id mới** thay đúng vị trí.
- Lưu trữ: `SessionStore` ghi nguyên tử, tuần tự hoá `load`/`save`/`importOriginal`, cách ly manifest hỏng thành
  `session.corrupt-{ms}.json`, chỉ xoá bản gốc khi manifest đã lưu không còn tham chiếu (TRAPS, F-001).
- Xuất: render tuần tự qua `DecodeGate`; PDF dựng trong `Isolate.run`; lỗi xoá mọi file đã ghi; `DEBT:` bộ nhớ PDF.
- Kế hoạch §4.2 đề xuất 5 hợp đồng (CapturedPage, EditRecipe, QualityReport, OcrResult, ExportJob). Spec này chốt ba cái
  có người dùng gần (tài liệu/trang, revision, tác vụ xuất); QualityReport, OcrResult và trường depth của CapturedPage để
  spec của XS-17, XS-21, XS-14 chốt, nhưng phải tuân §12.3 (khoá theo revision).

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | Không tốn gì | Mỗi spec sau tự định nghĩa revision/trạng thái xuất; dễ lệch hệ toạ độ và gắn kết quả cũ (kế hoạch §4.2) | Loại |
| A. Chỉ hợp đồng (spec + ADR); kiểu Dart và codec được viết trong PR của **người dùng đầu tiên** (XS-09 cho tài liệu/revision, XS-12 cho tác vụ xuất) | Không có code chết; mỗi phần code có test hành vi ngay | Hợp đồng chỉ được kiểm khi consumer đầu tiên merge | **Đề xuất** |
| B. Hợp đồng + kiểu Dart + codec schema 2 + contract test ngay ở XS-08 | Kiểm được sớm, consumer chỉ việc dùng | Code chưa ai gọi tới khi XS-09 được duyệt; nếu XS-09 đổi ý thì phải sửa lại | Chủ repo chọn ở D-1 nếu muốn |
| C. Chuyển sang SQLite ngay | Truy vấn/chỉ mục cho OCR | Thêm dependency (D2), migration file + DB cùng lúc; kế hoạch §4.1 yêu cầu ADR riêng | Loại ở XS-08; XS-22 xét lại |

## 5. Scope / non-goals

- Trong phạm vi: định nghĩa **Tài liệu**, **Trang** (= tài sản gốc + công thức chỉnh), **revision**, **kết quả dẫn
  xuất**, **tác vụ xuất**; schema `document.json` phiên bản 2; quy tắc đọc schema 1; quy tắc tương thích phiên bản.
- Không làm ở XS-08: UI thư viện, bố cục thư mục nhiều tài liệu và migration thật (XS-09); writer PDF mới, huỷ/tiếp tục
  thật (XS-11/XS-12); bộ lọc (XS-19); OCR (XS-21/22); camera/depth (XS-14/15); hash bản gốc (cần dependency, xem D-3).

## 6. User journeys và mọi state

Spec hợp đồng không đổi hành vi người dùng. Các journey dùng hợp đồng (thuộc spec consumer):
mở tài liệu cũ sau khi nâng app (schema 1 → 2, không mất trang); sửa góc trong lúc thumbnail/OCR đang chạy (kết quả cũ
bị bỏ); xuất 100 trang có tiến độ i/N, huỷ giữa chừng (không để lại file dở); xuất lỗi (thông báo không lộ tên/đường dẫn).

## 7. Functional requirements

- **FR-1 Tài liệu.** `ScanDocument { id, title, createdAt, updatedAt, pages }`. `id` 32 hex (cùng khuôn `newPageId`),
  bất biến. `title` 1–120 ký tự sau khi bỏ khoảng trắng đầu/cuối, không ký tự điều khiển (U+0000–U+001F, U+007F).
  `createdAt`/`updatedAt` là UTC, ghi ISO-8601 có `Z`; `updatedAt ≥ createdAt`; `updatedAt` đổi ở mọi lần lưu có thay
  đổi trang hoặc tiêu đề. `pages` giữ mọi bất biến của `ScanSession` hiện tại (thứ tự, id duy nhất).
- **FR-2 Trang.** Giữ `ScanPage` hiện tại (id, `originalPath`, `quad`, `quarterTurns`) và thêm `revision`: số nguyên
  ≥ 0, bắt đầu 0 khi trang được tạo (chụp, nhập, chụp lại).
- **FR-3 Revision.** Mọi thao tác trả về công thức chỉnh mới của **cùng** trang (`withQuad`, `rotatedClockwise`, và mọi
  tham số chỉnh thêm sau này như bộ lọc) trả `revision + 1`, kể cả khi giá trị mới bằng giá trị cũ (đơn giản, không so
  sánh số thực). Sắp xếp/xoá trang khác không đổi revision. Chụp lại tạo trang **id mới**, revision 0 (giữ hành vi P1).
- **FR-4 Kết quả dẫn xuất.** Thumbnail, ảnh xem trước đã cắt, ảnh render, OCR và chỉ mục tìm kiếm của một trang được khoá
  bằng `(pageId, revision)`. Kết quả hoàn tất với revision khác revision hiện tại của trang bị bỏ, không hiển thị, không lưu.
- **FR-5 Tác vụ xuất.** Một tác vụ có:
  - *Snapshot* chụp lúc tạo: id tài liệu, danh sách `(pageId, revision, originalPath, quad, quarterTurns)` theo thứ tự,
    định dạng (`pdf`/`jpeg`/`png`). Sửa tài liệu sau đó không đổi tác vụ đang chạy.
  - *Trạng thái*: `queued → running → {succeeded | failed | cancelled}`; ba trạng thái cuối không đổi được nữa; chuyển
    sai thứ tự là lỗi lập trình (`StateError`).
  - *Tiến độ*: `done` / `total` trang, `0 ≤ done ≤ total`, chỉ tăng; `total` = số trang trong snapshot ≥ 1.
  - *Huỷ*: yêu cầu huỷ được kiểm giữa hai trang (điểm an toàn); tác vụ huỷ hoặc lỗi **không để lại file** trong thư mục xuất.
  - *Kết quả*: chỉ `succeeded` mới công bố danh sách file, theo thứ tự trang (giữ quy ước tên file P1).
  - *Lỗi*: mã lỗi đóng `renderFailed | writeFailed | cancelled` — không kèm thông điệp, đường dẫn, tiêu đề hay byte ảnh.
- **FR-6 Đọc schema 1.** Manifest `schemaVersion: 1` đọc được thành **một** tài liệu: mọi trang revision 0; `id`, `title`,
  `createdAt` do bên gọi cung cấp (migration XS-09 quyết nguồn, ví dụ thời điểm sửa đổi của file), không đoán trong codec.
- **FR-7 Phiên bản schema.** Bộ đọc nhận schema 1 và 2. Schema **lớn hơn** bản app biết → kết quả riêng
  "cần cập nhật app", **không** cách ly như manifest hỏng và không xoá bản gốc nào (hôm nay app cách ly mọi version lạ).
  Thêm trường tuỳ chọn có mặc định giữ cùng schema; đổi nghĩa trường hoặc thêm trường bắt buộc thì tăng schema.

## 8. Non-functional requirements

- Riêng tư: `title` là dữ liệu người dùng; không log, không đưa vào thông báo lỗi/`FormatException` (chỉ nêu tên trường và
  chỉ số trang, đúng khuôn `decodeManifest`).
- Độ bền: schema 2 vẫn ghi nguyên tử và giữ quy tắc xoá bản gốc của `SessionStore` (TRAPS F-001).
- Không dependency mới; codec thuần Dart, kiểm bằng unit test không cần thiết bị.
- Thời gian: chuẩn hoá về UTC khi ghi; đọc chuỗi không có `Z` là lỗi định dạng (không đoán múi giờ).

## 9. Acceptance criteria

Áp cho code của hợp đồng, ở PR đầu tiên hiện thực nó (phương án A) hoặc ở XS-08 (phương án B).

- **AC-1** Given một tài liệu hợp lệ, when mã hoá schema 2 rồi giải mã, then mọi trường (id, title, thời điểm, thứ tự trang,
  quad, quarterTurns, revision) giữ nguyên.
- **AC-2** Given manifest schema 1 của P1, when đọc với id/title/createdAt do bên gọi đưa, then ra một tài liệu đúng thứ tự
  trang, mọi revision 0, không trang nào bị bỏ.
- **AC-3** Given `title` rỗng/toàn khoảng trắng/> 120 ký tự/có ký tự điều khiển, `revision` âm hoặc không phải số nguyên,
  thời điểm thiếu `Z` hoặc `updatedAt < createdAt`, when giải mã, then `FormatException` chỉ nêu tên trường, không chứa
  giá trị người dùng.
- **AC-4** Given manifest `schemaVersion` lớn hơn bản app biết, when tải, then kết quả "cần cập nhật app", file không bị
  đổi tên, không bản gốc nào bị xoá.
- **AC-5** Given trang revision n, when `withQuad`/`rotatedClockwise`, then trang mới revision n + 1, id và `originalPath`
  không đổi; chụp lại cho trang id mới revision 0.
- **AC-6** Given kết quả dẫn xuất của `(id, n)` hoàn tất sau khi trang đã thành revision n + 1, then kết quả bị bỏ (kiểm ở
  consumer đầu tiên dùng cache theo revision — XS-13 hoặc XS-22).
- **AC-7** Given tác vụ xuất đang chạy, when tài liệu bị sửa, then file xuất phản ánh snapshot lúc tạo tác vụ.
- **AC-8** Given tác vụ xuất, when huỷ giữa hai trang hoặc một trang lỗi, then trạng thái cuối là `cancelled`/`failed`,
  thư mục xuất rỗng, không trạng thái nào đổi được sau đó, tiến độ không giảm.

## 11. Architecture và code touchpoints

Dự kiến (phương án A, theo PR consumer; phương án B gom PR-1):

| Hợp đồng | File | Consumer đầu tiên |
| --- | --- | --- |
| `ScanDocument`, `revision` trong `ScanPage` | `lib/core/scan_document.dart` (mới), `lib/core/scan_page.dart` | XS-09 |
| Codec schema 2 + đọc schema 1 + kết quả "cần cập nhật app" | `lib/core/session_manifest.dart` (đổi tên khi XS-09 đổi bố cục), `lib/storage/session_store.dart` | XS-09 |
| Khoá dẫn xuất `(pageId, revision)` | `lib/ui/session_controller.dart` (`thumbnailFor`, cache) | XS-13 |
| `ExportJob` (snapshot, trạng thái, tiến độ, huỷ, mã lỗi) | `lib/export/export_job.dart` (mới), `lib/export/page_exporter.dart` | XS-12 |

Hệ toạ độ không đổi: `PageQuad` chuẩn hoá `[0,1]` trên ảnh gốc **chưa xoay** (sau EXIF), `quarterTurns` xoay sau khi nắn.
Mọi consumer (xem trước, render, OCR, depth) đổi về hệ này, không tự định nghĩa hệ khác (kế hoạch §4.3).

## 12. API/event contract

### 12.1 Mô hình (Dart, thuần, bất biến)

```dart
class ScanDocument {
  final String id;          // 32 lowercase hex
  final String title;       // 1..120 chars after trim, no control chars
  final DateTime createdAt; // UTC
  final DateTime updatedAt; // UTC, >= createdAt
  final List<ScanPage> pages; // unmodifiable, unique ids
}

class ScanPage {            // existing fields unchanged
  final int revision;       // >= 0; +1 on every recipe change of this page
}
```

### 12.2 Tác vụ xuất

```dart
enum ExportState { queued, running, succeeded, failed, cancelled }
enum ExportFailure { renderFailed, writeFailed, cancelled }

class ExportJob {
  final String documentId;
  final ExportFormat format;
  final List<ExportPageSnapshot> pages; // (pageId, revision, originalPath, quad, quarterTurns), length >= 1
  ExportState get state;
  int get done;                         // 0..pages.length, never decreases
  ExportFailure? get failure;           // set only in failed/cancelled
  List<File>? get files;                // set only in succeeded
  void cancel();                        // idempotent; takes effect at the next page boundary
}
```

Lưu tác vụ qua lần khởi động lại (tiếp tục sau khi app bị đóng) **không** thuộc hợp đồng này; XS-12 quyết.

### 12.3 Quy tắc chung cho kết quả dẫn xuất (QualityReport, OcrResult… của spec sau)

Mỗi kết quả mang `pageId`, `revision` và phiên bản thuật toán/engine sinh ra nó; nơi dùng so với trang hiện tại trước khi
hiển thị hoặc lưu. Không kết quả dẫn xuất nào được ghi đè bản gốc.

## 13. Data contract/migration

`document.json`, `schemaVersion` 2 (ví dụ, không phải dữ liệu thật):

```json
{
  "schemaVersion": 2,
  "document": {
    "id": "0123456789abcdef0123456789abcdef",
    "title": "Hợp đồng thuê nhà",
    "createdAt": "2026-10-12T09:00:00Z",
    "updatedAt": "2026-10-12T09:05:00Z"
  },
  "pages": [
    {
      "id": "fedcba9876543210fedcba9876543210",
      "original": "originals/fedcba9876543210fedcba9876543210.jpg",
      "quad": [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0],
      "quarterTurns": 0,
      "revision": 2
    }
  ]
}
```

- Trường trang giữ đúng tên và kiểm tra của schema 1; thêm `revision` (bắt buộc ở schema 2).
- Đọc schema 1 theo FR-6. Ghi luôn là schema 2 **chỉ khi** XS-09 bật bố cục mới; trước đó app P1 tiếp tục ghi schema 1
  (không có hai lần migration cho cùng dữ liệu).
- Bố cục thư mục (một thư mục mỗi tài liệu hay chung `originals/`), nhật ký/commit marker và đường quay lại thuộc spec
  XS-09; bắt buộc giữ: không bản gốc nào bị xoá trong migration, bản cũ còn đọc lại được đến khi bản mới đã kiểm đủ trang.

## 14. Security/privacy/abuse cases

- Manifest là đầu vào không tin cậy (file có thể bị sửa tay/hỏng): mọi trường kiểm như schema 1; `original` vẫn chỉ nhận
  `originals/{id}.{ext}` của chính trang đó (chống path traversal).
- `title` dài/ký tự điều khiển bị từ chối khi đọc và khi tạo, không cắt ngầm.
- Lỗi xuất không mang đường dẫn/tiêu đề ra UI hay log (giữ khuôn `exportFailed` của P1).

## 16. Test/eval plan

Unit test thuần cho codec và mô hình (AC-1..AC-5), test controller cho khoá revision (AC-6), test `PageExporter`/tác vụ với
renderer giả có thể chặn và làm lỗi theo trang (AC-7, AC-8). Mỗi hành vi có test đỏ trước (ADR-0005).

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | chưa có — viết trong PR consumer (XS-09) hoặc PR-1 nếu chọn phương án B | `test/core/` |
| AC-2 | chưa có — như AC-1 | fixture schema 1 lấy từ test P1 hiện có |
| AC-3 | chưa có — như AC-1 | |
| AC-4 | chưa có — viết ở XS-09 cùng lớp lưu trữ | `test/storage/` |
| AC-5 | chưa có — như AC-1 | `test/core/scan_page_test.dart` |
| AC-6 | chưa có — XS-13 hoặc XS-22 | |
| AC-7 | chưa có — XS-12 | |
| AC-8 | chưa có — XS-12 | |

## 17. Slice/PR plan

- PR-0 (#26 `f227a4d`): spec Draft + hồ sơ công việc. Không code.
- PR-1: duyệt spec + ADR-0004 (D-1 = A). Không code.
- Sau khi duyệt: ADR mới ghi quyết định hợp đồng (§4, D-1..D-3). Phương án A: không PR code riêng; XS-09/XS-12/XS-13 trích
  spec này và mang AC tương ứng. Phương án B: PR-1 = `ScanDocument` + `revision` + codec schema 2/đọc schema 1 + AC-1..AC-5,
  app vẫn ghi schema 1.

## 18. Rollout/rollback

Không có rollout ở XS-08 (không đổi hành vi). Với consumer: schema 2 chỉ được ghi sau khi migration XS-09 được duyệt;
rollback app về bản chỉ biết schema 1 sẽ gặp FR-7 nên bản đó phải có FR-7 trước (đưa FR-7 vào PR đầu tiên chạm `SessionStore`).

## 19. Risk, assumptions và open decisions

| Item | Verification/mitigation | Owner | Due | Decision |
| --- | --- | --- | --- | --- |
| D-1 Phương án A (hợp đồng, code theo consumer) hay B (code + test ngay) | §4 | Phiên chính (§3d) | 2026-10-12 | Chốt A (ADR-0004) |
| D-2 Tiêu đề mặc định khi tạo/migrate (ví dụ "Tài liệu 12/10/2026 09:00" theo giờ máy) | Chốt ở XS-09 cùng UI đặt tên | Chủ repo | XS-09 | Mở, không chặn hợp đồng |
| D-3 Hash bản gốc để kiểm migration | `dart:core` không có SHA-256; cần `package:crypto` (dependency mới, D2) hoặc kiểm bằng kích thước + giải mã thử | Chủ repo | XS-09 | Mở, không chặn hợp đồng |
| FR-7 đổi hành vi hiện tại với schema lạ (đang cách ly) | AC-4; an toàn hơn (không đổi tên, không xoá) | Phiên chính | PR đầu tiên chạm store | Chấp nhận (ADR-0004 §3) |
| Revision tăng cả khi giá trị không đổi làm mất cache thừa | Chi phí: một lần giải mã thumbnail; đổi lại không so sánh số thực | Phiên chính | — | Chấp nhận |

## Approval

- [x] Product/scope
- [x] UX/a11y (không đổi UI ở XS-08)
- [x] Architecture/API/data
- [x] Security/privacy/cost
- [x] Test/telemetry/rollout/rollback
- [x] Blocking decisions closed (D-1)

**Conclusion:** **Approved for implementation** — phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12. Không cho phép triển khai XS-09..XS-23; mỗi việc cần spec riêng được duyệt.
**Approver/date:** phiên chính theo ủy quyền §3d · 2026-10-12
