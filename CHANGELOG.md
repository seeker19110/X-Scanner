# Changelog — X-Scanner

## Unreleased — 2026-10-12

- P1 scan và xuất (#6–#10): phiên nhiều trang lưu bền giữ bản gốc, chụp bằng camera hệ thống hoặc nhập ảnh,
  sắp xếp/xoá/chụp lại/xoay, chỉnh 4 góc và nắn phối cảnh, Dark/Light, tắt sao lưu Android,
  xuất PDF/JPG/PNG qua share sheet.
- Hoàn thiện P1 (#11–#20, /completion): khôi phục phiên lỗi I/O không ghi đè phiên cũ, xoá bản sao ảnh
  của picker sau khi lưu, một cổng giải mã cho thumbnail và render xuất, tắt kéo-thả khi bận, PDF dựng trong
  isolate có trần điểm ảnh, trạng thái "Đang mở phiên…" và thử lại thumbnail lỗi, kiểm a11y Dark/Light,
  gate tự kiểm manifest release đã gộp, tài liệu trạng thái, ADR-0003, `TRAPS.md`.
- Sửa sau quét lại (#21, #22): khi app bận, thao tác TalkBack Move up/down không đổi thứ tự trang; ảnh xem
  trước lỗi chỉ giải mã lại khi bấm "Tải lại" (có vòng quay); mọi lỗi khi kiểm ảnh mới đều báo "không đọc được".
- Gate manifest release (W-504): chặn khi `targetSdkVersion` < 31, thiếu hoặc không phải số — dưới 31 component có
  intent-filter mà không khai `exported` vẫn bị exported ngầm.
- Hàng rào ảnh đầu vào (W-104a): chỉ nhận JPEG/PNG/WebP tĩnh nhận dạng theo nội dung, từ chối bản gốc trên 64 MiB
  trước khi đọc, và dừng hẳn thumbnail/render quá 60 giây; các trường hợp này báo "không đọc được", không mất trang.
- XS-09 PR-1 (#31, chưa nối vào app): mô hình tài liệu `ScanDocument` (tên 1–120 ký tự, thời điểm UTC), `revision` mỗi trang
  tăng ở mọi lần chỉnh, codec `document.json` schema 2 đọc được schema 1 và báo "cần cập nhật app" với schema mới hơn.
- XS-09 PR-2 (#32, chưa nối vào app): lưu mỗi tài liệu một thư mục với cùng bảo đảm như phiên P1, thư viện liệt kê không
  đổi gì trên đĩa (tài liệu hỏng chỉ hiện "không mở được", schema mới hơn hiện "cần cập nhật app"), tạo tài liệu nguyên tử.
- XS-09 PR-3 (#33, chưa nối vào app): migration phiên P1 thành một tài liệu — copy rồi so từng byte bản gốc, commit bằng
  rename, giữ phiên cũ làm bản quay lại không tự xoá, nhật ký để dừng ở bất kỳ bước nào cũng làm tiếp được; tên mặc định
  "Tài liệu dd/MM/yyyy HH:mm".
- XS-13 PR-1: ô trang trong danh sách hiện ảnh đã cắt và xoay đúng như file xuất (F-026), dựng từ thumbnail; kết quả
  của lần chỉnh cũ không bao giờ hiện thay cho lần chỉnh mới.
- P0 nền (#1, #2): app Flutter `apps/mobile`, lõi `PageQuad`/`ScanPage`, gate APK debug/analyze/format/test.

## 2026-10-11

- Lưu nghiên cứu scan/PDF/ảnh/OCR/depth làm gợi ý.
- Áp dụng projects-template, provenance, project brief và gate repository.

Chưa có app release.
