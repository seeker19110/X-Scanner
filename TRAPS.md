# TRAPS.md — bẫy đã mắc trong repo này

> Sổ bẫy ĐÃ MẮC THẬT. Mỗi mục có ngày + PR + cách rà + test chốt chặn. Khác `docs/adr/`: ADR ghi quyết định;
> file này ghi lỗi đã xảy ra và khuôn của nó. Gặp triệu chứng lạ → tìm khuôn ở đây trước (`/debug` Pha 1).
> Sửa bug xong → thêm mục mới hoặc thêm ngày/PR vào mục cũ nếu tái phát.

**Widget test treo vô hạn khi trộn vùng fake-async và `runAsync` trên cùng hàng đợi.** Store/controller có
hàng đợi `Future` (`_tail`/`_writeTail`) tạo hoặc nối tiếp trong vùng fake-async của `testWidgets` chỉ chạy tiếp khi
`pump`; gọi nó từ `tester.runAsync` thì chờ mãi, `--timeout` cũng không cắt được (cả file chết theo trần ngoài).
Gặp ở XS-09 PR-4b.2: màn test gọi `restore()` lần hai dưới fake clock trên `PendingPickStore` dùng chung, và một
controller dựng trong thân test được `restore()` trong `runAsync`. *Cách rà*: mọi đối tượng có hàng đợi dùng trong
`runAsync` phải được dựng và gọi lần đầu ở vùng thật (setUp hoặc bên trong `runAsync`); không gọi cùng hàng đợi ở
cả hai vùng. *Chốt*: `apps/mobile/test/ui/document_test_app.dart` (`restore: false` khi test đã mở bằng I/O thật),
`review_screen_test.dart` `start()`. (2026-10-23, Work ID `2026-10-18-xs09-pr4b-integration`)

**Nội suy ánh xạ identity vẫn làm đổi pixel.** Full-frame13×9 RGBA Random17 đi qua
homography/bilinear làm16kênh giảm1LSB do sai số số thực và cắt về số nguyên. Test chỉ dùng ảnh
solid hoặc một kích thước có thể bỏ sót lỗi. *Cách rà*: so mọi byte của ảnh có
màu/alpha thay đổi ở kích thước lẻ, kể cả PNG xuất có xoay. *Chốt*: chỉ copy byte
vào output mới khi quad bằng fullFrame theo giá trị và dimensions sau normalize/cap
khớp source; quad gần toàn khung hoặc bị cap vẫn phải nội suy. Không dùng
`Image.from`: constructor đó mang metadata/frames mà output cũ không giữ.
Regression trong `apps/mobile/test/imaging/page_render_test.dart` kiểm exact pixels,
metadata, alias hai chiều, near-full/cap và mapping xoay độc lập.
(2026-10-17, Work ID `2026-10-17-xs07a-full-frame-render`)

**Fixture tên file POSIX làm test hỏng trên Windows trước khi gọi code cần kiểm.**
Test benchmark tạo directory có newline/backslash vô điều kiện. Win32 cấm control
characters và dùng backslash phân cách path; API Windows `Directory.CreateDirectory`
trả `ArgumentException` trước benchmark. *Chốt*: khai `testOn: '!windows'` riêng ca
filename POSIX bằng metadata test runner, giữ đủ 46 ca trên Linux và không tuyên bố
đã chạy native Windows Flutter gate. Nguồn: [Win32 naming rules](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file).
(2026-10-17, seeker19110/X-Scanner#54; `apps/mobile/test/tool/scanner_benchmark_test.dart`)

**Dọn "file không được tham chiếu" xoá bản gốc của phiên chưa đọc được.** Bước dọn của `SessionStore.load`
xoá mọi file trong `originals/` không có trong manifest hiện tại. Khi manifest cũ bị cách ly (hỏng) hoặc không
đọc được, "không được tham chiếu" không có nghĩa là "rác": đó là bản gốc duy nhất của phiên trước. Lỗi im lặng
vì app vẫn chạy bình thường, chỉ ảnh biến mất ở lần mở sau. *Cách rà*: mọi chỗ xoá trong `originals/` — hỏi
"manifest nào đang chứng minh file này là rác, và manifest đó đã thật sự được đọc xong chưa?". *Chốt chặn*:
`apps/mobile/test/storage/session_store_test.dart` `a later new session never deletes the quarantined originals`.
(2026-10-11, seeker19110/X-Scanner#7)

_Tái phát 2026-10-12_: `load` lỗi I/O (không phải manifest hỏng) không cách ly gì, `save` sau đó ghi đè manifest,
lần mở sau xoá bản gốc cũ (F-001, W-101). Bài học: "không được tham chiếu" chỉ đúng khi một manifest đã **load
xong** cùng store.

**Lấy mẫu pixel ngoài biên làm viền ảnh tối.** Nắn phối cảnh lấy mẫu song tuyến tại `p − 0,5`; ở mép ảnh
`getPixelLinear` đọc pixel −1 (đen) nên viền trang trắng thành xám (229 thay 255). *Cách rà*: test ảnh trắng
đồng nhất, kiểm pixel ở 4 mép đầu ra. *Chốt chặn*: `apps/mobile/test/imaging/page_render_test.dart`.
(2026-10-11, seeker19110/X-Scanner#8)

**Nhầm RGBA logic với storage gray-alpha hai kênh.** Trong image4.10.1,
`PixelUint8.g` của ảnh hai kênh trả gray nhưng `ImageDataUint8.setPixelRgba` ghi g
vào byte1 (alpha). Vì vậy nội suy hoặc `copyRotate` qua `setPixel` thay alpha bằng
gray. *Cách rà*: tạo fixture bằng byte thô, gray khác alpha, gồm0/partial/255;
kiểm crop/cap/skew và ma trận xoay tay, không dùng chính setter/transform làm expected.
*Chốt chặn*: regression XS-07b trong `apps/mobile/test/imaging/page_render_test.dart`.
Giữ hai kênh qua storage mapping và byte rotation. Chuyển RGBA riêng lúc xoay còn
đổi cách JPEG blend nền và thêm buffer lớn; đó không phải workaround tương đương.
(2026-10-17, Work ID `2026-10-17-xs07b-gray-alpha-render`; nợ có trướcPR55)
W104b18Oct: image4.12 đã sửa setter/copyRotate hai kênh; bỏ workaround sau khi21regression xanh trước/sau. Không đổi policyJPEG hoặc xoá test chỉ vì upstream sửa.

**Ảnh 16-bit bị cắt về 0 khi mã hoá.** Ảnh PNG 16-bit/kênh mã hoá thẳng sang JPEG 8-bit cho ảnh đen.
*Cách rà*: mọi đường mã hoá đầu ra phải chuẩn hoá về 8-bit/kênh trước. *Chốt chặn*: test ảnh 16-bit trong
`apps/mobile/test/imaging/page_render_test.dart`. (2026-10-11, seeker19110/X-Scanner#8)

**Plugin nền tảng để lại bản sao tài liệu trong cache của app.** `image_picker_android` ghi ảnh chụp vào cache
và chép ảnh chọn từ thư viện vào `cache/{uuid}/`; app chép sang `originals/` nhưng không xoá bản của plugin, nên
ảnh tài liệu còn trên máy sau khi người dùng xoá trang hoặc xoá tất cả (F-005). *Cách rà*: mỗi plugin trả về một
đường dẫn file — đọc mã nguồn plugin xem file đó nằm đâu và ai xoá nó. *Chốt chặn*:
`apps/mobile/test/ui/page_source_test.dart` và các test "(F-005)" trong `apps/mobile/test/ui/session_controller_test.dart`.
(2026-10-12, W-102)

**Thao tác theo chỉ số vẫn nhận được khi app bận.** Mọi nút tắt khi `busy` nhưng kéo-thả vẫn bật; `move(from, to)`
vào hàng đợi ghi sau các thao tác đang chờ và chạy với chỉ số cũ, nên chuyển nhầm trang (F-007). *Cách rà*: mỗi
cử chỉ/nút tạo một thao tác mang chỉ số hoặc id — nó có bị tắt cùng các nút khi bận không. **Tái phát (F-051):**
tắt tay kéo không tắt thao tác ngữ nghĩa Move up/down mà `ReorderableListView` gắn cho mỗi dòng; chúng gọi thẳng
`onReorderItem`. Chặn ở callback (`if (busy) return`), không chỉ ở widget nhập liệu. *Chốt chặn*: test "(F-007)" và
"(F-051)" trong `apps/mobile/test/ui/review_screen_test.dart`. (2026-10-12, W-103; W-502)

**Cache một `Future` lỗi.** `thumbnailFor` cache future theo id trang; một lần giải mã lỗi (file tạm thời không đọc
được) bị giữ mãi nên trang không chỉnh góc được tới khi mở lại app (F-020). *Cách rà*: mọi map cache `Future` —
nhánh lỗi có cho thử lại không. **Đính chính (F-047):** gỡ future lỗi khỏi map ngay khi lỗi làm MỌI lần dựng lại
widget giải mã lại bản gốc hỏng; giữ future lỗi trong cache, đánh dấu id lỗi (so `identical`) và chỉ gỡ khi người dùng
bấm thử lại (`retryThumbnail`). *Chốt chặn*: test "(F-020)"/"(F-047)" trong
`apps/mobile/test/ui/session_controller_test.dart` và `review_screen_test.dart`. (2026-10-12, W-402; W-502)

**So sánh ruleset thiếu mặc định phía GitHub báo drift giả.** Sau POST cấu hình XS-05, GitHub
trả thêm `required_reviewers: []` và `require_extra_approval_for_unattributed_changes: true`,
làm so sánh nguyên rule đỏ dù các giá trị đã yêu cầu khớp. *Cách rà*: đọc nguyên readback,
đối chiếu tài liệu chính thức trước khi bỏ qua field hoặc hạ rule; extra approval không tăng
count khi required approvals=0. *Chốt*: khai rõ mặc định đã kiểm trong `.github/rulesets/main.json`,
so JSON với readback thật và kiểm CI không đạt bị BLOCKED; không nuốt mọi field lạ.
(2026-10-16, Work ID `2026-10-16-xs05-repository-guards`; evidence trong hồ sơ)

**Truyền giới hạn decoder sau startDecode là quá muộn.** Từ image4.12, JPEG/PNG nhậnmaxPixels ởconstructor; WebP dùngproperty phải gántrướcparse. <=0 của thư viện nghĩa là unlimited, app phải từchối. Defaultstatic cóthểkhácappcap: testtạmdefault1/callercap6 choJPEG/PNG/WebP vàkhôiphụcfinally; khôngđổiglobal trongproduction. imageSizeOf phải giữnullable khi thư việnnémImageException doheadercap. *Chốt chặn*: `apps/mobile/test/imaging/decoder_security_test.dart`; fixtureEXIFbịkillhữuhạn vàPNGunusedtail~64KiB chỉkiểmconsumption, không phảiPNGconformance/RAMquota. (2026-10-18, W104b)


**Dung lượng không đo được không có nghĩa là 0 hoặc vô hạn.** Dùng StatFs.availableBytes trên đúng volume filesDir; không nhận arbitrary path qua channel. Dart chỉ nhận int>=0, giữ0 và >32bit; lỗi platform/missingplugin/badtype thành FileSystemException static với path:null tường minh (bỏ argument thì SDK mặc định chuỗi rỗng). JVM chỉ catch Exception của supplier, không nuốt lỗi callback hoặc Error. *Chốt*: android_storage_test.dart và StorageHandlerTest.kt chạy qua dispatcher; mock/JVM không chứng minh nativeAPI đã chạy trên thiết bị. (2026-10-18, XS09 capacity)


**Destructive picker recovery needs durable ownership before launching.** Installed image_picker clears lost-result preferences before Dart receives them and before a new picker. Per-document global retrieval can attach A's image to B, and replay with a fresh pageId duplicates a committed page. Reserve owner/stablepage before launch, journal cache-relative path and bounded stagedoriginal outside document orphan cleanup, retain unknown state; only durable commit permits cleanup. Rejected invalid images need retained parking so P1AC7 still permits a later capture. Size rejection must be distinguishable from I/O, which stays active for retry; never parse OS error text. *Chốt*: pending_pick_store_test.dart (identity/CAS/paths/caps/faults/retained rejection/classification). Leaf tests do not prove app integration or native-to-Dart exactly-once; residual handoff DEBT is required when connected. (2026-10-18, XS09 pending foundation)


**Dispose không tự dừng hàng đợi của ChangeNotifier.** Chặn bắt đầu operation trong `_enqueue` khi đã dispose; chỉ huỷ export đang chạy, không cắt ngang save đang bền hoá. Queued/new picker/share sau dispose phải không chạy. *Chốt*: `session_controller_test.dart` hai ca `disposed controller`; assertion RED trước guard, GREEN cùng toàn suite. (2026-10-23, scanner-experience)

**Huỷ ở final progress vẫn phải thắng PDF packaging.** Listener `pageDone` có thể yêu cầu huỷ sau trang cuối. Kiểm huỷ trước đóng gói, nếu không PDF không hợp lệ có thể trả writeFailed thay vì cancelled và làm việc thừa. *Chốt*: `page_exporter_test.dart` `final progress cancellation skips PDF packaging`, assertion RED→GREEN. (2026-10-23)

**Scaled JPEG vẫn phải kiểm raster gốc và giữ cả hai chiều mục tiêu.** Cap kiểm trước parse/decode; không coi raster thu nhỏ là quyền nhận ảnh vượt cap. Chọn scale theo cả hai cạnh, làm tròn cạnh lẻ và clamp cạnh ngắn ít nhất1px; bake đủ8EXIF. Raster gần vuông có thể làm tròn thành vuông và mất dấu trục: giảm scale đến khi phân biệt được, giữ tỷ lệ header và lấy hướng thực tế của decoder. Không dùng EXIF parser riêng để chọn hướng: utility lấy APP1 đầu, decoder có thể áp APP1 sau. *Chốt*: regressions near-square/duplicate-EXIF/imaging/security và host benchmark có source/binary hashes; không suy thumbnail lossy thành pixel-identical hoặc chất lượng export. (2026-10-23)
