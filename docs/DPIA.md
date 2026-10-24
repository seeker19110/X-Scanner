# DPIA — sàng lọc (screening) · X-Scanner app Android offline · phiên bản 1 · 2026-10-24

> Đây là **bản sàng lọc nội bộ**, không phải hồ sơ đánh giá tác động nộp cơ quan nhà nước và không phải ý kiến pháp lý.
> Mẫu đầy đủ: `.xtemplates/framework/templates/DPIA.md`. Căn cứ và nguồn: `PROJECT.md` mục "Khung pháp lý".
> Mọi kết luận dưới đây **cần chủ repo/luật sư xác nhận** trước khi phát hành.

| Trường | Giá trị |
|---|---|
| Hoạt động xử lý | Người dùng chụp/nhập ảnh tài liệu, đặt tên, cắt/xoay, lưu trên máy và xuất PDF/ảnh qua share sheet |
| Nơi xử lý | Chỉ trên thiết bị người dùng; không server, không mạng, không tài khoản, không telemetry |
| Dữ liệu | Ảnh tài liệu (có thể chứa dữ liệu cá nhân, kể cả nhạy cảm: giấy tờ tuỳ thân, sức khoẻ, tài chính); tiêu đề tài liệu; thời điểm tạo/sửa (UTC). Chi tiết: `docs/privacy/data-map.yaml` |
| Chủ thể dữ liệu | Người dùng và bất kỳ ai xuất hiện trên giấy tờ được chụp (app không biết) |
| Bên nhận | Không có mặc định; chỉ app do người dùng chọn khi chia sẻ |
| Chuyển ra nước ngoài | Không do app thực hiện (không có mạng); sao lưu đám mây bị tắt |
| Trạng thái phát hành | Chưa phát hành, chưa có người dùng thật (`PROJECT.md`, `CHANGELOG.md`) |

## 1. Câu hỏi sàng lọc

| # | Câu hỏi | Trả lời | Bằng chứng |
|---|---|---|---|
| 1 | App có xử lý dữ liệu cá nhân không? | Có thể: nội dung ảnh do người dùng chọn | `docs/privacy/data-map.yaml` |
| 2 | Có dữ liệu nhạy cảm không? | Có thể (app không phân loại nội dung) → đối xử như nhạy cảm | data map `classification: nhay-cam-mac-dinh` |
| 3 | Nhà phát triển có nhận/truy cập dữ liệu không? | Không: không mạng, không server, không log | `test/android_manifest_test.dart`, `scripts/check-release-manifest.py` |
| 4 | Có theo dõi hành vi, hồ sơ hoá, quyết định tự động? | Không | không có analytics/AI trong `apps/mobile/pubspec.yaml` |
| 5 | Có chia sẻ cho bên thứ ba? | Chỉ khi người dùng chủ động chọn app nhận | `lib/export/file_sharer.dart` |
| 6 | Có chuyển dữ liệu xuyên biên giới? | Không do app | sao lưu tắt: `data_extraction_rules.xml` |
| 7 | Trẻ em? | App không thu thập tuổi; có thể có người dùng là trẻ em khi phát hành qua cửa hàng | cần chủ repo quyết đối tượng |
| 8 | Có công nghệ mới rủi ro cao (OCR, AI, sinh trắc)? | Chưa; OCR là ứng viên tương lai (ADVISORY) | `PROJECT.md` "Chưa có" |

## 2. Kết luận sàng lọc (tạm thời)

- Theo **GDPR** (Regulation (EU) 2016/679): Art. 2(2)(c) loại trừ xử lý "by a natural person in the course of a purely
  personal or household activity"; Recital 18 lại nói Regulation vẫn áp dụng cho "controllers or processors which provide
  the means for processing personal data for such personal or household activities". Việc nhà phát triển một app offline,
  không nhận dữ liệu, có là controller/processor hay không **cần luật sư xác nhận**; Art. 3(2) chỉ kéo bên ngoài EU vào khi
  chào bán hàng hoá/dịch vụ cho người ở EU hoặc theo dõi hành vi — phụ thuộc kênh phát hành chưa chốt.
- Theo **Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15** và **Nghị định 356/2025/NĐ-CP**: nhà phát triển hiện không thu thập,
  lưu hay truy cập dữ liệu; nghĩa vụ lập hồ sơ đánh giá tác động có áp dụng hay không **cần luật sư xác nhận** (phiên AI
  không đọc được toàn văn điều khoản ngày 2026-10-24, chỉ xác minh số hiệu và ngày hiệu lực).
- **Đề xuất (không phải quyết định):** chưa cần DPIA đầy đủ khi app chưa phát hành; **làm lại sàng lọc** khi có một trong các
  sự kiện: phát hành qua cửa hàng, thêm mạng/đồng bộ/cloud, OCR hoặc AI, analytics/crash report, tài khoản, đối tượng trẻ em.

## 3. Rủi ro cho chủ thể dữ liệu và biện pháp

| ID | Rủi ro | Khả năng | Mức độ | Biện pháp | Rủi ro còn lại |
|---|---|---|---|---|---|
| DP-01 | Lộ ảnh giấy tờ qua sao lưu đám mây | Thấp | Cao | sao lưu tắt (THREAT-MODEL TM-03) | Thấp |
| DP-02 | Lộ ảnh khi người khác cầm máy root/đã mở khoá | Thấp | Cao | sandbox + mã hoá theo file của Android (TM-12) | TB, chờ quyết định mã hoá at-rest (`docs/RISKS.md` RK-004) |
| DP-03 | Mất bản gốc do lỗi app | TB | TB | ghi nguyên tử, so byte, không tự xoá bản cũ (TM-02) | Thấp |
| DP-04 | Dữ liệu nằm lại lâu hơn cần (ảnh bị từ chối, bản P1 cũ, tài liệu hỏng) | Cao | Thấp | chưa có UI xoá (DEBT, XS-10) | TB, xem `PROJECT.md` mục "Dữ liệu & pháp lý" |
| DP-05 | Người dùng chưa được thông báo cách app xử lý dữ liệu | Cao khi phát hành | TB | chưa có chính sách quyền riêng tư | chặn phát hành (`docs/ops/release-readiness.md` mục Privacy) |

## 4. Ký

| Vai trò | Tên | Ngày |
|---|---|---|
| Người lập | phiên AI (Work ID `2026-10-24-governance-docs`) | 2026-10-24 |
| Chủ repo xác nhận | _chưa_ | |
| Luật sư rà | _chưa_ | |

## Lịch sử cập nhật

| Phiên bản | Ngày | Lý do |
|---|---|---|
| 1 | 2026-10-24 | Sàng lọc đầu tiên (PM-RISK-007, STD-PRIV-001) |
