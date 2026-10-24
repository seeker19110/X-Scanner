# RISKS.md — sổ rủi ro X-Scanner

> PM-RISK-001, PM-RISK-003, PM-RISK-006. Lập 2026-10-24 (Work ID `2026-10-24-governance-docs`) từ `PROJECT.md`, `PROGRESS.md`,
> `docs/THREAT-MODEL.md`, spec §19 và code tại `edbdc50`. **Chủ** của mọi rủi ro là chủ repo (@seeker19110) vì dự án một người;
> phiên AI chỉ đề xuất. Rà lại mỗi khi đóng một lát (slice) hoặc trước phát hành.
> Xác suất/Ảnh hưởng: Thấp · TB · Cao. Cách ứng xử: tránh / giảm / chuyển / chấp nhận.

## 1. Sổ rủi ro

| ID | Mô tả | Xác suất | Ảnh hưởng | Chủ | Cách ứng xử | Biện pháp | Trigger | Trạng thái | Ngày rà |
|---|---|---|---|---|---|---|---|---|---|
| RK-001 | Chất lượng scan/camera trên thiết bị thật chưa được đo; app có thể không đạt "bản scan rõ, đủ" | Cao | Cao | chủ repo | giảm | P1 chọn camera hệ thống thay camera tự dựng (ADR-0003) để giảm rủi ro sớm; AC-9 chạy trên emulator 18/10 (`docs/ops/evidence/p1-android-uat-2026-10-18/ac9.json`); corpus/benchmark host XS-06a (`docs/benchmarks/README.md`) | UAT trên thiết bị thật cho kết quả mờ/thiếu mép | mở — chờ thiết bị (PROGRESS "Tiếp theo" 1) | 2026-10-24 |
| RK-002 | Mất ảnh gốc/tài liệu khi migration P1 hoặc khi app bị dừng giữa lúc lưu | TB | Cao | chủ repo | giảm | THREAT-MODEL TM-02: ghi nguyên tử, so byte, giữ `session.migrated*`; test `apps/mobile/test/storage/*` | báo lỗi "không chuyển được phiên cũ", người dùng mất trang | giảm trên host; chờ UAT APK có thư viện (W-602) | 2026-10-24 |
| RK-003 | Lỗ hổng trong bộ giải mã ảnh (`image`) bị khai thác bằng ảnh dựng sẵn | TB | Cao | chủ repo | giảm | TM-01; ghim `image 4.12.0`, ngoại lệ chuỗi cung ứng EX-1 đã đóng (`docs/ops/supply-chain-exceptions.md`); dependency review CI | advisory mới cho `image`; crash/treo khi mở ảnh | giảm | 2026-10-24 |
| RK-004 | Ảnh giấy tờ nhạy cảm lưu không mã hoá ở mức app | Thấp | Cao | chủ repo | chấp nhận có điều kiện | dựa vào mã hoá theo file của Android (TM-12) | chọn MAS-L2, phát hành, hoặc thêm OCR | mở — quyết định trước phát hành | 2026-10-24 |
| RK-005 | Chưa chọn giấy phép sản phẩm → không phân phối/nhận đóng góp hợp lệ được | Cao | TB | chủ repo | tránh | non-goal hiện tại (`PROJECT.md`); README ghi trạng thái | trước phát hành hoặc khi có người muốn đóng góp | mở — chủ repo quyết | 2026-10-24 |
| RK-006 | Chưa rõ nghĩa vụ theo Luật 91/2025/QH15, NĐ 356/2025/NĐ-CP, GDPR khi phát hành | TB | Cao | chủ repo | chuyển (luật sư) | `PROJECT.md` mục "Khung pháp lý", `docs/DPIA.md` sàng lọc | chọn kênh phát hành/đối tượng | mở — cần luật sư | 2026-10-24 |
| RK-007 | Một người giữ mọi quyền (repo, CI, tương lai: khoá ký, cửa hàng); mất quyền truy cập = dự án dừng | TB | Cao | chủ repo | giảm | danh sách tài khoản và offboarding `docs/ops/RUNBOOK.md` §7–§8; CODEOWNERS | chủ repo vắng mặt/mất tài khoản | mở | 2026-10-24 |
| RK-008 | iOS chưa từng build; khai báo nền tảng iOS có thể không chạy | Cao | TB | chủ repo | chấp nhận | ADR-0002: Android trước; không tuyên bố iOS chạy | chủ repo muốn phát hành iOS | chấp nhận | 2026-10-24 |
| RK-009 | Dependency đổi major/ngừng bảo trì (vd `share_plus` đổi API theo major) | TB | TB | chủ repo | giảm | ghim chính xác, Dependabot chỉ patch/minor đủ 7 ngày (`docs/ops/dependency-updates.md`); bảng §2 | pub.dev đánh dấu discontinued hoặc major bắt buộc cho SDK mới | theo dõi | 2026-10-24 |
| RK-010 | Dữ liệu giữ lại không có UI xoá (ảnh bị từ chối, `session.migrated*`, tài liệu hỏng) làm đầy bộ nhớ/giữ dữ liệu lâu hơn cần | Cao | Thấp | chủ repo | giảm (sau) | dấu `DEBT:` trong `pending_pick_store.dart`, `document_store.dart`; XS-10 xoá/thùng rác cần spec | người dùng báo đầy bộ nhớ; trước phân phối | mở — chờ spec XS-10 | 2026-10-24 |
| RK-011 | Bí mật (khoá ký tương lai) lọt vào repo; CI chưa quét toàn lịch sử | Thấp | Cao | chủ repo | giảm | pre-commit chặn mẫu khoá; quy trình xoay `docs/ops/RUNBOOK.md` §6 | tạo khoá ký đầu tiên | mở một phần | 2026-10-24 |

### Rủi ro đầu bảng và lát đầu tiên (PM-RISK-003)

Xếp theo xác suất × ảnh hưởng: **RK-001** (Cao × Cao) đứng đầu. Biện pháp đã bắt đầu từ lát P1 (lát dọc đầu có tính năng):
chọn camera hệ thống + xử lý ảnh Dart để chạy được trên emulator ngay (ADR-0003), rồi AC-9 trên emulator. Phần còn thiếu là
**spike trên thiết bị thật** (camera độ phân giải cao/depth, ADR-0002 "Việc tiếp") — cần chủ repo cung cấp thiết bị; đây là
việc đầu tiên đề xuất cho lát kế tiếp (xem `PROJECT.md` mục "Lộ trình lát dọc").

## 2. Thẩm định phụ thuộc runtime (PM-RISK-006)

Nguồn: `apps/mobile/pubspec.yaml` (ghim chính xác), metadata pub.dev API `https://pub.dev/api/packages/<tên>` và
`/score` truy cập 2026-10-24; mã nguồn trong pub cache được grep `package:http/|HttpClient|analytics|telemetry|firebase`.
endoflife.date không có mục Flutter/Dart (`https://endoflife.date/api/flutter.json` và `dart.json` trả 404 ngày 2026-10-24),
nên "hỗ trợ" ghi theo trạng thái pub.dev.

| Phụ thuộc | Phiên bản ghim | Bản mới nhất (ngày) | Publisher | License (OSI?) | EOL / hỗ trợ | Telemetry mặc định | Thoát / thay thế |
|---|---|---|---|---|---|---|---|
| Flutter SDK / Dart | 3.47.7 / 3.13.5 | xem ADR-0002 | Google | BSD-3-Clause (OSI) | không có lịch EOL công bố trên endoflife.date; theo kênh stable | Flutter tool có analytics cho **máy dev** (không vào APK); không kiểm trong phiên này | không thay (ADR-0002) |
| `image` | 4.12.0 | 4.12.0 (2026-10-11) | taosengine.com | MIT (OSI) | không discontinued | grep 0 lần | decoder nền tảng (`ui.instantiateImageCodec`) hoặc native; dữ liệu là file ảnh chuẩn |
| `image_picker` | 1.2.4 | 1.2.4 (2026-10-06) | flutter.dev | Apache-2.0 + BSD-3-Clause (OSI) | không discontinued | grep 0 lần (1 lần trong `image_picker_platform_interface` `picked_file/html.dart`, chỉ web) | intent camera/picker trực tiếp qua platform channel |
| `path_provider` | 2.1.6 | 2.1.6 (2026-06-15) | flutter.dev | BSD-3-Clause (OSI) | không discontinued | grep 0 lần | gọi `Context.getFilesDir()`/`getCacheDir()` qua channel |
| `pdf` | 3.13.1 | 3.13.1 (2026-09-19) | nfet.net | Apache-2.0 (OSI) | không discontinued | grep 0 lần | `android.graphics.pdf.PdfDocument` qua channel; PDF là định dạng chuẩn |
| `share_plus` | 13.3.1 | 13.3.1 (2026-10-01) | fluttercommunity.dev | BSD-3-Clause (OSI) | không discontinued | grep 0 lần | `Intent.ACTION_SEND` + FileProvider qua channel |

Ghi chú:
- Release APK không có quyền `INTERNET` (gate `scripts/check-release-manifest.py`), nên kể cả code mạng trong phụ thuộc
  bắc cầu (vd `http` qua `image_picker_platform_interface`) cũng không gửi được dữ liệu ra ngoài trên Android.
- Dev dependency `flutter_lints` (BSD-3-Clause) không vào APK.
- Publisher của `image` trên pub.dev là `taosengine.com` (2026-10-24); spec P1 §3 ghi `loki3d.com` (2026-10-11). Spec đã duyệt
  không sửa; ghi chênh lệch ở đây để lần nâng cấp sau kiểm lại publisher.
