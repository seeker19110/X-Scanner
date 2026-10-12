# FEATURE-MAP — Bản đồ tính năng X-Scanner

> Nguồn sự thật về "app có những gì". Cập nhật khi thêm/bỏ tính năng.
> Trạng thái: ✅ ổn · ⚠️ nghi ngờ (có phát hiện audit) · 🚧 dở dang. Phát hiện: `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`.
> Lập 2026-10-12 từ code thật `apps/mobile/lib` @ `6177e29` (P1, spec `docs/specs/2026-10-11-p1-scan-export.md`).
> Mọi luồng chạy trong `ReviewScreen` (màn duy nhất) và `QuadEditorScreen`; dữ liệu nằm trong sandbox app, không có mạng.

| ID | Tính năng / luồng | Điểm vào (widget → method) | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|-----------------------------|------------------|-----------|--------------|
| FT-01 | Khôi phục phiên khi mở app (AC-2, AC-3) | `XScannerApp.initState` → `SessionController.restore` → `PageExporter.clearLeftovers`, `SessionStore.load`, `PageSource.retrieveLost` | `session.json`, `originals/`, `session.corrupt-*.json`, `temp/exports`, `temp/share_plus` | ⚠️ (F-001, F-018, F-021) | `test/storage/session_store_test.dart`, `test/ui/session_controller_test.dart` restore*, `test/ui/review_screen_test.dart` restoreFailed |
| FT-02 | Chụp trang (camera hệ thống, D1) | nút "Chụp" → `capture` → `_addFromPath` (giải mã thử → `importOriginal` → `save`) | ảnh tạm của picker trong cache, `originals/{id}.{ext}`, `session.json` | ⚠️ (F-004, F-005) | `review_screen_test` captured/cancelled/undecodable (AC-7); `session_controller_test` add* |
| FT-03 | Nhập ảnh từ thư viện | nút "Nhập ảnh" → `importFromGallery` → `_addFromPath` | như FT-02 | ⚠️ (F-004, F-005) | `session_controller_test` add* |
| FT-04 | Sắp xếp trang | `ReorderableListView.onReorderItem` → `move` | `session.json` | ⚠️ (F-007) | `review_screen_test` dragging…; `session_controller_test` move* |
| FT-05 | Xoá trang (xác nhận, FR-3) | nút "Xoá trang" → `remove` | `session.json`; bản gốc xoá sau khi lưu | ✅ | `review_screen_test` deleting…; `session_store_test` AC-1 |
| FT-06 | Chụp lại trang (xác nhận) | nút "Chụp lại" → `retake` | `originals/` mới; bản cũ xoá sau khi lưu | ✅ | `review_screen_test` retake…; `session_store_test` retake… |
| FT-07 | Xoay 90° từ danh sách | nút "Xoay 90°" → `updatePage(rotatedClockwise())` | `session.json` | ✅ | `review_screen_test` rotate… |
| FT-08 | Chỉnh 4 góc và xoay (FR-4, AC-4) | nút "Chỉnh góc" → `QuadEditorScreen` → pop → `updatePage` | thumbnail (RAM), `session.json` | ⚠️ (F-020, F-025, F-026, F-032; DEBT a11y kéo góc) | `test/ui/quad_editor_screen_test.dart`, `test/core/quad_editing_test.dart` |
| FT-09 | Xoá tất cả (xác nhận) | nút "Xoá tất cả trang" → `clearAll` | `session.json` rỗng, xoá bản gốc đã lưu | ⚠️ (F-005, F-018) | `review_screen_test` clearing all… |
| FT-10 | Xuất và chia sẻ PDF/JPG/PNG (FR-6, FR-7, AC-6) | nút "Xuất" → bottom sheet → `exportAndShare` → `PageExporter.export` → `renderPage`/`buildPdf` → `FileSharer.share` → `clear` | đọc `originals/`; ghi/xoá `temp/exports`; `temp/share_plus` | ⚠️ (F-006, F-012, F-013, F-023); AC-9 chờ UAT | `test/export/*`, `test/imaging/*`, `session_controller_test` export*, `review_screen_test` export* |
| FT-11 | Dark/Light (mặc định Dark) | icon AppBar → `_XScannerAppState._toggleTheme` | không (chỉ trong RAM) | ⚠️ (F-011) | `test/app_test.dart`, `review_screen_test` theme… |
| FT-12 | Thông báo lỗi | `SessionController._report` → `ReviewScreen._showNotices` (SnackBar) | không | ✅ | test AC-7, restoreFailed, saveFailed, exportFailed |

## Luồng chính (đối chiếu Definition of Complete)

- **LC-1 Chụp → chỉnh → xuất PDF** (FT-02, FT-08, FT-10): widget test qua `ReviewScreen` với nguồn ảnh/chia sẻ giả; trên thiết bị là AC-9 (UAT emulator, chủ repo).
- **LC-2 Đóng app → mở lại → còn trang và chỉnh sửa** (FT-01): `session_store_test` + `session_controller_test` restore.
- **LC-3 Nhập ảnh hỏng/huỷ → không mất trang cũ** (FT-02, FT-03, FT-12): `review_screen_test` AC-7.

## Ghi chú phạm vi

- Ảnh xem trước trong danh sách là ảnh gốc đã xoay, chưa áp khung cắt (F-026, chủ ý cho P1; kết quả cắt thấy ở file xuất).
- Không có tự nhận mép, OCR, depth, iOS, cloud (spec P1 §5 non-goal).
