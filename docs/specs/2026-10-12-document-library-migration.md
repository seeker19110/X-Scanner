# Feature spec: XS-09 — thư viện nhiều tài liệu và migration từ P1

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | XS-09 của `docs/plans/2026-10-12-comprehensive-development-plan.md` (§6.1, §13) · Work ID `2026-10-12-xs09-document-library-spec` |
| Spec owner | Phiên chính (Claude Code) |
| State | **Approved for implementation** — phạm vi PR-1..PR-3 (§17); PR-4 chờ chủ repo |
| Approver / date | Phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12 — chỉ PR-1..PR-3 |
| Last updated | 2026-10-12 |

> Mức **L**: đổi bố cục lưu trữ dữ liệu thật của người dùng (migration). PR-1..PR-3 chỉ thêm code không nối vào app, không
> chạm dữ liệu thật → phiên chính duyệt theo §3d. **PR-4** (công tắc chạy migration trên dữ liệu thật) không tự duyệt:
> chờ chủ repo (§3d "không bao giờ tự quyết").
> Tuân hợp đồng XS-08 (`docs/specs/2026-10-12-document-revision-export-contract.md`, ADR-0004): spec này là consumer
> đầu tiên, nên mang AC-1..AC-5 và FR-7 của hợp đồng.

## 1. Problem, user và evidence

P1 chỉ có **một phiên**: mọi trang nằm trong `session/session.json` (`schemaVersion` 1) + `session/originals/`. Người dùng
muốn số hoá nhiều giấy tờ (kế hoạch §1) phải xuất rồi "Xoá hết" trước khi chụp tài liệu mới; không đặt được tên, không mở
lại tài liệu cũ. Bằng chứng trong code (`main` @ `474fa28`): `main.dart` tạo đúng một `SessionStore(Directory('…/session'))`;
`ReviewScreen` là màn duy nhất, tiêu đề cố định "X-Scanner"; `ScanSession` không có id/tên/thời điểm.

## 2. Outcome, baseline, target và guardrails

- Baseline: 1 phiên không tên; bản cập nhật app chưa có đường đổi bố cục dữ liệu.
- Target: thư viện gồm nhiều **tài liệu** (hợp đồng XS-08 FR-1), mỗi tài liệu mở ra màn xem lại P1; dữ liệu P1 hiện có
  được chuyển thành **một** tài liệu khi mở bản mới lần đầu, không mất bản gốc hay chỉnh sửa nào.
- Guardrails (kế thừa, không nới): bản gốc không bị ghi đè, không bị xoá khi chưa có manifest đã lưu không tham chiếu nó
  (TRAPS F-001); không log/hiển thị tiêu đề, đường dẫn, nội dung trang; không mạng; không thêm dependency; mọi luồng P1
  (chụp, nhập, sắp xếp, chỉnh góc, xoay, xuất) giữ nguyên hành vi trong một tài liệu.

## 3. Research current state

- `SessionStore` (`lib/storage/session_store.dart`): một gốc thư mục, ghi manifest nguyên tử (`.tmp` → rename), copy bản
  gốc qua `.part` + flush + rename, cách ly manifest hỏng thành `session.corrupt-{ms}.json`, xoá bản gốc mồ côi chỉ sau
  `load` thành công và không còn bản cách ly. Toàn bộ thao tác tuần tự hoá trong một hàng đợi.
- `session_manifest.dart`: codec schema 1; `decodeManifest` ném `FormatException` khi `schemaVersion` ≠ 1 → bị cách ly
  (XS-08 FR-7 sửa).
- `SessionController`: một phiên, hàng đợi ghi, cache thumbnail theo `page.id`, `DecodeGate` chung với xuất.
- Hợp đồng XS-08 đã duyệt: `ScanDocument {id, title, createdAt, updatedAt, pages}`, `revision` mỗi trang, `document.json`
  schema 2, đọc schema 1 với id/title/createdAt do bên gọi cung cấp, schema mới hơn → "cần cập nhật app".
- Kế hoạch §6.1: ghi đích ra khu vực tạm, kiểm đủ trang/recipe, chuyển trạng thái khi hợp lệ, giữ đường quay lại; dùng nhật
  ký/commit marker, kiểm phục hồi sau khi dừng ở từng bước. §4.1/§13: SQLite là ứng viên, cần ADR riêng.

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | Không tốn gì | Không đạt mốc M1 (nhiều tài liệu) | Loại |
| A. Mỗi tài liệu một thư mục `documents/{docId}/` (`document.json` + `originals/`); danh sách = quét `documents/*/document.json`; tái dùng logic `SessionStore` cho từng thư mục | Hỏng một tài liệu không lan sang tài liệu khác; xoá tài liệu (XS-10) = xoá một thư mục; không có chỉ mục phải giữ khớp; dùng lại code + test P1 | Mở thư viện đọc N file nhỏ; `DEBT:` khi N lớn | **Đề xuất** |
| B. Chung `originals/` + một `library.json` chỉ mục | Một file đọc khi mở thư viện | Chỉ mục và manifest có thể lệch; một file hỏng làm mất cả thư viện; xoá phải dọn chéo | Loại |
| C. SQLite cho metadata + file cho ảnh | Truy vấn/tìm kiếm, chỉ mục OCR sau này | Dependency mới (ngoài D2), hai loại migration cùng lúc, transaction DB không bảo vệ thao tác file (kế hoạch §6.1) | Loại ở XS-09; xét ở XS-22 bằng ADR riêng |

Migration: **copy rồi kiểm** (chọn) thay vì **di chuyển (rename) từng file**. Rename không cần thêm dung lượng nhưng giữa
chừng dữ liệu nằm ở cả hai bố cục, phục hồi phải lần theo từng file; copy giữ nguyên bản cũ đọc được cho tới khi bản mới
đã kiểm đủ (kế hoạch §6.1), đổi lại cần dung lượng trống bằng tổng bản gốc (FR-6 kiểm trước).

## 5. Scope / non-goals

- Trong phạm vi: mô hình + codec schema 2 (hợp đồng XS-08); lưu trữ theo tài liệu; migration P1 → một tài liệu; màn thư
  viện (danh sách, tạo, mở, đổi tên); đưa màn xem lại P1 thành màn của một tài liệu.
- Không làm ở XS-09: xoá tài liệu/thùng rác, màn phục hồi tài liệu hỏng (XS-10); tìm theo tên, thẻ, nhân bản, gộp/tách
  (sau XS-10, spec riêng); thumbnail theo revision (XS-13); tác vụ xuất có tiến độ (XS-12); SQLite; OCR.

## 6. User journeys và mọi state

1. **Mở bản mới lần đầu, có dữ liệu P1.** Màn chờ "Đang nâng cấp dữ liệu…" → thư viện có 1 tài liệu (tên mặc định D-2,
   đúng số trang). Lỗi (vd thiếu bộ nhớ) → thông báo lỗi + "Thử lại"; dữ liệu P1 còn nguyên, không có tài liệu dở.
2. **Thư viện.** Trạng thái: đang tải · rỗng ("Chưa có tài liệu" + nút "Tài liệu mới") · lỗi đọc (thông báo + "Thử lại")
   · có dữ liệu (danh sách mới sửa trước). Mỗi mục: tên, số trang, ngày sửa (giờ máy); mục không mở được hiện "Không mở
   được tài liệu này" (bản gốc vẫn giữ); mục của bản app mới hơn hiện "Cần cập nhật app để mở".
3. **Tài liệu mới.** Tạo tài liệu rỗng tên mặc định → mở màn xem lại của tài liệu đó (giữ mọi hành vi P1).
4. **Đổi tên.** Hộp thoại có giá trị cũ; lỗi tại chỗ khi rỗng/> 120 ký tự/có ký tự điều khiển; "Huỷ" giữ tên cũ; lỗi lưu →
   tên cũ + thông báo "Không lưu được".
5. **Quay lại thư viện** từ màn tài liệu: danh sách phản ánh tên, số trang, ngày sửa mới.

## 7. Functional requirements

- **FR-1 Mô hình và codec.** Hiện thực XS-08 FR-1..FR-3, FR-6, FR-7 và §12.1/§13: `ScanDocument`, `ScanPage.revision`,
  `document.json` schema 2, đọc schema 1, kết quả "cần cập nhật app".
- **FR-2 Bố cục.** Gốc dữ liệu `documents/`; mỗi tài liệu `documents/{docId}/document.json` + `documents/{docId}/originals/
  {pageId}.{ext}`. `docId` là tên thư mục và phải bằng `document.id` trong file (khác → coi như hỏng). Đường dẫn bản gốc
  trong manifest vẫn là `originals/{pageId}.{ext}`, tương đối với thư mục tài liệu.
- **FR-3 Lưu trữ theo tài liệu.** `DocumentStore` giữ mọi bảo đảm của `SessionStore` (ghi nguyên tử, tuần tự, cách ly
  manifest hỏng ngay trong thư mục tài liệu, không xoá bản gốc của tài liệu có bản cách ly) cho từng thư mục tài liệu.
  Tạo tài liệu = tạo `documents/{docId}.part/` với `document.json` rồi rename thành `documents/{docId}/`.
- **FR-4 Thư viện.** Liệt kê mọi `documents/{docId}/` (bỏ qua `*.part`, xoá `*.part` mồ côi khi không có migration đang
  dở); mỗi mục là `Loaded(document)` · `NeedsUpdate` · `Unreadable`; sắp theo `updatedAt` giảm dần, hoà thì theo `id`.
  Đọc lỗi I/O cả thư mục → trạng thái lỗi của thư viện, không xoá gì.
- **FR-5 Đổi tên và cập nhật thời điểm.** Đổi tên kiểm theo XS-08 FR-1 (trim, 1–120, không ký tự điều khiển) cả khi nhập
  lẫn khi đọc; mọi lần lưu có đổi trang hoặc tên đặt `updatedAt = now (UTC)`.
- **FR-6 Migration P1.** Chạy trước khi hiện thư viện, khi `session/session.json` tồn tại:
  1. Đọc schema 1 (hỏng → giữ nguyên `session/`, thư viện hiện như bình thường kèm thông báo "Không chuyển được phiên cũ",
     không xoá gì; phục hồi ở XS-10).
  2. Ghi nhật ký `migration.json` (`{"state":"copying","docId":…}`) nguyên tử; `docId` mới chỉ sinh một lần.
  3. Kiểm dung lượng trống ≥ tổng kích thước bản gốc + 10 % (không đủ → lỗi `insufficientSpace`, xoá nhật ký, giữ `session/`).
  4. Copy từng bản gốc vào `documents/{docId}.part/originals/`, flush; ghi `document.json` schema 2 (trang revision 0,
     `title` theo D-2, `createdAt` = thời điểm sửa của `session.json` theo UTC, `updatedAt` = `createdAt`).
  5. Kiểm: đọc lại `document.json` bằng codec, cùng số trang, cùng thứ tự id, cùng `quad`/`quarterTurns`, từng bản gốc có
     **cùng kích thước và cùng byte** với bản P1 (D-3: so byte, không hash).
  6. Rename `documents/{docId}.part` → `documents/{docId}` (commit), rồi nhật ký `committed`.
  7. Rename `session/` → `session.migrated/` (bản quay lại) rồi xoá nhật ký. `session.migrated/` được **giữ**, không code nào
     tự xoá (D-5); xoá bản quay lại là quyết định của chủ repo cùng XS-10.
- **FR-7 Phục hồi migration.** Lúc khởi động, theo nhật ký: `copying` + chỉ có `.part` → xoá `.part`, chạy lại từ bước 3 với
  cùng `docId`; `copying` + đã có `documents/{docId}` (đã kiểm trước khi rename) → coi là `committed`; `committed` → làm bước
  7. Không bao giờ tạo tài liệu thứ hai cho cùng dữ liệu P1, không xoá `session/` trước bước 6.
- **FR-8 Màn tài liệu.** `ReviewScreen` nhận một tài liệu: tiêu đề AppBar = tên tài liệu, nút quay lại thư viện, "Xoá hết"
  chỉ xoá trang của tài liệu này (giữ hành vi P1), tên file xuất giữ quy ước P1.
- **FR-9 Revision.** `withQuad`/`rotatedClockwise` tăng `revision` (XS-08 FR-3); cache thumbnail vẫn theo `page.id`
  (XS-13 đổi sang revision) — không đổi hành vi hiển thị ở XS-09.

## 8. Non-functional requirements

- Độ bền: mỗi bước ghi đều nguyên tử (tmp + rename) hoặc lặp lại được; dừng ở bất kỳ bước nào không mất trang (kế hoạch §11
  "0 mất trang/gốc").
- Riêng tư: tiêu đề là dữ liệu người dùng — không log, không đưa vào `FormatException`/thông báo lỗi.
- Hiệu năng: mở thư viện đọc tối đa N `document.json` nhỏ; `DEBT:` khi N > 500 hoặc mở thư viện > 1 s trên thiết bị P2.
- A11y: nhãn đọc màn hình cho mỗi mục (tên, số trang, ngày), vùng chạm ≥ 48 dp, AA ở Dark/Light, không chỉ dùng màu.
- Không dependency mới; định dạng ngày tự viết (không `intl`).

## 9. Acceptance criteria

- **AC-1** (XS-08 AC-1) Given một tài liệu hợp lệ, when mã hoá schema 2 rồi giải mã, then mọi trường giữ nguyên.
- **AC-2** (XS-08 AC-2) Given manifest schema 1 của P1, when đọc với id/title/createdAt do bên gọi đưa, then ra một tài liệu
  đúng thứ tự trang, mọi revision 0.
- **AC-3** (XS-08 AC-3) Given trường không hợp lệ (title, revision, thời điểm, `updatedAt < createdAt`), when giải mã, then
  `FormatException` chỉ nêu tên trường, không chứa giá trị người dùng.
- **AC-4** (XS-08 AC-4) Given `document.json` có `schemaVersion` lớn hơn bản app biết, when mở thư viện, then mục đó là
  "Cần cập nhật app", file không bị đổi tên, không bản gốc nào bị xoá.
- **AC-5** (XS-08 AC-5) Given trang revision n, when `withQuad`/`rotatedClockwise`, then revision n + 1, id/`originalPath`
  không đổi; chụp lại → id mới revision 0.
- **AC-6** Given dữ liệu P1 có k trang (k = 0, 1, 3) với quad/xoay khác nhau, when mở bản mới, then thư viện có đúng một tài
  liệu k trang, cùng thứ tự, cùng quad/xoay, từng bản gốc trùng byte, `session/` thành `session.migrated/`.
- **AC-7** Given migration bị dừng (lỗi I/O tiêm vào) ở mỗi bước 2–7, when mở lại app, then cuối cùng có đúng một tài liệu
  đủ trang **hoặc** dữ liệu P1 còn nguyên và đọc được; không bao giờ có hai tài liệu cho cùng dữ liệu, không mất bản gốc.
- **AC-8** Given dung lượng trống không đủ (giả lập), when migration, then lỗi "không đủ bộ nhớ" có "Thử lại", `session/`
  không đổi, không thư mục `documents/*` nào được tạo.
- **AC-9** Given `session.json` P1 hỏng, when mở bản mới, then `session/` giữ nguyên, thư viện vẫn dùng được, có thông báo
  "Không chuyển được phiên cũ".
- **AC-10** Given `document.json` của một tài liệu hỏng hoặc `id` khác tên thư mục, when mở thư viện, then chỉ mục đó là
  "Không mở được", các tài liệu khác mở bình thường, bản gốc của nó còn nguyên.
- **AC-11** Given thư viện rỗng/đang tải/lỗi/có dữ liệu, then mỗi trạng thái hiện đúng nội dung §6, sắp theo `updatedAt`
  giảm dần, đọc được bằng TalkBack (semantics) ở Dark và Light.
- **AC-12** Given "Tài liệu mới", then có tài liệu rỗng tên mặc định, mở thẳng màn tài liệu; given đổi tên không hợp lệ, then
  báo lỗi tại chỗ, tên cũ giữ nguyên; given đổi tên hợp lệ, then tên + `updatedAt` mới được lưu và hiện ở thư viện.
- **AC-13** Given một tài liệu, when chạy lại các luồng P1 (AC-1..AC-8 của spec P1) trong tài liệu đó, then hành vi như P1;
  sửa tài liệu này không đổi tài liệu khác.
- **AC-14** Given một migration thành công, when mở lại app (kể cả nhiều lần) và tài liệu migrate được tải, then
  `session.migrated/` còn nguyên, cùng mọi bản gốc trong đó (D-5: không tự xoá).

## 10. UX/content/accessibility

Chuỗi (vi): "Thư viện", "Tài liệu mới", "Chưa có tài liệu", "Đổi tên", "Tên tài liệu", "Tên không được để trống",
"Tên tối đa 120 ký tự", "Tên có ký tự không hợp lệ", "Đang nâng cấp dữ liệu…", "Không đủ bộ nhớ để nâng cấp dữ liệu. Hãy giải
phóng bộ nhớ rồi thử lại.", "Không chuyển được phiên cũ. Ảnh gốc vẫn được giữ trong bộ nhớ của app.", "Không mở được tài liệu
này", "Cần cập nhật app để mở", "{n} trang". Màu qua theme hiện có (không hard-code), Dark mặc định + Light.

## 11. Architecture và code touchpoints

| Thay đổi | File |
| --- | --- |
| `ScanDocument`, `revision` | `lib/core/scan_document.dart` (mới), `lib/core/scan_page.dart`, `lib/core/scan_session.dart` (thay bằng `ScanDocument` hoặc bọc) |
| Codec schema 1/2, "cần cập nhật app" | `lib/core/session_manifest.dart` (PR-1 thêm schema 2 vào file này; đổi tên thành `document_manifest.dart` ở PR-4, khi `SessionStore` được thay) |
| Lưu trữ theo tài liệu | `lib/storage/session_store.dart` → `lib/storage/document_store.dart` (gốc = thư mục tài liệu) |
| Thư viện + tạo/đổi tên | `lib/storage/library_store.dart` (mới), `lib/ui/library_controller.dart` (mới), `lib/ui/library_screen.dart` (mới) |
| Migration + nhật ký + phục hồi | `lib/storage/p1_migration.dart` (mới) |
| Màn tài liệu | `lib/ui/review_screen.dart`, `lib/ui/session_controller.dart` (nhận `DocumentStore` + tài liệu) |
| Nối app | `lib/main.dart` (migration → thư viện; một `DecodeGate` chung) |

Hướng phụ thuộc giữ nguyên (`CODEMAP.md`): `ui` → `storage`, `core`; `storage` → `core`; `core` thuần Dart.

## 12. API/event contract

```dart
sealed class LibraryEntry { String get docId; }
final class LibraryDocument extends LibraryEntry { ScanDocument get document; }
final class LibraryNeedsUpdate extends LibraryEntry {}
final class LibraryUnreadable extends LibraryEntry {}

sealed class MigrationOutcome {}
final class MigrationNotNeeded extends MigrationOutcome {}
final class MigrationDone extends MigrationOutcome { String get docId; }
final class MigrationSourceUnreadable extends MigrationOutcome {}   // AC-9
final class MigrationFailed extends MigrationOutcome { MigrationFailure get reason; } // insufficientSpace | io

abstract interface class Storage {   // seam để tiêm lỗi I/O ở từng bước (AC-7)
  Future<int> freeBytes(Directory dir);
}
```

Không có API mạng. Lỗi trả về là enum đóng, không mang đường dẫn/tiêu đề.

## 13. Data contract/migration

- Schema: `document.json` schema 2 đúng XS-08 §13. `migration.json`: `{"version":1,"state":"copying"|"committed","docId":"<32 hex>"}`.
- Bố cục sau migration: `documents/{docId}/document.json`, `documents/{docId}/originals/*`, `session.migrated/` (bản quay lại, giữ — D-5).
- Ownership/retention: tài liệu tồn tại tới khi XS-10 cho xoá; `session.migrated/` giữ tới khi chủ repo quyết cùng XS-10 (D-5, AC-14).
- Verify: so số trang, thứ tự id, recipe, kích thước + byte từng bản gốc (FR-6 bước 5).
- Compatibility: bản app chỉ biết P1 sẽ không thấy dữ liệu sau migration (`session/` đã đổi tên) — chấp nhận vì P1 chưa
  phân phối; bản quay lại `session.migrated/` có thể đổi tên tay về `session/`.
- Recovery: FR-7; không bao giờ xoá dữ liệu người dùng để giải quyết lỗi migration (kế hoạch §10).

## 14. Security/privacy/abuse cases

- `document.json` và `migration.json` là đầu vào không tin cậy: mọi trường kiểm như XS-08; `docId` chỉ 32 hex (chống path
  traversal qua tên thư mục); bản gốc chỉ `originals/{pageId}.{ext}` của chính trang đó.
- Không theo symlink khi liệt kê/copy (`followLinks: false`).
- Tiêu đề không vào log, lỗi, tên file xuất.

## 15. Observability và operations

Không telemetry (offline, không mạng). Trạng thái lỗi hiển thị bằng mã đóng; không log nội dung.

## 16. Test/eval plan

Unit thuần (codec, mô hình), test lưu trữ trên thư mục tạm, test migration với `Storage` tiêm lỗi ở từng bước (fault
injection), widget test thư viện (4 trạng thái, semantics, Dark/Light), chạy lại toàn bộ test P1 trên màn tài liệu. Mỗi hành
vi có test đỏ trước (ADR-0005).

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | chưa có — PR-1 | `test/core/` |
| AC-2 | chưa có — PR-1 | fixture schema 1 từ test P1 |
| AC-3 | chưa có — PR-1 | |
| AC-4 | chưa có — PR-2 | `test/storage/` |
| AC-5 | chưa có — PR-1 | |
| AC-6 | chưa có — PR-3 | |
| AC-7 | chưa có — PR-3 | tiêm lỗi từng bước 2–7 |
| AC-8 | chưa có — PR-3 | |
| AC-9 | chưa có — PR-3 | |
| AC-10 | chưa có — PR-2 | |
| AC-11 | chưa có — PR-4 | widget test |
| AC-12 | chưa có — PR-4 | |
| AC-13 | chưa có — PR-4 | test P1 chạy trên màn tài liệu |
| AC-14 | chưa có — PR-3 | |

## 17. Slice/PR plan

Tuần tự (cùng lớp lưu trữ), mỗi PR một outcome, app vẫn chạy bố cục P1 tới PR-4:

- PR-1: mô hình + codec schema 1/2 + revision (AC-1, AC-2, AC-3, AC-5). Không nối vào app.
- PR-2: `DocumentStore` + `LibraryStore` (AC-4, AC-10). Không nối vào app.
- PR-3: migration + nhật ký + phục hồi + tiêm lỗi (AC-6..AC-9, AC-14). Không nối vào app.
- PR-4: màn thư viện + màn tài liệu + nối `main.dart` (AC-11..AC-13). **Chỉ PR này đổi hành vi** — chờ chủ repo duyệt (Approval).

## 18. Rollout/rollback

Bản nội bộ (P1 chưa phân phối). PR-4 là công tắc duy nhất; revert PR-4 trước khi có ai chạy bản mới thì không có migration.
Sau khi đã migrate, quay về bản P1 cần đổi tên tay `session.migrated/` → `session/` (D-5: thư mục này được giữ). Không feature flag
(ít cấu hình hơn; chưa phân phối).

## 19. Risk, assumptions và open decisions

| Item | Verification/mitigation | Owner | Due | Decision |
| --- | --- | --- | --- | --- |
| D-2 Tên mặc định: "Tài liệu {dd/MM/yyyy HH:mm}" theo giờ máy lúc tạo; tài liệu migrate dùng thời điểm sửa của `session.json` | AC-12, AC-6 | Phiên chính | 2026-10-12 | **Chốt** như trên (bậc 2: không cần chuỗi định dạng mới; đổi được ở PR-4 nếu chủ repo muốn) |
| D-3 Kiểm bản gốc khi migrate: so kích thước + byte, không hash | FR-6 bước 5; không cần `package:crypto` | Phiên chính | 2026-10-12 | **Chốt** so byte (bậc 2: không dependency mới; chặt hơn hash cho mục đích kiểm copy) |
| D-4 Xoá tài liệu: để XS-10 (thùng rác có hạn giữ) hay thêm "xoá vĩnh viễn có xác nhận" ngay ở XS-09 | Kế hoạch §6.1 đòi thùng rác thấy được | Phiên chính | 2026-10-12 | **Chốt** để XS-10 (bậc 1: xoá là thao tác phá dữ liệu; bậc 2: ít code hơn) |
| D-5 Bản quay lại `session.migrated/`: giữ, không tự xoá (thay đề xuất nháp "xoá ở lần mở sau") | AC-14; tốn gấp đôi dung lượng tới khi chủ repo quyết | Phiên chính | 2026-10-12 | **Chốt** giữ (bậc 1: tự xoá dữ liệu thật là việc §3d không tự quyết; bậc 2: bớt một nhánh code). Xoá → chủ repo, cùng XS-10 |
| Bố cục mỗi tài liệu một thư mục (§4 A) | AC-10 | Phiên chính | 2026-10-12 | Chốt (ADR-0011) |
| Copy rồi kiểm thay vì rename | AC-7, AC-8; cần dung lượng gấp đôi lúc migrate | Phiên chính | 2026-10-12 | Chốt (ADR-0011) |
| Giả định: P1 chưa phân phối nên không cần đường downgrade tự động | §18 | Chủ repo | Trước PR-4 | Mở — chặn PR-4, không chặn PR-1..PR-3 (không nối vào app) |

D-2..D-5 đã chốt. Giả định downgrade và việc bật migration trên dữ liệu thật (PR-4) chờ chủ repo.

## Approval

- [x] Product/scope — PR-1..PR-3
- [ ] UX/a11y — PR-4, chủ repo
- [x] Architecture/API/data — ADR-0011
- [x] Security/privacy/cost — §14; không dependency, không chi phí
- [x] Test/telemetry/rollout/rollback — §16; PR-4 là công tắc duy nhất (§18)
- [x] Blocking decisions closed (D-2..D-5) — cho PR-1..PR-3

**Conclusion:** **Approved for implementation** — phạm vi PR-1..PR-3 (không nối vào app, không chạm dữ liệu thật); PR-4 chờ
chủ repo
**Approver/date:** Phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12
