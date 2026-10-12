# CODEMAP.md — muốn đổi X thì sửa ở đâu

> Bảng tra cứu, không phải tài liệu đọc từ đầu. Mỗi dòng: **muốn gì → sửa file/thư mục nào → rồi chạy lại gì**.
> "Có tính năng gì" ở `docs/FEATURE-MAP.md`; "viết thế nào" ở `docs/CONVENTIONS.md`.
> Đổi cấu trúc (thư mục, lệnh gate, CI) → cập nhật dòng liên quan trong cùng PR.
> Lệnh gate đầy đủ: `bash scripts/dev-task.sh gate` (build APK debug, `flutter analyze --fatal-infos`,
> `dart format`, `flutter test` + kiểm repository; lệnh cụ thể ở `.claude/project-commands.sh`).

## App `apps/mobile`

Hướng phụ thuộc: `ui` → `export`, `storage`, `imaging`, `core`; `export` → `imaging` → `core`; `storage` → `core`. `core` thuần Dart, không import Flutter (`test/core/core_purity_test.dart`).

| Muốn | Sửa | Rồi chạy |
| --- | --- | --- |
| Đổi mô hình trang (quad, xoay, `revision`), phiên hoặc tài liệu (XS-09) | `lib/core/page_quad.dart`, `lib/core/scan_page.dart`, `lib/core/scan_session.dart`, `lib/core/scan_document.dart` | `cd apps/mobile && flutter test test/core` |
| Đổi luật kéo góc (lồi, diện tích tối thiểu, kẹp) | `lib/core/quad_editing.dart` | `flutter test test/core/quad_editing_test.dart test/ui/quad_editor_screen_test.dart` |
| Đổi định dạng manifest phiên (schema 1) hoặc `document.json` (schema 2, XS-08 §13) | `lib/core/session_manifest.dart` (tăng `schemaVersion`, giữ đọc bản cũ; schema mới hơn → `DocumentNeedsAppUpdate`, không cách ly) | `flutter test test/core/session_manifest_test.dart test/storage` |
| Đổi cách lưu/khôi phục/cách ly phiên, giữ bản gốc | `lib/storage/session_store.dart` | `flutter test test/storage` — mọi ca mất dữ liệu phải có test đỏ trước |
| Đổi thuật toán nắn phối cảnh | `lib/imaging/homography.dart` | `flutter test test/imaging` |
| Đổi giải mã/EXIF/giới hạn điểm ảnh/thumbnail | `lib/imaging/page_render.dart` | `flutter test test/imaging test/export` |
| Đổi định dạng ảnh nhận (JPEG/PNG/WebP theo magic bytes) hoặc trần byte bản gốc | `lib/imaging/page_render.dart` (`_decoderFor`, `maxOriginalBytes`) | `flutter test test/imaging test/ui/session_controller_test.dart` |
| Đổi ngân sách thời gian giải mã (isolate bị kill khi quá hạn) | `lib/imaging/isolate_budget.dart` (`decodeBudget`, `runWithinBudget`) | `flutter test test/imaging/isolate_budget_test.dart` |
| Đổi cách giới hạn giải mã đồng thời (thumbnail + render khi xuất) | `lib/imaging/decode_gate.dart`; nối một cổng duy nhất ở `lib/main.dart` | `flutter test test/imaging/decode_gate_test.dart test/ui/session_controller_test.dart` |
| Đổi khổ trang PDF | `lib/export/pdf_export.dart` (`pdfLongSidePoints`, `pageFormatFor`) | `flutter test test/export/pdf_export_test.dart` (AC-6) |
| Đổi tên file xuất, định dạng, dọn file tạm | `lib/export/page_exporter.dart` | `flutter test test/export test/ui/session_controller_test.dart` |
| Đổi cách chia sẻ / MIME | `lib/export/file_sharer.dart` | `flutter test test/export/page_exporter_test.dart` |
| Thêm thao tác người dùng lên phiên | `lib/ui/session_controller.dart` (hàng đợi, `SessionNotice`) | `flutter test test/ui/session_controller_test.dart` |
| Đổi màn danh sách trang / nút / thông báo | `lib/ui/review_screen.dart` | `flutter test test/ui/review_screen_test.dart test/app_test.dart` |
| Đổi màn chỉnh góc | `lib/ui/quad_editor_screen.dart` | `flutter test test/ui/quad_editor_screen_test.dart` |
| Đổi nguồn ảnh (camera hệ thống / thư viện) | `lib/ui/page_source.dart` | `flutter test test/ui` |
| Đổi theme Dark/Light | `lib/app/theme.dart` | `flutter test test/app_test.dart test/ui/accessibility_test.dart` (vùng chạm, nhãn, tương phản ở cả hai theme) |
| Nối dependency, thư mục lưu | `lib/main.dart` | `flutter test test/app_test.dart` + gate |
| Đổi quyền / backup Android | `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/data_extraction_rules.xml` | `flutter test test/android_manifest_test.dart`; gate (bước build gộp manifest release và chạy `scripts/check-release-manifest.py`, AC-8) |
| Thêm/nâng dependency | `pubspec.yaml` (ghim chính xác), `pubspec.lock` (sinh bởi `flutter pub get`) | gate + kiểm manifest release đã gộp; spec §3 yêu cầu bản phát hành ≥ 7 ngày |

## Repository

| Muốn | Sửa | Rồi chạy |
| --- | --- | --- |
| Đổi lệnh gate | `.claude/project-commands.sh` | `bash scripts/dev-task.sh doctor` rồi `gate` |
| Hạ `targetSdk` (gate FAIL khi < 31: dưới 31 component có intent-filter không khai `exported` bị exported ngầm) | `scripts/check-release-manifest.py` (`MIN_TARGET_SDK`), `android/app/build.gradle.kts` | `python3 scripts/check-release-manifest.py --self-test` + gate |
| Cho phép thêm quyền / component exported (cần lý do + spec) | `scripts/check-release-manifest.py` (`ALLOWED_PERMISSIONS`, `ALLOWED_EXPORTED`) | `python3 scripts/check-release-manifest.py --self-test` + gate |
| Đổi CI | `.github/workflows/ci.yml` | `bash scripts/dev-task.sh gate`; xem run trên PR |
| Đổi kiểm adoption / placeholder | `scripts/check-adoption.py` | `python3 scripts/check-adoption.py && python3 scripts/check-adoption.py --lint` |
| Mở việc mới | `bash scripts/new-work.sh <slug>` → `docs/work/<id>/working.md` | `bash scripts/test-new-work.sh` khi đổi script |
| Spec / goal / ADR | `docs/specs/`, `docs/goals/`, `docs/adr/` (ADR mới, không sửa ADR cũ) | `bash scripts/spec-compiler.sh --trace <spec>` |
