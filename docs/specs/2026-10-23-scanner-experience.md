# Feature spec: Trải nghiệm X-Scanner và hiệu năng ảnh xem trước

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | `docs/work/2026-10-23-scanner-experience/working.md` |
| Spec owner | Phiên chính |
| State | Approved for implementation |
| Approver / date | Phiên chính theo ủy quyền §3d, 2026-10-23; yêu cầu nâng cấp trực tiếp của chủ repo |
| Last updated | 2026-10-23 |

## 1. Problem, user và evidence

Người dùng cần giữ quy trình scan hiện tại nhưng thao tác rõ, dễ tiếp cận và ít tốn tài nguyên hơn. Nghiên cứu `docs/research/2026-10-23-scanner-experience.md` xác định giới hạn bố cục, thao tác góc chỉ bằng kéo, giải mã thumbnail toàn ảnh và hai biên vòng đời/huỷ.

## 2. Outcome, baseline, target và guardrails

Một bản nâng cấp thống nhất cho quy trình đang chạy, không đổi dữ liệu: UI Material 3 xanh đậm/Light, hướng dẫn và nút xuất rõ, vùng chạm tối thiểu 48 dp; không overflow tại viewport và text scale được kiểm. Thumbnail JPEG dùng raster nhỏ hơn khi vẫn đủ độ phân giải xem trước; so sánh wall/RSS bằng AOT cùng corpus. Không đặt lời hứa p95 hoặc hiệu năng thiết bị từ số đo host. Mọi regression hiện có và full gate phải xanh.

## 5. Scope / non-goals

Gồm theme, màn xem phiên, sheet xuất, editor góc có nút chạm, scaled JPEG thumbnail, biên dispose và huỷ trước PDF. Giữ render/export toàn độ phân giải, schema, tên file, quyền Android, dependency/lock và cơ chế bảo toàn ảnh gốc. Không kích hoạt library/migration, thêm OCR/depth/cloud/tài khoản hoặc phát hành.

## 9. Acceptance criteria

- AC-1: Giữ toàn bộ luồng capture/import/edit/reorder/retake/delete/restore/export/share/cancel và Dark/Light; các test hiện có tiếp tục qua.
- AC-2: Màn rỗng/có trang và chọn định dạng hiển thị rõ ở 320 dp và cỡ chữ 200%; nội dung dài cuộn, hành động không bị cắt; hình thức thống nhất theo ColorScheme.
- AC-3: Có nút xuất có nhãn rõ, số trang, mô tả định dạng; thao tác bận/huỷ giữ đúng hợp đồng. Khi tất cả trang đã render nhưng chưa xong PDF, UI hiển thị pha tạo PDF.
- AC-4: Chạm chọn góc không thay dữ liệu/history; bốn nút dịch dùng cùng phép biến đổi/validate 1%; undo/redo/save và các thao tác kéo/semantics vẫn hoạt động.
- AC-5: JPEG thumbnail chọn scale lớn nhất trong 1/2/4/8 không làm thiếu độ phân giải mục tiêu và không làm mất phân biệt trục của ảnh gốc không vuông; dùng hướng do decoder thực tế áp dụng, giữ cap kích thước gốc trước decode, lỗi sanitize, output maxSide. PNG/WebP và export giữ đường hiện tại.
- AC-6: Thao tác chưa bắt đầu không gọi picker/share hoặc ghi dữ liệu sau dispose; thao tác đang ghi không bị cắt giữa chừng.
- AC-7: Huỷ ở final-page progress dừng trước PDF packaging, kết quả cancelled thay vì writeFailed; không share/file xuất còn lại, ảnh gốc không đổi.
- AC-8: Full gate xanh, số đo AOT trước/sau và giới hạn ghi rõ, không đưa dữ liệu cá nhân vào fixture/ảnh chụp/log.

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | `apps/mobile/test/ui/review_screen_test.dart`, `apps/mobile/test/ui/session_controller_test.dart` | Existing functional regressions + full gate |
| AC-2 | `apps/mobile/test/ui/review_screen_test.dart`, `apps/mobile/test/ui/accessibility_test.dart` | Responsive/large text + a11y |
| AC-3 | `apps/mobile/test/ui/review_screen_test.dart` | Visible export/format/phase |
| AC-4 | `apps/mobile/test/ui/quad_editor_screen_test.dart` | Tap adjustment/history |
| AC-5 | `apps/mobile/test/imaging/page_render_test.dart`, `apps/mobile/test/imaging/decoder_security_test.dart` | Geometry/orientation/limits |
| AC-6 | `apps/mobile/test/ui/session_controller_test.dart` | Queued/new operations after dispose |
| AC-7 | `apps/mobile/test/export/page_exporter_test.dart` | Final-page cancellation boundary |
| AC-8 | `docs/work/2026-10-23-scanner-experience/working.md` | Actual command evidence retained |

## 11. Architecture và code touchpoints

Giữ hành vi mặc định của API và wiring P1; `decodeOriented` được thêm optional `jpegScale: 1`, chỉ thay raster JPEG khi caller thumbnail yêu cầu. Presentation thay ở `apps/mobile/lib/app/theme.dart`, `apps/mobile/lib/ui/review_screen.dart`, `apps/mobile/lib/ui/quad_editor_screen.dart`. Thumbnail ở `apps/mobile/lib/imaging/page_render.dart`; guard ở `apps/mobile/lib/ui/session_controller.dart` và `apps/mobile/lib/export/page_exporter.dart`. Dùng lại test trong bảng AC và benchmark `apps/mobile/tool/scanner_benchmark.dart`.

## Approval

- Bổ sung trước bản sửa review ngày 2026-10-23, phiên chính duyệt theo §3d: ảnh gần vuông có thể cần scale nhỏ hơn để raster vẫn phân biệt hai trục. Không đọc EXIF lần hai vì nhiều APP1 có thể chọn hướng khác decoder; giữ tỷ lệ từ header và hướng của raster thực tế. Đây là ngoại lệ correctness cho tối ưu scale, không đổi cap hoặc export.
- [x] Product/scope, UX/a11y, architecture/data, privacy, test và rollback được phiên chính đối chiếu dưới §3d.
- [x] Không có quyết định chặn; rollback là revert code, không có migration.

**Conclusion:** Approved for implementation. Phê duyệt phạm vi code; không cấp quyền merge/deploy.
