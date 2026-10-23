# Công việc: XS-09 PR-4b — design tích hợp và dung lượng Android

- Work ID: 2026-10-18-xs09-pr4b-design
- Yêu cầu / outcome: root giao research/design PR-4b sau lời duyệt trực tiếp chủ repo18Oct “Duyệt PR-4b; P1 chưa phân phối”, ghi ở hồ sơ root. Chốt reuse/lifecycle/capacity/picker ownership để root duyệt spec/PLAN trước code.
- Trạng thái: Ready — thiết kế tĩnh bàn giao, chưa source/test/compiler/gate.
- Chủ trì / writer: worker w104b_research, chỉ ghi hồ sơ này; root giữ authority/spec/PLAN/gates và mọi quyết định cuối.
- Mức rủi ro / số PR: L ở outcome tích hợp dữ liệu; một unit thiết kế cho PR-4b, không tự mở PR.
- Scope / non-goal: đọc app/library/store/migration và official platform API; đề xuất contract/tests/phạm vi ghi. Không sửa production/tests/spec/plan/dep, không compiler/gate/commit/push/merge hoặc subagent; không dữ liệu thật/OCR.
- Spec / goal / issue: docs/specs/2026-10-12-document-library-migration.md; ADR-0011; docs/work/2026-10-18-xs09-pr4b-integration/working.md; prior PR1..3/4a done; execution chờ actual W104b merge/fresh main.
- Nhánh / base SHA / thời điểm reconcile: `codex/xs09-pr4b` @ `314a296` · 2026-10-18T01:28:30Z

## Kế hoạch và phân công

1. Đọc CLAUDE/PROJECT/PROGRESS, full XS09 spec/ADR, PR1..3 và4a done, authority record root; tạo hồ sơ trước thiết kế.
2. Lần code thật: main → SessionController/ReviewScreen → SessionStore, đối chiếu DocumentStore/LibraryStore/P1Migration/LibraryController/LibraryScreen và tests hiện có.
3. Kiểm Stdlib Android StatFs/Flutter MethodChannel bằng official docs; kiểm installed picker/path-provider code cho ownership phục hồi.
4. Bàn giao contract hữu hạn, tests-only RED cần chạy thật và giới hạn. Root duyệt spec/PLAN rồi mới giao implementation trên base mới; worker này dừng ở thiết kế.

## Quyết định và bằng chứng

- Giữ brownfield Flutter/store/library có sẵn, không database/framework/dependency mới · loại xây lại · đúng/bảo toàn dữ liệu rồi ít code.
- Giữ LibraryStore app-lifetime vì nó đã cache đúng một DocumentStore mỗi docId; không tạo DocumentStore độc lập cho mỗi route · loại nhiều queue/_saved trên cùng folder · đúng + không mất dữ liệu.
- Root chốt qua message: **giữ policy journal hỏng = MigrationFailed(io), thư viện đóng + Thử lại**, không mở ghi mới khi journal mơ hồ; giới hạn cố ý tới XS10. Worker ban đầu nêu handoff PR3 có câu khác, sau đối chiếu root chọn giữ intentional policy/code/test hiện tại. Không đề xuất outcome mới trong PR4b.

## Lần thử / blocker

- Không chạy test; không có RED/GREEN hoặc gate claim. Dependency base chưa reconcile với W104b ở checkout thiết kế314a296; execution phải chờ root.
- Một số read output kết hợp bị cắt; đã đọc lại riêng full spec§12–Approval và priorPR1..3 record, không coi output bị cắt là đọc đủ.

## Bàn giao / bước tiếp theo

- Root chốt spec/PLAN hữu hạn từ contract dưới, đặc biệt pending picker và lifecycle; giao tests-only trước production logic trên actual main sau W104b. Chỉ ownrecord chưa commit.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Chưa Done: thiết kế là evidence tĩnh, không nghiệm thu app/migration/UAT hoặc PR-4b. Root giữ hồ sơ working tới khi chốt thật.

## Hợp đồng tích hợp tối giản đề xuất

### Ownership và khởi động

- `main.dart` lấy support/temp rồi tạo **một** LibraryStore(documents), P1Migration, DecodeGate, PageSource và exporter/sharer cho app lifetime. Không tạo `session/` mới nữa; không chạy SessionStore.load trước migration (nó có thể cách ly P1, trái FR6).
- Tái dùng LibraryController.migrate callback và queue start/refresh; chỉ một entrypoint gọi migration, không gọi song song từ main và LibraryScreen. Retry phải gọi run mới sau failure, không memoize một Future failed vĩnh viễn.
- XScannerApp đổi từ một SessionController toàn app sang LibraryController + document builder/factory; giữ cách tiêm của PR4a cho widget tests. LibraryScreen đã có startup/loading/retry/empty/list/rename/new và refresh khi route đóng.
- Mỗi route tài liệu có một Stateful owner tạo controller đúng một lần, gọi restore đúng một lần, rồi dispose đúng một lần. Store lấy từ LibraryController.storeOf/LibraryStore.open; không dispose shared app store/gate khi đóng route.
- Cleanup exports/share_plus **một lần khi app khởi động**, trước khi có share mới; không chạy clearLeftovers ở mỗi document.restore. Không dọn toàn cache picker hoặc pending originals. Mỗi export vẫn dọn exportDir sau khi share Future kết thúc.

### Controller và màn tài liệu

- Thay SessionStore bằng DocumentStore, giữ tên SessionController nếu đổi tên không có lợi. Khuyến nghị một ScanDocument canonical state; dùng ScanSession transient cho added/moved/replaced/removed để tái dùng kiểm unique/order. Không cần generic ManifestStore/adapter hoặc copy logic store thứ ba.
- Restore lấy document thật từ store; chỉ DocumentLoaded được sửa. DocumentNeedsUpdate, DocumentUnrecoverable hoặc I/O không được âm thầm biến thành tài liệu rỗng ghi được. Tình huống listing còn readable nhưng file đổi/hỏng trước open phải được chặn ở route/controller, giữ originals và hiển thị thông báo đóng, không auto-recreate.
- Save đổi trang giữ id/title/createdAt, updatedAt UTC theo clock tiêm và không trước createdAt; chỉ adopt state sau save thành công. Lỗi save giữ cùng object/bytes; không discard picker source. ClearAll chỉ tác động doc hiện tại, không xoá document folder/rollback.
- Giữ DecodeGate chung qua thumbnail, cropped preview và exporter renderer. Cache id/revision thuộc controller tài liệu; không dùng cache toàn app key chỉ pageId.
- ReviewScreen title = tên document hiện tại, back về thư viện; `PopScope(canPop: !busy)` chặn system back/gesture và AppBar/semantics dùng maybePop, không gọi Navigator.pop thẳng khi bận. Share Future cũng giữ busy dù exportJob đã null; chỉ mở doc kế khi writes/share đã xong.
- Dispose cần chặn queued/new picker/export operations và tránh share sau dispose; current code chỉ cancel exportJob hiện tại nên operation còn xếp hàng có thể tiếp tục. Normal route không được pop khi busy; unit test vẫn kiểm forced dispose/completer để không có async action ngoài owner.
- Theme: LibraryScreen/ReviewScreen hiện nhận snapshot themeMode. Pushed route có thể giữ icon/tooltip cũ khi root đổi theme; derive icon từ Theme.of(context).brightness là ít state nhất, hoặc root phải rebuild owned route. Kiểm toggle trong route rồi quay về thư viện.

### Picker recovery thuộc đúng tài liệu (cần root ghi rõ trong spec)

Đường cũ `SessionController.restore → PageSource.retrieveLost` hợp lý khi chỉ có một P1 session. Khi mỗi document có controller, **không được gọi global retrieveLost ở mỗi restore**: doc B có thể nhận ảnh đang chờ của doc A.

- Installed `image_picker_android-0.8.13+25` `ImagePickerDelegate.java`261–289 đọc cache rồi clear trước khi trả kết quả;950–965 clear cache khi bắt đầu một picker mới. Vì vậy context phải bao phủ **camera, gallery và retake**, không riêng camera.
- Hợp đồng tối thiểu đề xuất: một file marker atomic nhỏ dưới support root, schema/version đóng; chứa validated docId, preallocated destination pageId và optional replacePageId; ghi thành công **trước** OS picker launch. Thất bại ghi marker → không launch picker, báo lỗi lưu đã sanitize.
- Khi có result, giữ path/ảnh tạm và owner durably trước xử lý; nếu root chọn staging riêng thì đặt ngoài document.originals để successful DocumentStore.load không coi pending copy là orphan. Không dọn pending bằng exporter.clearLeftovers.
- Startup xử lý pending trước khi cho launch picker mới: chỉ route/controller đúng owner đọc được mới có quyền nhận kết quả. Doc khác restore không consume plugin result. Owner missing/unreadable/newer hoặc marker invalid → giữ marker/file, thông báo ngắn + retry, không autoassign sang doc mới/ngẫu nhiên và không xoá nguồn.
- Destination pageId ổn định cho phép nhận ra save đã commit trước khi crash nhưng marker chưa clear: không thêm lần hai. Retake chỉ thay đúng replacePageId; target biến mất thì giữ pending, không tự đổi thành append. Chỉ clear pending/discard source sau manifest durable; cancel không có result được clear marker.
- Đây là contract cần chứng minh bằng fake/completer và disk state, chưa là code hoàn thiện. Public plugin retrieval là destructive read nên vẫn có cửa sổ handoff không atomic với app journal; không tuyên bố exactly-once ở mọi instruction hoặc camera process-death thực tế chỉ từ unit test. Cần ghi residual window rõ nếu chưa có evidence che đủ.

### Capacity adapter Android

- Reuse `Storage.freeBytes(Directory dir)` có sẵn, một leaf adapter `lib/storage/android_storage.dart` và MethodChannel nhỏ ở MainActivity.kt. Không Process shell, FFI/plugin mới hoặc quyền Android mới.
- Native đo `StatFs(path).availableBytes` (**available**, không freeBytes có reserved blocks). API từ18, app minSdk24 đủ. Chuỗi path/type phải được kiểm; lỗi trả static code/message, không path/exception.toString. Unknown method → notImplemented.
- Dart gọi channel với dir.path, nhận Object? rồi kiểm int>=0 (0 là giá trị thật, >32bit phải giữ nguyên). Null/double/string/negative và lỗi platform/missing plugin chuyển thành **FileSystemException đã sanitize, không path/title/details**; không giả unlimited hoặc 0 khi không đo được.
- Đã xác minh installed path_provider_android2.3.1 getApplicationSupportPath lấy applicationContext.filesDir; đây là cùng filesystem root mà migration copy tới. Không đo free space ở temp/external volume khác rồi coi là capacity support.
- Full Android build chứng minh Kotlin compile, mocked channel tests chứng minh Dart contract; chúng không chứng minh native channel được gọi thật. Synthetic emulator/device smoke cần riêng nếu muốn claim adapter runtime.

## Các ca RED và regression hữu hạn

Không ca nào đã chạy trong unit thiết kế này. Root/worker phải ghi actual logs, phân biệt behavior failure với compile/setup failure.

| Nhóm | Behavior cần chứng minh / baseline có thể RED |
| --- | --- |
| App shell | Từ current XScannerApp harness đang compile: expect home thư viện, không hiện editor P1 cố định; baseline thực hiện sai. API helper có thể đổi cơ học sau đó, assertion không hạ. Không dùng thiếu class/method làm RED |
| AC13 cross-document | Hai document có original khác byte; mở A, capture/import/reorder/crop/rotate/retake/export/clear, quay về; B manifest/original hashes giữ nguyên; relaunch A giữ recipe/revision/time, library count/order mới |
| Save/restore failures | DocumentStore fake/completer hiện có đổi từ FlakyStore; save fail giữ state identity/manifest/source; newer/corrupt giữa list→open không launch picker/ghi/cleanup originals |
| Busy route | Hold copy, picker result, render và share lần lượt; system back/AppBar/semantics không pop; release rồi pop đúng một route, library refresh sau durable write. Baseline ReviewScreen không PopScope nên navigation expectation RED |
| Dispose | Queue capture/export sau held operation rồi force dispose; không OS picker/share mới, không notify disposed, pending result/source giữ để owner recovery; exporter không bị doc B cleanup giữa share |
| Lost-data owner | Marker A + global FakeSource.lost; mở B không retrieve/discard/ghi; startup/relaunch đúng A nhận một lần. Gallery+retake, failure lưu marker không launch, process-like reconstruction từ disk, crash sau commit trước clear không duplicate |
| Pending unresolved | Owner missing/newer/corrupt, marker invalid, decode/copy/save fail: nguồn/marker còn; picker mới không clear pending của plugin; retry không đổi doc khác, không log path/title |
| Migration lifecycle | Reuse P1Migration + temp directories và existing fault seam, kiểm app startup k0/1/3, retry lowspace rồi đủ, sourcecorrupt notice, journalcorrupt vẫn closed+retry, relaunch nhiều lần một doc và rollback bytes nguyên. Không sao chép lại38 fault tests chỉ để tăng count |
| Capacity leaf | Mock handler nhận đúng method/path;0,5GiB pass; null/negative/wrongtype/PlatformException/MissingPluginException đều sanitizedFSE. Sau scaffolding có API mới, phải lấy behavioralRED khi wrongresponse/channelfailure, không compile failure |
| Theme/a11y | Dark/Light library+document; icon đổi đúng trong pushed route; text lớn/semantics vàbackbusy vẫn hoạt động; giữ existing a11y guidelines |

Fakes tái dùng: FakeSource, FakeSharer, HeldRenderer/FlakyStore trong session_controller_test (đổi backend có metadata), existing HeldStore/IOOverrides của document_store_test, LibraryScreen.documentScreen builder và LibraryController.migrate callback. Không thêm test injection vào core migration khi seam hiện tại đủ.

## Phạm vi file / contract cho root chia việc

- **Root writer:** spec XS09 Approval/AC13 clarification (authority18Oct), PLAN/goal/work/maps/TRAPS/PROGRESS, gate/CI/PR/reconcile; nghiệm thu mọi source.
- **Một implementation writer tuần tự** cho app/controller/review/library lifecycle + pending owner: main.dart, ui/session_controller.dart, review_screen.dart, library_screen.dart nếu cần, page_source.dart và pending marker leaf được root duyệt; tests app/ui liên quan. Chúng dùng chung giao diện nên không chia hai writer chạy song song thiếu contract.
- **Capacity leaf có thể writer riêng sau contract** nếu root muốn: android_storage.dart, MainActivity.kt, test/storage/android_storage_test.dart; thống nhất channel/method/value/error types trước. Không build/compiler song song với gate hoặc worker khác.
- **Xoá legacy store** chỉ sau chuyển hết callers/tests: session_store.dart và suite cũ tương ứng; DocumentStore tests đã có F001/F019, no-overwrite, quarantine, orphan cleanup. Map từng ca trước xoá; port ca còn thiếu, không bỏ vì count giảm. Giữ ScanSession cho pure page operations và schema1 codec cho migration.
- Spec§11 hiện nói rename session_manifest→document_manifest ở PR4. Đề xuất root giữ tên hiện có vì file vẫn chứa codec legacy+schema2, ít churn; nếu chọn vậy phải ghi deviation/update spec trước source. Không tự đổi ở unit này.

## Nguồn chính thức và read scope

Đã đọc full current code 8 file luồng/storage (~2801 dòng), main, PageSource/PageExporter, ScanDocument/ScanSession, tests helpers/guarantee names và lịch sử PR1..3/4a. Không dùng số test cũ làm bằng chứng execution.

- [Android StatFs](https://developer.android.com/reference/android/os/StatFs#getAvailableBytes()) — availableBytes và constructor error; kiểm sống18Oct.
- [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels) — configureFlutterEngine/MethodChannel handler.
- [StandardMessageCodec](https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html) — mapping Long/int, cần giữ >32bit.
- [PopScope](https://api.flutter.dev/flutter/widgets/PopScope-class.html) — canPop chặn back gesture/system navigation.
- [image_picker official package](https://pub.dev/packages/image_picker#handling-mainactivity-destruction) — startup retrieveLostData và ảnh camera ở cache tạm; cross-check installed Android delegate thay vì suy theo README.
- Local primary source: `/home/liend/.pub-cache/hosted/pub.dev/image_picker_android-0.8.13+25/android/src/main/java/io/flutter/plugins/imagepicker/ImagePickerDelegate.java`, cùng Dart image_picker_android.dart; path_provider_android2.3.1/lib/src/path_provider_android_real.dart.

Giới hạn: chưa update source theo W104b, chưa TDD/gate/native runtime/UAT; pending-owner exact interface/UI cần root duyệt trong cùng spec trước implementation. Không mở XS10/OCR/depth/release hay tự xoá rollback.
