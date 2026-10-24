# ADR-0012: Điều kiện đọc lại cho ADR-0002 và giữ nguyên ADR-0001 theo dạng cũ

- **Trạng thái:** Đã chấp nhận — phiên AI duyệt theo ủy quyền §3d (chỉ bổ sung tài liệu, không đổi quyết định kiến trúc nào); chủ repo có thể bác bằng ADR mới.
- **Ngày:** 2026-10-24
- **Work ID:** `2026-10-24-governance-docs`
- **Liên quan:** ADR-0001 (không sửa), ADR-0002 (không sửa), ADR-0003, ADR-0011

## Bối cảnh

Blueprint của khung yêu cầu kiểu kiến trúc được chốt bằng ADR có ≥ 2 phương án **và mục "điều kiện đọc lại"** (ARC-STYLE-001),
và mỗi ADR có đủ Trạng thái · Ngày · Bối cảnh · Phương án đã cân nhắc · Quyết định · Hệ quả (ARC-ADR-003, BASE-DOC-003).

- ADR-0002 (Flutter, Android trước, lõi Dart thuần) có bối cảnh, ≥ 4 phương án, quyết định và hệ quả, nhưng **không có
  điều kiện đọc lại**.
- ADR-0001 (áp dụng projects-template, 2026-10-11) viết dạng 7 dòng: có ngày, trạng thái, bối cảnh và quyết định trong câu,
  **không có** heading Bối cảnh / Phương án / Hệ quả.
- Luật repo: **không sửa ADR cũ**; đổi hay bổ sung thì viết ADR mới (`docs/adr/0000-template.md`, `CLAUDE.md` §1).

Số hiệu: tiếp sau ADR-0011 (ADR-0011 đã giải thích vì sao bỏ qua 0005–0010).

## Quyết định

1. **Điều kiện đọc lại ADR-0002.** Mở lại quyết định Flutter/Android-first/lõi Dart thuần (bằng ADR mới) khi **một** trong các
   điều sau có bằng chứng:
   - Spike trên thiết bị thật cho thấy camera hệ thống + xử lý ảnh Dart không đạt chất lượng scan cần thiết (rủi ro RK-001,
     `docs/RISKS.md`), hoặc cần camera/depth native mà platform channel không đáp ứng.
   - Đo p95 xử lý một trang trên thiết bị theo protocol `docs/benchmarks/README.md` vượt mục tiêu đã duyệt (đề xuất ≤ 2 s)
     và nguyên nhân nằm ở runtime Dart/Flutter.
   - Chủ repo quyết phát hành iOS (Android-first không còn đủ) hoặc cần macOS runner.
   - Flutter 3.47.7 không còn build được với Android SDK/targetSdk mà kênh phát hành yêu cầu, hoặc nâng Flutter cần đổi API lớn.
   - Một dependency bắt buộc khiến `lib/core` phải import Flutter (phá `test/core/core_purity_test.dart`).
2. **ADR-0001 giữ nguyên (grandfathered).** ADR-0001 chỉ ghi việc áp khung, không chọn kiến trúc; dạng ngắn được chấp nhận như
   bản ghi lịch sử. Không sửa nội dung. Các mục còn thiếu được hiểu như sau (ghi tại đây, không chép vào ADR-0001):
   - *Phương án đã cân nhắc:* ADR-0001 không ghi; phương án thực tế lúc đó là áp template bằng `copy-framework.sh` hoặc không áp.
   - *Hệ quả:* repo có docs/hooks/scripts của khung và gate repository; stack để ngỏ tới ADR-0002.
3. **ADR từ nay** dùng `docs/adr/0000-template.md` và thêm heading **"Điều kiện đọc lại"** cho mọi quyết định kiến trúc/công nghệ.

## Lý do

- Không có điều kiện đọc lại thì quyết định stack hoặc bị lật ngược tuỳ hứng, hoặc bị giữ khi bằng chứng đã đổi; các điều kiện
  trên đều đo/kiểm được và gắn với rủi ro đã ghi.
- Sửa ADR cũ phá luật bất biến của repo và làm mất ngữ cảnh lúc quyết định; một ADR mới bổ sung là cách ít xâm lấn nhất.

## Các phương án đã cân nhắc

- **Sửa trực tiếp ADR-0002/ADR-0001** thêm mục còn thiếu: nhanh nhưng vi phạm luật "không sửa ADR cũ"; loại.
- **Viết ADR mới thay thế (supersede) ADR-0002:** không cần, vì quyết định không đổi; chỉ bổ sung điều kiện; loại.
- **Không làm gì:** blueprint ARC-STYLE-001/ARC-ADR-003 còn hở, không có tiêu chí xem lại stack; loại.
- **ADR bổ sung (chọn):** giữ lịch sử, thêm đúng phần thiếu.

## Hệ quả

- Tích cực: ADR-0002 có điều kiện đọc lại kiểm được; trạng thái ADR-0001 rõ ràng.
- Đánh đổi: thông tin của một quyết định nằm ở hai file (ADR-0002 + ADR này); `docs/adr/` cần đọc kèm.
- Chưa có lint heading ADR trong CI (đổi CI cần chủ repo duyệt).
- Việc tiếp: khi một điều kiện ở mục Quyết định 1 xảy ra, mở ADR mới và đổi dòng trạng thái của ADR-0002 thành "Đã thay thế bởi …".

## Điều kiện đọc lại

Đọc lại ADR này khi khung đổi luật ADR (vd chuyển hẳn sang MADR tiếng Anh) hoặc khi chủ repo yêu cầu chuẩn hoá lại ADR-0001.
