# ADR-0003: P1 dùng camera hệ thống, xử lý ảnh Dart thuần, `pdf` và `share_plus`

- **Trạng thái:** Đã chấp nhận — chủ repo duyệt spec P1 (D1–D4) ngày 2026-10-11; ADR này ghi lại quyết định đó cho `docs/adr/` (F-042, `/completion` 2026-10-12).
- **Ngày:** 2026-10-12
- **Work ID:** `2026-10-12-p1-completion` (quyết định gốc: `2026-10-11-p1-scan-export`)

## Bối cảnh

ADR-0002 chốt Flutter, Android trước, lõi Dart thuần, và dự kiến camera/depth đi qua platform channel native
"quyết định bằng ADR riêng sau spike thiết bị"; P0 không có package bên thứ ba. P1 (spec
`docs/specs/2026-10-11-p1-scan-export.md`) cần chụp, chỉnh 4 góc, lưu phiên và xuất PDF/ảnh, trong khi phiên AI
không có thiết bị thật hay emulator (`/dev/kvm`) để làm spike camera/depth.

## Quyết định

1. **Camera hệ thống và photo picker qua `image_picker` 1.2.3** (D1): app không xin quyền CAMERA/STORAGE;
   ảnh được chép vào `originals/` của app và giữ nguyên byte. Camera native/depth vẫn để ADR sau spike thiết bị.
2. **Xử lý ảnh Dart thuần**: `image` 4.10.1 để giải mã/xoay/mã hoá; nắn phối cảnh bằng homography dạng đóng
   tự viết (`lib/imaging/homography.dart`), không dùng `copyRectify` (nội suy song tuyến, sai khi trang nghiêng);
   chạy trong `Isolate.run`, có trần điểm ảnh.
3. **Xuất bằng `pdf` 3.13.1** (mỗi trang một trang PDF theo tỷ lệ ảnh, nhúng JPEG) và **chia sẻ bằng
   `share_plus` 13.3.1** qua share sheet; file tạm xoá sau khi chia sẻ và khi mở lại app.
4. **Lưu phiên ở thư mục hỗ trợ của app qua `path_provider` 2.1.6**, manifest JSON có `schemaVersion`, ghi nguyên tử;
   **tắt sao lưu và chuyển máy Android** (D3).
5. Mọi dependency ghim chính xác, bản phát hành ≥ 7 ngày khi ghim (spec §3).

## Lý do

- Camera hệ thống cho ảnh độ phân giải đầy đủ mà không cần quyền nhạy cảm hay code native chưa kiểm được.
- Dart thuần chạy và test được trên runner Linux; đổi sang native/OpenCV sau chỉ chạm `lib/imaging/`.
- `pdf`/`share_plus` là gói Flutter phổ biến, license MIT/BSD-3/Apache-2.0, không cần mạng.

## Các phương án đã cân nhắc

- Plugin `camera` (preview trong app): cần quyền CAMERA và test trên thiết bị — để P2 cùng spike depth.
- OpenCV qua FFI: mạnh hơn nhưng tăng kích thước và độ phức tạp build; chưa cần cho chỉnh góc thủ công.
- Tự viết PDF: ít dependency hơn nhưng rủi ro sai định dạng; `pdf` đã kiểm mã nguồn.

## Hệ quả

- ADR-0002 quyết định 2 (camera qua platform channel) và 3 (không package ở P0) vẫn đúng cho phạm vi của nó;
  P1 thay đường camera bằng camera hệ thống cho tới khi có spike thiết bị.
- `image` 4.10.1 có lỗi giải mã ảnh độc hại (F-004): nâng ≥ 4.12.0 từ 2026-10-18 (W-104), exception ở
  `docs/ops/supply-chain-exceptions.md`.
- Hiệu năng trên thiết bị (p95) chưa đo — P2 (spec §2).
