# X-Scanner — Project brief

## Trạng thái

P1 scan và xuất đã merge (2026-10-12), chờ UAT emulator (AC-9). Chủ dự án: @seeker19110.
Đã duyệt ngày 2026-10-11: lưu nghiên cứu, áp dụng projects-template, stack ADR-0002, spec P0 nền và spec P1 scan và xuất.
Mục tiêu sản phẩm: scan tài liệu, xuất PDF hoặc ảnh; nghiên cứu khoảng cách/depth để tăng chất lượng.
Người dùng: người cần số hóa tài liệu; phân khúc cụ thể và nền tảng phát hành chưa chốt.
Outcome: bản scan rõ, đủ và file dùng được; chưa có số đo thực nghiệm.

## Scope hiện tại

App Flutter `apps/mobile` (Android trước), offline, theo `docs/specs/2026-10-11-p1-scan-export.md`:
chụp bằng camera hệ thống hoặc nhập ảnh (`image_picker`, không xin quyền camera/bộ nhớ), sắp xếp, xoá, chụp lại,
xoay, chỉnh 4 góc (nắn phối cảnh bằng homography Dart), lưu phiên giữ nguyên bản gốc qua lần đóng app,
xuất PDF nhiều trang hoặc JPG/PNG từng trang qua share sheet. Tính năng: `docs/FEATURE-MAP.md`.
Chưa có: tự nhận mép, depth, OCR, PDF searchable, iOS.

## Gợi ý, không phải quyết định

Xem `docs/research/2026-10-11-scanner-product-suggestions.md`. Flutter/native/OpenCV, local-first, Android/iOS,
OCR Việt/Anh, PDF searchable và P0–P4 là ứng viên. Depth không mặc định là phần cứng bắt buộc.
Các ngưỡng 95%, CER 2%, p95 2 giây, 100 trang, giảm chụp lại 15% chưa được nghiệm thu.

## Non-goals

Không tự triển khai roadmap, phát hành, chọn license sản phẩm, thêm X-Agents,
bắt buộc tài khoản/cloud/billing hoặc gọi AI API trả phí.

## Guardrails và quyết định mở

Đặc tả sản phẩm cần kiểm tra bảo toàn bản gốc/nội dung, quyền camera/lưu trữ, retention,
không log/upload tài liệu thật, Unicode Việt, bộ nhớ và fallback depth.
Đã chốt: Flutter 3.47.7, Android build trước (ADR-0002); camera hệ thống, xử lý ảnh Dart, PDF bằng `pdf`,
chia sẻ bằng `share_plus` (ADR-0003, spec P1 D1–D4). Còn mở: thiết bị, đường capture native/depth,
OCR, giấy phép sản phẩm, threat model, Data Governance trước phát hành và benchmark trên thiết bị (P2).

## Gate hiện tại

Doctor/gate qua scripts/dev-task.sh: build APK debug, kiểm manifest release đã gộp (`scripts/check-release-manifest.py`), `flutter analyze --fatal-infos`, `dart format`, `flutter test`
và kiểm tra repository; CI chạy cùng gate. Lệnh theo khu vực: `CODEMAP.md`. Build iOS và kiểm thử thiết bị thật: **chưa kiểm chứng**.
