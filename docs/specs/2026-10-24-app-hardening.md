# App hardening — lỗi toàn cục, giảm chuyển động, dialog xoá, trần manifest, a11y, khai báo iOS, phân vị benchmark

| Thuộc tính | Giá trị |
| --- | --- |
| Work ID | 2026-10-24-app-hardening |
| State | **Approved for implementation** |
| Approver / date | Phiên chính duyệt theo ủy quyền §3d; chủ repo yêu cầu 'làm hết các việc còn lại' 2026-10-24 |
| Risk | M; một nhánh `local/backlog-c`, nhiều commit nhỏ, không thêm dependency, không đổi schema |

## 1. Problem and evidence

`BLUEPRINT.md` còn các mục MUST chưa đạt trên app Flutter: `BASE-ERR-002` (không có handler lỗi toàn cục),
`UX-VISUAL-001` (chuyển cảnh không tôn trọng giảm chuyển động), `UX-STATE-008` (dialog xoá không nêu hậu quả),
`XC-PERF-006` (đọc `document.json`/`session.json` không giới hạn cỡ), `XC-UNITS-009` (hằng kích thước thiếu
hậu tố đơn vị), nhóm a11y `UX-A11Y-001/002/003`, `UX-DS-003`, `UX-RESP-001`, `STD-A11Y-002` (chưa có kiểm tương
phản mức token, chưa có test bàn phím, chưa có test 320 dp cho thư viện), `PRF-MOB-004/005` (thiếu
`PrivacyInfo.xcprivacy`, thiếu usage string iOS) và `XC-PERF-004` (benchmark chưa có p95/p99).

## 3. Research and choice

| Comparison | Evidence | Decision |
| --- | --- | --- |
| Đã có và sâu hơn | Trần ảnh `maxOriginalBytes`, `maxDecodedPixels`, test guideline Flutter Dark/Light, test 320 dp cho màn tài liệu | Dùng lại, không đổi |
| Đã có nhưng nông hơn | `textContrastGuideline` chỉ đo chữ đang vẽ; dialog xoá chỉ hỏi "Xoá trang N?"; benchmark chỉ in một mẫu/tiến trình | Thêm test token, câu hậu quả, lệnh `summarize` |
| Chưa có, sự cố thật | `FlutterError.onError`/`PlatformDispatcher.onError` mặc định in toàn văn lỗi (có thể chứa đường dẫn) ra logcat bản release; manifest lớn đọc trọn vào bộ nhớ | Handler không ghi nội dung; đọc có trần |

Chỉ dùng API sẵn của Flutter SDK (`FlutterError`, `PlatformDispatcher`, `ErrorWidget`, `MediaQuery.disableAnimationsOf`,
`PageTransitionsTheme`, `AnimationStyle.noAnimation`, `Color.computeLuminance`) và `dart:io` `File.openRead(start, end)`.
Không thêm package. Tương phản theo công thức WCAG 2.2 (độ chói tương đối, tỷ lệ `(L1 + 0.05) / (L2 + 0.05)`).

## 7. Contract

- FR-1 (`BASE-ERR-002`): `lib/app/error_handling.dart` `installErrorHandlers({release})` đặt `FlutterError.onError`,
  `PlatformDispatcher.instance.onError` (trả `true`, app chạy tiếp) và ở release `ErrorWidget.builder` hiện câu chung.
  Release chỉ ghi một dòng có kiểu lỗi, không message, không stack, không đường dẫn, không tiêu đề. Debug giữ
  `FlutterError.presentError` cho nhà phát triển. `main()` gọi nó trước `runApp`.
- FR-2 (`UX-VISUAL-001`): theme bọc mọi `PageTransitionsBuilder` mặc định; khi `MediaQuery.disableAnimations` bật,
  trang mới hiện ngay không dịch chuyển/zoom. Bottom sheet xuất dùng `AnimationStyle.noAnimation` khi giảm chuyển động.
- FR-3 (`UX-STATE-008`): dialog "Xoá trang N?" và "Xoá tất cả trang?" nêu hậu quả: trang và ảnh gốc của nó bị xoá
  khỏi tài liệu, không hoàn tác được. Back/Esc đóng dialog và không xoá gì.
- FR-4 (`XC-PERF-006`): `maxManifestBytes` = 4 MiB. `DocumentStore.load`, `LibraryStore.list`, `P1Migration` (đọc
  `session.json`) đọc tối đa `maxManifestBytes + 1` byte; vượt trần thì coi là không đọc được **mà không đổi tên,
  không cách ly, không xoá gì**: `load` ném `FileSystemException` (store không ready, `save` từ chối), `list` trả
  `LibraryUnreadable`, migration trả `MigrationSourceUnreadable` và giữ `session/`. `save` từ chối ghi manifest vượt trần.
- FR-5 (`XC-UNITS-009`): đổi tên hằng kích thước đã chạm: `_thumbSide` → `_thumbSidePx`, `_handleSize` →
  `_handleSizePx`, `_handleDot` → `_handleDotPx`, `_loupeDiameter` → `_loupeDiameterPx`. Không đổi hành vi.
- FR-6 (a11y): test token tương phản cho các cặp `ColorScheme` app dùng (chữ ≥ 4.5:1; chữ lớn/icon/viền điều khiển
  ≥ 3:1) ở Dark và Light; test bàn phím Tab/Enter/Escape cho thư viện và màn tài liệu; thư viện ở 320 dp, textScale 2.0.
- FR-7 (`PRF-MOB-004/005`): `ios/Runner/PrivacyInfo.xcprivacy` (không tracking, không thu dữ liệu, File timestamp
  `C617.1` vì migration đọc `lastModified` trong container), thêm vào Resources của target Runner;
  `Info.plist` có `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` tiếng Việt, đúng hành vi.
- FR-8 (`XC-PERF-004`): `tool/scanner_benchmark.dart summarize <jsonl>` in số mẫu và min/p50/p95/p99/max (nearest-rank)
  cho từng chỉ số thời gian; file có trần cỡ, lỗi không lộ đường dẫn.

## 9. Acceptance

- AC-1: test handler: lỗi framework và lỗi bất đồng bộ có chuỗi nhạy cảm giả không xuất hiện trong log; `onError` trả `true`; `ErrorWidget` release hiện câu chung.
- AC-2: widget test: bật `disableAnimations`, push trang: khung đầu đã ở vị trí cuối; tắt thì đang chuyển động (đối chứng).
- AC-3: widget test hai dialog có câu hậu quả; Esc và Back đóng dialog, số trang và ảnh gốc giữ nguyên.
- AC-4: test store/list/migration: manifest đúng trần đọc được; vượt trần một byte không đọc, tên file và ảnh gốc giữ nguyên; `save` vượt trần không ghi.
- AC-5: đổi tên cơ học, toàn bộ test cũ xanh.
- AC-6: test tương phản token, bàn phím, 320 dp/textScale 2.0 xanh ở cả hai theme.
- AC-7: plist/xcprivacy parse được bằng `python3 plistlib`; test Dart kiểm khoá và chuỗi không rỗng. Không build iOS.
- AC-8: test `summarize` với mẫu biết trước ra đúng p50/p95/p99; file sai/quá lớn trả lỗi chung.

## 11. Architecture và code touchpoints

- `apps/mobile/lib/app/error_handling.dart`, `apps/mobile/lib/main.dart` — FR-1.
- `apps/mobile/lib/app/theme.dart`, `apps/mobile/lib/ui/review_screen.dart` — FR-2, FR-3, FR-5.
- `apps/mobile/lib/storage/document_store.dart`, `apps/mobile/lib/storage/library_store.dart`, `apps/mobile/lib/storage/p1_migration.dart` — FR-4.
- `apps/mobile/lib/ui/quad_editor_screen.dart` — FR-5.
- `apps/mobile/ios/Runner/PrivacyInfo.xcprivacy`, `apps/mobile/ios/Runner/Info.plist`, `apps/mobile/ios/Runner.xcodeproj/project.pbxproj` — FR-7.
- `apps/mobile/tool/scanner_benchmark.dart`, `docs/benchmarks/README.md` — FR-8.
- `docs/work/2026-10-24-app-hardening/working.md` — quyết định và bằng chứng RED/GREEN.

## 14. Không làm (quyết định, không triển khai)

- `BASE-DATA-002`, `UX-CONTENT-002`, `XC-I18N-005` (NFC): Dart SDK không có chuẩn hoá Unicode; cần bảng Unicode = dependency mới. App không tìm kiếm/so sánh tiêu đề, tiêu đề chỉ để hiển thị. Xem lại khi thêm tìm kiếm, sắp xếp hoặc khoá theo tiêu đề.
- `XC-I18N-001/003/009`: spec chốt app chỉ tiếng Việt; xem lại khi thêm ngôn ngữ thứ hai.
- `UX-DS-006`: render font tiếng Việt cần thiết bị/font hệ thống thật; widget test dùng font Ahem không chứng minh được.

## 16. Evidence

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `apps/mobile/test/app/error_handling_test.dart` |
| AC-2 | `apps/mobile/test/app/reduced_motion_test.dart` |
| AC-3 | `apps/mobile/test/ui/review_screen_test.dart` |
| AC-4 | `apps/mobile/test/storage/document_store_test.dart`; `apps/mobile/test/storage/library_store_test.dart`; `apps/mobile/test/storage/p1_migration_test.dart` |
| AC-5 | `apps/mobile/lib/ui/quad_editor_screen.dart` |
| AC-6 | `apps/mobile/test/app/theme_contrast_test.dart`; `apps/mobile/test/ui/keyboard_test.dart`; `apps/mobile/test/ui/library_screen_test.dart` |
| AC-7 | `apps/mobile/test/ios_declarations_test.dart` |
| AC-8 | `apps/mobile/test/tool/scanner_benchmark_test.dart` |

Gate PASS không là bằng chứng build iOS, thiết bị, giảm chuyển động trên máy thật hay chất lượng release.
