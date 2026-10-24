# Trạng thái Audit toàn diện

> AI đọc/ghi file này để biết quét tới đâu — cho phép tiếp tục qua nhiều phiên.
> Trạng thái mỗi nhóm: ⬜ Chưa quét · 🔄 Đang dở · ✅ Xong · ➖ Không áp dụng.

- Lần quét bắt đầu: 2026-10-12, trên `main` @ `6177e29` (P1 merged #6..#10). Chạy trong `/completion` Pha 1 (Work ID `2026-10-12-p1-completion`).
- Hồ sơ dự án áp dụng (KHUNG-3 PHẦN C): mobile native (Flutter, Android trước), offline, dữ liệu tài liệu nhạy cảm, không server.
- Cách quét: 3 auditor chỉ đọc chạy song song (A: nhóm 1/3/10/12; B: 2/7/11; C: 4/5/6/8/9); phiên chính gộp trùng, kiểm lại phát hiện mức Cao/Trung trên code thật (vd F-001 lần theo `session_store.dart` `_load`/`_save` và `session_controller.dart` `restore`).
- Lệnh đo đã chạy: `dart analyze` (0 vấn đề); `flutter pub outdated`; `flutter pub deps`; OSV querybatch 86 package (0 advisory); grep bí mật trên `git ls-files` và `git log --all -p` (0); `spec-compiler.py --trace` (AC-1..8 MAPPED, AC-9 PENDING); PoC giải mã `image` 4.10.1 bằng ảnh tổng hợp (EXIF IFD lặp: treo, bị dừng ở 10 s; PNG 1 MB header 1×1: maxRSS 2061 MB).
- **Quét lại toàn bộ 12 nhóm (Pha 4):** 2026-10-12 trên `6ee3362` (= `main` `a7399de` sau #19), cùng 3 cụm auditor chỉ đọc. Mọi phát hiện cũ: đóng (có file:dòng + test chốt chặn) hoặc dời có chủ đích (F-004 EX-1 tới 2026-10-18; F-009, F-014 WAITING chủ repo; F-018, F-026, F-030..F-033, F-036, F-038). Phát hiện mới F-043..F-058: 0 Cao · 2 Trung (F-051, F-052) · 14 Thấp. OSV 86 package hosted: 0 advisory; bí mật: 0. F-037: gate trong workflow adopt không còn chạy khi giữ token, nhưng bước checkout vẫn giữ credentials (rủi ro dư, chấp nhận: chỉ checkout + `command -v` chạy khi `FRAMEWORK-VERSION` có).
- **Quét lại nhóm bị ảnh hưởng (Pha 4, lần 2):** 2026-10-12 trên `da7cae8` (W-501 #20, W-503 #21, W-502), 2 auditor chỉ đọc: X nhóm 3/4/6/12 (thêm mutation test 7 đột biến, 6 bị test bắt; đột biến bỏ `identical` không gây lỗi thấy được), Y nhóm 2/8/9. F-043, F-044, F-047, F-048, F-050..F-058 đóng; mới F-059, F-070..F-072: 0 Cao · 0 Trung · 4 Thấp. Tổng 62 phát hiện: 3 Cao · 16 Trung · 43 Thấp.
- **Quét lại lần 4 (nhóm 2/3/5/7):** 2026-10-12 trên `474fa28` (W-104a, #28): rà bảo mật diff → 1 Trung bình + 2 Thấp sửa trong #28, 2 Thấp chấp nhận; sweep 🔴 0 · 🟡 2 (F-009; radar do script khung) → hội tụ.
- **Quét lại lần 3 (nhóm 2/8):** 2026-10-12 trên `36861e2` (W-504, merged #24 `0327ab7`), phiên chính: F-071 đóng, 0 phát hiện mới → hội tụ. `maintenance-sweep` 🔴 0; OSV 86 package hosted: 0 advisory; bí mật: 0.

| # | Nhóm | Trạng thái | Tóm tắt phát hiện (số lượng theo mức độ; phát hiện nhiều nhóm tính ở mọi nhóm của nó) | Cập nhật lần cuối |
|---|------|-----------|-------------------------------------------|---------------------|
| 1 | Kiến trúc & thiết kế | ✅ | 0 Cao · 0 Trung · 3 Thấp (F-025, F-027, F-046) — hướng phụ thuộc sạch, khớp ADR-0002 §2 | 2026-10-12 |
| 2 | Bảo mật | ✅ | 0 Cao · 3 Trung (F-004, F-005, F-008) · 5 Thấp (F-018, F-038, F-043, F-045, F-071) — không log, chống path traversal, provider không exported, backup tắt | 2026-10-12 |
| 3 | Chất lượng mã & chống lỗi logic | ✅ | 0 Cao · 4 Trung (F-006, F-007, F-013, F-051) · 3 Thấp (F-020, F-047, F-048) | 2026-10-12 |
| 4 | Kiểm thử & coverage | ✅ | 0 Cao · 2 Trung (F-008, F-010) · 5 Thấp (F-028, F-029, F-053, F-056, F-058) — AC-1..8 có test thật | 2026-10-12 |
| 5 | Hiệu năng | ✅ | 0 Cao · 3 Trung (F-006, F-012, F-013) · 3 Thấp (F-022, F-030, F-057) — p95 trên thiết bị để P2 (spec §2) | 2026-10-12 |
| 6 | Accessibility & UI/UX | ✅ | 0 Cao · 2 Trung (F-011, F-051) · 7 Thấp (F-020, F-021, F-031, F-032, F-033, F-047, F-056) | 2026-10-12 |
| 7 | Dependency & chuỗi cung ứng | ✅ | 0 Cao · 1 Trung (F-009) · 3 Thấp (F-035, F-036, F-044) — license MIT/BSD-3/Apache-2.0, lock khớp ghim | 2026-10-12 |
| 8 | CI/CD & vận hành/observability | ✅ | 0 Cao · 2 Trung (F-014, F-015) · 5 Thấp (F-034, F-037, F-043, F-044, F-071) | 2026-10-12 |
| 9 | Tài liệu & đồng bộ | ✅ | 2 Cao (F-002, F-003) · 4 Trung (F-015, F-016, F-017, F-052) · 9 Thấp (F-027, F-039, F-040, F-041, F-042, F-054, F-055, F-070, F-072) | 2026-10-12 |
| 10 | Dữ liệu & migration | ✅ | 1 Cao (F-001) · 1 Trung (F-005) · 3 Thấp (F-018, F-019, F-049) — ghi nguyên tử, `schemaVersion`, cách ly manifest hỏng | 2026-10-12 |
| 11 | Cấu hình môi trường & bí mật | ✅ | 0 Cao · 0 Trung · 1 Thấp (F-037) — không bí mật, `.gitignore` phủ keystore/`local.properties`/`.env` | 2026-10-12 |
| 12 | Thống nhất chéo tính năng | ✅ | 0 Cao · 0 Trung · 8 Thấp (F-021, F-023, F-024, F-026, F-048, F-049, F-050, F-059) | 2026-10-12 |

## Phát hiện (ID cố định; W-xxx ở `docs/ops/COMPLETION-PLAN.md`)

Mức: Cao = mất/hỏng dữ liệu, rò riêng tư, crash luồng chính, tài liệu khai sai trạng thái · Trung = sai ở ca biên hoặc lỗ hổng cần điều kiện thực tế · Thấp = nhỏ/hardening.

| ID | Nhóm | Mức | Vị trí | Phát hiện | Rủi ro nếu để | Kết cục |
|----|------|-----|--------|-----------|---------------|---------|
| F-001 | 10 | Cao | `apps/mobile/lib/storage/session_store.dart` `_load`/`_save`; `lib/ui/session_controller.dart` `restore` | `load` lỗi I/O (vd `readAsBytes`) → manifest không bị cách ly, controller vẫn cho lưu; lưu trang mới ghi đè `session.json`; lần mở sau bước dọn xoá mọi bản gốc của phiên cũ | Mất vĩnh viễn bản gốc, trái thông báo "ảnh gốc vẫn được giữ" | W-101 |
| F-002 | 9 | Cao | `README.md:4` | Ghi "P0 nền… chưa có chức năng chụp" trong khi P1 đã merge | Người/agent hiểu sai trạng thái | W-201 |
| F-003 | 9 | Cao | `PROJECT.md:5, 13-14, 31-32` | Ghi "chưa có camera, PDF engine hoặc lưu trữ", "PDF engine còn mở" | Lập kế hoạch trên phạm vi sai | W-201 |
| F-004 | 2 | Trung | `apps/mobile/pubspec.yaml` `image: 4.10.1`; `lib/imaging/page_render.dart` | Decoder `image` 4.10.1: EXIF IFD lặp treo vô hạn; PNG bom giải nén qua được trần điểm ảnh (PoC) | Nhập ảnh độc hại → UI kẹt/OOM tới khi khởi động lại (không mất trang) | W-104 (chờ 2026-10-18) + exception |
| F-005 | 2/10 | Trung | `lib/ui/session_controller.dart` `_addFromPath`; `image_picker_android` 0.8.13+25 | Picker chép ảnh vào cache app; app không bao giờ xoá bản sao, kể cả sau "Xoá tất cả" | Ảnh tài liệu nằm lại vô thời hạn, tốn gấp đôi dung lượng | W-102 |
| F-006 | 3/5 | Trung | `session_controller.dart` `exportAndShare`; `lib/export/page_exporter.dart` | Render khi xuất không đi qua hàng đợi giải mã của thumbnail → 2 bản gốc giải mã cùng lúc (trái spec §8) | OOM trên máy RAM thấp | W-103 |
| F-007 | 3 | Trung | `lib/ui/review_screen.dart` `onReorderItem`; `session_controller.dart` `move` | Kéo-thả vẫn bật khi bận; `move` dùng chỉ số cũ → chuyển nhầm trang hoặc chuyển hai lần | Thứ tự trang xuất sai (AC-1) | W-103 |
| F-008 | 4/2 | Trung | `apps/mobile/test/android_manifest_test.dart` | AC-8 chỉ kiểm manifest nguồn; manifest release đã gộp (quyền từ plugin) chỉ kiểm tay | Nâng dependency thêm INTERNET/CAMERA lọt gate | W-301 |
| F-009 | 7 | Trung | `.github/workflows/`; `docs/ops/supply-chain.md` §Exception | Không có cảnh báo lỗ hổng/dependency review; hoãn không có owner/hạn | Bỏ lỡ bản vá bảo mật (như F-004) | W-201 (exception) + Dependabot version updates (2026-10-13); còn chủ repo bật alerts/dependency review |
| F-010 | 4 | Trung | `test/ui/session_controller_test.dart` | Ca "sao chép bản gốc lỗi (đầy đĩa)" (spec §6) không có test ở controller | Hồi quy nhánh đầy đĩa lọt gate | W-302 |
| F-011 | 6 | Trung | `apps/mobile/test/**` | Không có `meetsGuideline` (vùng chạm, nhãn, tương phản) cho Dark/Light | Lỗi a11y lọt gate dù spec yêu cầu AA | W-302 |
| F-012 | 5 | Trung | `page_exporter.dart`; `lib/export/pdf_export.dart` | `buildPdf`/`doc.save()` chạy trên UI isolate, giữ mọi trang trong RAM, không trần số trang | Giật/ANR, OOM khi xuất nhiều trang | W-401 |
| F-013 | 5/3 | Trung | `page_render.dart` `maxDecodedPixels`, `rectifiedSize` | Trần 50 MP chưa đo bộ nhớ; đầu ra nắn có thể lớn hơn đầu vào (không trần) | OOM với ảnh lớn + khung xiên | W-401 |
| F-014 | 8 | Trung | repo settings; `docs/ops/repository-settings.md` | Chưa có ruleset/branch protection; tên check bắt buộc trong tài liệu không khớp job `Framework and Android app gate` | Commit đỏ vào `main` không bị chặn | Chủ repo (WAITING) + W-201 |
| F-015 | 8/9 | Trung | `CLAUDE.md` §2, §8; `.github/workflows/` | CLAUDE.md nói `pr-policy.yml`/`progress-freshness` kiểm tự động; hai workflow không tồn tại | Agent tin có cổng tự động, bỏ tự kiểm | W-201 |
| F-016 | 9 | Trung | goal P1, `working.md` P1, `PROGRESS.md`, `CHANGELOG.md` | Trạng thái tụt sau #10 | Reconcile sai | W-201 |
| F-017 | 9 | Trung | `docs/ops/repository-settings.md` (ghim hash) | Bảng Evidence là của repo khung ("ruleset active") | Tưởng `main` đã được bảo vệ | W-201 (bảng riêng X-Scanner) |
| F-018 | 10/2 | Thấp | `session_store.dart` `_hasQuarantinedManifest` | Bản gốc của phiên bị cách ly giữ vô thời hạn, không UI xoá; còn file corrupt thì không dọn orphan mới | Dữ liệu nhạy cảm/dung lượng tồn đọng | W-101 (DEBT) → P2 Data Governance |
| F-019 | 10 | Thấp | `session_store.dart` `importOriginal` | Không tuần tự với `load` (GC có thể xoá bản vừa import) — an toàn nhờ hàng đợi controller | Bẫy cho P2 import song song | W-101 |
| F-020 | 3/6 | Thấp | `session_controller.dart` `thumbnailFor`; `review_screen.dart` | Future thumbnail lỗi bị cache mãi; ô lỗi không có nhãn | Trang không chỉnh góc được tới khi mở lại app | W-402 |
| F-021 | 6/12 | Thấp | `review_screen.dart`; `session_controller.dart` | Lúc khôi phục hiện trạng thái "rỗng" thay vì "đang tải"; thanh tiến trình không nhãn | Người dùng tưởng mất phiên | W-402 |
| F-022 | 5 | Thấp | `review_screen.dart` `Image.memory` | Thumbnail 1024 px giải mã đủ cho ô 72 dp (thiếu `cacheWidth`) | Tốn bộ nhớ ảnh | W-402 |
| F-023 | 12 | Thấp | `page_exporter.dart` `padLeft(2)` | ≥ 100 trang thì tên file sắp sai thứ tự | Thứ tự ảnh xuất sai ở tài liệu dài | W-401 |
| F-024 | 12 | Thấp | controller, store, manifest, `file_sharer.dart` | Khuôn phần mở rộng lặp 3 nơi, tách đuôi lặp 2 nơi | Lệch quy tắc → ngoại lệ không xử lý | W-403 |
| F-025 | 1 | Thấp | `lib/ui/quad_editor_screen.dart` | `ui/` import thẳng `package:image` | Logic giải mã phân tán | W-403 |
| F-026 | 12 | Thấp | `review_screen.dart` thumbnail | Xem trước danh sách không áp khung cắt | Không thấy kết quả cắt trước khi xuất | Đóng 2026-10-12: XS-13 PR-1 #36 `f7dc45c` |
| F-027 | 1/9 | Thấp | spec P1 §11; `test/core/core_purity_test.dart` | Touchpoint `rectify.dart`/`image_export.dart` không tồn tại, thiếu tiền tố `apps/mobile/`; test ghi "spec FR-3" sai spec | Truy vết gãy | W-201 + W-403 |
| F-028 | 4 | Thấp | `session_controller.dart`, `review_screen.dart` | Một số nhánh lỗi chưa có test (file biến mất, `StateError`, lost image hỏng, ô lỗi thumbnail, chuỗi saveFailed) | Đổi hành vi không ai biết | W-302 |
| F-029 | 4 | Thấp | `quad_editor_screen_test.dart`, `review_screen_test.dart`, `pdf_export_test.dart` | Test yếu hơn tên (44 thay 48 dp; nhãn AC-6 chỉ kiểm đuôi; kích thước trang PDF chỉ ở bản không nén) | Test xanh khi tiêu chí đã sai | W-302 |
| F-030 | 5 | Thấp | `session_controller.dart` thumbnails | Thumbnail chỉ trong RAM, mỗi lần mở app giải mã lại | Khởi động chậm với phiên dài | Dời P2 (cần số đo thiết bị) |
| F-031 | 6 | Thấp | `lib/main.dart` | Không có `flutter_localizations`: chuỗi framework (Back, Move up…) tiếng Anh | TalkBack đọc lẫn Anh–Việt | Dời P2 (thêm dependency ngoài D2) |
| F-032 | 6 | Thấp | `quad_editor_screen.dart` | Trình chỉnh góc hiện ảnh chưa xoay; Back bỏ thay đổi không hỏi | Chỉnh nhầm, mất công | Đóng 2026-10-12: XS-13 PR-2 #37 `9fbe2fd` |
| F-033 | 6 | Thấp | `review_screen.dart` | Xuất nhiều trang không có tiến trình i/N, không huỷ | Tưởng app treo | Đóng 2026-10-12: XS-12a PR-1 #40 `614b5b4` |
| F-034 | 8 | Thấp | `.github/workflows/ci.yml` concurrency | `cancel-in-progress` áp cả push `main` | Mất kết quả CI của commit trên `main` | W-301 |
| F-035 | 7 | Thấp | `.claude/project-commands.sh` | Gate không `flutter pub get --enforce-lockfile` | Build/test với lock khác bản đã review | W-301 |
| F-036 | 7 | Thấp | `apps/mobile/android/` | Không có Gradle verification metadata | Artifact Maven bị thay không phát hiện | Dời trước release |
| F-037 | 11/8 | Thấp | `.github/workflows/adopt-projects-template.yml` | Token ghi còn trong `.git/config` khi chạy gate (mã bên thứ ba) | Dependency bị xâm phạm có thể push | W-301 |
| F-038 | 2 | Thấp | `android/.../MainActivity.kt` | Ảnh chụp Recents hiện nội dung tài liệu | Lộ nội dung trong trình chuyển app | Dời P2 Data Governance (quyết định sản phẩm) |
| F-039 | 9 | Thấp | `CLAUDE.md`, `AGENTS.md` header; `docs/adoption/README.md` | Header không nhắc spec P1 Approved; adoption README còn câu "N/A trước khi code app" | Agent hiểu nhầm P1 chưa được phép | W-201 |
| F-040 | 9 | Thấp | gốc repo | Chưa có `TRAPS.md` cho 3 khuôn lỗi đã sửa ở P1 | Lỗi cùng khuôn tái phát | W-201 |
| F-041 | 9 | Thấp | `apps/mobile/README.md` | README app chỉ có tiêu đề | Người mới không biết bắt đầu | W-201 |
| F-042 | 9 | Thấp | `docs/adr/` | Không có ADR cho lựa chọn P1 (camera hệ thống, homography Dart, pdf/share_plus) | `docs/adr/` không phản ánh kiến trúc đang chạy | W-201 (ADR-0003) |
| F-043 | 2/8 | Thấp | `scripts/check-release-manifest.py` | Chỉ coi `exported="true"` là exported; `True`/`TRUE`/`@bool/…` lọt cổng (re-audit) | Plugin mới lộ component mà gate xanh | W-501 |
| F-044 | 7/8 | Thấp | `.claude/project-commands.sh` `build` | Không xoá manifest gộp cũ trước Gradle; gate cục bộ có thể đọc file cũ (CI checkout sạch nên vẫn chặn) | Pre-commit xanh sai | W-501 |
| F-045 | 2 | Thấp | `lib/main.dart`; `page_source.dart` `discard` | iOS: picker ghi `NSTemporaryDirectory`, còn `getTemporaryDirectory` là Caches → không xoá bản sao (giữ file, an toàn) | Bản sao còn trên iOS | Dời P2 iOS (iOS non-goal P1) |
| F-046 | 1 | Thấp | `session_controller.dart`, `page_exporter.dart`, `main.dart` | "Một cổng giải mã" chỉ đúng nhờ `main.dart` nối tay hai chỗ tiêm | Quên nối → F-006 quay lại mà vẫn biên dịch | Dời: quy ước ghi ở CONVENTIONS + test F-006 lặp đúng cách nối; xem lại khi thêm nơi giải mã |
| F-047 | 3/6 | Thấp | `review_screen.dart` ô lỗi; `session_controller.dart` `thumbnailFor` | Thumbnail lỗi giải mã lại ở mọi lần dựng lại dòng (chen vào hàng đợi giải mã); bấm thử lại không có spinner | Tốn giải mã, không phản hồi | W-502 |
| F-048 | 3/12 | Thấp | `session_controller.dart` `_addFromPath` | Lỗi khác `ImageDecodeFailure`/`FileSystemException` khi giải mã thử thoát ra không báo (vd isolate `RemoteError`, hết bộ nhớ với file rất lớn) | Người dùng không thấy gì | W-502 |
| F-049 | 10/12 | Thấp | `session_store.dart` `_save`; `session_controller.dart` | Sau `load` lỗi I/O, mọi lần thêm trang báo "Không lưu được (bộ nhớ đầy)" sai nguyên nhân và chép bản gốc mồ côi (lần load sau dọn) | Thông báo sai; không mất dữ liệu đã lưu | Dời P2 Data Governance (cần notice mới + thử load lại); hiếm (lỗi I/O khi đọc) |
| F-050 | 12 | Thấp | `lib/ui/quad_editor_screen.dart` dấu `DEBT:` | Dấu trải 3 dòng, `maintenance-sweep.sh` báo sai thiếu "xem lại khi:" | Cảnh báo giả | W-503 |
| F-051 | 6/3 | Trung | `review_screen.dart` `onReorderItem` | Khi bận vẫn sắp xếp được bằng thao tác ngữ nghĩa (TalkBack Move up/down) → `move` chỉ số cũ (F-007 qua đường khác) | Thứ tự trang sai | W-502 |
| F-052 | 9 | Trung | `docs/FEATURE-MAP.md` | Còn ⚠️ trỏ phát hiện đã đóng; thiếu test mới; LC chưa ghi tên test | Bản đồ khai sai trạng thái (bi quan) | W-503 |
| F-053 | 4 | Thấp | `test/ui/review_screen_test.dart` | LC-1 chưa có một test đi liền chụp → kéo góc → lưu → xuất PDF | Hồi quy ở chỗ nối các bước | W-502 |
| F-054 | 9 | Thấp | spec P1 §16 AC-8; `README.md`; `PROJECT.md` | Ghi manifest release "kiểm tay", gate đã tự kiểm từ W-301 | Tài liệu lệch | W-503 |
| F-055 | 9 | Thấp | `CHANGELOG.md` | Unreleased thiếu các sửa #11–#19 | Lịch sử thiếu | W-503 |
| F-056 | 6/4 | Thấp | `test/ui/accessibility_test.dart` | Guideline chưa phủ trạng thái rỗng và "Đang mở phiên…" | Lỗi a11y lọt | W-502 |
| F-057 | 5 | Thấp | `page_exporter.dart` `DEBT:` PDF | `Isolate.run` chép mọi JPEG sang isolate (đỉnh ~2×), trần trong `DEBT:` chưa tính | Ước lượng trần sai | W-503 (ghi vào `DEBT:`) |
| F-058 | 4 | Thấp | `.claude/project-commands.sh` `test` | Không có số coverage baseline | Không biết vùng chưa test | W-503 (baseline một lần; ngưỡng dời P2) |
| F-059 | 12 | Thấp | `docs/CONVENTIONS.md` "Báo lỗi cho người dùng"; `session_controller.dart` `_addFromPath`, `exportAndShare` | Quy ước ghi "bắt kiểu lỗi cụ thể" trong khi hai chỗ cố ý bắt mọi lỗi (re-audit 2) | Ai đó "sửa" lại thành bắt kiểu cụ thể → F-048 quay lại | W-502 (sửa quy ước) |
| F-070 | 9 | Thấp | `PROGRESS.md`; `COMPLETION-PLAN.md` đầu; bảng theo nhóm của file này | Số phát hiện và bảng theo nhóm còn đếm F-001..F-042 | Reconcile đọc sai số lượng | W-502 (tài liệu) |
| F-071 | 2/8 | Thấp | `scripts/check-release-manifest.py` | Coi component không khai `exported` là không exported — chỉ đúng khi targetSdk ≥ 31; không gì chốt targetSdk | Hạ targetSdk → component có intent-filter exported ngầm mà gate xanh | W-504 |
| F-072 | 9 | Thấp | `CHANGELOG.md` | Chưa có dòng cho các sửa W-502 | Lịch sử thiếu (khuôn F-055) | W-502 |

## Ghi chú điểm dừng

- Không có nhóm đang dở. Đã kiểm, không thành phát hiện: hướng EXIF không xoay hai lần; PNG trong suốt không thành nền đen; PDF nhúng JPEG `/DCTDecode` không nén lại; file xuất không mang EXIF/GPS; `onReorderItem` đúng chỉ số; manifest chống traversal; không bí mật trong code/lịch sử.

## Đối chiếu XS-05 — 2026-10-16

F-014 đã có native control/evidence: ruleset 25250032/no bypass, required app 15368 strict,
CI cố ý cancelled làm PR #53 BLOCKED (run 38925328599, không thử merge). F-009 partial:
alerts/graph 86/86 Pub bật, dependency review step SUCCESS trên PR; EX-2 giữ tới khi
workflow merge main. Bằng chứng [XS-05](../work/2026-10-16-xs05-repository-guards/done.md)
và [PR #53](https://github.com/seeker19110/X-Scanner/pull/53). Các thống kê audit 12/10 giữ
nguyên lịch sử; đây không phải một full audit mới hoặc bằng chứng decoder F-004 đã an toàn.

## Reconcile sau merge XS-05 — 2026-10-16

PR #53 đã merge `3f49039` (head được review `51af8e0`, CI `38930758793` SUCCESS).
Workflow đã vào main; CI `38931930723` SUCCESS và native rules/readback vẫn khớp.
Alerts trả 204, graph 86/86 Pub và dependency compare cuối không warning; EX-2 đã đóng.
Các dòng chờ owner settings/partial trước đó là lịch sử. EX-1/W-104b (18/10), AC-9
và PR-4b vẫn mở. XS-06a chuẩn bị fixture/tooling host theo Work ID
`2026-10-16-xs06-host-baseline`; chưa nghiệm thu thiết bị, chất lượng, OCR hoặc 100 trang.

## Re-audit W104b chuẩn bị18Oct

F004: image4.12.0 đủtuổi, archivehash/taglibverified, wholelockchỉimageđổi; root actualREDA trên4.10.1/REDB saupintrướcwire, targeted240/240. Reuse byte/time/format/staticWebP guards và original-preservation; explicitperinstancecap khôngphảiquotaRAM/lazyinflatercóreadahead. Đây làrànhóm2/7/corebịảnhhưởng, khôngfullaudit/newsecuritycertification. Rootfullgate/CI/actualmergepending; F004/EX1 giữmởđếnđủevidence. PR4bownerapproval18Octthuộcgoalriêng, chưacode/appactivation.


## Re-audit W104b sau actualmerge — 2026-10-18

F004 đóng bởi PR58/c50670a: reviewed4.12.0, hash/age/tag/lock chính thức, actual stagedRED→GREEN, rootgate/hook639+639, CI39088067553 SUCCESS, core/AOT/CLI originals unchanged, nativeproof đúnghead/base. EX1 đóng. Rà nhóm2/7 và core bị ảnh hưởng không có finding mới từ review cuối23files; đây không phải full security audit hay deviceRAM acceptance. Những dòng W104b/EX1WAITING trong checkpoint12–17Oct là lịch sử.

Capacityleaf dùng StatFs trên filesDir, mock/JVM/error-boundary tests và gate bổ sung; chưa nối app nên chưa nghiệm thu XS09AC13. Pendingpicker actual plugin read-clear và perdoc recovery được ghi để chặn crossdoc data-loss trước khi tích hợp.


## Re-audit Pha 4 lần 4 — 2026-10-23 (sau #61 `e21e2cb`, #57 `4ce9a76`, #62 `4956064`)

Phạm vi: các nhóm bị ảnh hưởng — 2/10 (dữ liệu: migration P1 bật trong app, luồng ảnh picker), 3 (logic), 4/8 (test, hook/CI từ #57), 6 (a11y màn thư viện/tài liệu), 9 (tài liệu), 12 (thống nhất). Không phải full 12 nhóm, không phải chứng nhận bảo mật.
Đầu vào: review độc lập của #62 (2 phát hiện F1/F2, đã sửa có RED trước khi merge); `scripts/maintenance-sweep.sh` (🔴 1 · 🟡 1); `scripts/arch-health-radar.sh --scan` (54/100); grep tài liệu.

| ID | Nhóm | Mức | Phát hiện | Kết cục |
|----|------|-----|-----------|---------|
| F-073 | 9 | Thấp | README/PROJECT/README app còn "lưu phiên", "chờ UAT AC-9" sau khi AC-9 nghiệm thu và #62 merge | Sửa trong PR reconcile này |
| F-074 | 9 | Thấp | 8 hồ sơ `working.md` đã xong (picker leaf, PR-4b, AC-9 UAT, P1, X-Templates) chưa đóng | Đổi `done.md` kèm SHA trong PR này |
| F-075 | 2 | Thấp | `maintenance-sweep` 🔴 "bí mật" ở `.xtemplates/scripts/xt.py:144` là regex dùng để che khoá riêng, không phải khoá | Dương tính giả; chấp nhận, không xoay khoá. Xem lại khi: thêm allowlist cho file vendored |
| F-076 | 8 | Thấp | Radar 54/100 do script khung chưa có test, spec khung thiếu mục, file vendored dài (`xt.py`, `guard.py`) | Ngoài phạm vi sản phẩm (khung/template); chấp nhận |
| F-077 | 8 | Trung | Sau #57 mỗi `git commit` từ Claude Code chạy gate 2 lần **song song** (PreToolUse `pre-commit-gate.sh` + `pre-bash-guard.sh`) trên cùng `apps/mobile/build/`; 23/10 lần commit đầu của PR reconcile hỏng build vì hai bản va nhau (`Could not set file mode 644 … kernel_blob.bin`), lần thử lại PASS | Đổi hook/settings là cấu hình cổng → chủ repo quyết (đề xuất của #57: tắt gate trong guard, giữ hook cũ). Tới khi đó: thất bại build ở hook commit phải đọc log trước khi coi là lỗi code |
| F-078 | 2/10 | Trung | APK có thư viện (#62) chưa chạy trên emulator/thiết bị: migration thật, StatFs thật, picker thật | WAITING — cần môi trường Android tăng tốc (container không có KVM) |
| F-079 | 3 | Thấp | `retrieveLost` chỉ bắt `PlatformException`; lỗi khác để marker rỗng tới lần khởi động sau | Chấp nhận (tự hết ở lần khởi động sau, không mất byte) |

Hội tụ: 0 phát hiện Cao mới; Trung F-078 có kết cục WAITING ghi nhận.
