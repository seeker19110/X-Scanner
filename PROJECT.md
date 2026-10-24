# X-Scanner — Project brief

## Trạng thái

P1 scan và xuất đã merge (2026-10-12); AC-9 được root nghiệm thu trên emulator18/10 theo ủy quyền, agent thực hiện (bằng chứng `docs/ops/evidence/p1-android-uat-2026-10-18/ac9.json`). XS-09 thư viện nhiều tài liệu + migration P1 nối vào app ở #62 (2026-10-23); chưa UAT bản này trên emulator/thiết bị. Chủ dự án: @seeker19110.
Đã duyệt ngày 2026-10-11: lưu nghiên cứu, áp dụng projects-template, stack ADR-0002, spec P0 nền và spec P1 scan và xuất.
Mục tiêu sản phẩm: scan tài liệu, xuất PDF hoặc ảnh; nghiên cứu khoảng cách/depth để tăng chất lượng.
Người dùng: người cần số hóa tài liệu; phân khúc cụ thể và nền tảng phát hành chưa chốt.
Outcome: bản scan rõ, đủ và file dùng được; chưa có số đo thực nghiệm.

## Vấn đề

Người cần lưu hoặc gửi giấy tờ giấy mà không có máy scan phải tự chụp từng trang, nhận về ảnh nghiêng, lệch, thừa nền và nhiều
tệp rời khó gửi như một tài liệu; nhiều người còn ngại đưa giấy tờ cá nhân qua dịch vụ trực tuyến để xử lý.
*(Giả thuyết từ mục tiêu sản phẩm và guardrail local-first; chưa có phỏng vấn hay số đo người dùng.)*

## Scope hiện tại

App Flutter `apps/mobile` (Android trước), offline, theo `docs/specs/2026-10-11-p1-scan-export.md`:
chụp bằng camera hệ thống hoặc nhập ảnh (`image_picker`, không xin quyền camera/bộ nhớ), sắp xếp, xoá, chụp lại,
xoay, chỉnh 4 góc (nắn phối cảnh bằng homography Dart), lưu từng tài liệu trong thư viện (tạo, đổi tên; spec XS-09) giữ nguyên bản gốc qua lần đóng app,
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
OCR, giấy phép sản phẩm, Data Governance trước phát hành và benchmark trên thiết bị (P2).
Threat model bản 1 (`docs/THREAT-MODEL.md`), sổ dữ liệu (`docs/privacy/data-map.yaml`), sàng lọc DPIA (`docs/DPIA.md`) và sổ rủi ro
(`docs/RISKS.md`) lập 2026-10-24, **chưa có chủ repo duyệt**.

## Gate hiện tại

Doctor/gate qua scripts/dev-task.sh: build APK debug, kiểm manifest release đã gộp (`scripts/check-release-manifest.py`), `flutter analyze --fatal-infos`, `dart format`, `flutter test`
và kiểm tra repository; CI chạy cùng gate. Lệnh theo khu vực: `CODEMAP.md`. Build iOS và kiểm thử thiết bị thật: **chưa kiểm chứng**.

## Yêu cầu (R-NNN)

ID ổn định, **không tái sử dụng** ID đã bỏ. Chi tiết và tiêu chí chấp nhận nằm ở spec; đây chỉ là chỉ mục.

| ID | Yêu cầu | Spec (mã gốc) |
|---|---|---|
| R-001 | Thêm trang bằng camera hệ thống hoặc nhập ảnh, không xin quyền camera/bộ nhớ | `docs/specs/2026-10-11-p1-scan-export.md` (FR-1, FR-2) |
| R-002 | Giữ nguyên byte ảnh gốc qua mọi chỉnh sửa và lần mở lại app | P1 (FR-2, FR-3); `docs/specs/2026-10-18-xs09-picker-preservation.md` |
| R-003 | Sắp xếp, xoá, chụp lại, xoay trang; xoá/chụp lại cần xác nhận | P1 (FR-1, FR-3) |
| R-004 | Chỉnh 4 góc và nắn phối cảnh từ bản gốc | P1 (FR-4, FR-5); `docs/specs/2026-10-12-preview-and-corner-editor.md` (FR-5..FR-9) |
| R-005 | Xuất PDF nhiều trang hoặc JPG/PNG từng trang qua share sheet, dọn file tạm | P1 (FR-6, FR-7) |
| R-006 | Xuất có tiến độ và huỷ được, không để lại file dở | `docs/specs/2026-10-12-export-progress-cancel.md` (FR-1..FR-5) |
| R-007 | Xem trước trang đã cắt/xoay đúng như file xuất | `docs/specs/2026-10-12-preview-and-corner-editor.md` (FR-1..FR-4) |
| R-008 | Thư viện nhiều tài liệu: tạo, đổi tên, mở; mỗi tài liệu một thư mục | `docs/specs/2026-10-12-document-library-migration.md` (FR-2..FR-5, FR-8) |
| R-009 | Chuyển dữ liệu P1 sang thư viện một lần, so byte, giữ bản quay lại | XS-09 (FR-6, FR-7); ADR-0011 |
| R-010 | Hợp đồng tài liệu/revision/schema đọc được bản cũ, báo "cần cập nhật app" với bản mới hơn | `docs/specs/2026-10-12-document-revision-export-contract.md` (FR-1..FR-7) |
| R-011 | Dark blue mặc định + Light, WCAG 2.2 AA và vùng chạm 48 dp | `docs/specs/2026-10-11-p0-foundation.md` (FR-4); `docs/specs/2026-10-23-scanner-experience.md` |
| R-012 | Ảnh đầu vào không tin cậy không làm treo/crash app hay mất trang | P1; `docs/specs/2026-10-18-w104b-decoder-upgrade.md` |
| R-013 | Không mạng, không log/upload tài liệu, không sao lưu đám mây | P1 (Guardrails, mục Privacy); `docs/THREAT-MODEL.md` TM-03..TM-05 |

## Tính năng MVP (MoSCoW)

ID tính năng dùng **FT-NN** của `docs/FEATURE-MAP.md` vì `F-NNN` đã dùng cho phát hiện audit (F-001..F-079 trong test và
`docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`); dùng lại `F-NNN` cho tính năng sẽ trùng nghĩa khi grep.
Mọi spec dưới đây có dòng `Approved for implementation`.

| Mức | ID | Tính năng | Yêu cầu | Spec |
|---|---|---|---|---|
| Must | FT-02 | Chụp trang bằng camera hệ thống | R-001, R-002 | `docs/specs/2026-10-11-p1-scan-export.md` |
| Must | FT-03 | Nhập ảnh từ thư viện | R-001, R-012 | P1; `docs/specs/2026-10-18-w104b-decoder-upgrade.md` |
| Must | FT-04, FT-05, FT-06, FT-07 | Sắp xếp, xoá, chụp lại, xoay | R-003 | P1 |
| Must | FT-08 | Chỉnh 4 góc | R-004 | P1; `docs/specs/2026-10-12-preview-and-corner-editor.md` |
| Must | FT-10 | Xuất và chia sẻ PDF/JPG/PNG | R-005, R-006 | P1; `docs/specs/2026-10-12-export-progress-cancel.md` |
| Must | FT-01 | Khôi phục tài liệu khi mở lại | R-002 | P1; `docs/specs/2026-10-18-xs09-picker-preservation.md` |
| Must | FT-13 | Thư viện nhiều tài liệu + migration P1 | R-008, R-009, R-010 | `docs/specs/2026-10-12-document-library-migration.md` |
| Should | FT-11 | Dark/Light | R-011 | `docs/specs/2026-10-11-p0-foundation.md` |
| Should | FT-12 | Thông báo lỗi rõ ràng | R-012 | P1 |
| Should | — | Xem trước đã cắt, hoàn tác/làm lại, kính lúp | R-007 | `docs/specs/2026-10-12-preview-and-corner-editor.md` |
| Could | — | Xoá tài liệu/thùng rác, khôi phục ảnh bị giữ riêng (XS-10) | — | chưa có spec |
| Won't (lúc này) | — | Tự nhận mép, OCR, PDF searchable, depth, iOS, cloud | — | ADVISORY (`docs/plans/`) |

Thay đổi phạm vi sau khi chốt: theo `SCOPE.md` (commit `docs(scope): …`).

## Lộ trình lát dọc

Mỗi lát là một lát dọc chạy được từ UI tới lưu trữ, demo được, có cổng máy:

1. **Lát 0 — walking skeleton (P0, #1–#2):** app Flutter rỗng + lõi `PageQuad`/`ScanPage` + gate thật
   (`bash scripts/dev-task.sh gate`: build APK debug, analyze, format, test) trên CI **trước** mọi tính năng. Chưa có "deploy"
   vì chưa phát hành; tương đương smoke là APK debug UAT do CI tạo (`docs/ops/android-uat.md`).
2. **Lát 1 — P1 scan & xuất:** chụp → chỉnh → xuất PDF trên một phiên; xử lý rủi ro đầu bảng RK-001 bằng camera hệ thống
   (`docs/RISKS.md`); smoke: AC-9 trên emulator.
3. **Lát 2 — XS-09 thư viện + migration** (đã merge #62; UAT APK chờ chủ repo).
4. **Lát kế tiếp (đề xuất, chưa duyệt):** spike camera/chất lượng trên thiết bị thật cho RK-001, rồi XS-10 xoá/thùng rác.
Kế hoạch theo task của vòng autopilot hiện tại: `docs/autopilot/PLAN.md`.

## Dữ liệu & pháp lý

- **Có dữ liệu cá nhân: CÓ THỂ** — nội dung ảnh do người dùng chọn; **có thể có dữ liệu nhạy cảm** (giấy tờ tuỳ thân, sức khoẻ,
  tài chính, trẻ em trên giấy tờ). App không phân loại nội dung nên mặc định đối xử như nhạy cảm.
  Không thu: tài khoản, liên hệ, vị trí, định danh thiết bị, log, analytics.
- Sổ dữ liệu, phân loại và thời hạn lưu: `docs/privacy/data-map.yaml`. Tóm tắt thời hạn: bản gốc và `document.json` giữ tới khi
  người dùng xoá trang/xoá tất cả hoặc xoá dữ liệu app; file xuất và bản sao picker xoá ngay sau dùng; ảnh bị từ chối,
  `session.migrated*` và tài liệu hỏng giữ tới khi xoá dữ liệu app (dấu `DEBT:` trong code, chờ XS-10).
- Mã hoá at-rest: không do app, dựa vào Android (`docs/THREAT-MODEL.md` TM-12, `docs/RISKS.md` RK-004).

### Dữ liệu test

**Cấm** đưa dump/bản sao dữ liệu thật của người dùng (thư mục app, ảnh giấy tờ, file xuất) vào repo, CI, issue, PR, artifact hay
máy dev; fixture chỉ dùng dữ liệu tổng hợp. Chính sách và cổng đang chạy: `docs/compliance/test-data-policy.md`.

## Khung pháp lý

> Danh sách do phiên AI tra ngày **2026-10-24** từ nguồn chính thức dưới đây. **Kiểm tra văn bản sửa đổi** trước khi dựa vào.
> Mọi kết luận áp dụng/không áp dụng **cần chủ repo/luật sư xác nhận**; đây không phải ý kiến pháp lý.

| Văn bản | Số hiệu | Ban hành | Hiệu lực | Nguồn (truy cập 2026-10-24) | Ghi chú |
|---|---|---|---|---|---|
| Luật Bảo vệ dữ liệu cá nhân | 91/2025/QH15 | 26/06/2025 | 01/01/2026 | https://congbao.chinhphu.vn/van-ban/luat-so-91-2025-qh15-45578.htm ; tình trạng "Còn hiệu lực": https://bocongan.gov.vn/chinh-sach-phap-luat/co-so-du-lieu-van-ban/luat-bao-ve-du-lieu-ca-nhan-1753688803 | Chỉ xác minh số hiệu/ngày; toàn văn điều khoản chưa đọc được trong phiên |
| Nghị định quy định chi tiết Luật BVDLCN | 356/2025/NĐ-CP | 31/12/2025 | 01/01/2026 | https://congbao.chinhphu.vn/van-ban/nghi-dinh-so-356-2025-nd-cp-468371.htm | Trang Công báo không nêu quan hệ thay thế văn bản; việc thay Nghị định 13/2023/NĐ-CP cần đối chiếu toàn văn |
| GDPR | Regulation (EU) 2016/679 | 27/04/2016 | áp dụng từ 25/05/2018 (Art. 99(2)) | https://publications.europa.eu/resource/celex/32016R0679 (bản XHTML tiếng Anh, Publications Office of the EU) | Art. 2(2)(c) loại trừ xử lý "purely personal or household activity"; Recital 18 vẫn áp cho bên "provide the means"; Art. 3(2) phạm vi lãnh thổ |

Đánh giá sơ bộ cho app offline (cần xác nhận): nhà phát triển không nhận dữ liệu; nghĩa vụ phát sinh chủ yếu khi phát hành
(chính sách quyền riêng tư, kênh phát hành, đối tượng người dùng). Sàng lọc DPIA: `docs/DPIA.md`.

## Chuẩn áp dụng

- **Trợ năng:** **WCAG 2.2 AA** (W3C Recommendation 12/12/2024, https://www.w3.org/TR/WCAG22/, truy cập 2026-10-24) cho cả Dark
  và Light, cùng hướng dẫn trợ năng Android (https://developer.android.com/guide/topics/ui/accessibility, truy cập 2026-10-24):
  vùng chạm ≥ 48 dp, nhãn cho thao tác, tương phản chữ. Kiểm tự động: `apps/mobile/test/ui/accessibility_test.dart`
  (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`). TalkBack/chữ lớn trên thiết bị: chưa kiểm.
- **Bảo mật:** **OWASP MASVS 2.1.0, hồ sơ kiểm thử MAS-L1** (bản MASVS mới nhất trên https://github.com/OWASP/masvs/releases;
  nhóm kiểm soát ở https://mas.owasp.org/MASVS/; truy cập 2026-10-24). Lý do chọn L1: không tài khoản, không mạng, không bí mật
  lúc chạy, chưa phát hành; nhóm áp dụng thực tế là STORAGE, PLATFORM, CODE, PRIVACY. **Xem lại lên MAS-L2** (mã hoá at-rest)
  trước phát hành nếu giữ giấy tờ nhạy cảm (`docs/RISKS.md` RK-004) — chủ repo quyết. OWASP ASVS không áp dụng (không có server/API).
- **Mô hình chất lượng:** ISO/IEC 25010:2023 (ISO catalogue https://www.iso.org/standard/78176.html, edition 2, 2023-11; trang
  trả 403 khi tải trực tiếp nên tên đặc tính dưới đây cần đối chiếu bản chuẩn). Chỉ ghi ngưỡng repo đo được hôm nay:

| Đặc tính (ISO/IEC 25010:2023) | Số đo | Ngưỡng | Đo ở đâu | Hiện trạng |
|---|---|---|---|---|
| Functional suitability | tỷ lệ test Flutter qua | 100% | `flutter test` trong gate | 806/806 trên CI run 40055848269 (`22707f3`, 2026-10-24) |
| Reliability | ca mất dữ liệu có test (storage) đỏ | 0 test fail trong `test/storage` | gate | đạt trong cùng run |
| Security | quyền/component export ngoài danh sách cho phép trong manifest release | 0 | `scripts/check-release-manifest.py` trong build | đạt |
| Security | advisory dependency mức ≥ low trong thay đổi | 0 | `actions/dependency-review-action` (`fail-on-severity: low`) | đạt trên CI |
| Maintainability | cảnh báo analyzer (kể cả info) / file sai format | 0 / 0 | `flutter analyze --fatal-infos`, `dart format --set-exit-if-changed` | đạt |
| Interaction capability (usability) | màn được kiểm qua 3 guideline trợ năng ở Dark + Light | 100% màn trong `accessibility_test.dart` | gate | đạt; thiết bị thật: chưa đo |
| Performance efficiency | thời gian xử lý trang p95 | ≤ 2 s (đề xuất) | thiết bị thật | **chưa đo** |

## Hiệu năng

Chỉ số chính cho hồ sơ mobile offline là **thời gian xử lý một trang** (giải mã → nắn → mã hoá) và **thời gian xuất N trang**.

| Chỉ số | Mục tiêu / trần | Điều kiện đo | Nơi đo | Trạng thái |
|---|---|---|---|---|
| Ngân sách giải mã mỗi ảnh | dừng hẳn isolate sau 60 s (`decodeBudget`) | mọi thiết bị | code `apps/mobile/lib/imaging/isolate_budget.dart`, test `isolate_budget_test.dart` | đã cưỡng chế |
| Byte ảnh gốc tối đa | 64 MiB (`maxOriginalBytes`) | mọi ảnh | `lib/imaging/page_render.dart`, `page_render_test.dart` | đã cưỡng chế |
| Điểm ảnh giải mã tối đa | 50.000.000 (`maxDecodedPixels`) | mọi ảnh | `lib/imaging/page_render.dart`, `decoder_security_test.dart` | đã cưỡng chế |
| Ảnh xem trước | cạnh dài ≤ 1024 px | danh sách trang | `docs/FEATURE-MAP.md` ghi chú phạm vi | đã cưỡng chế |
| p95 xử lý một trang | ≤ 2 s (đề xuất, chưa nghiệm thu) | thiết bị thật, Flutter profile, ảnh 12/24/48 MP | protocol `docs/benchmarks/README.md` (≥ 30 mẫu/case) | **chưa đo** |
| Xuất 100 trang | hoàn tất, không hết RAM (đề xuất) | thiết bị thật | như trên | **chưa đo** |
| Thời gian gate CI | đo, không đặt ngưỡng | runner `ubuntu-24.04` | `docs/perf/baseline-2026-10-24.md` | 6 phút 19 giây (bước gate, run 40055848269) |

Số đo host (Dart AOT trên máy dev/CI) ở `docs/benchmarks/README.md` **không** đại diện thiết bị; không suy ra tốc độ trên điện thoại.
