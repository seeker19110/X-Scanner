# CONVENTIONS — Sổ quy ước X-Scanner

> Mỗi pattern lặp lại có MỘT cách đúng duy nhất. Tính năng mới và mọi lần sửa phải đối chiếu.
> Lệch quy ước = phát hiện Nhóm 12 khi audit. Đổi quy ước lớn → ghi ADR.
> Lập 2026-10-12 từ code `apps/mobile/lib` @ `6177e29`.

| Pattern | Cách đúng duy nhất | File ví dụ chuẩn | Ghi chú |
|---------|--------------------|------------------|---------|
| Thay đổi phiên | Mọi thao tác ghi đi qua hàng đợi `_enqueue`; trạng thái trong RAM chỉ đổi **sau** khi `SessionStore.save` thành công (`_commit`) | `lib/ui/session_controller.dart` | |
| Báo lỗi cho người dùng | Bắt kiểu lỗi cụ thể → `SessionNotice` → câu tiếng Việt ở một `switch` duy nhất; không đưa đường dẫn/nội dung, không log | `session_controller.dart` `_report`, `lib/ui/review_screen.dart` `_message` | Thêm notice mới = thêm nhánh `switch` (analyzer bắt thiếu) |
| Validate dữ liệu ngoài | Biên đọc file ném `FormatException` chỉ nêu tên trường; constructor lõi ném `ArgumentError` | `lib/core/session_manifest.dart`, `lib/core/page_quad.dart` | |
| Kiểu lõi | Bất biến, thao tác trả bản mới, không I/O, không import Flutter | `lib/core/scan_session.dart`, `lib/core/scan_page.dart` | `test/core/core_purity_test.dart` |
| Ghi file bền | Ghi `.tmp`/`.part` → flush/fsync → rename; không ghi đè bản gốc | `lib/storage/session_store.dart` `importOriginal`, `_save` | |
| Không xoá bản gốc | Chỉ xoá bản gốc khi một manifest **đã lưu** không còn tham chiếu nó; khi nghi ngờ (manifest hỏng/không đọc được) thì giữ | `session_store.dart` `_load`, `_deleteUnreferencedOriginals` | CLAUDE.md: never discard scan originals |
| Xoá best-effort | `_deleteQuietly` chỉ nuốt `FileSystemException`, dùng sau khi trạng thái chính đã bền | `session_store.dart`, `lib/export/page_exporter.dart` | |
| Xử lý ảnh nặng | Giải mã trong `Isolate.run` ở `lib/imaging/`; lỗi giải mã → `ImageDecodeFailure` không mang nội dung; có trần `maxDecodedPixels` | `lib/imaging/page_render.dart` | Mọi lần giải mã bản gốc đi qua **một** `DecodeGate` (`lib/imaging/decode_gate.dart`), tạo ở `main.dart` |
| Phụ thuộc nền tảng | Interface + adapter tiêm qua constructor để test dùng fake | `lib/ui/page_source.dart`, `lib/export/file_sharer.dart` | Nối thật ở `lib/main.dart` |
| Hành động phá huỷ | Luôn qua hộp xác nhận `_confirm(question, label)` | `review_screen.dart` | |
| Trạng thái bận | Khi `controller.busy`, mọi nút **và kéo-thả** đều tắt; một `LinearProgressIndicator` cố định 4 dp | `review_screen.dart` `build` | `buildDefaultDragHandles: !busy` |
| Trạng thái màn | Đủ 4 trạng thái: đang tải / rỗng / lỗi (SnackBar) / có dữ liệu | `review_screen.dart` | Đang tải khi khôi phục: `controller.restoring` → "Đang mở phiên…" |
| Màu / theme | Chỉ `Theme.of(context).colorScheme`; seed duy nhất ở `lib/app/theme.dart`; mặc định Dark | `lib/app/theme.dart` | |
| Nút icon | Có `tooltip` (là nhãn trình đọc màn hình); vùng chạm ≥ 48 dp | `review_screen.dart` | |
| Chuỗi UI | Tiếng Việt inline, `static const` khi dùng lại | `review_screen.dart` | Chưa có l10n (F-031, P2) |
| Phần mở rộng / đường dẫn bản gốc | Một helper ở `core/session_manifest.dart` | `lib/core/session_manifest.dart` | Hợp nhất ở W-403 |
| Trần cố ý | `DEBT: … \| trần: … \| xem lại khi: …` ngay tại chỗ | `lib/ui/quad_editor_screen.dart` | CLAUDE.md §3.7 |
| Test sửa lỗi | Test tái hiện đỏ trước, ở lại làm hồi quy; khuôn lỗi ghi `TRAPS.md` | `test/storage/session_store_test.dart` | |

## Đang có NHIỀU KIỂU — cần hợp nhất

- Khuôn phần mở rộng `[a-z0-9]{1,5}` viết 3 nơi; tách đuôi file viết 2 nơi (F-024) → một helper ở `core/session_manifest.dart`, W-403.
- Đọc kích thước ảnh: `ui/quad_editor_screen.dart` import thẳng `package:image` (F-025) → `imaging/page_render.dart`, W-403.
