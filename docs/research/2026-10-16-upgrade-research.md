# Nghiên cứu nâng cấp X-Scanner ngày 16 tháng 10 năm 2026

**Đề xuất:** giữ Flutter và luồng scan offline hiện có; ưu tiên an toàn decoder, bằng chứng trên thiết bị, thư viện nhiều tài liệu và ngân sách xuất PDF. Sau đó bổ sung nhận mép trên ảnh đã chụp, bộ lọc giữ nội dung và OCR Việt–Anh. Camera riêng và depth cần thử nghiệm riêng, sau khi có baseline để so sánh.

Phạm vi lần này là nghiên cứu và tài liệu, theo yêu cầu pull và nghiên cứu nâng cấp của chủ repo. Đây là **ADVISORY**, không duyệt migration PR-4b, dependency mới, thay đổi settings hoặc phát hành. Dùng lại ID XS của [kế hoạch hiện có](../plans/2026-10-12-comprehensive-development-plan.md), không tạo một roadmap cạnh tranh. Hồ sơ: [2026-10-16-upgrade-research](../work/2026-10-16-upgrade-research/done.md).

## 1. Hiện trạng đã đối chiếu

Base: [`cda650f310d326b612db4712503fdac0d8047108`](https://github.com/seeker19110/X-Scanner/commit/cda650f310d326b612db4712503fdac0d8047108). Thư mục ban đầu trống nên đã clone, sau đó `git pull --ff-only` trả `Already up to date`. Nghiên cứu trên nhánh `docs/upgrade-research-2026-10-16`; không sửa mã app.

| Hạng mục | Bằng chứng hiện tại | Ý nghĩa cho nâng cấp |
| --- | --- | --- |
| Luồng app thực | [main.dart](../../apps/mobile/lib/main.dart) nối `SessionStore` → `SessionController` → `ReviewScreen` | App vẫn dùng một phiên P1 |
| Thư viện tài liệu | Có `ScanDocument`, `DocumentStore`, `LibraryStore`, `P1Migration`, `LibraryController`, `LibraryScreen` và test | XS-09 PR-1..3/4a đã làm; phần còn lại là tích hợp PR-4b, không xây lại |
| Chỉnh trang | `ScanPage.revision`, preview theo revision, homography, kính lúp, undo/redo, thao tác semantics | XS-08 đã có consumer; XS-13 đã triển khai |
| Xuất | Snapshot `ExportJob`, i/N trang, huỷ ở ranh giới trang, PDF/JPG/PNG | XS-12a đã triển khai; chưa có resume hoặc huỷ tức thì pha đóng gói PDF |
| Giải mã | JPEG/PNG/WebP tĩnh theo nội dung, 64 MiB, 50 MP, isolate 60 s có kill và chờ thoát; `DecodeGate` dùng chung | W-104a đã làm; không đề xuất thêm lại các hàng rào này |
| Bộ nhớ PDF | [PageExporter.run](../../apps/mobile/lib/export/page_exporter.dart) thêm mọi JPEG vào `images`; [buildPdf](../../apps/mobile/lib/export/pdf_export.dart) dùng `pw.MemoryImage` | Xử lý từng trang chưa làm tổng bộ nhớ PDF độc lập số trang |
| Kiểm thử app | 27 file Dart trong lib, 28 file `*_test.dart`; chưa có `apps/mobile/integration_test` hoặc thư mục benchmark cấp gốc | Unit/widget test và số lượng file không chứng minh camera/share sheet/RAM trên máy thật |
| CI đúng base | [Repository checks run 38350895593](https://github.com/seeker19110/X-Scanner/actions/runs/38350895593), job `Framework and Android app gate`: success | Có bằng chứng build/analyze/format/test trên base; không phải kết quả máy hiện tại |
| Artifact cho UAT | `.github/workflows/ci.yml` chưa có bước upload APK/checksum | XS-04 nên cung cấp APK debug theo commit SHA để người chạy UAT lấy đúng bản |
| Nhánh chính | API [branches/main](https://api.github.com/repos/seeker19110/X-Scanner/branches/main): `protected=false`; [rules/branches/main](https://api.github.com/repos/seeker19110/X-Scanner/rules/branches/main): `[]`; 0 PR mở lúc kiểm | F-014 được xác minh còn thiếu, thay vì chỉ đọc ghi chú cũ |
| Release | [build.gradle.kts](../../apps/mobile/android/app/build.gradle.kts) còn dùng signing config debug; CI build debug, kiểm merged manifest release | Chưa có bằng chứng AAB ký phát hành; không đồng nhất manifest sạch với release sẵn sàng |

API GitHub/Pub là ảnh chụp ngày 16/10/2026, cần đọc lại trước khi hành động. [FEATURE-MAP](../FEATURE-MAP.md), [PROGRESS](../../PROGRESS.md) và hồ sơ có merge SHA giúp phân biệt code đã làm, code chưa nối và tiêu chí còn chờ.

### Phiên bản và thời điểm nâng decoder

Manifest phát hành [Flutter Linux chính thức](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json) xác nhận Flutter 3.47.7, Dart 3.13.5 và SHA-256 `af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230`, khớp CI. Chưa có lý do đổi SDK trong đợt này.

| Dependency trực tiếp | Đang ghim | Bản mới nhất theo Pub API lúc kiểm | Đề xuất |
| --- | --- | --- | --- |
| `image` | 4.10.1 | 4.12.0 | Nối W-104b sau mốc đủ tuổi; kiểm lại bản đích lúc làm |
| `image_picker` | 1.2.4 | 1.2.4 | Giữ |
| `path_provider` | 2.1.6 | 2.1.6 | Giữ |
| `pdf` | 3.13.1 | 3.13.1 | Giữ cho baseline, đo trước khi đổi engine |
| `share_plus` | 13.3.1 | 13.3.1 | Giữ; kiểm UAT ứng dụng nhận |

Nguồn phiên bản: Pub API từng package, ví dụ [image 4.12.0](https://pub.dev/api/packages/image/versions/4.12.0), [image_picker](https://pub.dev/api/packages/image_picker), [pdf](https://pub.dev/api/packages/pdf), [path_provider](https://pub.dev/api/packages/path_provider), [share_plus](https://pub.dev/api/packages/share_plus).

`image` 4.12.0 phát hành **11/10/2026 00:28:00 UTC**, đủ 7 × 24 giờ lúc **18/10/2026 07:28:00 giờ Việt Nam**. Giữ [EX-1](../ops/supply-chain-exceptions.md) và mốc W-104b trong kế hoạch; không tạo lịch tự động hoặc nâng sớm. Trạng thái hoạt động của tác vụ hẹn trước được nhắc trong hồ sơ cũ chưa được kiểm ở phiên này.

Đã tải [archive chính thức](https://pub.dev/api/archives/image-4.12.0.tar.gz), xác minh SHA-256 khớp Pub API: `89ed75b2f8231fe676808c5564f9590d728024ded7ac782a7ed8474f1c95b72a`, rồi đọc CHANGELOG và mã decoder, không cài package. Những điểm tác động trực tiếp: sửa EXIF IFD lặp, thêm trần pixel cho decoder và hỗ trợ giải mã JPEG ở scale 1/2/4/8. Không lấy số tăng tốc của upstream làm số đo X-Scanner.

## 2. Điểm mới đáng ưu tiên từ mã nguồn

### Thumbnail đang giải mã toàn ảnh

`thumbnailSync` gọi `decodeOriented` trước `copyResize(maxSide: 1024)`. Vì vậy ảnh xem trước nhỏ vẫn có chi phí giải mã ảnh gốc lớn. Sau W-104b, thử JPEG scaled decode bằng API đã kiểm trong archive: `JpegDecoder(maxPixels: ..., scale: ...)`. PNG có `PngDecoder(maxPixels: ...)`; WebP có thuộc tính `maxPixels`. Không giả định ba decoder dùng cùng constructor.

Nối trần theo từng instance với giới hạn của app; tránh đổi biến static toàn cục giữa các job. Giữ kiểm kích thước gốc trước decode, kiểm kích thước kết quả và fallback PNG/WebP. Chọn scale để thumbnail đủ chi tiết chỉnh góc, kiểm tám hướng EXIF, cạnh lẻ, ảnh rất dài và hình học preview/export. Đây là thử nghiệm thuộc **XS-07**, không phải lý do bỏ timeout hoặc nâng trần ảnh. Chỉ nhận thay đổi khi đo giảm chi phí mà không làm lệch góc hoặc giảm khả năng đọc.

### Pha đóng gói PDF cần ngân sách riêng

Sau khi render trang cuối, `job.done == total`; app vẫn chờ `_buildPdfInIsolate(images)` và ghi file. `cancelRequested` được kiểm sau pha này. Tiến độ trang không biểu thị toàn bộ thời gian còn lại. Đây là giới hạn đã chọn của XS-12a, không kết luận test AC-3 hiện có sai.

XS-11/12 nên đo riêng **render → đóng gói PDF → ghi file → share**; UI hiển thị “Đang tạo PDF…” khi đã render đủ trang. Đo độ trễ huỷ trong từng pha, trạng thái cuối và file tạm sau lỗi. Không thêm resume trước khi hợp đồng checkpoint, dung lượng và recipe snapshot được chốt.

Đối chứng writer hiện tại với đường native nếu cần. [`android.graphics.pdf.PdfDocument`](https://developer.android.com/reference/android/graphics/pdf/PdfDocument) có API tạo trang và `writeTo`, nhưng chữ ký đó không chứng minh engine có bộ nhớ hằng. Đo RAM tiến trình cả Dart/native, không chỉ kích thước list hay Dart heap. Chưa đạt tài liệu dài thì chọn giới hạn/profile có bằng chứng và thông báo rõ; không giữ lời hứa “100 trang trên máy 4 GB” từ comment DEBT chưa đo.

### OCR và nhận mép ảnh tĩnh có thể thử trước camera riêng

Kế hoạch cũ đặt detector sau camera riêng. Nên tách **đề xuất góc trên ảnh đã chụp/nhập** khỏi **tracker và tự chụp trên preview**. Phần đầu dùng được với camera hệ thống và thao tác hiện có; giúp đo chất lượng trước khi mở rộng quyền và lifecycle camera. Đây là điều chỉnh thứ tự đề xuất, chưa đổi spec đã duyệt.

Tương tự, XS-21 benchmark OCR có thể chạy trên ảnh đã render từ P1, sau XS-06, không cần đợi XS-16 camera riêng. OCR job/tìm kiếm sản phẩm vẫn cần thư viện và hợp đồng revision của XS-09/22.

## 3. Học từ các repo của chủ sở hữu

Chọn nguồn theo vấn đề thực tế của scanner. Đã liệt kê repo công khai của `seeker19110`; đọc sâu năm repo dưới đây. Không coi catalog tổng hợp hoặc checklist của repo khác là bằng chứng app hiện tại đã có tính năng.

| Repo và snapshot đã đọc | Phần liên quan | Phần lấy cho đề xuất |
| --- | --- | --- |
| [stored @8569c2a](https://github.com/seeker19110/stored/tree/8569c2aac428335cb495b4712d21c7b3ef2e9b4d) | `14-voice-multimodal/README.md`, `23-own-repos-lessons/README.md` | Dùng làm chỉ mục tìm nguồn; xác minh lại từng khuyến nghị với code/CI. VLM là hướng đánh giá tài liệu khó, chưa phải OCR mặc định trên điện thoại |
| [X-Templates @58b8c8b](https://github.com/seeker19110/X-Templates/tree/58b8c8bb53dff6dbd6ccf3ad152e34506fd99a87) | `framework/02-profiles/mobile-app.md`, `14-testing-quality/test-data-and-fixtures.md`, `performance-and-load.md` | Bổ sung phép đo cold start/app size, Unicode NFC/NFD, fixture có seed và holdout. Không nhập stack React Native, backend, telemetry hoặc toàn bộ cổng web |
| [projects-template @bac75d3](https://github.com/seeker19110/projects-template/tree/bac75d31e61c490d82f82a2abb3810234fc4fd38) | `.claude/hooks/auto-complete-guard.sh` | Xác nhận gợi ý guard ngày 13/10 còn có cơ sở; đây là bảo trì harness, xếp sau các điểm sản phẩm. Chỉ nhập qua workflow adoption, kèm test/marker/lifecycle tương ứng |
| [X-Studio ADR-0014 @93a290a](https://github.com/seeker19110/X-Studio/blob/93a290a1705ee7c62669804b48cfb9e0f2690a9d/docs/adr/0014-factory-cleanup-and-thumbnail-staging.md) | Staging trước publish, cleanup khi khởi tạo/đóng lỗi; giới hạn thread khác quota RAM | Dùng khuôn thử lỗi ở mọi bước export/migration. App đã có tmp/rename và journal; chỉ thêm ca thiếu, không tạo lại một transaction abstraction |
| [dhcb retention tests @f29d823](https://github.com/seeker19110/dhcb/blob/f29d823785f0e099fd9528582a39a59f219f09c5/apps/server/src/api/_lib/retentionCleanup.test.ts) | Retention có thời hạn cụ thể, giới hạn batch và kiểm lỗi | Áp cách đặt tiêu chí cho cache/quarantine của XS-10. Không sao chép TTL 365 ngày, SQL, cron hoặc tự xoá scan gốc |

X-Scanner đang ghim framework ở `aab9f88`, khác HEAD `bac75d3` của projects-template. [check-adoption.py](../../scripts/check-adoption.py) kiểm hash snapshot hiện có. Chép riêng hook từ HEAD rồi tuyên bố “đồng bộ khung” sẽ bỏ qua contract adoption và phần phụ thuộc.

### Đã có và sâu hơn cho nhu cầu scanner hiện tại

| Ý tưởng nguồn ngoài | Cổng/code đã có | Quyết định |
| --- | --- | --- |
| Xử lý media phải giới hạn tài nguyên | `DecodeGate`, `runWithinBudget`, kiểm byte/pixel, test heartbeat sau kill và WebP động | Giữ, không thay bằng mỗi `Future.timeout` hoặc giới hạn thread |
| Giữ bản gốc và recipe thay vì ghi đè | `ScanPage`, store tmp/rename, test quarantine/I/O F-001 trong `test/storage` | Giữ; kiểm lại invariants khi nối PR-4b |
| Cache kết quả theo phiên bản | Preview keyed theo page id/revision, test kết quả cũ không chiếm cache mới | Dùng lại cho OCR/filter; không dựng cache framework mới |
| Ghim toolchain và hạn chế quyền | CI ghim Flutter/hash/action SHA; manifest gate kiểm quyền/exported/backup; Gradle wrapper có checksum | Giữ; độ chặt này phù hợp app offline hơn checklist xin quyền camera mặc định |

### Đã có nhưng nông hơn ở điểm đã xác định

| Ý tưởng nguồn ngoài | Điểm thiếu cụ thể và bằng chứng | Chỉ lấy phần thiếu |
| --- | --- | --- |
| Mobile E2E | LC-1 là widget test dùng adapter giả; AC-9 đang mở; không có integration_test | Luồng trên thiết bị gồm OS camera, lost data, share recipient và mở PDF thật |
| Ngân sách media | Exporter giữ toàn bộ JPEG; comment trần chưa đo; thumbnail giải mã toàn ảnh | Benchmark RAM/latency, scaled JPEG, lựa chọn writer theo số đo |
| Staging và phục hồi | P1Migration có journal và test từng bước, nhưng chưa nối với lifecycle app thật | Test nâng cấp P1 và kill/relaunch của PR-4b, gồm mất focus và thiếu dung lượng |
| Retention | F-018/F-049, quarantine được giữ nhưng chưa có UI quản lý | UX phục hồi/xoá tường minh theo XS-10; không tự gom file “không tham chiếu” thành rác |
| Bảo vệ merge | Hook/CI chạy thật nhưng main không được protected và rules trả rỗng | Chủ repo cấu hình required check đúng tên rồi thử PR cố tình đỏ |

### Chưa có và điều kiện cân nhắc

| Hạng mục | Sự cố hoặc nhu cầu đã ghi | Đề xuất và điều kiện xem lại |
| --- | --- | --- |
| Cổng corpus/benchmark thiết bị | Nợ F-006/F-033 và các trần chưa đo; XS-06/07/11 đã ghi nhu cầu | Làm trước tối ưu chất lượng; lưu fixture tổng hợp và kết quả có phiên bản |
| Chỉnh góc không cần kéo hoặc screen reader | DEBT của XS-13 và XS-20 | Bổ sung nút dịch góc nhỏ, test bằng chạm với chữ lớn; không coi semantics hiện tại đã giải quyết mọi dạng thao tác |
| Stop guard mới của framework | Gợi ý số 1 ngày 13/10; file thực sự chưa có | Chưa nhập trong nghiên cứu này; đánh giá adoption riêng khi tiếp tục luồng dài qua Claude Code. Không coi hook Claude là cơ chế bảo đảm cho mọi runner |
| Vault/cloud/LLM đa agent/backend | Không tìm thấy nhu cầu vận hành buộc thêm trong scope scan offline | **Chưa cần**; xem lại khi người dùng chốt threat model hoặc yêu cầu đồng bộ/hiểu tài liệu |
| Segmentation model/dewarp | Chưa có benchmark scanner chứng minh baseline nhẹ thất bại ở đâu | **Chưa cần tích hợp**; dùng thử ngoại tuyến khi corpus chỉ ra nhóm lỗi cần xử lý |

Thực sự lấy trong đợt này: tiêu chí đánh giá, đối chiếu nguồn và điều chỉnh thứ tự đề xuất. Không nhập code, model, dependency, hook hoặc cấu hình từ repo khác.

## 4. Nguồn scanner và lựa chọn engine

### Nhận mép và camera

| Ứng viên | Bằng chứng upstream | Cách dùng cho X-Scanner |
| --- | --- | --- |
| [FairScan @c1517c5](https://github.com/pynicolas/FairScan/tree/c1517c52bf10eeeea8aef6710c7fad94d4edcc67) | CameraX, segmentation qua LiteRT, OpenCV, Tesseract, PDFBox-Android; repo khai GPL-3.0 | Đối chứng UX và detector trên cùng corpus; xem riêng [model](https://github.com/pynicolas/fairscan-segmentation-model) và [dataset](https://github.com/pynicolas/fairscan-dataset), kiểm quyền dùng từng asset trước nhập |
| [OSS-DocumentScanner @83fd6db](https://github.com/ossappscollective/OSS-DocumentScanner/tree/83fd6db8dbf5d46658e182fe7211523473fd5dcd) | Scanner có OpenCV/Tesseract; metadata repo khai MIT | Tham khảo luồng và cách tích hợp; không suy mọi thư viện/model đi kèm cùng license hoặc app đã stream PDF |
| [OpenScan của ethereal @27bb7ab](https://github.com/ethereal-developers/OpenScan/tree/27bb7ab973fbb621fce182c43bc875856c785a30) | Repo scanner bảo vệ riêng tư, BSD-3-Clause | Đối chứng workflow tối giản; ghi đúng owner vì internet có nhiều repo cùng tên OpenScan |
| [ML Kit Document Scanner](https://developers.google.com/ml-kit/vision/doc-scanner) | Có UI chụp/crop/filter và xử lý trên máy; tài nguyên qua Google Play services | Baseline thử nhanh. Không thay đường P1 làm mặc định trước khi chứng minh first-run offline và giữ bản gốc |
| Baseline tự kiểm soát | Hình học/homography đã có trong app | Thử detector ảnh tĩnh nhẹ; chỉ thêm OpenCV/model khi phép đo chứng minh đáng đổi chi phí native/model |

[Hướng dẫn Android của ML Kit scanner](https://developers.google.com/ml-kit/vision/doc-scanner/android) yêu cầu Android API 21+, RAM tổng tối thiểu 1,7 GB và có thể phải chờ tải model/logic/UI lần đầu; trả JPEG/PDF đã scan. API không thiết lập cam kết trả ảnh camera gốc chưa chỉnh. Do đó “on-device” không đủ chứng minh “cài mới không mạng là dùng được”, hoặc đáp ứng invariant lưu gốc của X-Scanner.

Chỉ khi cần live guidance/auto capture mới ưu tiên camera riêng: [CameraX ImageAnalysis](https://developer.android.com/media/camera/camerax/analyze), giữ frame mới nhất, một tác vụ phân tích tại một thời điểm, đóng `ImageProxy` trong mọi đường kết thúc. Kiểm ánh xạ sensor → preview → ảnh chụp → quad; overlay đúng không chứng minh crop cuối đúng.

### Bộ lọc và OCR

Thử gốc, màu tài liệu, xám, đen trắng trên dependency `image` đã có sau khi giải quyết decoder. [OpenCV adaptive threshold](https://docs.opencv.org/4.x/d7/d4d/tutorial_py_thresholding.html) là đối chứng cho ánh sáng không đều, không phải lý do tự động thêm OpenCV. Đo riêng dấu tiếng Việt, mực nhạt, chữ ký, con dấu, ảnh in; giữ nút trở về gốc. Bộ lọc phải vào recipe/revision và dùng chung preview/export; không chỉ tô hiệu ứng trên UI.

| OCR | Điểm kiểm được | Đề xuất |
| --- | --- | --- |
| [ML Kit Text Recognition v2](https://developers.google.com/ml-kit/vision/text-recognition/v2/android) bundled Latin | Model đi kèm app; [tiếng Việt trong danh sách supported](https://developers.google.com/ml-kit/vision/text-recognition/v2/languages) | Baseline Android đầu tiên, thử cài sạch/chế độ máy bay và chạy trên thiết bị đích |
| [Tesseract tessdata_fast](https://github.com/tesseract-ocr/tessdata_fast), có [vie.traineddata](https://github.com/tesseract-ocr/tessdata_fast/blob/main/vie.traineddata) | Có model Việt để thử offline | Đối chứng `vie+eng` trên cùng bản render; ghi checksum/model/PSM, không ship hai engine mặc định |
| [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR), [tài liệu pipeline hiện hành](https://www.paddleocr.ai/main/en/version3.x/pipeline_usage/OCR.html) | Có nhiều pipeline/model; tài liệu hiện hiển thị PP-OCRv6 và đường triển khai Android/iOS | Đối chứng tiếp theo nếu hai baseline không đạt. Ghim model/runtime; danh mục hỗ trợ không chứng minh RAM, CER Việt hoặc tốc độ trên điện thoại đích |
| VLM từ catalog stored | Có ứng viên đọc/hiểu tài liệu | Chưa đưa vào scan cơ bản; chỉ nghiên cứu sau khi có lỗi OCR cụ thể và yêu cầu riêng về quyền riêng tư/chi phí |

OCR chạy sau hình học/bộ lọc cuối; kết quả mang page id, revision, engine/model version. Chỉnh trang làm kết quả cũ hết hiệu lực. Một job muộn không được ghi đè revision mới. PDF vẫn xuất được khi OCR lỗi; lớp chữ vô hình phải có Unicode, vị trí và thứ tự đọc đúng, trong khi ảnh scan là nội dung nhìn thấy.

### Depth và sách cong

[ARCore Raw Depth](https://developers.google.com/ar/develop/java/depth/raw-depth) có confidence, không phủ mọi pixel, không phải frame nào cũng có depth mới và không bắt buộc ToF. Vùng ít texture như mặt giấy trắng là trường hợp cần kiểm riêng. [Shared camera](https://developers.google.com/ar/develop/java/camera-sharing) dùng Camera2; không suy CameraX và ARCore mở camera độc lập cùng lúc.

[UVDoc @4c9b82b](https://github.com/tanguymagne/UVDoc/tree/4c9b82b537057aff2526e6dd118a847cdd072e82) là nguồn thử dewarp lưới; repo code khai MIT, còn quyền dùng weights/data phải kiểm riêng. Chưa có kết quả thiết bị X-Scanner để chọn tích hợp. Spike chỉ cần kết luận high-res capture + timestamp/calibration khả thi; phát hành depth sau khi A/B cho lợi ích rõ hơn RGB, gồm nhiệt và thời gian hoàn thành.

## 5. Bộ đo để lựa chọn nâng cấp

Đề xuất XS-06 tạo **120 trang thử ban đầu**: 80 trang Việt, 20 Anh, 20 trộn. Đây là thiết kế thử, chưa có corpus hoặc kết quả. Chia 60 development/60 holdout theo tài liệu vật lý; các ảnh khác ánh sáng/góc chụp của cùng một trang ở cùng tập. Phân tầng đủ sáng, thiếu sáng, bóng/chói, nền cùng màu giấy, chữ nhỏ/mực nhạt và giấy cong. Không suy 120 trang chứng minh chất lượng mọi trường hợp.

Fixture CI tổng hợp có seed cố định, nhãn góc/recipe/text và checksum. Trang in rồi chụp có quyền sử dụng được giữ theo chính sách riêng; không đưa giấy tờ cá nhân vào repo, screenshot CI hoặc dịch vụ tra cứu. Ground truth OCR chép và kiểm tay; engine đang chấm không tự tạo đáp án.

| Phép đo | Cách kiểm | Điều kiện chọn phương án |
| --- | --- | --- |
| Bảo toàn nội dung | Đánh dấu vùng chữ sát mép, dấu, chữ ký và con dấu; so trước/sau crop/filter | 0 mất vùng bắt buộc trong regression set; không dùng chỉ IoU đẹp để bỏ qua chữ bị cắt |
| OCR | CER = (thay + xoá + chèn) / số ký tự đáp án; báo bản NFC, giữ dấu/case/punctuation theo protocol cố định | Báo theo từng nhóm ảnh và chênh lệch so baseline. CER ≤2% của kế hoạch cũ vẫn là mục tiêu chưa đạt |
| Scan thực | Số lần chụp lại, thời gian tới PDF dùng được, số thao tác sửa góc | So cùng máy/trang/ánh sáng; đảo thứ tự thử ứng viên, ghi phiên bản và thiết lập |
| CPU/RAM | Profile/release, peak RSS/PSS tiến trình, Dart/native heap, wall time từng pha | 1/10/30/100 trang; 12/24/48 MP; đo khi vào nền/mở lại. 100 trang là stress target, chưa là mức hỗ trợ |
| Huỷ và lỗi | Huỷ khi decode/render/package/write/share, đĩa đầy, process kill | Không công bố file dở, không mất gốc; ghi độ trễ huỷ và lượng cache còn lại |
| Migration | Bản P1 có 0/1/nhiều trang, manifest hỏng/newer schema/thiếu file; kill từng bước và relaunch | Đúng một tài liệu migrate hợp lệ hoặc nguồn cũ còn nguyên; so hash/thứ tự/quad/xoay; lần chạy lại không nhân bản |
| PDF | Mở ở ít nhất hai viewer; đếm trang, tỷ lệ, chiều; sau OCR thử search/copy Việt | Trang đọc được, text không lộ lên ảnh, không gắn OCR revision cũ |
| Accessibility | TalkBack, font scale 200%, Dark/Light, chỉnh góc bằng chạm | Hoàn tất luồng chính trên máy thật; test semantics bổ sung nhưng không thay thao tác thực |

Đề xuất hai Android khác RAM/CPU làm baseline, thêm máy hỗ trợ Depth cho nhánh D. Khởi đầu mỗi case lặp 5 lần để tìm lỗi; khi báo p95 latency cần protocol nhiều mẫu hơn, tối thiểu 30 lần ở điều kiện đã ghi, kèm số mẫu và độ phân tán. Không chấm tốc độ bằng debug build hoặc runner chia sẻ rồi áp thành cam kết thiết bị. [Flutter performance guidance](https://docs.flutter.dev/perf/best-practices) dùng profile mode khi đánh giá frame.

Mỗi record tối thiểu có: `appSha`, `fixtureId/hash`, `device/OS/RAM`, `buildMode`, `engine/model`, `recipeRevision`, `stage`, `durationMs`, `peakProcessMemory`, `outputBytes`, `cancelLatencyMs`, `outcome`. Không ghi nội dung OCR, tiêu đề tài liệu hoặc đường dẫn cá nhân. Metric chưa đo để null, không điền 0.

## 6. Thứ tự triển khai đề xuất

| Thứ tự | Nối việc có sẵn | Phạm vi nhỏ để review | Xong khi |
| --- | --- | --- | --- |
| 1 | XS-03 / W-104b | Sau 18/10 đủ tuổi: ghim bản decoder, lockfile, nối trần instance, hồi quy ảnh lỗi | Test đỏ với 4.10.1 cho lỗi mục tiêu → xanh bản vá; full gate + manifest; đóng EX-1 theo bằng chứng |
| 2 | XS-04 / AC-9 | Chạy UAT luồng P1 hiện tại và lưu artifact theo SHA | Camera/import → chỉnh → xuất → app nhận mở được; lost-data, huỷ và relaunch có kết quả |
| 3 | XS-05 / F-014 | Chủ repo bật required check `Framework and Android app gate`, kiểm dependency/secret settings riêng | PR cố tình đỏ thực sự không merge được; không dùng tên check mẫu `gate` khi chưa có |
| 4 | XS-06, rồi XS-07/11 | Dựng corpus/protocol, baseline thumbnail và PDF; thử scaled JPEG trước đổi engine | Báo bộ nhớ/thời gian có thể chạy lại; chọn tối ưu hoặc cap bằng số đo |
| 5 | XS-09 PR-4b, rồi XS-10 | Nối màn thư viện/store và adapter dung lượng; quản lý phục hồi sau đó | Đạt AC-13 và các ca migration trên lifecycle thật; dữ liệu P1/bản rollback giữ nguyên. **PR-4b vẫn cần chủ repo duyệt rõ theo spec hiện hành** |
| 6 | XS-20 và XS-19 | Việt hoá thành phần hệ thống, chỉnh góc không kéo; filter trong recipe | Chữ lớn/TalkBack/chạm hoàn tất luồng; preview/export khớp và không mất nét/dấu |
| 7 | Tách XS-17 ảnh tĩnh; XS-21 → 22 → 23 | Đề xuất góc trên ảnh nhập; chọn OCR bằng benchmark rồi tìm kiếm/PDF text layer | Có fallback chỉnh tay, OCR theo revision, Unicode search/copy đúng |
| 8 | XS-14/15/16/18, nhánh D | Camera/live quality; spike camera-depth và A/B sau đó | Cải thiện tác vụ thực so camera hệ thống, fallback hoạt động, không vượt RAM/nhiệt |

Thứ tự 1–3 là ưu tiên, không buộc làm tuần tự nếu thiết bị/quyền settings chưa sẵn. XS-06 có thể chuẩn bị ngay; XS-21 benchmark độc lập phần UI camera. Mỗi thay đổi nguồn có hồ sơ/spec và bằng chứng theo mức rủi ro, không duyệt cả bảng từ báo cáo này.

Trước beta còn XS-25: signing thật, inventory license/model, privacy/retention và artifact release. Kiểm mọi `.so` trong APK/AAB, **kể cả engine Flutter hiện có**, về [16 KB page sizes](https://developer.android.com/guide/practices/page-sizes); không đợi tới lúc thêm OpenCV mới xem native libraries. Thử [Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files) cho “Lưu thành…” khi cần file tồn tại lâu dài theo nơi người dùng chọn; share sheet hiện tại không phải thư viện export bền vững.

## 7. Đính chính và các giả thuyết đã loại

- “Cần thêm Dependabot” trong snapshot gợi ý 13/10 đã được xử lý ở #47/#48; config có `pub`, `github-actions`, nhóm PR và cooldown 7 ngày. Không thêm bot thứ hai. Alerts/dependency review là việc khác, trạng thái tài khoản chưa được kiểm từ API quản trị.
- XS-13 và XS-12a đã có code/test; không dùng roadmap ngày 12/10 để báo còn thiếu preview/loupe/undo/progress/cancel.
- Màn thư viện tồn tại không có nghĩa app đã có thư viện. `main.dart` vẫn nối P1; PR-4b đang là điểm tích hợp cần quyết định riêng.
- Test xuất 100 trang hiện có kiểm **tên/sắp thứ tự ảnh với renderer thử**, không chứng minh PDF 100 ảnh 12 MP không OOM.
- Có isolate và gate giải mã tuần tự không tạo quota RAM cho toàn tiến trình; ảnh render, cache preview và JPEG/PDF tích luỹ vẫn phải đo.
- Không mặc định “chưa có branch protection” chỉ từ văn xuôi: lần này đã đọc hai endpoint GitHub, nhận protected=false và rules rỗng.
- Một số trang pub.dev/documentation và tutorial document-scanner của OpenCV không đọc được bằng web renderer. API/chữ ký `image` được kiểm qua archive đã xác minh hash; threshold đối chiếu qua tutorial chính thức đọc được. Không suy API từ kết quả tìm kiếm.

## 8. Kiểm chứng ở giai đoạn nghiên cứu

| Kiểm tra | Kết quả và phạm vi |
| --- | --- |
| `git pull --ff-only` | Already up to date trên main cda650f; sau đó tạo nhánh tài liệu |
| `python3 scripts/check-adoption.py` | 7/7 PASS; snapshot framework và nghiên cứu gốc được giữ |
| `python3 scripts/check-adoption.py --lint` | 47 kiểm tra cú pháp/cấu hình PASS |
| `python3 scripts/check-release-manifest.py --self-test` | 10/10 PASS; dòng FAIL của ca manifest không tồn tại là negative test dự kiến, không phải kiểm manifest build hiện tại |
| `bash scripts/test-hooks-gate.sh` | PASS, gồm negative controls bắt hook hỏng |
| `bash scripts/test-hooks-gate-guard.sh` | PASS, gồm pattern bí mật và biến thể lệnh Git |
| OSV querybatch với hosted package trong pubspec.lock | 86/86 trả kết quả, 0 advisory; không đồng nghĩa không có bug hoặc F-004 đã đóng |
| `dev-task.sh doctor` / `dev-task.sh gate` cục bộ | **BLOCKED, exit 2: thiếu Flutter**; chưa chạy lại build/analyze/format/test app |
| CI trên base | Run 38350895593 success; không dùng làm bằng chứng thay đổi chưa commit |
| Tài liệu | Các link nội bộ trong bốn file thay đổi đều có đích; kiểm whitespace/diff sạch |

Không đo CER, p95, RAM hoặc chất lượng ảnh trong đợt này. Các con số ở phần protocol là thiết kế thử. Khi kết thúc nghiên cứu, chưa commit hoặc mở PR vì full gate thiếu công cụ. Sau yêu cầu triển khai tiếp của chủ repo cùng ngày, việc cài toolchain, chạy lại full gate và đưa nghiên cứu vào PR được ghi ở [hồ sơ XS-04](../work/2026-10-16-android-uat-artifacts/done.md); không dùng kết quả mới để viết lại bằng chứng lịch sử ở bảng trên.
