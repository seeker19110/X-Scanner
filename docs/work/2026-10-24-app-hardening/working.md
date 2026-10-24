# Công việc: App hardening (blueprint batch C)

- Work ID: 2026-10-24-app-hardening
- Yêu cầu / outcome: đóng lô blueprint C (BASE-ERR-002, UX-VISUAL-001, UX-STATE-008, XC-PERF-006, XC-UNITS-009, nhóm a11y, PRF-MOB-004/005, XC-PERF-004) trên app Flutter
- Trạng thái: Active
- Chủ trì / writer: subagent lô C của phiên chính, chỉ ghi trong worktree `/home/user/xs-c`
- Mức rủi ro / số PR: M; commit cục bộ trên `local/backlog-c`, phiên chính quyết định PR
- Scope / non-goal: không thêm dependency, không đổi schema, không build iOS, không sửa BLUEPRINT/PROGRESS/.github/.claude
- Spec / goal / issue: `docs/specs/2026-10-24-app-hardening.md` (Approved, viết trước mọi sửa source)
- Nhánh / base SHA / thời điểm reconcile: `local/backlog-c` @ `edbdc50` · 2026-10-24T03:26:19Z

## Kế hoạch và phân công

Một nhánh cục bộ `local/backlog-c`, commit theo từng mục; phiên chính review, chọn PR/merge. Không subagent con.

## Quyết định và bằng chứng

Spec `docs/specs/2026-10-24-app-hardening.md` viết trước khi sửa source (State Approved theo ủy quyền §3d).
Mỗi mục: test viết trước, chạy đỏ bằng assertion (không phải lỗi biên dịch), rồi sửa, rồi xanh. Lệnh đều là
`flutter test <file>` trong `apps/mobile` trên base `edbdc50`.

| Mục | Quyết định | RED (đã thấy) | GREEN (đã thấy) |
| --- | --- | --- | --- |
| BASE-ERR-002 | `installErrorHandlers`: release chỉ ghi `X-Scanner: unhandled error (<Type>)`, không message/stack (có thể chứa đường dẫn/tiêu đề); `PlatformDispatcher.onError` trả `true`; `ErrorWidget.builder` release hiện câu chung; debug giữ `FlutterError.presentError` | stub rỗng: 5/5 fail (`Expected: an object with length of <1> Actual: []`, `Null check operator` vì handler chưa đặt, `found 0 widgets` câu chung) | `error_handling_test.dart` +5 All tests passed |
| UX-VISUAL-001 | Bọc mọi builder mặc định của `PageTransitionsTheme`; `MediaQuery.disableAnimations` thì trả trang không chuyển động. Bottom sheet xuất `AnimationStyle.noAnimation`. Không dùng `accessibleNavigation` (đó là trình đọc màn hình, không phải ưu tiên chuyển động). Hạn chế: khi giảm chuyển động, trên iOS mất cử chỉ vuốt lui của Cupertino builder; nút Back vẫn còn | `reduced_motion_test` 2 fail: `Expected Rect(0,0,128.3,20) Actual Rect(196.8,0,325,20)`; sheet: `Expected Rect(...552.2...) Actual (...276...)` | 3/3 pass; `review_screen_test` +40 pass |
| UX-STATE-008 | Dialog có tiêu đề câu hỏi + nội dung hậu quả ("…ảnh gốc của nó sẽ bị xoá khỏi tài liệu. Không hoàn tác được."), đúng vì `DocumentStore.save` xoá bản gốc không còn tham chiếu. Esc/Back đã huỷ sẵn (Flutter), nay có test; dialog chụp lại giữ câu cũ | 2 fail: `Found 0 widgets with text "Trang này và ảnh gốc…"`, `"Mọi trang và ảnh gốc…"` | pass, test cũ giữ nguyên kỳ vọng |
| XC-PERF-006 | `maxManifestBytes` 4 MiB, `readManifestBytes` đọc qua `openRead(0, cap+1)`. Vượt trần: `load` ném `FileSystemException` (không ready, không đổi tên/cách ly/xoá; save từ chối), `list` → `LibraryUnreadable`, migration → `MigrationSourceUnreadable` (giữ `session/`, app không bị khoá ở trạng thái lỗi). `save` từ chối manifest vượt trần để không tự tạo tài liệu không đọc được. Dấu `DEBT:` về việc chưa có trần số trang. Fake `_FailingManifest`/`_CountingFile` thêm `openRead` (cố ý) | load: `Expected: throws FileSystemException Actual: Future<DocumentLoadResult>`; list: entry sai loại (`Expected 'a473…' Actual '6971…'`); migration: `Expected MigrationSourceUnreadable Actual MigrationDone`; save: `threw StateError: original of a page is missing` thay vì `too large` | `document_store_test` +38, `library_store_test` +18, `p1_migration_test` +42 All passed |
| XC-UNITS-009 | Đổi tên cơ học `_thumbSide`→`_thumbSideDp`, `_handleSize/_handleDot/_margin/_loupeDiameter/_loupeGap`→`…Dp`, biến cục bộ `px`→`sidePx`. Hậu tố `Dp` (pixel logic) thay vì `Px` để không nhầm với pixel vật lý `sidePx = dp × devicePixelRatio`. Ngoại lệ TDD số 2 (đổi tên cơ học) | n-a | test cũ của hai màn xanh |
| UX-A11Y-001/002/003, UX-DS-003, UX-RESP-001, STD-A11Y-002 | `theme_contrast_test`: 19 cặp `ColorScheme` app vẽ (chữ ≥4.5, viền/icon/focus ≥3) ở Dark/Light, công thức kiểm bằng giá trị chuẩn (21:1, #767676 = 4.54). `outlineVariant` (viền thẻ) coi là trang trí. `keyboard_test`: thư viện và màn tài liệu chỉ bằng Tab/Enter/Esc. Thư viện 320 dp × chữ 200 %: phát hiện lỗi thật, nhãn nút "Tài liệu mới" tràn trái màn (`left -10.6`, rồi `-16` khi đo cả nút); sửa: đo nhãn bằng `TextPainter`, không vừa thì chỉ hiện icon, `tooltip` giữ tên | contrast/keyboard: xanh ngay lần đầu (kiểm token hiện có, không phải logic mới); 320 dp: `Expected >= 0 Actual -16.0` | `library_screen_test`, `keyboard_test`, `accessibility_test` +29 All passed |
| PRF-MOB-004/005 | `PrivacyInfo.xcprivacy`: không tracking, không thu dữ liệu, chỉ `FileTimestamp` `C617.1` vì `P1Migration` gọi `lastModified()` trong container; không khai DiskSpace (`AndroidStorage` chỉ Android). Plugin tự mang manifest riêng. Thêm file vào Resources của target Runner trong `project.pbxproj` (sửa tay, ID mới, cân ngoặc 80/80). Usage string camera/ảnh tiếng Việt khớp `requestFullMetadata: false`. Ngoại lệ TDD số 3 (config thuần); test chốt chặn | n-a | `python3 -I plistlib` parse OK cả hai file; `ios_declarations_test` 3/3 pass. **Chưa build iOS**, chưa kiểm Xcode mở project |
| XC-PERF-004 | Lệnh `summarize <jsonl>`: số mẫu + min/p50/p95/p99/max nearest-rank, file ≤16 MiB, từ chối mẫu trộn/hỏng bằng lỗi chung. Chưa có histogram | 10 fail `Expected <0|1> Actual <2>` (usage) | `scanner_benchmark_test` +57 All passed |

Không triển khai (quyết định): NFC (`BASE-DATA-002`, `UX-CONTENT-002`, `XC-I18N-005`) cần bảng Unicode = dependency
mới, app không tìm/so sánh tiêu đề; i18n (`XC-I18N-001/003/009`) app chỉ tiếng Việt theo spec; `UX-DS-006` cần thiết bị.

## Lần thử / blocker

- Lần chạy RED đầu của `error_handling_test` treo 10 phút: test widget khôi phục `FlutterError.onError` về giá trị chụp ở `setUp` (trước khi binding cài handler riêng). Sửa: test widget tự lưu/khôi phục trong thân, các test thường nằm trong group có setUp riêng.
- Test "save vượt trần" bản đầu mã hoá lại cả tài liệu sau mỗi trang (bậc hai), chạy quá trần 15 phút; sửa thêm trang theo lô 1000.

## Bàn giao / bước tiếp theo

<Một hành động cụ thể, file/lệnh cần đọc/chạy; thay đổi chưa commit và nơi giữ;
điều kiện có thể tiếp tục. Cập nhật trước nén/chuyển phiên/giao việc.>

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
