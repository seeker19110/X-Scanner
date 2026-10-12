# Trạng thái Audit toàn diện

> AI đọc/ghi file này để biết quét tới đâu — cho phép tiếp tục qua nhiều phiên.
> Trạng thái mỗi nhóm: ⬜ Chưa quét · 🔄 Đang dở · ✅ Xong · ➖ Không áp dụng.

- Lần quét bắt đầu: 2026-10-12, trên `main` @ `6177e29` (P1 merged #6..#10). Chạy trong `/completion` Pha 1 (Work ID `2026-10-12-p1-completion`).
- Hồ sơ dự án áp dụng (KHUNG-3 PHẦN C): mobile native (Flutter, Android trước), offline, dữ liệu tài liệu nhạy cảm, không server.
- Cách quét: 3 auditor chỉ đọc chạy song song (A: nhóm 1/3/10/12; B: 2/7/11; C: 4/5/6/8/9); phiên chính gộp trùng, kiểm lại phát hiện mức Cao/Trung trên code thật (vd F-001 lần theo `session_store.dart` `_load`/`_save` và `session_controller.dart` `restore`).
- Lệnh đo đã chạy: `dart analyze` (0 vấn đề); `flutter pub outdated`; `flutter pub deps`; OSV querybatch 86 package (0 advisory); grep bí mật trên `git ls-files` và `git log --all -p` (0); `spec-compiler.py --trace` (AC-1..8 MAPPED, AC-9 PENDING); PoC giải mã `image` 4.10.1 bằng ảnh tổng hợp (EXIF IFD lặp: treo, bị dừng ở 10 s; PNG 1 MB header 1×1: maxRSS 2061 MB).

| # | Nhóm | Trạng thái | Tóm tắt phát hiện (số lượng theo mức độ) | Cập nhật lần cuối |
|---|------|-----------|-------------------------------------------|---------------------|
| 1 | Kiến trúc & thiết kế | ✅ | 0 Cao · 0 Trung · 2 Thấp (F-025, F-027) — hướng phụ thuộc sạch, khớp ADR-0002 §2 | 2026-10-12 |
| 2 | Bảo mật | ✅ | 0 Cao · 2 Trung (F-004, F-005) · 2 Thấp (F-018, F-038) — không log, chống path traversal, provider không exported, backup tắt | 2026-10-12 |
| 3 | Chất lượng mã & chống lỗi logic | ✅ | 0 Cao · 2 Trung (F-006, F-007) · 3 Thấp (F-013 phần rectify, F-019, F-020) | 2026-10-12 |
| 4 | Kiểm thử & coverage | ✅ | 0 Cao · 2 Trung (F-008, F-010) · 2 Thấp (F-028, F-029) — AC-1..8 có test thật | 2026-10-12 |
| 5 | Hiệu năng | ✅ | 0 Cao · 2 Trung (F-012, F-013) · 2 Thấp (F-022, F-030) — p95 trên thiết bị để P2 (spec §2) | 2026-10-12 |
| 6 | Accessibility & UI/UX | ✅ | 0 Cao · 1 Trung (F-011) · 5 Thấp (F-020, F-021, F-031, F-032, F-033) | 2026-10-12 |
| 7 | Dependency & chuỗi cung ứng | ✅ | 0 Cao · 1 Trung (F-009) · 2 Thấp (F-035, F-036) — license MIT/BSD-3/Apache-2.0, lock khớp ghim | 2026-10-12 |
| 8 | CI/CD & vận hành/observability | ✅ | 0 Cao · 2 Trung (F-014, F-015) · 2 Thấp (F-034, F-037) | 2026-10-12 |
| 9 | Tài liệu & đồng bộ | ✅ | 2 Cao (F-002, F-003) · 2 Trung (F-016, F-017) · 5 Thấp (F-027, F-039, F-040, F-041, F-042) | 2026-10-12 |
| 10 | Dữ liệu & migration | ✅ | 1 Cao (F-001) · 0 Trung · 2 Thấp (F-018, F-019) — ghi nguyên tử, `schemaVersion`, cách ly manifest hỏng | 2026-10-12 |
| 11 | Cấu hình môi trường & bí mật | ✅ | 0 Cao · 0 Trung · 1 Thấp (F-037) — không bí mật, `.gitignore` phủ keystore/`local.properties`/`.env` | 2026-10-12 |
| 12 | Thống nhất chéo tính năng | ✅ | 0 Cao · 0 Trung · 4 Thấp (F-021, F-024, F-025, F-026) | 2026-10-12 |

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
| F-009 | 7 | Trung | `.github/workflows/`; `docs/ops/supply-chain.md` §Exception | Không có cảnh báo lỗ hổng/dependency review; hoãn không có owner/hạn | Bỏ lỡ bản vá bảo mật (như F-004) | W-201 (exception) + chủ repo bật |
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
| F-026 | 12 | Thấp | `review_screen.dart` thumbnail | Xem trước danh sách không áp khung cắt | Không thấy kết quả cắt trước khi xuất | Dời P2 (chủ ý, ghi FEATURE-MAP) |
| F-027 | 1/9 | Thấp | spec P1 §11; `test/core/core_purity_test.dart` | Touchpoint `rectify.dart`/`image_export.dart` không tồn tại, thiếu tiền tố `apps/mobile/`; test ghi "spec FR-3" sai spec | Truy vết gãy | W-201 + W-403 |
| F-028 | 4 | Thấp | `session_controller.dart`, `review_screen.dart` | Một số nhánh lỗi chưa có test (file biến mất, `StateError`, lost image hỏng, ô lỗi thumbnail, chuỗi saveFailed) | Đổi hành vi không ai biết | W-302 |
| F-029 | 4 | Thấp | `quad_editor_screen_test.dart`, `review_screen_test.dart`, `pdf_export_test.dart` | Test yếu hơn tên (44 thay 48 dp; nhãn AC-6 chỉ kiểm đuôi; kích thước trang PDF chỉ ở bản không nén) | Test xanh khi tiêu chí đã sai | W-302 |
| F-030 | 5 | Thấp | `session_controller.dart` thumbnails | Thumbnail chỉ trong RAM, mỗi lần mở app giải mã lại | Khởi động chậm với phiên dài | Dời P2 (cần số đo thiết bị) |
| F-031 | 6 | Thấp | `lib/main.dart` | Không có `flutter_localizations`: chuỗi framework (Back, Move up…) tiếng Anh | TalkBack đọc lẫn Anh–Việt | Dời P2 (thêm dependency ngoài D2) |
| F-032 | 6 | Thấp | `quad_editor_screen.dart` | Trình chỉnh góc hiện ảnh chưa xoay; Back bỏ thay đổi không hỏi | Chỉnh nhầm, mất công | Dời P2 (UX) |
| F-033 | 6 | Thấp | `review_screen.dart` | Xuất nhiều trang không có tiến trình i/N, không huỷ | Tưởng app treo | Dời P2 (UX) |
| F-034 | 8 | Thấp | `.github/workflows/ci.yml` concurrency | `cancel-in-progress` áp cả push `main` | Mất kết quả CI của commit trên `main` | W-301 |
| F-035 | 7 | Thấp | `.claude/project-commands.sh` | Gate không `flutter pub get --enforce-lockfile` | Build/test với lock khác bản đã review | W-301 |
| F-036 | 7 | Thấp | `apps/mobile/android/` | Không có Gradle verification metadata | Artifact Maven bị thay không phát hiện | Dời trước release |
| F-037 | 11/8 | Thấp | `.github/workflows/adopt-projects-template.yml` | Token ghi còn trong `.git/config` khi chạy gate (mã bên thứ ba) | Dependency bị xâm phạm có thể push | W-301 |
| F-038 | 2 | Thấp | `android/.../MainActivity.kt` | Ảnh chụp Recents hiện nội dung tài liệu | Lộ nội dung trong trình chuyển app | Dời P2 Data Governance (quyết định sản phẩm) |
| F-039 | 9 | Thấp | `CLAUDE.md`, `AGENTS.md` header; `docs/adoption/README.md` | Header không nhắc spec P1 Approved; adoption README còn câu "N/A trước khi code app" | Agent hiểu nhầm P1 chưa được phép | W-201 |
| F-040 | 9 | Thấp | gốc repo | Chưa có `TRAPS.md` cho 3 khuôn lỗi đã sửa ở P1 | Lỗi cùng khuôn tái phát | W-201 |
| F-041 | 9 | Thấp | `apps/mobile/README.md` | README app chỉ có tiêu đề | Người mới không biết bắt đầu | W-201 |
| F-042 | 9 | Thấp | `docs/adr/` | Không có ADR cho lựa chọn P1 (camera hệ thống, homography Dart, pdf/share_plus) | `docs/adr/` không phản ánh kiến trúc đang chạy | W-201 (ADR-0003) |

## Ghi chú điểm dừng

- Không có nhóm đang dở. Đã kiểm, không thành phát hiện: hướng EXIF không xoay hai lần; PNG trong suốt không thành nền đen; PDF nhúng JPEG `/DCTDecode` không nén lại; file xuất không mang EXIF/GPS; `onReorderItem` đúng chỉ số; manifest chống traversal; không bí mật trong code/lịch sử.
