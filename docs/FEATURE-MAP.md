# FEATURE-MAP — Bản đồ tính năng X-Scanner

> Nguồn sự thật về "app có những gì". Cập nhật khi thêm/bỏ tính năng.
> Trạng thái: ✅ ổn · ⚠️ nghi ngờ (có phát hiện audit) · 🚧 dở dang. Phát hiện: `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`.
> Lập 2026-10-12 từ code thật `apps/mobile/lib` @ `6177e29` (P1, spec `docs/specs/2026-10-11-p1-scan-export.md`); cập nhật sau /completion Đợt 1–4 @ `673ed97` (W-503) và W-502: ⚠️ chỉ còn trỏ phát hiện đang mở hoặc đã dời.
> Mọi luồng chạy trong `ReviewScreen` (màn duy nhất) và `QuadEditorScreen`; dữ liệu nằm trong sandbox app, không có mạng.

| ID | Tính năng / luồng | Điểm vào (widget → method) | Dữ liệu đụng tới | Trạng thái | Test hiện có |
|----|-------------------|-----------------------------|------------------|-----------|--------------|
| FT-01 | Khôi phục phiên khi mở app (AC-2, AC-3) | `XScannerApp.initState` → `SessionController.restore` → `PageExporter.clearLeftovers`, `SessionStore.load`, `PageSource.retrieveLost` | `session.json`, `originals/`, `session.corrupt-*.json`, `temp/exports`, `temp/share_plus` | ⚠️ (F-018, F-049 dời P2) | `test/storage/session_store_test.dart` (gồm F-001); `test/ui/session_controller_test.dart` restore*, `restoring` (F-021); `review_screen_test` restoreFailed, "while the session is opening…" (F-021) |
| FT-02 | Chụp trang (camera hệ thống, D1) | nút "Chụp" → `capture` → `_addFromPath` (giải mã thử → `importOriginal` → `save`) → `PageSource.discard` | ảnh tạm của picker trong cache (xoá sau khi lưu), `originals/{id}.{ext}`, `session.json` | ⚠️ (F-004 → W-104 sau 2026-10-18) | `review_screen_test` captured/cancelled/undecodable (AC-7); `session_controller_test` add*, "(F-048) any other error of the decode check…"; `test/ui/page_source_test.dart` (F-005) |
| FT-03 | Nhập ảnh từ thư viện | nút "Nhập ảnh" → `importFromGallery` → `_addFromPath` | như FT-02 | ⚠️ (F-004 → W-104) | `session_controller_test` add*; `page_source_test` (F-005) |
| FT-04 | Sắp xếp trang | `ReorderableListView.onReorderItem` → `move` (tay kéo tắt khi bận) | `session.json` | ✅ | `review_screen_test` dragging…, "dragging a page while busy does not reorder (F-007)", Move down accessibility action (F-051); `session_controller_test` move* |
| FT-05 | Xoá trang (xác nhận, FR-3) | nút "Xoá trang" → `remove` | `session.json`; bản gốc xoá sau khi lưu | ✅ | `review_screen_test` deleting…; `session_store_test` AC-1 |
| FT-06 | Chụp lại trang (xác nhận) | nút "Chụp lại" → `retake` | `originals/` mới; bản cũ xoá sau khi lưu | ✅ | `review_screen_test` retake…; `session_store_test` retake… |
| FT-07 | Xoay 90° từ danh sách | nút "Xoay 90°" → `updatePage(rotatedClockwise())` | `session.json` | ✅ | `review_screen_test` rotate… |
| FT-08 | Chỉnh 4 góc và xoay (FR-4, AC-4) | nút "Chỉnh góc" → `QuadEditorScreen` → pop → `updatePage` | thumbnail (RAM), `session.json` | ✅ (F-026, F-032 đóng ở XS-13; DEBT thu hẹp: chưa có cách chỉnh một-chạm cho người không kéo và không dùng trình đọc màn hình → XS-20) | `test/ui/quad_editor_screen_test.dart`, `test/core/quad_editing_test.dart`; `review_screen_test` thumbnail lỗi/thử lại (F-020, F-028, F-047), kích thước ô (F-022); `session_controller_test` retryThumbnail (F-047), xem trước đã cắt theo revision (XS-13 AC-1, AC-3, AC-4); `page_render_test` cùng hình học xem trước/xuất (XS-13 AC-2); `quad_editor_screen_test` hiển thị xoay, hoàn tác/làm lại, hỏi bỏ thay đổi, kính lúp, thao tác trợ năng (XS-13 AC-5..AC-10), `edit_history_test` |
| FT-09 | Xoá tất cả (xác nhận) | nút "Xoá tất cả trang" → `clearAll` | `session.json` rỗng, xoá bản gốc đã lưu | ⚠️ (F-018 dời P2) | `review_screen_test` clearing all… |
| FT-10 | Xuất và chia sẻ PDF/JPG/PNG (FR-6, FR-7, AC-6) | nút "Xuất" → bottom sheet → `exportAndShare` → `ExportJob` (snapshot) → `PageExporter.run` → `renderPage` (qua `DecodeGate`)/`buildPdf` (isolate) → `FileSharer.share` → `clear`; "Huỷ" → `cancelExport` | đọc `originals/`; ghi/xoá `temp/exports`; `temp/share_plus` | ⚠️ AC-9 chờ UAT (F-033 đóng ở XS-12a: tiến độ i/N, huỷ ở ranh giới trang) | `test/export/*` (gồm `export_job_test`, XS-12a AC-1..AC-5), `test/imaging/*` (gồm `decode_gate_test`, F-006), `session_controller_test` export* (XS-12a AC-6), `review_screen_test` export* (F-029, XS-12a AC-7) |
| FT-11 | Dark/Light (mặc định Dark) | icon AppBar → `_XScannerAppState._toggleTheme` | không (chỉ trong RAM) | ✅ | `test/app_test.dart`, `review_screen_test` theme…, `test/ui/accessibility_test.dart` (F-011, F-056: có trang, ô lỗi, rỗng, đang mở phiên, trình chỉnh góc; cả Dark và Light) |
| FT-12 | Thông báo lỗi | `SessionController._report` → `ReviewScreen._showNotices` (SnackBar) | không | ✅ | test AC-7, restoreFailed, saveFailed, exportFailed |

## Luồng chính (đối chiếu Definition of Complete)

- **LC-1 Chụp → chỉnh → xuất PDF** (FT-02, FT-08, FT-10): widget test qua `ReviewScreen` với nguồn ảnh/chia sẻ giả — `review_screen_test` "captured image appears as a page", "crop button opens the editor and saves its result", "exporting as PDF shares one X-Scanner.pdf (AC-6) (F-029)"; `quad_editor_screen_test` "a valid drag moves only that corner". Test đi liền một mạch: `review_screen_test` "LC-1: capture, move a corner, save and export as PDF in one flow (F-053)". Trên thiết bị là AC-9 (UAT emulator, chủ repo).
- **LC-2 Đóng app → mở lại → còn trang và chỉnh sửa** (FT-01): `session_store_test` "a new store on the same root restores pages and edits" + các ca (F-001); `session_controller_test` "restore loads the saved session", "(F-001) restore failing with an I/O error, then capture, keeps the …".
- **LC-3 Nhập ảnh hỏng/huỷ → không mất trang cũ** (FT-02, FT-03, FT-12): `review_screen_test` "cancelled capture adds no page (AC-7)", "undecodable image shows a message and keeps pages (AC-7)"; `session_controller_test` "cancelled capture adds no page and no notice (AC-7)".

## Ghi chú phạm vi

- Ảnh xem trước trong danh sách áp khung cắt + xoay như file xuất, dựng từ thumbnail ≤ 1024 px, cache theo `(pageId, revision)` (F-026 đóng ở XS-13 PR-1).
- Không có tự nhận mép, OCR, depth, iOS, cloud (spec P1 §5 non-goal).
