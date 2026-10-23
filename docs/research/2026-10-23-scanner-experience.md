# Nâng chất lượng trải nghiệm và hiệu năng — 23/10/2026

Phạm vi: yêu cầu chủ repo nâng chất lượng, hiệu năng, UI/UX và giữ tính năng hiện có. Đối chiếu checkout `30b47dadf4323d5d4744c78c0f57ea1c26cfc170`; ba reviewer chỉ đọc độc lập về UI, hiệu năng và an toàn dữ liệu.

| Phát hiện từ mã đang chạy | Quyết định | Kiểm chứng |
| --- | --- | --- |
| `ReviewScreen` dùng Column không cuộn cho màn rỗng và sheet định dạng; thiếu kiểm thử viewport/text scale | Bố cục thích ứng, hướng dẫn ngắn, nhóm hành động rõ, sheet cuộn | Widget test 320 dp/landscape, text scale 2; Dark/Light a11y |
| `theme.dart` chỉ tạo ColorScheme; màn xem tài liệu ít phân cấp thị giác | Chung typography, tonal surface, bo góc và vùng chạm 48 dp; giữ seed xanh và mặc định Dark | Test theme + kiểm ảnh chụp widget tổng hợp |
| Editor chỉ có kéo và thao tác ngữ nghĩa; nợ WCAG 2.5.7 đã ghi ngay tại code | Chọn góc bằng chạm và bốn nút dịch 1%, dùng lại `_nudge`/undo/redo | Test chọn không sửa, dịch theo góc/rotation, undo và save |
| `thumbnailSync` giải mã JPEG toàn kích thước rồi thu nhỏ | Dùng scaled decode 1/2/4/8 của dependency `image 4.12.0` đã cài, chỉ cho thumbnail | Hướng EXIF, cạnh lẻ, ảnh dài, trần header, JPEG progressive, PNG/WebP; AOT benchmark trước/sau |
| `_enqueue` không kiểm `_disposed` trước khi bắt đầu thao tác | Không bắt đầu thao tác đã xếp hàng sau dispose; vẫn cho thao tác đã bắt đầu hoàn tất lưu an toàn | Held-operation regression đỏ trước |
| Export gọi `pageDone` cuối rồi đóng gói PDF trước kiểm huỷ | Kiểm huỷ trước đóng gói; hiển thị pha hoàn tất thay vì báo trang cuối mãi | Regression huỷ ở final-progress với rendered bytes cố ý không hợp lệ |

Nguồn API: source dependency đã cài `image-4.12.0/lib/src/formats/jpeg_decoder.dart` mô tả và kiểm scale 1/2/4/8; Flutter 3.47.7 SDK đã cài cung cấp Material 3/ColorScheme và widget semantics. Không thêm thư viện hoặc đổi pin. Git HTTPS read từ môi trường lúc rà soát không nối được proxy; không coi local HEAD là remote HEAD mới kiểm.

Giữ nguyên: camera/gallery, khôi phục phiên, xoay/cắt/undo/redo, sắp xếp, xác nhận xoá/chụp lại, PDF/JPG/PNG và chia sẻ, tiến độ/huỷ, Dark/Light, decode gate và trần dữ liệu. Library/migration/pending preservation integration đã có hồ sơ riêng; không kích hoạt lại qua thay đổi giao diện.

Trần cần bằng chứng riêng: cache nhiều trang, PDF dài, hiệu năng thiết bị, camera/OCR/depth và iOS. Benchmark host tổng hợp chỉ dùng so sánh thumbnail trên cùng workload; không suy ra tốc độ hoặc chất lượng thiết bị.
