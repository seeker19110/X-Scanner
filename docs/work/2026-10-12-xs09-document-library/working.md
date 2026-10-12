# Công việc: XS-09: thư viện nhiều tài liệu và migration P1 (PR-1..PR-3)

- Work ID: 2026-10-12-xs09-document-library
- Yêu cầu / outcome: `/auto-complete` lần 8 (2026-10-12): hiện thực XS-09 PR-1..PR-3 theo spec Approved (#30 `508f057`) — mô hình + codec schema 2, `DocumentStore`/`LibraryStore`, migration P1 có nhật ký + tiêm lỗi; không nối vào app.
- Trạng thái: In progress — PR-1 (#31), PR-2 (#32) merged; PR-3 (migration) đang review.
- Chủ trì / writer: phiên chính (kế hoạch, review, tích hợp, cổng); mỗi PR một worker `complex-implementer`, tuần tự.
- Mức rủi ro / số PR: L (spec XS-09); 3 PR tuần tự vì cùng lớp `core`/`storage` (spec §17). PR-4 (nối app, migration dữ liệu thật) BLOCKED chờ chủ repo.
- Scope / non-goal: AC-1..AC-10, AC-14 của spec. Non-goal: UI thư viện, `main.dart`, chạy migration trên dữ liệu thật (PR-4); xoá tài liệu/thùng rác (XS-10).
- Spec / goal / issue: `docs/specs/2026-10-12-document-library-migration.md` · ADR-0011 · hợp đồng XS-08/ADR-0004 · hồ sơ spec `docs/work/2026-10-12-xs09-document-library-spec/done.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `d691d68` · 2026-10-12T13:32:15Z

## Kế hoạch và phân công

- PR-1 `route: complex`: `ScanPage.revision`, `lib/core/scan_document.dart`, codec schema 2 trong `session_manifest.dart` (AC-1, AC-2, AC-3, AC-5; phần codec của AC-4). Brief PLAN qua `subagent-dispatch.sh --check-plan` (exit 0).
- PR-2 (sau PR-1 merge): `DocumentStore` + `LibraryStore` (AC-4, AC-10).
- PR-3 (sau PR-2 merge): migration + nhật ký + phục hồi + tiêm lỗi (AC-6..AC-9, AC-14).
- Nhánh duy nhất `claude/admiring-mccarthy-5b360i`, mỗi PR mở sau khi PR trước merge.

## Quyết định và bằng chứng

- PR-1 giao một worker `complex-implementer` cho cả T1+T2 · loại hai worker · bậc 2 (T2 phụ thuộc T1, cùng lớp `core`; một PR).
- Đọc schema 1 thành tài liệu không thêm hàm (`decodeManifest` + constructor `ScanDocument`) · loại `decodeSchema1Document(...)` · bậc 2 (thang §3.4 nấc 2: dùng lại).
- `ScanDocument` kiểm trùng id trang qua `ScanSession(pages:)` · loại viết lại kiểm trùng · bậc 2.
- Không `copyWith`/`==` ở PR-1 · loại thêm sẵn · bậc 2 (chưa có caller; PR-2 thêm khi cần).
- Giữ hai lựa chọn worker thêm ngoài brief: đọc thời điểm kiểm lịch chặt (`DateTime.tryParse` lăn `02-30` thành `03-02`) và `encodeDocument` từ chối năm ngoài 0000–9999 · loại bỏ đi cho đúng brief · bậc 1 (đọc ngày sai thành ngày khác là sai dữ liệu; ghi file không đọc lại được vi phạm "unreadable manifest is never written").
- Ca AC-3 title 121 rune dùng `'SECRET-TITLE' + 'x'*109` thay mẫu brief (mẫu brief kết thúc bằng dấu cách nên rơi vào luật trim, không thử luật độ dài) · bậc 3 (test chứng minh đúng luật).
- PR-1 worker: đỏ-trước có output (T1 `+48 -19`, T2 `+45 -38` với stub; compile đỏ trước đó), xanh `flutter test test/core/ test/ui/session_controller_test.dart` +191; gate worker PASS (+349) trên `d691d68` + diff; log ở scratchpad phiên.
- Review PR-1 (`reviewer`): 0 Cao/Trung bình; 3 Thấp. F1 (thiếu ca giờ 24/phút 60/giây 60/7 chữ số thập phân + ngày nhuận hợp lệ) và F2 (title có dấu cách đầu/cuối, U+007F qua `decodeDocument`) đã thêm test; kiểm đột biến (bỏ so giờ/phút/giây) → 2 ca đỏ, ca giờ 24 vẫn bị chặn nhờ so ngày. F3 (AC-2 qua `decodeManifest` + constructor, không API riêng) giữ — đúng FR-6, ghi ở mô tả PR.
- PR-1 merged #31 `c1bdcad` (CI "Framework and Android app gate" xanh trên `3cac07d`).
- PR-2: `DocumentStore` = bản chép `SessionStore` + `DEBT:` · loại `ManifestStore<T>` chung · bậc 2 (PR-4 xoá `SessionStore` vì migration không được dùng `SessionStore.load` — nó cách ly manifest hỏng, trái FR-6 bước 1; trừu tượng chung sẽ thừa sau PR-4) rồi bậc 1 (không đụng `SessionStore` đang chạy P1).
- PR-2: dọn `{id}.part` mồ côi của thư viện để PR-3 (cần biết nhật ký migration) · loại xoá trong `list()` · bậc 1 (`list()` chỉ đọc; `.part` có thể là migration đang dở).
- PR-2: thiếu `document.json` → `DocumentUnrecoverable(null)` · loại thêm kiểu `DocumentMissing` · bậc 2.
- PR-2: các mục không đọc được xếp sau tài liệu, theo docId · loại trộn theo thời gian (không có `updatedAt`) · bậc 3 (thứ tự xác định, test được).
- PR-2 worker: đỏ-trước với stub `UnimplementedError` (T1 `+0 -32`, T2 `+0 -16`), xanh `test/storage/` +75, gate PASS +405 trên `a5983ae` + diff; Tầng 1 đối chiếu `diff session_store.dart document_store.dart`: chỉ 4 khác biệt của brief.
- Rà bảo mật PR-2 (`security-reviewer`): 0 Cao. Sửa đỏ-trước (3 test đỏ → xanh, `test/storage/` +78): F1 Trung bình — `open()` tạo nhiều `DocumentStore` trên cùng thư mục (hàng đợi/`_saved` tách rời → ghi đè lẫn nhau, xoá bản gốc) → một store mỗi docId, `create` trả đúng instance đó, hợp đồng "một chủ mỗi tài liệu, màn thư viện chỉ `list()`" ghi ở doc; F2 Thấp — `importOriginal` tạo thư mục tài liệu thiếu manifest → `StateError` khi thư mục chưa có; F4 Thấp — `_load` giữ `_saved` cũ khi tải lại ra NeedsUpdate/lỗi → đặt lại `{}`; F6 Thấp — doc comment nói sai về đường dẫn trong lỗi → sửa. Không sửa: F3 TOCTOU `create` (id ngẫu nhiên 128 bit, cửa sổ rất hẹp; sau F1 mọi lệnh trên một tài liệu đi qua một store), F5 symlink trong thư mục riêng của app (cần đã chiếm app; giống `SessionStore`), F7 không trần kích thước `document.json` khi liệt kê (file do app tự ghi; xem lại khi PR-4 đo thời gian mở thư viện, spec §8 `DEBT` N > 500).
- PR-2 merged #32 `8aa493e` (CI xanh trên `29be4c7`).
- PR-3 brief: dọn `.part` mồ côi (FR-4) đặt ở cuối `P1Migration.run` · loại trong `LibraryStore` · bậc 1 (chỉ migration biết nhật ký còn mở hay không).
- PR-3: lỗi sau khi commit (ghi nhật ký `committed`, bước 7) trả `MigrationDone` · loại `MigrationFailed` · bậc 1 (tài liệu đã kiểm byte và commit; báo lỗi sẽ chặn thư viện vô ích, lần sau làm nốt bước 7).
- PR-3: nhật ký hỏng → `MigrationFailed(io)`, không đổi gì · loại xoá nhật ký/đoán · bậc 1 (kế hoạch §10: không xoá dữ liệu để giải quyết lỗi); đổi lại kẹt tới khi XS-10 có màn phục hồi.
- PR-3: bản quay lại thứ hai đặt `session.migrated-2`… · loại ghi đè/xoá `session.migrated` · bậc 1 (D-5).
- PR-3: kiểm thử chết-giữa-chừng bằng một `Error` riêng ném ở lệnh đổi đĩa thứ i (code chỉ bắt `FileSystemException`, nên không khối dọn nào chạy) · loại hook test trong code chạy thật · bậc 2 + bậc 3.
- PR-3 worker: đỏ-trước (T1 compile đỏ; T2 stub `+0 -36`), xanh 61 test, gate PASS +448 trên `3cc71cd` + diff; AC-7: 19 lệnh đổi đĩa × {kill, I/O} = 38 ca; kiểm đột biến 2 kiểu → 3 và 6 test đỏ. Tầng 1 đọc toàn bộ `p1_migration.dart`: mọi `catch` đúng kiểu, không nhánh nào xoá `session/`/`session.migrated*`; thay `print` trong test bằng `expect(ops, hasLength(19))`.
- PR-3 ba chỗ worker tự chọn (giữ, bậc 1): `FileSystemException` khi đọc nguồn → `MigrationFailed(io)` không đổi gì; thiếu dung lượng cũng xoá `.part` cũ của chính migration; `freeBytes` ném lỗi khác `FileSystemException` thì ném ra (PR-4 bảo đảm hàm nền tảng chỉ ném `FileSystemException`).
- Rà bảo mật PR-3 (`security-reviewer`, có PoC): 0 Cao; không đường nào mất byte bản gốc. Sửa đỏ-trước (6 test đỏ → xanh, `test/storage/` +118): F1 Trung bình — phục hồi tin nhật ký `committed`/thư mục tồn tại mà không kiểm (đĩa không giữ thứ tự rename → `session/` bị cất, `.part` đã kiểm bị xoá, thư viện rỗng) → `_isComplete` kiểm `document.json` đúng id + mọi bản gốc là file thường; không đạt: còn `session.json` thì copy lại (bước 6 không đè), không còn thì `MigrationFailed(io)` không đổi gì; F3 Thấp — `migration.json.tmp` mồ côi → dọn ở `_finish`/`_abandon` (chỉ khi có, giữ 19 lệnh); F4 Thấp — `session/` hoặc `session/originals` là link → `MigrationSourceUnreadable`; khe test a (nhánh chết `NotNeeded` trong `expectFinal`) bỏ, khe d (kiểm `.tmp`) thêm, khe c (3 ca nhật ký/đĩa mâu thuẫn) thêm. Không làm: khe b lỗi kép (đọc mã: thứ tự `.part` rồi nhật ký an toàn; lần chạy lại idempotent).
- Cho PR-4 (từ rà PR-3, F5): `Storage.freeBytes` nền tảng chỉ ném `FileSystemException`; gọi `run()` qua một `Future` dùng chung (không chạy song song); `MigrationFailed` do nhật ký hỏng lặp mãi → vẫn cho vào thư viện kèm thông báo; `session/` không có `session.json` (bị cách ly ở P1) → `MigrationNotNeeded`, bản gốc nằm lại tới XS-10.

## Lần thử / blocker

- PR-4 BLOCKED (§3d): bật migration trên dữ liệu thật + giả định "P1 chưa phân phối" chờ chủ repo.

## Bàn giao / bước tiếp theo

- PR-1: worker đang sửa `apps/mobile/lib/core/` + `test/core/`, `test/ui/session_controller_test.dart` (chưa commit, trong cây làm việc). Xong → review diff, `reviewer`, gate, commit `feat:`, PR, CI, merge; rồi brief PR-2.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
