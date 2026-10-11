# ADR-0002: Flutter, Android trước, lõi Dart thuần cho hợp đồng trang

- **Trạng thái:** Đề xuất — chờ chủ repo xác nhận (ngữ cảnh X-Scanner trong `CLAUDE.md`/`AGENTS.md` nói research/roadmap không tự cho phép triển khai sản phẩm).
- **Ngày:** 2026-10-11
- **Work ID:** `2026-10-11-p0-foundation`

## Bối cảnh

ADR-0001 chỉ áp khung và để ngỏ stack. Bản nghiên cứu (ADVISORY) đề xuất Flutter cho UI, native
(CameraX/ARCore, AVFoundation/ARKit) cho camera/depth, OpenCV cho xử lý ảnh, OCR/xuất file qua
interface thay được. Build/typecheck của repo đang N/A nên chưa thể code sản phẩm. Ràng buộc:
local-first, không API trả phí, không upload tài liệu, CI miễn phí trên runner Linux, chưa có thiết bị thật
hay quyền ký/runner macOS trong phiên này.

Nguồn sống (truy cập 2026-10-11): Flutter stable **3.47.7**, Dart **3.13.5**
(`storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`, sha256
`af7455f5…6230`); Android command-line tools **23.0** (`dl.google.com/android/repository/repository2-3.xml`).

## Quyết định

1. **Flutter 3.47.7 (Dart 3.13.5)**, một dự án ở `apps/mobile`; khai báo Android + iOS nhưng
   **Android là nền tảng build/kiểm chứng đầu tiên**. iOS chỉ được nói "chạy" khi có build macOS thật.
2. **Lõi Dart thuần** ở `apps/mobile/lib/core/` (không import Flutter): hợp đồng trang, tọa độ, thứ tự trang.
   Camera/depth sau này đi qua platform channel tới code native, quyết định bằng ADR riêng sau spike thiết bị.
3. **Không thêm package bên thứ ba ở P0** ngoài lint chính thức `flutter_lints` (dev). Mỗi dependency
   sau này cần kiểm phiên bản, license và lý do theo thang `CLAUDE.md` §3.4.
4. **Cổng thật:** `dart format` · `flutter analyze` (lint + type) · `flutter test` · `flutter build apk --debug`,
   chạy qua `scripts/dev-task.sh gate` cả cục bộ lẫn CI. CI cài Flutter từ archive ghim phiên bản + sha256,
   không dùng action bên thứ ba.

## Lý do

- Một codebase UI cho hai nền tảng, khớp kiến trúc ứng viên của nghiên cứu và đường PDF `dart_pdf`
  (chưa thêm). Phần chất lượng ảnh nằm ở camera/thuật toán native/OpenCV, không phụ thuộc framework UI.
- Lõi Dart thuần kiểm bằng unit test rẻ, chạy trên Linux; chốt hợp đồng tọa độ trước khi chia việc
  Android/iOS/xử lý ảnh song song (nghiên cứu §7).
- Android-first vì build/test được trên runner Linux miễn phí; iOS cần macOS runner/ký số — chi phí và quyền chưa cấp.

## Các phương án đã cân nhắc

- **Native Kotlin + Swift:** camera/depth trực tiếp nhất, nhưng hai UI codebase; loại ở bậc "ít hơn".
- **React Native:** nghiên cứu ghi nhận không có lợi thế chất lượng ảnh; thêm cầu JS cho dữ liệu ảnh lớn; loại.
- **Kotlin Multiplatform + Compose:** khả thi nhưng mức chín của UI iOS chưa được kiểm chứng ở phiên này; loại vì thiếu bằng chứng.
- **Không làm gì (giữ N/A):** không mở được cổng thật để bắt đầu P0/P1; loại.
- **`subosito/flutter-action`:** tiện nhưng thêm phụ thuộc chuỗi cung ứng; tải archive ghim sha256 đủ dùng.

## Hệ quả

- Tích cực: có build/type/lint/test thật; hợp đồng trang kiểm được; không chi phí mới.
- Đánh đổi: app chưa có camera, chưa đo chất lượng scan; build iOS chưa kiểm chứng.
- License inventory P0: Flutter SDK (BSD-3-Clause), `flutter_lints` (BSD-3-Clause, dev), thư viện Android
  do Gradle kéo theo template Flutter (AndroidX/Kotlin, Apache-2.0). Chưa chọn license sản phẩm (non-goal của `PROJECT.md`).
- Việc tiếp: spike camera độ phân giải cao + ARCore depth trên thiết bị thật (cần chủ repo chạy/cung cấp thiết bị),
  rồi ADR cho đường capture native; build iOS khi được cấp macOS runner.
