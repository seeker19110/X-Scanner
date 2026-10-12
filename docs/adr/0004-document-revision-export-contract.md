# ADR-0004: Hợp đồng chung cho tài liệu, revision trang và tác vụ xuất; code đi cùng consumer đầu tiên

- **Trạng thái:** Đã chấp nhận — phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12.
- **Ngày:** 2026-10-12
- **Work ID:** `2026-10-12-xs08-document-contract-spec`
- **Spec:** `docs/specs/2026-10-12-document-revision-export-contract.md` (XS-08)

## Bối cảnh

P1 lưu một phiên (`session.json` schema 1), trang không có revision, thumbnail cache theo `page.id`, xuất không có tiến độ
hay huỷ, và mọi `schemaVersion` khác 1 bị coi là hỏng rồi cách ly. Kế hoạch phát triển (#23, DRAFT) đặt XS-09 (nhiều
tài liệu + migration), XS-12 (tiến độ/huỷ xuất), XS-13 (xem trước đã cắt) và XS-22 (OCR theo revision) sau XS-08; nếu mỗi
việc tự định nghĩa trang/revision/trạng thái xuất thì dễ lệch hệ toạ độ và gắn kết quả của bản chỉnh cũ vào trang mới.

## Quyết định

1. Hợp đồng ở spec XS-08 là nguồn duy nhất cho: `ScanDocument` (id, tiêu đề 1–120 ký tự không ký tự điều khiển, thời
   điểm UTC), `revision` mỗi trang (+1 ở mọi thay đổi công thức chỉnh; chụp lại = trang mới revision 0), khoá mọi kết quả
   dẫn xuất bằng `(pageId, revision)`, `document.json` schema 2 đọc được schema 1, schema mới hơn → "cần cập nhật app"
   không cách ly, và `ExportJob` (snapshot, trạng thái, tiến độ, huỷ giữa hai trang, mã lỗi không chứa nội dung).
2. **D-1 = phương án A:** không viết code riêng cho XS-08. Kiểu và codec được viết, kèm AC của spec và test đỏ trước,
   trong PR của consumer đầu tiên: XS-09 cho tài liệu/revision/schema, XS-12 cho tác vụ xuất, XS-13 hoặc XS-22 cho khoá
   kết quả dẫn xuất.
3. FR-7 (schema mới hơn không bị cách ly) đi vào PR đầu tiên chạm `SessionStore`.

## Lý do

- Bậc 1 (đúng + không mất dữ liệu): hai phương án như nhau về an toàn; FR-7 sửa một đường hiện tại có thể đổi tên
  manifest của bản app mới hơn.
- Bậc 2 (ít hơn): phương án A không để code chưa ai gọi trên `main`; nếu spec XS-09 đổi bố cục lưu trữ, không phải sửa lại
  codec đã merge. Đây là bậc phân thắng bại.

## Các phương án đã cân nhắc

- B. Kiểu + codec schema 2 + contract test ngay ở XS-08: kiểm được sớm hơn, nhưng là code chết tới khi XS-09 được duyệt.
- C. SQLite ngay: thêm dependency ngoài D2 và hai loại migration cùng lúc; để XS-22 xét lại bằng ADR riêng.
- Không làm gì: mỗi spec sau tự định nghĩa, rủi ro lệch revision/hệ toạ độ (kế hoạch §4.2).

## Hệ quả

- Tích cực: XS-09/XS-12/XS-13/XS-22 có hợp đồng để trích dẫn; không thêm code hay dependency hôm nay.
- Đánh đổi: hợp đồng chỉ được máy kiểm khi consumer đầu tiên merge; AC-1..AC-8 của spec giữ "chưa có" tới lúc đó.
- Không cho phép triển khai XS-09..XS-23: mỗi việc vẫn cần spec riêng được duyệt (D-2 tiêu đề mặc định, D-3 hash bản gốc
  mở ở XS-09).
