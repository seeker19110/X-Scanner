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
- P0 nền (#1, #2): app Flutter `apps/mobile`, lõi `PageQuad`/`ScanPage`, gate APK debug/analyze/format/test.

## 2026-10-11

- Lưu nghiên cứu scan/PDF/ảnh/OCR/depth làm gợi ý.
- Áp dụng projects-template, provenance, project brief và gate repository.

Chưa có app release.
