# X-Scanner — Project brief

## Trạng thái

Greenfield / P0 nền. Chủ dự án: @seeker19110.
Đã duyệt ngày 2026-10-11: lưu nghiên cứu, áp dụng projects-template, stack ADR-0002 và spec P0 nền.
Mục tiêu sản phẩm: scan tài liệu, xuất PDF hoặc ảnh; nghiên cứu khoảng cách/depth để tăng chất lượng.
Người dùng: người cần số hóa tài liệu; phân khúc cụ thể và nền tảng phát hành chưa chốt.
Outcome: bản scan rõ, đủ và file dùng được; chưa có số đo thực nghiệm.

## Scope hiện tại

App Flutter nền `apps/mobile` (Android trước) và lõi hợp đồng trang `PageQuad`/`ScanPage` theo
`docs/specs/2026-10-11-p0-foundation.md`. Chưa có camera, depth, OCR, PDF engine hoặc lưu trữ.

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
Đã chốt: Flutter 3.47.7, Android build trước (ADR-0002). Còn mở: thiết bị, đường capture native/depth,
OCR/PDF engine, giấy phép sản phẩm, threat model và benchmark.

## Gate hiện tại

Doctor/gate qua scripts/dev-task.sh: build APK debug, `flutter analyze --fatal-infos`, `dart format`, `flutter test`
và kiểm tra repository; CI chạy cùng gate. Build iOS và kiểm thử thiết bị thật: **chưa kiểm chứng**.
