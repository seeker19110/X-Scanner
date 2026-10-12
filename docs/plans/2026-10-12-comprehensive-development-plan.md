# X-Scanner — Kế hoạch phát triển toàn diện

**Ngày lập:** 12/10/2026 (Asia/Ho_Chi_Minh).  
**Mốc mã nguồn đối chiếu:** `d219ce7aed4cd434e6511814d6248eb5cf043cd0`, nhánh `main`.  
**Trạng thái:** DRAFT / ĐỀ XUẤT PHÁT TRIỂN. Không phải phê duyệt triển khai toàn bộ, không phải báo cáo nghiệm thu.  
**Phạm vi:** nâng cấp sản phẩm hiện có, Android trước; chuẩn bị iOS và nghiên cứu depth song song có giới hạn. Không viết lại toàn bộ, không mở rộng framework hoặc thêm hệ điều phối mới chỉ để phát triển scanner.

## 1. Mục tiêu và quyết định định hướng

X-Scanner giúp người dùng số hóa tài liệu rõ, đủ, đúng ngay từ lần chụp đầu; lưu được lâu dài, tìm được nội dung và xuất file phù hợp công việc. Nhóm người dùng ưu tiên đề xuất: người Việt số hóa giấy tờ, học liệu và hồ sơ công việc; tiếng Anh là ngôn ngữ thứ hai. Phân khúc này cần xác nhận bằng thử nghiệm với người dùng, không coi là nhu cầu thị trường đã được đo.

Thứ tự giá trị: **an toàn dữ liệu → chụp đúng → xử lý trung thực → tài liệu hữu dụng → tiện lợi → tính năng đặc biệt**.

Các nguyên tắc đề xuất:

- Scan/PDF/ảnh và OCR cơ bản xử lý tại máy; không bắt buộc tài khoản hoặc máy chủ.
- Không tự sinh lại chữ, chữ ký, dấu, số tiền hoặc phần tài liệu bị che/chói. Cần chụp lại khi không đủ dữ liệu.
- Lưu bản gốc trong vùng riêng của app. Chỉnh sửa tạo tham số/bản dẫn xuất, không ghi đè bản gốc.
- Máy thiếu depth vẫn có đầy đủ scan thông thường. Depth phải chứng minh lợi ích trước khi bật mặc định.
- Android 1.0 không phụ thuộc việc nghiên cứu sách cong/depth thành công.
- Mọi chỉ tiêu số dưới đây là mục tiêu đề xuất, chưa phải kết quả X-Scanner đạt được. Đo baseline và chốt lại ở spec trước triển khai; thay đổi ngưỡng phải có lý do, không hạ ngưỡng để hợp thức hóa lỗi.

## 2. Baseline phải kế thừa

Theo PROJECT.md tại commit đối chiếu, P1 đã có chụp qua camera hệ thống/nhập ảnh, quản lý trang, chỉnh bốn góc bằng homography Dart, lưu phiên/bản gốc và xuất PDF/JPG/PNG. UAT AC-9 chưa hoàn tất; OCR, camera tự chụp, depth và build iOS chưa được nghiệm thu. [R1]

CI hiện cấu hình Flutter 3.47.7, build Android debug, analyze, format, test và cổng repository. Đây không phải bằng chứng phát hành release hay camera hoạt động trên mọi thiết bị. [R2]

Kế hoạch cũ có W-104 cho decoder, W-504 cho kiểm target SDK; W-502 còn ghi đang làm dù commit main đã chứa thay đổi PR #22. Kế hoạch mới phải đối chiếu, đóng đúng việc đã merge, không tạo lại chúng. [R3][R4]

Nhánh main trả về protected=false ở lần kiểm tra. Cấu hình bảo vệ và required checks thực phải được xác minh; không suy luận từ file ruleset mẫu. [R4]

### Giữ lại

Flutter và cấu trúc `apps/mobile/lib`; core hình học; cách tách storage/imaging/export/UI; bộ test hồi quy; lưu bản gốc; hàng đợi giải mã; quy trình projects-template đã áp dụng.

### Nâng cấp có chọn lọc

Camera, chiến lược giải mã/bộ nhớ, xuất PDF dài, thư viện nhiều tài liệu, UI xem trước, OCR và kiểm thử thiết bị. Chỉ thay xử lý Dart bằng native/OpenCV ở nơi benchmark chứng minh cần thiết; không chuyển toàn bộ lõi sang C++ theo cảm tính.

## 3. Phạm vi các bản sản phẩm

| Mốc sản phẩm đề xuất | Người dùng nhận được | Điều không được quảng cáo ở mốc này |
|---|---|---|
| Alpha P1 ổn định | Scan thủ công, giữ bản gốc, xuất an toàn, phục hồi lỗi | Scanner AI, OCR, LiDAR, độ chính xác thương mại |
| Beta scan thông minh | Camera trong app, tự nhận trang, xem trước đã cắt, bộ lọc, tự chụp có kiểm chất lượng | Scan sách/giấy bóng hoàn hảo |
| Android 1.0 | Beta + nhiều tài liệu, tìm kiếm OCR Việt/Anh, PDF searchable, bộ kiểm chứng thiết bị và bảo mật | iOS đã nghiệm thu; xử lý mọi loại giấy/chữ viết tay |
| iOS tương đương | Luồng cốt lõi đạt cùng tiêu chí, có kiểm thử riêng trên iPhone | LiDAR có trên mọi iPhone; kết quả ngang nhau khi chưa benchmark |
| Scanner nâng cao | Chế độ sách, giấy bóng, hóa đơn dài, depth theo thiết bị | Đo vật lý chính xác tuyệt đối; phục hồi phần chữ không có trong ảnh |

Tạm ngoài phạm vi 1.0: cloud riêng, cộng tác nhiều người, fax, chatbot tài liệu, bảng biểu thành Excel/Word hoàn hảo, e-signature pháp lý, chỉnh PDF tổng quát, backend AI lớn. Nhập PDF có sẵn cũng là phạm vi riêng: parser không tin cậy và hợp nhất tài liệu phải được review trước khi bật.

## 4. Kiến trúc đích

### 4.1. Thành phần và cách phát triển

| Thành phần | Hướng đề xuất | Điều kiện quyết định |
|---|---|---|
| UI/domain | Giữ Flutter; tách màn và controller theo nghiệp vụ khi có nhu cầu | Không tạo lớp trừu tượng chỉ để giống sơ đồ kiến trúc |
| Camera Android | Adapter CameraX cho preview, analysis và ảnh chụp; giữ camera hệ thống dự phòng | Spike độ phân giải, vòng đời, phân tích đồng thời, quyền CAMERA |
| Camera iOS | Adapter AVFoundation/Vision cho luồng riêng | Build macOS/Xcode và thử thiết bị; không suy từ scaffold |
| Xử lý ảnh | Giữ Dart làm đối chứng; native/OpenCV cho điểm nghẽn được đo | So độ nét, thời gian, bộ nhớ, kích thước app và chi phí bảo trì |
| Dữ liệu | DocumentRepository; ảnh ở file riêng, metadata có phiên bản; SQLite là ứng viên cho nhiều tài liệu và chỉ mục OCR | ADR migration, rollback và kiểm fault injection trước khi đổi store |
| OCR | OcrEngine thay thế được; chọn một engine mặc định theo benchmark | Việt/Anh, offline lần đầu, giấy phép, RAM và kích thước |
| PDF/ảnh | ExportJob + PdfWriter/renderer thay thế được | Bằng chứng bộ nhớ không giữ toàn bộ dữ liệu ảnh lớn trong app/engine |
| Depth | DepthProvider tùy chọn, sau camera contract | Runtime capability, đồng bộ và confidence; không bắt buộc để mở app |

CameraX hỗ trợ phân tích ảnh với chiến lược lấy frame mới nhất; không cần xếp hàng tất cả frame preview để làm scanner. [R7]

### 4.2. Contract cần chốt trước khi chia việc

- **CapturedPage:** assetId, nguồn camera/import, kích thước, orientation và cameraId. Nếu có depth: timestamp, hiệu chuẩn và phép đổi tọa độ gắn với đúng frame.
- **EditRecipe:** revision, bốn góc trong hệ tọa độ chuẩn, xoay, bộ lọc/tham số, phiên bản thuật toán. Mọi biến đổi về một quy ước nhất quán.
- **QualityReport:** nét, rung, chói, thiếu mép, confidence và lý do hướng dẫn. Trường thiếu phải là unknown, không giả định đạt.
- **OcrResult:** assetId + revision + engine/model version, chữ, bounding boxes và thứ tự đọc. Không sửa ảnh gốc bằng chữ OCR.
- **ExportJob:** snapshot danh sách trang và recipe, định dạng/profile, trạng thái, tiến độ, lỗi, cancel/resume token và file đích.

Kết quả chạy muộn của revision cũ không được gắn vào trang đã sửa. Undo/redo phải vô hiệu hóa cache và OCR liên quan có chủ đích. Chụp ảnh full-resolution không gửi qua bridge dưới dạng chuỗi base64; dùng file/buffer thích hợp, preview chỉ gửi dữ liệu cần thiết.

### 4.3. Chuỗi xử lý

Capture/import → kiểm đầu vào → lưu gốc → xác định trang/quality → recipe → render → OCR trên hình học cuối → xuất file.

Preview, kết quả xuất và OCR phải dùng cùng hệ tọa độ và revision. Đây là ràng buộc xuyên suốt, không để từng màn tự tính góc/cắt/xoay khác nhau.

## 5. Giai đoạn M0 — Đóng P1 và bảo đảm an toàn đầu vào

### 5.1. Decoder và W-104

Repo đang có exception EX-1 cho image 4.10.1 đến 18/10/2026. Changelog chính thức 4.12.0 nêu sửa vòng lặp EXIF/TIFF, thêm giới hạn điểm ảnh và các trường hợp giải nén dữ liệu không tin cậy. Không suy luận nâng version tự giải quyết hết mọi vấn đề. [R5][R6]

Đề xuất chuẩn bị bản vá ngay: kiểm nguồn phát hành và thay đổi trực tiếp/bắc cầu, ghim version + lockfile, test các tệp lỗi tổng hợp, kiểm mọi lời gọi decoder đều dùng giới hạn phù hợp. Nếu cần rút ngắn thời gian chờ 7 ngày, thực hiện qua ngoại lệ bảo mật được người có thẩm quyền duyệt; không âm thầm phá chính sách.

Chặn phân phối ngoài nhóm phát triển cho tới khi trường hợp treo/giải nén quá mức đã có kiểm soát được chứng minh. Ảnh do người dùng chọn vẫn là đầu vào không tin cậy.

Hàng rào gồm: trần byte đầu vào, kích thước giải mã, số frame/metadata/giải nén khi engine hỗ trợ; nhận dạng theo nội dung chứ không chỉ đuôi file; ngân sách thời gian và cơ chế dừng worker thật. `Future.timeout` chỉ kết thúc chờ, không tự hủy công việc nguồn. Isolate giúp điều phối nhưng không phải ranh giới cách ly bộ nhớ bảo mật của tiến trình. [R13]

### 5.2. Cổng, báo cáo và UAT

Hoàn thành W-504 cùng test đỏ-trước/xanh-sau; đối chiếu target SDK thực, component exported và quyền của manifest release. Cập nhật W-502 theo merge SHA thay vì tiếp tục sửa lại.

Nghiệm thu AC-9: camera/import → chỉnh → xuất PDF → mở bằng ứng dụng xem PDF thật, thử hủy camera, hủy share, xoay màn, mất focus, đóng/mở app và file hỏng. Emulator kiểm tích hợp cơ bản; thiết bị thật kiểm camera, nhiệt và bộ nhớ.

Bật required checks đúng tên hiện tại `Framework and Android app gate`, hoặc di chuyển có kiểm soát sang job tổng hợp `gate`; không nhập ruleset mẫu trỏ check không tồn tại. Thử PR cố tình lỗi và xác nhận không merge được. Chuẩn bị secret scan, kiểm phụ thuộc, khóa artifact build, quy tắc không đưa giấy tờ cá nhân vào repo public.

**Cổng M0:** các lỗi dữ liệu mức cao trong phạm vi đã được đóng bằng test; decoder không còn ca treo đã biết chưa kiểm soát; UAT cơ bản có bằng chứng; settings thực đã xác minh hoặc blocker rõ. Chưa gọi sản phẩm sẵn sàng phát hành chỉ vì M0 qua.

## 6. Giai đoạn M1 — Tài liệu bền vững, xuất file và UX đúng

### 6.1. Từ một phiên sang thư viện tài liệu

Bổ sung tạo tài liệu, tên, ngày, nhiều phiên độc lập, mở lại, nhân bản, thêm trang và gộp/tách các tài liệu do app quản lý. Chưa cần cây thư mục phức tạp; danh sách gần đây, tìm theo tên, sắp xếp và thẻ đơn giản là đủ để thử dùng.

Migration phải giữ nguyên mọi ảnh và chỉnh sửa hiện có. Ghi dữ liệu đích ra khu vực tạm, kiểm đủ trang/hash/recipe, chuyển trạng thái khi hợp lệ và giữ đường quay lại. Không giả định transaction SQLite đồng thời bảo vệ thao tác file; dùng nhật ký/commit marker và kiểm phục hồi sau khi dừng tại từng bước.

Có màn phục hồi/xóa phiên hỏng, giải thích lỗi I/O khác bộ nhớ đầy (F-018/F-049). Xóa tài liệu phải quản lý cả thumbnail, OCR, chỉ mục và export cache; thời hạn giữ thùng rác cần người dùng nhìn thấy. Không hứa xóa vật lý tuyệt đối trên bộ nhớ flash; bản đã chia sẻ ra ngoài nằm ngoài phạm vi app.

### 6.2. Xuất PDF và ảnh

Exporter hiện tích lũy mọi trang ảnh trong một list trước khi tạo PDF. Chuyển sang isolate không làm dữ liệu này biến mất. [R8]

Cần spike writer nhận nguồn trang theo file/lazy input và kiểm bộ nhớ thực của cả engine. Nếu engine vẫn giữ ảnh toàn bộ, cân nhắc writer khác hoặc giới hạn tài liệu minh bạch; không đổi sang danh sách đường dẫn rồi tuyên bố đã có streaming. Xuất ảnh tuần tự, snapshot recipe, cancel ở điểm an toàn, không công bố file dở như file hoàn chỉnh.

Profile đề xuất: Gửi nhanh, Cân bằng, Chất lượng cao; có dự kiến dung lượng, chọn trang, tên file, JPG/PNG/PDF và khổ gốc/A4/Letter. Giữ tỷ lệ, không kéo giãn để vừa khổ; không dùng tăng DPI metadata như tuyên bố tăng chi tiết.

Hiện tiến độ i/N, nút hủy, lỗi có hành động thử lại/chọn nơi khác và khả năng tiếp tục phần hợp lệ. File chia sẻ tồn tại đủ thời gian cho ứng dụng nhận đọc; kiểm theo hợp đồng nền tảng, hủy chia sẻ, share thất bại và dọn cache có hạn dùng. Không mặc định đóng share sheet nghĩa là app nhận đã chép xong.

### 6.3. Thiết kế giao diện

Bốn màn nghiệp vụ: **Tài liệu → Chụp → Xem/sửa → Xuất**. Chế độ tối/sáng theo hệ thống và tùy chọn người dùng được lưu; không thay thiết kế đang dùng chỉ vì sở thích của agent.

Xem trước phải áp đúng cắt/xoay/bộ lọc như file xuất (F-026). Trình chỉnh góc có phóng to, vùng lúp khi kéo, undo/redo và hỏi trước khi bỏ thay đổi (F-032). Xuất có tiến độ/hủy (F-033). Việt hóa cả nhãn hệ thống/thao tác trợ năng (F-031), hỗ trợ cỡ chữ lớn và cách chỉnh góc không chỉ dựa vào kéo.

**Cổng M1:** cập nhật từ bản P1 không mất trang; kill/restart tại các bước lưu vẫn khôi phục; preview khớp export; tài liệu dài có giới hạn tài nguyên được đo; người dùng không phải đoán công việc đang chạy hay lỗi.

## 7. Giai đoạn M2 — Camera và scan thông minh

### 7.1. Camera trong app

Tách adapter camera riêng, giữ đường camera hệ thống/import dự phòng. Prototype phải thử preview + frame analysis + ảnh chụp chất lượng cao trên máy yếu và máy phổ thông, xử lý permission từ chối/thu hồi, app vào nền, camera bị app khác dùng, xoay màn, autofocus, exposure, torch và phát sinh nhiệt.

Chuyển sang camera trong app làm thay đổi cam kết P1 không cần CAMERA. Cần spec/ADR mới và cập nhật test/allowlist có chủ đích; vẫn không xin quyền truy cập kho ảnh rộng khi system picker đủ dùng. Không vô hiệu cổng bảo mật cho qua.

CameraX là đường Android mặc định đề xuất. Khả năng dùng depth phải có spike riêng: Google mô tả shared camera của ARCore dựa trên Camera2; không giả định mở hai session độc lập hoặc lấy ảnh CPU từ ARCore tương đương ảnh chụp độ phân giải cao. [R9]

### 7.2. Tự nhận mép và hình học

Thử baseline OpenCV/thuật toán nhẹ trên tập ảnh dự án trước. Các ca bắt buộc: trang trắng trên nền trắng, bóng tay, giấy nhỏ, nền họa tiết, nhiều hình chữ nhật, trang lệch và thiếu góc. Confidence thấp thì cho chỉnh tay; không tự cắt theo phỏng đoán.

Ưu tiên ổn định khung và giữ nội dung sát mép hơn khung trông gọn. Làm mượt theo thời gian nhưng không để trễ dài. Refinement sau chụp chạy trên ảnh độ phân giải cao; không chỉ phóng lớn kết quả preview.

Kiểm riêng ánh xạ sensor → preview crop → ảnh gốc → recipe → ảnh xuất. Tỷ lệ trang vật lý không tự suy ra chắc chắn chỉ từ bốn góc; khổ giấy người dùng xác nhận hoặc hiệu chuẩn đáng tin cậy là thông tin bổ sung, không được giả là A4.

### 7.3. Chất lượng và tự chụp

Đo độ nét ở nhiều vùng trong trang, chuyển động, thiếu sáng, chói và thiếu mép. Trước khi tự chụp cần trạng thái ổn định đủ lâu, lấy nét/exposure phù hợp và chất lượng qua ngưỡng theo thiết bị; không chỉ kiểm có bốn góc.

Chỉ hiện một hướng dẫn ưu tiên: đưa gần hơn, giảm nghiêng, tránh chói hoặc giữ yên. Luôn có chụp thủ công. Có thời gian chờ sau chụp và phát hiện đổi trang để tránh chụp lặp; cảnh báo trùng không tự xóa trang.

Phân tích preview ở độ phân giải nhỏ, ban đầu thử 5–10 lần/giây và giữ frame mới nhất. Xử lý full-resolution sau chụp; giảm tần suất khi nóng. Không chạy OCR nặng hoặc mô hình sinh ảnh ở mọi frame.

### 7.4. Bộ lọc giữ nội dung

Gốc, Màu tài liệu, Xám, Đen trắng; cân sáng, bóng đổ và nghiêng nhẹ theo nhu cầu. Không tẩy nền mạnh với ảnh in, con dấu hay mực nhạt. Giữ màu/ICC có kiểm soát, kiểm alpha, EXIF và dấu tiếng Việt. Người dùng xem trước/sau, cường độ và khôi phục bản gốc.

**Cổng M2:** bộ thử đủ sáng đạt mục tiêu nhận trang, bộ bảo toàn chữ/dấu không hồi quy; self-capture không lặp; giao diện phản hồi tốt; camera riêng thất bại vẫn có đường hoàn thành tác vụ. Có prototype camera/depth và kết luận thiết kế, chưa cần depth thương mại.

## 8. Giai đoạn M3 — OCR, tìm kiếm và PDF searchable

### 8.1. Chọn engine bằng số đo

Android thử ML Kit Text Recognition v2 bản bundled làm ứng viên chính. Google liệt kê tiếng Việt trong nhóm supported và phân biệt model đi kèm app với model tải qua Google Play Services. Bundled phù hợp mục tiêu OCR hoạt động ngay khi cài xong trong chế độ offline; kiểm trên bản cài sạch là bắt buộc. [R10][R11]

Dùng Tesseract `vie+eng` làm đối chứng offline nếu cần; kho tessdata_fast có `vie.traineddata`. Chỉ chọn thêm PaddleOCR/model khác nếu baseline không đạt và benchmark đủ biện minh. Không ship nhiều engine lớn mặc định. [R12]

iOS đánh giá Vision hoặc ML Kit theo ngôn ngữ/OS thực tế và cùng bộ dữ liệu; không giả định engine iOS ngang chất lượng Android.

### 8.2. Pipeline và UX

OCR chạy trên bản render cuối hoặc ảnh dẫn xuất nhẹ có ánh xạ ngược chính xác. Cắt/xoay/thay ảnh làm OCR cũ hết hiệu lực. Lưu revision và phiên bản engine, ưu tiên tài liệu người dùng đang mở, cho phép hủy/tiếp tục. Không để OCR chặn chụp hoặc mất phiên.

Tìm theo tên và chữ trong tài liệu, highlight kết quả; sao chép văn bản kèm hướng dẫn kiểm lại số liệu quan trọng. Đo chữ in Việt/Anh trước; không hứa chữ viết tay, công thức hay bảng phức tạp đã đạt.

PDF giữ ảnh nhìn thấy, thêm lớp chữ vô hình đúng tọa độ/Unicode/thứ tự đọc. Kiểm dấu tiếng Việt, copy/paste và search qua nhiều trình xem. File vẫn được xuất khi OCR không thành công, kèm trạng thái rõ. Không thay bản scan bằng chữ OCR vẽ lại.

Nếu bổ sung che thông tin nhạy cảm ở bản sau, phải loại cả pixel lẫn chữ OCR/chỉ mục trong vùng đó trên bản xuất; ô đen phủ bên trên không đủ. Bản gốc riêng tư và bản xuất đã che phải được phân biệt rõ.

**Cổng M3:** OCR Việt/Anh đạt tiêu chí trên tập đã chốt, lớp chữ không lệch sau cắt/xoay, không dùng kết quả cũ, tìm kiếm offline và nhập/xuất vẫn hoạt động khi OCR thất bại.

## 9. Nhánh D — Khoảng cách, depth và tài liệu khó

### D1. Spike sớm, phát hành sau

Chạy nghiên cứu ngắn cùng M1/M2 để không khóa sai kiến trúc camera: đối chiếu khả năng máy Android không depth, Android hỗ trợ ARCore Depth và iPhone có/không scene depth. Kiểm đường high-resolution capture, timestamp, intrinsics/extrinsics và chuyển hệ tọa độ.

Raw Depth của ARCore không bắt buộc cảm biến ToF riêng, có confidence và có vùng thiếu dữ liệu. Vì vậy không coi mọi máy hỗ trợ ARCore là hỗ trợ depth hoặc mọi pixel depth là đáng tin. [R14]

### D2. Hướng dẫn khoảng cách/góc

Ưu tiên dùng khoảng cách để tránh chụp quá xa/mất chi tiết và hỗ trợ giữ máy đúng hướng. Ảnh RGB cung cấp chữ; depth cung cấp ràng buộc hình học. Không giả rằng một khoảng cách duy nhất mô tả được độ cong cả trang.

Không có depth thì dùng độ phủ trang, nét, góc/IMU có hiệu chuẩn; không hiển thị centimet giả. Tính năng phải tắt được khi camera đổi lens, depth cũ, confidence kém hoặc registration lỗi.

Thử A/B theo cặp cùng máy, tài liệu và ánh sáng: (a) RGB + hướng dẫn thông thường; (b) thêm depth. Đo tỷ lệ chụp lại, thời gian, độ nét, năng lượng/nhiệt và lỗi hình học. Mục tiêu khám phá: giảm ít nhất 15% tương đối số lần chụp lại ở nhóm khó, không làm hỏng nhóm dễ; không coi đây là kết quả đã đạt.

### D3. Sách, giấy bóng và hóa đơn dài

Sách: tách hai trang, ước lượng lưới biến dạng từ ảnh/biên/dòng chữ, depth làm ràng buộc phụ nếu phù hợp. UVDoc là repo nghiên cứu phù hợp để thử neural grid-based unwarping; chưa có bằng chứng nhúng vào mobile đạt yêu cầu X-Scanner. Kiểm riêng license code, weights và dữ liệu. [R15]

Giấy bóng: thử nhiều góc để chọn vùng ít phản sáng, chưa hợp nhất ảnh khi alignment chưa chắc chắn. Hóa đơn dài: ghép có kiểm vùng chồng lặp, không mất/lặp dòng và tổng tiền. Chuỗi ảnh ngắn chọn khung tốt nhất trước khi triển khai fusion/super-resolution.

**Cổng D:** báo cáo có-và-không-depth trên thiết bị thật; bảo toàn nội dung; ngân sách tài nguyên; fallback rõ. Không đạt thì giữ thử nghiệm tắt mặc định, không trì hoãn Android 1.0.

## 10. Giai đoạn M4/M5 — iOS và phát hành

### 10.1. iOS

Kiểm build sớm sau khi các contract cốt lõi ổn định; triển khai tương đương theo nguồn lực, không hứa chỉ mở project là chạy đúng. Kiểm permission, photo picker, định dạng ảnh thực tế (đặc biệt HEIC từ iPhone), đường dẫn temp/cache, chia sẻ, tạm dừng/khôi phục và backup.

iPhone không depth phải đạt lõi scan. LiDAR/scene depth là nhóm thử nghiệm riêng. Kiểm accessibility bằng VoiceOver, cỡ chữ, theme, orientation; parity được xác nhận bằng test và UAT chứ không bằng cùng dùng Flutter.

### 10.2. Bảo mật và quyền riêng tư trước phát hành

Threat model tối thiểu: ảnh nhập độc hại, file lưu dư, cache chia sẻ, giấy tờ trong Recents, quyền rộng, metadata GPS và migration lỗi. Không log nội dung ảnh/OCR/tên tài liệu. Mặc định không upload; mọi chẩn đoán gửi ra ngoài phải opt-in và loại dữ liệu nhạy cảm.

Cân nhắc chế độ tài liệu nhạy cảm che Recents và khóa khi rời app. Nếu quảng cáo vault mã hóa, phạm vi phải gồm gốc, thumbnail, OCR, search index, temp và quản lý khóa bằng cơ chế nền tảng; không tự thiết kế mật mã. Không đưa tính năng vault nửa vời vào 1.0 để có tên quảng cáo.

Hoàn tất license sản phẩm, attribution/dependency/model inventory, chính sách riêng tư, retention và cách xuất/sao lưu do người dùng điều khiển. Backup không được bật lại âm thầm khi đang có quyết định P1 tắt backup.

### 10.3. Build và phân phối

Build Android release/AAB và iOS archive phù hợp; kiểm ký, versioning, artifact checksum, mapping/symbols và dependency lock. Rà SDK target/store rules/privacy declarations theo tài liệu chính thức tại lúc phát hành. Native/OpenCV yêu cầu đưa kiểm tương thích trang bộ nhớ Android 16 KB vào bài test artifact. [R16]

Có artifact APK thử nghiệm tải được cho đúng commit, thay vì chỉ log build thành công. Test máy thật chạy bản profile/release cho hiệu năng; debug build không đại diện tốc độ người dùng.

Phát hành: nhóm phát triển → nhóm thử nghiệm nhỏ tự nguyện → closed beta rộng hơn → production theo đợt sau khi các cổng đạt. Thu crash/hang, tỷ lệ hoàn tất scan, thời gian tới PDF đầu tiên, tỷ lệ chụp lại và phản hồi; không dùng lượng commit/agent làm KPI.

Rollback: tắt riêng tính năng qua cấu hình/feature flag phù hợp chế độ offline, dừng rollout và phát hành bản sửa. Không giả định cửa hàng cho downgrade tùy ý; schema mới phải giữ tương thích hoặc có đường phục hồi. Không xóa tài liệu của người dùng để giải quyết lỗi migration.

## 11. Bộ đo chất lượng và tiêu chí nghiệm thu

### 11.1. Dữ liệu benchmark

Khởi đầu đề xuất: 100 tài liệu vật lý hợp pháp/được phép dùng, tối thiểu 3 điều kiện chụp mỗi tài liệu; tăng tới 1.000 ảnh trước beta công khai. Chia tập theo tài liệu vật lý, không để cùng trang chỉ khác góc xuất hiện ở cả tập tinh chỉnh và tập nghiệm thu.

Bao gồm Việt/Anh, chữ nhỏ, dấu, chữ ký/con dấu, mực nhạt, số tiền/bảng, nền giống giấy, mép sát chữ, lệch góc, ánh sáng không đều, bóng tay, giấy bóng, sách, ảnh lớn/hỏng và tài liệu dài. Dữ liệu public chỉ dùng ảnh tổng hợp/được cấp phép; hồ sơ cá nhân không vào Git hoặc log CI.

Có nhãn góc trang, vùng nội dung phải giữ, transcription kiểm tay cho tập OCR và ảnh chuẩn tham chiếu phù hợp. Dùng camera-system hiện tại làm baseline; đối chiếu thêm các app scanner được chọn trên cùng thiết bị, phiên bản, độ phân giải/mức nén và điều kiện. Không cần khảo sát vô hạn mọi repo.

### 11.2. Chỉ tiêu đề xuất

| Nhóm | Mục tiêu ban đầu | Cách chứng minh |
|---|---|---|
| Toàn vẹn dữ liệu | 0 mất trang/gốc trên bộ fault-injection và migration bắt buộc | Kill tại từng bước, thiếu đĩa, file hỏng, đổi version, hash/manifest reconciliation |
| Mép trang | ≥95% trang thông thường đạt vùng cắt, đủ nội dung | Tập holdout chốt trước; sai số góc + nội dung sát mép, không chỉ IoU |
| Bảo toàn chữ | Không mất/thay chữ ký, dấu, ký tự kiểm soát trong tập bắt buộc | Diff có căn hình học, kiểm người, OCR chỉ là một tín hiệu |
| OCR Việt | CER ≤2% trên chữ in sạch | Nhãn chuẩn Unicode NFC; lỗi dấu được tính; báo riêng từng nhóm tài liệu |
| Xem trước | ≥24 frame/giây trên nhóm máy tầm trung, analysis 5–10 Hz | Frame timing đo khi chụp liên tục, không trộn FPS preview với tốc độ phân tích |
| Xử lý một trang | p95 ≤2 giây với ảnh 12 MP, không tính OCR | Profile/release, thiết bị được chỉ định, đo cold/warm và lúc nóng |
| Bộ nhớ | Thử ngân sách peak ≤400 MB trên thiết bị Android 4 GB với workload 12 MP | Đo toàn tiến trình gồm native, ảnh, PDF và Flutter; điều chỉnh phạm vi trước release nếu không đạt |
| PDF dài | 100 trang 12 MP hoàn thành trong giới hạn đã chốt, hủy/tiếp tục an toàn | Test thực end-to-end; không dùng ảnh thumbnail để giả bài stress |
| Offline | Cài sạch và hoàn tất scan/OCR/xuất ở chế độ máy bay | Kiểm model đã bundled, permission/network và cả nhánh lỗi |
| Dễ dùng | ≥90% trong tối thiểu 10 người mới hoàn thành tài liệu 3 trang không được chỉ tay từng bước | Kịch bản nhất quán, ghi điểm mắc, không suy ra thị trường từ mẫu nhỏ |
| Độ ổn định beta | Mục tiêu ≥99,5% phiên không crash trên ≥1.000 phiên đủ điều kiện | Ghi rõ mẫu/định nghĩa; đo hang và mất dữ liệu riêng; không gửi nội dung tài liệu |
| Depth | Mục tiêu giảm ≥15% tương đối chụp lại trong nhóm mục tiêu | A/B theo cặp, báo độ bất định; không giảm nét, không vượt ngân sách nhiệt/tài nguyên |

Các chỉ tiêu RAM/latency phải qua spike. Nếu không đạt thì tối ưu hoặc giảm phạm vi công khai một cách minh bạch, không ghi “PASS” bằng số dự đoán.

### 11.3. Ma trận thiết bị

Android: máy RAM thấp được chọn, máy tầm trung phổ biến, máy hỗ trợ ARCore Depth; nhiều phiên bản OS/hãng camera; môi trường 16 KB khi có native. iOS: iPhone không depth và thiết bị có scene depth, ít nhất phiên bản OS tối thiểu và phiên bản mục tiêu. Emulator kiểm integration; ảnh/nhiệt/depth cần máy thật.

## 12. Tổ chức công việc theo projects-template

Giữ Standard Delivery Contract hiện có, không thêm quy trình song song. Mỗi tính năng có spec/outcome, phạm vi, quyền thay đổi, acceptance, test, rollback; sau đó mới Approved và code. Không chuyển tài liệu gợi ý thành Approved bằng việc thêm nhãn tự động. [R17]

Đề xuất một goal nhiều PR cho mỗi milestone. `PROGRESS.md` chỉ tóm tắt; issue/PR giữ trạng thái thực; `docs/work/...` giữ checkpoint; spec giữ contract. Cập nhật trong PR thay đổi hành vi để tránh drift.

Phân vai: chủ sản phẩm quyết scope và quyền settings/release; người điều phối giữ contract/ưu tiên; kỹ sư mobile giữ camera/lifecycle; kỹ sư ảnh giữ renderer/quality; QA giữ corpus/UAT/perf; reviewer kiểm thay đổi nhạy cảm. Agent không thay thế thiết bị, sự phê duyệt hoặc bằng chứng CI.

Tác vụ độc lập có thể song song trong worktree riêng. Theo khung hiện có tối đa 5 subagent toàn cây; không cần dùng đủ. Các thay đổi pubspec.lock, schema, camera contract, controller chung hoặc spec quyền phải tuần tự với một owner. Chỉ re-audit phần bị ảnh hưởng sau sửa; audit rộng tại mốc lớn, tránh vòng review vô hạn không có lỗi mới.

CI chia lớp nhưng không bỏ cổng: kiểm nhanh/test phạm vi để phản hồi sớm; full gate trước merge; test ảnh/thiết bị/perf theo thay đổi và trước release. Required checks phải xác nhận trên GitHub thật. Nightly/scheduler chỉ là kế hoạch vận hành được bật sau khi có quyền, không phải tác vụ đã chạy.

## 13. Backlog triển khai ưu tiên

Đây là danh mục đề xuất, chưa tạo issue/PR và chưa tự gán người thật. “Owner” là vai cần phụ trách. Giữ liên kết W/F cũ để không tính lại việc đã làm.

| ID | Ưu tiên | Công việc | Phụ thuộc | Owner | Đầu ra nghiệm thu |
|---|---|---|---|---|---|
| XS-01 | Khẩn | Đối chiếu PR #22, đóng W-502 đúng trạng thái | Baseline | Lead | Main SHA, test và hồ sơ khớp nhau |
| XS-02 | Khẩn | W-504: target SDK và manifest gate | XS-01 | Mobile/CI | Test âm chặn cấu hình thiếu/hạ chuẩn |
| XS-03 | Khẩn | W-104: bản vá decoder và test ảnh lỗi | Review nguồn/exception | Imaging | Hết ca treo đã biết, giới hạn rõ, lockfile |
| XS-04 | Khẩn | UAT AC-9 và artifact APK theo SHA | XS-02/03 | QA/Mobile | Video/log tác vụ thật, PDF mở được |
| XS-05 | Cao | Ruleset/checks, secret/dependency gate | Quyền chủ repo | Lead/CI | PR lỗi không merge, không trỏ check mẫu |
| XS-06 | Cao | Corpus/benchmark và định nghĩa metric | Quyền dữ liệu | QA/Imaging | Tập riêng, nhãn, script đo, baseline |
| XS-07 | Cao | Ngân sách decode/render và cancellation | XS-03/06 | Imaging | Stress/fuzz có thời gian/RAM giới hạn |
| XS-08 | Cao | Hợp đồng document/revision/export | P1 baseline | Lead | Spec/ADR, contract tests, owner từng file |
| XS-09 | Cao | Thư viện nhiều tài liệu + migration | XS-08 | Mobile/Data | Cập nhật từ P1 không mất gốc/recipe |
| XS-10 | Cao | Phục hồi phiên hỏng/xóa dữ liệu đầy đủ | XS-09 | Mobile/Data | F-018/F-049 có hành vi và test |
| XS-11 | Cao | Export writer spike và PDF dài | XS-06/08 | Export | Đo RAM toàn engine; chọn writer/cap |
| XS-12 | Cao | Progress/cancel/resume, chia sẻ an toàn | XS-11 | Export/UI | Không file dở, recipient đọc ổn định |
| XS-13 | Cao | Preview đã cắt, zoom/loupe, undo | XS-08 | UI/Imaging | Preview/export cùng hình học |
| XS-14 | Cao | Native camera spike và spec quyền | XS-08 | Camera | Capture/analysis/lifecycle/permissions |
| XS-15 | Cao | Depth/high-res feasibility spike | XS-14 | Camera/CV | Kết luận khả thi, chi phí, fallback |
| XS-16 | Cao | Camera riêng + dự phòng | XS-14 | Camera | Không kẹt khi permission/app lifecycle đổi |
| XS-17 | Cao | Detector/tracker mép trang | XS-06/16 | CV | Confidence + sửa tay; holdout đạt |
| XS-18 | Cao | Quality guidance và auto capture | XS-17 | CV/Camera | Giảm chụp lại; không lặp; override |
| XS-19 | Cao | Bộ lọc bảo toàn nội dung | XS-06/13 | Imaging | Corpus dấu/chữ/mực nhạt không hồi quy |
| XS-20 | Cao | Việt hóa và accessibility đầy đủ | XS-13/16 | UI/QA | TalkBack, cỡ chữ, thứ tự focus, thao tác góc |
| XS-21 | Cao | Benchmark OCR Việt/Anh chọn engine | XS-06/08 | OCR | Báo CER/latency/RAM/license/offline |
| XS-22 | Cao | OCR job và tìm kiếm theo revision | XS-09/21 | OCR/Data | Không index/OCR cũ, cancel/retry |
| XS-23 | Cao | PDF text layer | XS-11/22 | Export/OCR | Search/copy Unicode đúng ở nhiều viewer |
| XS-24 | Cao | Full Android regression/perf/beta | XS-04/12/18/19/20/23 | QA | Bộ thiết bị, lỗi còn lại rõ, go/no-go |
| XS-25 | Cao | Release packaging/privacy/license | XS-05/24 | Lead | Artifact ký, quyền, notices, policy, rollout |
| XS-26 | Vừa | iOS build/lifecycle/permission baseline | XS-08 | iOS | CI macOS + thiết bị, chưa nhận parity |
| XS-27 | Vừa | iOS feature parity, HEIC/cache/share | XS-26 + contract ổn | iOS/QA | Đạt cùng luồng/tiêu chí cốt lõi |
| XS-28 | R&D | Depth guidance A/B | XS-15/18/06 | CV/Camera | Báo lợi ích thật và cơ chế tự tắt |
| XS-29 | R&D | Book dewarp từ ảnh, depth tùy chọn | XS-19/28 | CV | Bộ sách không hỏng chữ, mobile benchmark |
| XS-30 | R&D | Giấy bóng/ảnh đa góc | XS-18/19 | CV | Không halo/bóng chữ, chụp lại khi thiếu dữ liệu |
| XS-31 | Sau 1.0 | Hóa đơn dài/giấy tờ hai mặt | XS-24 | Mobile/CV | Không mất/lặp dòng, template đúng tỷ lệ |
| XS-32 | Sau 1.0 | Che thông tin/khóa tài liệu | Threat model + spec | Security/Mobile | Không còn OCR/pixel bị che trong bản xuất |
| XS-33 | Sau beta | Thử nghiệm mô hình trả phí | Dữ liệu người dùng | Product | Không mất quyền xuất tài liệu đã có |

## 14. Nguồn lực và khung lịch

Chưa có ngân sách hoặc đội ngũ xác nhận. Khung dưới đây chỉ dùng để phân bổ công việc, không là lời hứa ngày hoàn thành. Giả định 2 kỹ sư mobile (Android/Flutter và iOS/Flutter), 1 kỹ sư xử lý ảnh, QA khoảng nửa thời gian; chủ sản phẩm/UX review định kỳ. Thiết bị và quyền settings/signing sẵn có.

| Giai đoạn | Khối lượng lịch tham khảo | Phụ thuộc/cổng |
|---|---|---|
| M0 Đóng P1, decoder, UAT, guardrails | 1–2 tuần | Bắt đầu trước, cổng an toàn |
| M1 Dữ liệu/xuất/UX và camera-depth spike | 2–3 tuần | Sau M0; corpus/spike có thể song song |
| M2 Camera, mép trang, quality, bộ lọc | 3–4 tuần | Camera contract + benchmark |
| M3 OCR/search/PDF searchable | 2–3 tuần | Render/revision ổn; nghiên cứu OCR đi sớm |
| M4 Beta và Android 1.0 | 2–3 tuần | Tất cả cổng release; dự phòng fix |
| M5 iOS parity | 3–5 tuần, phần lớn có thể chồng lịch | Build sớm, parity sau contract ổn |
| D Depth/sách/đa góc | Đợt nghiên cứu 3–6 tuần sau spike | Không nằm trên đường bắt buộc Android 1.0 |

Đường Android khoảng 10–15 tuần trước dự phòng; khung quản lý nên dành khoảng 12–18 tuần sau khi tính rủi ro. Không cộng cơ học phần iOS/R&D nếu làm song song, cũng không coi thêm agent làm giảm tuyến tính thời gian. Đội ít người hơn: giảm tính năng 1.0 trước, không cắt kiểm thử dữ liệu/thiết bị.

Chi phí nên tập trung vào thiết bị thử, công phát triển/QA, CI và ký/phân phối. Chưa cần VPS/GPU server cho lõi offline. Không phát sinh phí inference API theo trang trong cấu hình hoàn toàn cục bộ, nhưng vẫn có chi phí hỗ trợ, store và phát triển. Chưa có cơ sở để chốt giá bán hoặc lợi nhuận.

## 15. Mô hình kinh doanh và vận hành đề xuất

Giai đoạn thử nghiệm: không quảng cáo xen luồng scan và không bắt đăng nhập. Đo tài liệu hoàn tất thành công, thời gian tới file đầu tiên, tỷ lệ quay lại và lý do bỏ dở.

Phương án thử sau beta: lõi scan/xuất miễn phí, bản nâng cao trả một lần cho tiện ích offline; chỉ cân nhắc subscription khi có giá trị lặp lại rõ như lưu trữ/đồng bộ tự nguyện. Chưa thêm billing/cloud vào critical path. Không khóa việc lấy lại tài liệu người dùng khi quyền trả phí hết hạn.

Vận hành: chu kỳ kiểm dependency, triage theo mức ảnh hưởng, ghi lỗi còn lại có owner/hạn/xem lại khi; tính năng ảnh mới luôn thử corpus. Bảo mật quan trọng được đánh giá sớm thay vì chờ quy tắc tuổi phiên bản một cách máy móc. Dịch vụ/scheduler/chẩn đoán từ xa chỉ bật sau khi phạm vi và quyền được duyệt.

## 16. Điều kiện dừng và quyết định mở

Dừng release khi có lỗi mất tài liệu, decoder treo chưa kiểm soát, file xuất sai/truncated, thay đổi chữ/dấu, quyền hoặc telemetry sai công bố, hoặc chưa có UAT trên nền tảng quảng cáo hỗ trợ. Không tính “đã ghi nợ” bằng “đã sửa”.

Nếu depth không cải thiện đủ: bỏ khỏi mặc định, tiếp tục scanner RGB. Nếu OpenCV/native không vượt baseline đủ: giữ Dart. Nếu OCR chưa đạt: vẫn giữ PDF ảnh, không quảng cáo OCR chuẩn xác. Nếu thư viện PDF không đáp ứng tài liệu dài: thay writer hoặc công bố giới hạn đã nghiệm thu, không phát hành lời hứa 100 trang không có đo.

Quyết định cần phê duyệt ở từng mốc: scope 1.0 và nguồn lực; ngoại lệ vá decoder sớm; native CAMERA; model/giấy phép; schema/migration; quyền settings; chính sách giữ/xóa/sao lưu; signing/store/billing. Chưa đủ quyết định không cản các hoạt động nghiên cứu/benchmark đã nằm trong phạm vi cho phép, nhưng không tự cấp phép code hoặc phát hành.

**Ưu tiên khởi động:** XS-01..XS-08 cùng bộ benchmark; tiếp theo chứng minh chất lượng camera/xuất trên thiết bị. Không đầu tư thêm framework trước khi các cổng sản phẩm này đạt.

## Nguồn đối chiếu

Các nguồn repo được ghim tại commit baseline. Tài liệu ngoài được đối chiếu ngày 12/10/2026; cần kiểm lại trước khi chốt version/giấy phép và phát hành. Những con số mục tiêu và lịch ở tài liệu này do kế hoạch đề xuất, không được nguồn ngoài chứng minh là X-Scanner đã đạt.

- R1 — PROJECT: `https://github.com/seeker19110/X-Scanner/blob/d219ce7aed4cd434e6511814d6248eb5cf043cd0/PROJECT.md`
- R2 — CI: `https://github.com/seeker19110/X-Scanner/blob/d219ce7aed4cd434e6511814d6248eb5cf043cd0/.github/workflows/ci.yml`
- R3 — Completion plan: `https://github.com/seeker19110/X-Scanner/blob/d219ce7aed4cd434e6511814d6248eb5cf043cd0/docs/ops/COMPLETION-PLAN.md`
- R4 — Main snapshot / PR #22: `https://api.github.com/repos/seeker19110/X-Scanner/branches/main`; `https://github.com/seeker19110/X-Scanner/commit/d219ce7aed4cd434e6511814d6248eb5cf043cd0`
- R5 — Exception decoder: `https://github.com/seeker19110/X-Scanner/blob/d219ce7aed4cd434e6511814d6248eb5cf043cd0/docs/ops/supply-chain-exceptions.md`
- R6 — Image changelog: `https://pub.dev/packages/image/changelog`
- R7 — CameraX analysis: `https://developer.android.com/media/camera/camerax/analyze`
- R8 — Exporter: `https://github.com/seeker19110/X-Scanner/blob/d219ce7aed4cd434e6511814d6248eb5cf043cd0/apps/mobile/lib/export/page_exporter.dart`
- R9 — ARCore camera sharing: `https://developers.google.com/ar/develop/java/camera-sharing`
- R10 — ML Kit Android OCR: `https://developers.google.com/ml-kit/vision/text-recognition/v2/android`
- R11 — OCR languages: `https://developers.google.com/ml-kit/vision/text-recognition/v2/languages`
- R12 — Tesseract trained data: `https://github.com/tesseract-ocr/tessdata_fast`
- R13 — Future.timeout: `https://api.dart.dev/dart-async/Future/timeout.html`
- R14 — ARCore Raw Depth: `https://developers.google.com/ar/develop/java/depth/raw-depth`
- R15 — UVDoc: `https://github.com/tanguymagne/UVDoc`
- R16 — Android 16 KB: `https://developer.android.com/guide/practices/page-sizes`
- R17 — Standard Delivery Contract: `https://github.com/seeker19110/X-Scanner/blob/d219ce7aed4cd434e6511814d6248eb5cf043cd0/docs/framework/standard-delivery.md`
