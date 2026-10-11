# X-Scanner — Project brief

## Trạng thái

Greenfield / discovery. Chủ dự án: @seeker19110.
Đã duyệt ngày 2026-10-11: lưu nghiên cứu làm gợi ý và áp dụng projects-template.
Mục tiêu sản phẩm: scan tài liệu, xuất PDF hoặc ảnh; nghiên cứu khoảng cách/depth để tăng chất lượng.
Người dùng: người cần số hóa tài liệu; phân khúc cụ thể và nền tảng phát hành chưa chốt.
Outcome: bản scan rõ, đủ và file dùng được; chưa có số đo thực nghiệm.

## Scope hiện tại

Advisory, bộ khung chuẩn, project brief, hướng dẫn agent, gate repository và provenance.
Không có code camera, OCR, PDF engine hoặc mobile app trong lần áp dụng này.

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
Còn mở: nền tảng, stack/SDK, thiết bị, OCR/PDF engine, giấy phép, threat model và benchmark.

## Gate hiện tại

Doctor/gate qua scripts/dev-task.sh. Build/typecheck app **N/A**, không phải PASS.
Trước feature đầu: spec duyệt, ADR phù hợp, lệnh app thật, SDK ghim phiên bản và review license.
