# X-Scanner — Gợi ý sản phẩm và phát triển

- Ngày lưu: 2026-10-11.
- Trạng thái: **ADVISORY / GỢI Ý**, không phải đặc tả đã duyệt hoặc quyết định kiến trúc.
- Nguồn: bản nghiên cứu và kế hoạch đã trao đổi với chủ dự án trong cuộc hội thoại ngày 2026-10-11.
- Yêu cầu tiếp theo của chủ dự án: lưu làm gợi ý rồi áp dụng `seeker19110/projects-template` lên X-Scanner.
- Phạm vi đã xác nhận: ứng dụng scan tài liệu, xuất PDF hoặc ảnh; nghiên cứu khả năng tận dụng đo khoảng cách/chiều sâu để tăng chất lượng.
- Chưa xác nhận: nền tảng phát hành đầu tiên, stack, mô hình thương mại, giấy phép sản phẩm, thiết bị hỗ trợ, ngưỡng nghiệm thu cuối cùng.

> Tài liệu này bảo tồn các đề xuất để tham khảo. Không tự động biến đề xuất thành việc phải triển khai, không coi toàn bộ roadmap đã được duyệt. Mọi lựa chọn công nghệ, phiên bản, giấy phép và benchmark cần kiểm chứng lại ở Research/Spec gate trước khi viết code sản phẩm. Khảo sát không bao phủ toàn bộ GitHub và chưa có so sánh thực nghiệm trên thiết bị thật.

## 1. Định hướng được đề xuất

X-Scanner nên giúp người dùng chụp được tài liệu rõ, đủ và đúng ngay lần đầu; xuất PDF/JPG/PNG, ưu tiên xử lý cục bộ, không yêu cầu tài khoản cho scan cơ bản. Chất lượng chụp đầu vào quan trọng hơn việc làm đẹp ảnh sau chụp.

Thứ tự ưu tiên đề xuất:

1. Bảo toàn chữ, dấu tiếng Việt, số tiền, chữ ký, con dấu và mực nhạt.
2. Hướng dẫn chụp, nhận diện trang, phát hiện rung/mờ/chói, tự chụp đúng lúc.
3. Xuất file nhiều trang đáng tin cậy, sắp xếp trang, dùng khi không có mạng.
4. OCR Việt/Anh và PDF tìm kiếm được.
5. Sách cong, giấy nhăn, giấy bóng, hóa đơn dài và depth trên máy phù hợp.

Không dùng AI sinh nội dung để lấp phần chữ bị mất, bị che hoặc phản sáng. Giữ bản gốc và khả năng quay lại trước chỉnh sửa.

## 2. Ứng dụng tham khảo

Các điểm dưới đây là nội dung khảo sát đã trao đổi, không phải bảng xếp hạng chất lượng ảnh đã đo. Tính năng/gói trả phí cần xác minh tại thời điểm chọn giải pháp.

| Ứng dụng | Điều nên học |
|---|---|
| Adobe Scan | Tự nhận diện, chỉnh phối cảnh, xử lý ảnh, OCR và PDF tìm kiếm được. |
| Genius Scan | Scan liên tục nhiều trang, thêm trang nhanh, ít gián đoạn. |
| Scanner Pro | Xem lại, sửa từng trang, quản lý tài liệu gọn. |
| SwiftScan | Phân tách scan/OCR và lưu trữ/đồng bộ; người dùng chọn nơi lưu. |
| CamScanner | Tổ chức chế độ tài liệu, sách, giấy tờ; chưa đưa toàn bộ bộ công cụ vào MVP. |
| Apple Notes/Files | Luồng đơn giản, tự chụp hoặc thủ công, sửa vùng cắt. |
| Google Drive | Chụp → kiểm tra → lưu; X-Scanner nên có đường lưu cục bộ độc lập. |
| Google PhotoScan | Chụp đa góc để giảm phản sáng, tham khảo cho giấy bóng/ảnh in. |

Microsoft Lens được ghi nhận trong khảo sát là ngừng tạo scan mới sau 2026-03-09; không lấy làm phụ thuộc hoặc nền tảng dài hạn. Xem thông báo chính thức trong danh mục nguồn.

## 3. Repo nên đối chiếu

Giấy phép trong bảng là ghi nhận từ khảo sát trước, **không phải kết luận thẩm định pháp lý**. Trước khi tái sử dụng phải kiểm tra LICENSE tại commit cụ thể, trọng số, dữ liệu, phụ thuộc bắc cầu và nghĩa vụ phân phối.

| Repo GitHub | Vai trò / đề xuất |
|---|---|
| ossappscollective/OSS-DocumentScanner | Tham khảo ứng dụng NativeScript/OpenCV/Tesseract, MIT; không fork toàn bộ ngay. |
| ethereal-developers/OpenScan | Tham khảo luồng tài liệu/PDF, BSD-3-Clause. |
| pynicolas/FairScan | Học UX tối giản, xử lý cục bộ và quyền riêng tư; GPL-3.0 cần quyết định tương thích. |
| pencilresearch/OpenScanner | Tham khảo iOS/SwiftUI và vòng đời tài liệu; MIT. |
| vicajilau/cunning_document_scanner | Ứng viên nguyên mẫu Flutter Android/iOS; không mặc định là lõi camera/depth lâu dài. |
| WebsiteBeaver/react-native-document-scanner-plugin | Phương án tham khảo nếu chọn React Native; không tích hợp song song chỉ để có thêm thư viện. |
| WeTransferArchive/WeScan | Nguồn tham khảo iOS; khảo sát ghi nhận đã archive, không chọn phụ thuộc chiến lược. |
| opencv/opencv | Hình học, biến đổi ảnh và phép đo chất lượng. |
| tesseract-ocr/tesseract | OCR offline đối chứng; có dữ liệu tiếng Việt `vie`. |
| PaddlePaddle/PaddleOCR | Đánh giá model gọn phù hợp thiết bị; không bê nguyên hệ thống lớn lên mobile. |
| DavBfr/dart_pdf | Ứng viên PDF khi chọn Flutter; phải thử lớp chữ, Unicode và bộ nhớ tài liệu dài. |
| ocrmypdf/OCRmyPDF | Tham khảo lớp OCR và giữ ảnh trang; công cụ kiểm thử/desktop, không nhúng nguyên Python app vào mobile. |
| ScanTailor-Advanced/scantailor-advanced | Tham khảo hậu kỳ sách, dewarp và batch; không coi là SDK mobile dùng trực tiếp. |
| tanguymagne/UVDoc | Ứng viên thử nghiệm đầu tiên cho trang cong, sau kiểm tra tốc độ và bảo toàn chữ. |
| cvlab-stonybrook/DewarpNet | Mốc đối chứng 3D/2D; không mặc định là lựa chọn tốt nhất. |
| ZZZHANG-jx/DocRes | Thử riêng cong, bóng đổ, mờ; chỉ tích hợp tác vụ vượt kiểm thử nội dung. |
| fh2019ustc/DocTr và DocTr-Plus | Tham khảo nghiên cứu; chưa đưa vào bản thương mại khi quyền sử dụng chưa được giải quyết. |
| tanguymagne/SyntheticDoc | Theo dõi dữ liệu tổng hợp; cần xác minh độ đầy đủ của dữ liệu đã phát hành. |
| fh2019ustc/Awesome-Document-Image-Rectification | Danh mục tìm thêm phương pháp, không phải bảo chứng production-ready. |

Nguyên tắc: xây sản phẩm riêng và tái sử dụng có chọn lọc; không ghép mọi repo thành một ứng dụng. Không mang dữ liệu người dùng thật vào repo public.

## 4. Khoảng cách và chiều sâu: hướng thử nghiệm

### 4.1. Phân biệt dữ liệu

- Một khoảng cách: giúp hướng dẫn gần/xa, không mô tả độ cong cả trang.
- Mặt phẳng tài liệu: hỗ trợ căn góc và kích thước khi đủ điều kiện.
- Bản đồ chiều sâu: bổ sung hình dạng bề mặt, không thay thế chi tiết chữ từ camera màu.

Depth cung cấp hình học; ảnh độ phân giải cao cung cấp chữ. Không yêu cầu LiDAR để dùng scan cơ bản.

### 4.2. Theo khả năng thiết bị

- Không có depth: nhận diện trang, phối cảnh, độ nét, rung/chói; có thể thử ước lượng khoảng cách khi biết kích thước vật lý và hiệu chuẩn camera.
- Không tự nhận một hình chữ nhật là A4 rồi hiển thị centimet như phép đo chính xác.
- Android hỗ trợ ARCore Depth: thử chiều sâu từ chuyển động và cảm biến hỗ trợ; dùng confidence để bỏ dữ liệu yếu.
- iOS/iPadOS có scene depth: kiểm tra khả năng API tại runtime, không suy đoán chỉ từ tên thiết bị.
- Chưa đủ tin cậy: quay về đường camera thường, không mất tính năng.

Tài liệu ARCore trong khảo sát nêu khoảng hoạt động tốt nhất 0,5–5 m; scan cận cảnh và trang trắng ít họa tiết phải được thử riêng. Không bắt người dùng lùi xa làm chữ nhỏ đi chỉ để depth ổn hơn.

### 4.3. Hướng dẫn chụp

Màn hình chỉ ưu tiên một hướng dẫn: gần hơn → giảm nghiêng → tránh chói → giữ yên → tự chụp. Kết hợp độ phủ trang, độ nét nhiều vùng, lấy nét, chuyển động, ánh sáng và depth nếu tin cậy.

Không tự chụp chỉ vì có bốn góc; luôn có chụp thủ công. Đầu tiên thử chuỗi ảnh ngắn rồi chọn ảnh tốt nhất. Chỉ hợp nhất ảnh khi căn chỉnh đáng tin cậy và không tạo bóng chữ.

Giấy bóng có thể thử nhiều góc. Nếu vùng chữ mất trong mọi ảnh, yêu cầu chụp lại; không tự sinh phần thiếu.

### 4.4. Sách cong

Ảnh màu + biên trang/dòng chữ + depth đáng tin cậy → ước lượng lưới biến dạng → ánh xạ lại ảnh gốc → kiểm tra nội dung. Depth làm ràng buộc phụ là đề xuất R&D, không phải tính năng có sẵn chỉ cần bật trong UVDoc.

Không cam kết sửa mọi nếp gấp, gáy sách hoặc chữ bị che. Kiểm chứng tích hợp camera/depth ngay P0 dù phát hành tính năng ở giai đoạn sau.

## 5. Kiến trúc ứng viên — chưa chốt

Ứng viên được đề xuất trong cuộc trao đổi: Flutter cho UI/thư viện/chỉnh trang; Kotlin CameraX/Camera2/ARCore trên Android; Swift AVFoundation/Vision/ARKit trên iOS; C++/OpenCV cho xử lý chung; SQLite metadata và ảnh ở file riêng; OCR và xuất file qua interface thay thế được.

Không giả định Flutter tự làm ảnh tốt hơn React Native. Chất lượng phụ thuộc camera, thuật toán, dữ liệu và pipeline.

Scanner hệ thống/ML Kit phù hợp làm nguyên mẫu và baseline. Luồng tải tài nguyên lần đầu, phụ thuộc Google Play Services và giới hạn can thiệp camera phải kiểm chứng trước khi hứa offline hoặc tích hợp depth.

Không giả định CameraX và ARCore mở camera độc lập cùng lúc. Thử shared camera/Camera2, đồng bộ timestamp, intrinsics, extrinsics, crop/orientation, confidence và độ phân giải ảnh/depth.

Pipeline đề xuất:

```text
Chụp/nhập ảnh → lưu bản gốc → kiểm tra chất lượng
→ cắt/chỉnh phối cảnh → dewarp khi cần → cân sáng/bộ lọc
→ OCR tùy chọn → PDF/JPG/PNG
```

Lưu thông số chỉnh sửa thay vì ghi đè bản gốc. PDF tìm kiếm được giữ ảnh làm nội dung nhìn thấy, thêm lớp chữ OCR vô hình; kiểm tra Unicode Việt, vị trí, thứ tự đọc, xoay trang, sao chép và tìm kiếm. Không thay ảnh scan bằng văn bản OCR vẽ lại.

Xử lý theo hàng đợi có giới hạn, thumbnail cho preview, model nặng sau chụp, cache và phục hồi phiên. Một ảnh 12 triệu pixel RGBA cần khoảng 48 MB vùng pixel; không nạp hàng chục ảnh gốc đồng thời. Mục tiêu scan cơ bản không phát sinh phí API theo trang; không có nghĩa mọi chi phí vận hành bằng không.

## 6. UX và phạm vi ứng viên

Ba bước: **Chụp → Xem lại → Xuất**.

- Chụp: camera lớn, nút chụp/nhập ảnh, thumbnail phiên, một cảnh báo ưu tiên, tự chụp có bật/tắt.
- Xem lại: thứ tự trang, đánh dấu mờ/chói/cắt thiếu, sửa góc, xoay, chụp lại, so sánh bản gốc.
- Xuất: PDF/JPG/PNG, chất lượng, tên/nơi lưu, khổ trang không kéo giãn sai tỷ lệ.

Bộ lọc đầu: gốc, màu tài liệu, xám, đen trắng. Ảnh in cần giữ màu, không dùng mặc định bộ lọc tẩy nền văn bản. Không gọi nội suy ảnh là tăng độ phân giải thực chỉ bằng nhãn DPI.

MVP ứng viên: chụp/nhập, cắt/chỉnh phối cảnh, nhiều trang, sắp xếp/chụp lại, lưu gốc, PDF/ảnh offline. Tiếp theo: OCR Việt/Anh, chất lượng tự chụp. Để sau: sách cong, chống chói đa góc, hóa đơn dài, hai mặt giấy tờ, đồng bộ.

Chưa đưa chatbot, fax, tài khoản bắt buộc, cloud riêng hoặc bộ chỉnh PDF toàn diện vào bản đầu. Mặc định không upload tài liệu, không log ảnh/OCR, quản lý cả file tạm và dữ liệu OCR khi xóa.

## 7. Roadmap tham khảo, không phải lịch cam kết

Ước lượng ban đầu giả định hai kỹ sư mobile, một kỹ sư xử lý ảnh và QA bán thời gian; cần lập lại sau P0.

| Mốc | Khung tham khảo | Đầu ra / cổng |
|---|---|---|
| P0 | Tuần 1–2 | Repo/CI, license inventory, camera high-res/depth spike, dữ liệu kiểm thử; xác nhận đường camera khả thi. |
| P1 | Tuần 3–6 | Scan nhiều trang, cắt/phối cảnh, lưu gốc, PDF/ảnh, phục hồi phiên offline. |
| P2 | Tuần 7–10 | Mờ/chói, tự chụp, chọn ảnh, cân sáng, OCR Việt/Anh và PDF text layer; test bộ nhớ. |
| P3 | Tuần 11–14 | Hướng dẫn khoảng cách/góc, confidence/fallback, A/B depth có lợi ích đo được. |
| P4 | R&D riêng | Sách, đa góc, hóa đơn dài; chỉ phát hành phần vượt quality/performance gate. |

Cấu trúc code gợi ý: apps/mobile; packages/scan_core, capture_android, capture_ios, depth, ocr, export; benchmarks; tests; docs; third_party. Chưa tạo giả code hoặc đánh dấu app đã build.

Android, iOS và dữ liệu/test có thể chạy song song khi phạm vi file độc lập. Cần chốt contract trang, tọa độ, thời gian và hiệu chuẩn trước khi chia việc.

## 8. Benchmark và tiêu chí nghiệm thu ứng viên

Tập thử: Việt/Anh, chữ nhỏ, dấu tiếng Việt, chữ ký/con dấu, mực nhạt, nền giống giấy, giấy nhăn/bóng, sách cong, thiếu sáng. Tách theo tài liệu vật lý, tránh rò rỉ cùng trang giữa tập tối ưu và đánh giá. So sánh app trên cùng thiết bị, ánh sáng, tài liệu; ghi phiên bản, xử lý và mức nén.

Các số sau **là mục tiêu đề xuất, chưa đo và chưa được phê duyệt**:

- Phát hiện đầy đủ trang ≥95% trên tập phẳng/đủ sáng đã định nghĩa.
- Không mất chữ/chữ ký/con dấu trong tập regression bắt buộc.
- OCR CER ≤2% trên chữ in Việt sạch; lỗi dấu vẫn tính là lỗi.
- Xử lý trang cơ bản p95 ≤2 giây trên nhóm máy được chọn, chưa tính OCR.
- Tài liệu 100 trang không hết bộ nhớ; phiên scan phục hồi được.
- PDF đúng số trang, tỷ lệ, chiều, vị trí/Unicode lớp chữ.
- Depth chỉ bật mặc định sau khi chứng minh giảm chụp lại mà không làm giảm độ nét hoặc vượt ngân sách tài nguyên.

A/B riêng: camera thường → thêm hướng dẫn rung/góc → thêm depth → thêm chọn ảnh. Ngưỡng thử ban đầu có thể là giảm ≥15% tương đối tỷ lệ chụp lại ở nhóm tình huống mục tiêu; phải điều chỉnh theo dữ liệu.

## 9. Nguồn đối chiếu

### Ứng dụng và API chính thức

- https://www.adobe.com/acrobat/mobile/scanner-app.html
- https://thegrizzlylabs.com/genius-scan/
- https://readdle.com/scannerpro
- https://swiftscanapp.com/
- https://www.camscanner.com/
- https://support.apple.com/en-us/108963
- https://support.google.com/drive/answer/3145835
- https://www.google.com/intl/en/photos/scan/
- https://support.microsoft.com/en-us/lens/retirement-of-microsoft-lens
- https://developers.google.com/ar/develop/depth
- https://developers.google.com/ar/develop/java/depth/raw-depth
- https://developers.google.com/ar/develop/java/camera-sharing
- https://developer.apple.com/documentation/arkit/displaying-a-point-cloud-using-scene-depth
- https://developer.apple.com/documentation/arkit/arconfiguration/framesemantics-swift.struct/scenedepth
- https://developers.google.com/ml-kit/vision/doc-scanner/android
- https://developers.google.com/ml-kit/vision/text-recognition/v2/languages

### Repo

- https://github.com/ossappscollective/OSS-DocumentScanner
- https://github.com/ethereal-developers/OpenScan
- https://github.com/pynicolas/FairScan
- https://github.com/pencilresearch/OpenScanner
- https://github.com/vicajilau/cunning_document_scanner
- https://github.com/WebsiteBeaver/react-native-document-scanner-plugin
- https://github.com/WeTransferArchive/WeScan
- https://github.com/opencv/opencv
- https://github.com/tesseract-ocr/tesseract
- https://github.com/PaddlePaddle/PaddleOCR
- https://github.com/DavBfr/dart_pdf
- https://github.com/ocrmypdf/OCRmyPDF
- https://github.com/ScanTailor-Advanced/scantailor-advanced
- https://github.com/tanguymagne/UVDoc
- https://github.com/cvlab-stonybrook/DewarpNet
- https://github.com/ZZZHANG-jx/DocRes
- https://github.com/fh2019ustc/DocTr
- https://github.com/fh2019ustc/DocTr-Plus
- https://github.com/tanguymagne/SyntheticDoc
- https://github.com/fh2019ustc/Awesome-Document-Image-Rectification

## 10. Quy tắc chuyển gợi ý thành công việc

Trước khi code sản phẩm: đọc PROJECT.md và quy trình projects-template, lập Work ID/spec nhỏ, kiểm chứng lựa chọn công nghệ và license, mô tả test/evidence, chỉ triển khai phạm vi được duyệt. Lưu template không đồng nghĩa đã hoàn thành P0, có app chạy được, CI mobile xanh hoặc quality target đạt.
