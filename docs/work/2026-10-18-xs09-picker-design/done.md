# Công việc: XS09 — pending picker preservation design

- Work ID: 2026-10-18-xs09-picker-design
- Yêu cầu / outcome: đề xuất API nhỏ nhất giữ kết quả picker đúng tài liệu và giữ ảnh trước decode, phục vụ XS09 PR-4b đã được chủ repo duyệt.
- Trạng thái: Design checkpoint; **chưa được root duyệt contract/PLAN để sửa source**.
- Chủ trì / writer: `/root/picker_contract`; root quyết định contract, nghiệm thu, gate và quyền merge.
- Mức rủi ro / số PR: leaf mức M trong outcome L PR-4b; đề nghị một PR lưu pending, sau đó PR tích hợp app phụ thuộc leaf này.
- Scope / non-goal: chỉ thiết kế journal/copy và contract bên gọi; không source, test, spec, PLAN, compiler, gate, commit, push, merge hay subagent. Không plugin fork, database, framework task, upload, xoá tài liệu hoặc rollback.
- Spec / goal / issue: `docs/specs/2026-10-12-document-library-migration.md` AC-13; `docs/work/2026-10-18-xs09-picker-preservation/working.md`; quyền trực tiếp của chủ repo 18/10: “Duyệt PR-4b; P1 chưa phân phối”.
- Nhánh / base SHA / thời điểm reconcile: `codex/xs09-picker-preservation` @ `c50670a` · 2026-10-18T02:03:17Z

## Kế hoạch và phân công

Checkout riêng `/home/liend/.local/share/x-scanner/xs09-picker-preservation`, branch `codex/xs09-picker-preservation`, base thật `c50670af18b1f11af38d15051b36264e1a051cb3`. Worker chỉ ghi file này. Root đang giữ spec và hồ sơ preservation trong cùng checkout; không ghi hai file đó. Placeholder trong hồ sơ này do lượt worker trước bị ngắt để lại, không phải bằng chứng thiết kế/test đã hoàn thành.

Đọc `CLAUDE.md`, `PROJECT.md`, `PROGRESS.md`, standard-delivery, research 11/10, TRAPS, spec migration, các store/controller/source thật và mã plugin đã cài. Không chạy Flutter/Gradle/test để giữ cửa sổ CPU của root/UAT. Những test bên dưới là kế hoạch, **chưa chạy RED hoặc GREEN**.

## Quyết định và bằng chứng

### Dữ kiện từ call chain

- `apps/mobile/lib/ui/page_source.dart:86` trả `null` cho cả empty response, response.exception và PlatformException. `_pick` cũng biến lỗi nền tảng thành cancel. Contract mới phải phân biệt lỗi với cancel trước khi cho xoá intent.
- `apps/mobile/lib/ui/session_controller.dart:198` retrieveLost toàn cục mỗi restore. Dùng cách này cho màn tài liệu B có thể gắn ảnh của A vào B. `_addFromPath` tạo pageId sau decode nên chưa có id replay ổn định; chỉ giữ cache OS khi decode/save thất bại, chưa có bản pending riêng của app.
- `apps/mobile/lib/storage/document_store.dart` cleanup originals không còn được manifest tham chiếu sau load thành công. Vì vậy pending original phải nằm ngoài `documents/*`, và retry import phải reload trước khi import lại, không giả định original mồ côi vẫn còn.
- `LibraryStore.open(id)` đã cache một DocumentStore/id. Dùng instance chung, không tạo store mới trong pending leaf. `DocumentUnrecoverable` có thể khiến save về sau được phép ở lớp store, nên controller phải tự giữ trạng thái không ghi được khi owner thiếu/hỏng/newer.
- `P1Migration.run()` trả `MigrationDone(docId)` là đích legacy đã biết; `MigrationNotNeeded` cũng có thể là camera P1 đầu tiên chưa từng lưu session.json. Không suy ra ảnh legacy thuộc một tài liệu đang có bất kỳ.
- Đã tìm package thực từ `w104b-decoder/apps/mobile/.dart_tool/package_config.json`: `image_picker_android 0.8.13+25`, không đoán API từ trí nhớ.
- `ImagePickerDelegate.java:261–289` đọc cache, resize nếu cần, rồi `cache.clear()` trước return; `:950–965` clear cache ngay khi picker mới được mở. `ImagePickerCache.clear()` dùng SharedPreferences.apply(), không phải transactional handoff cùng file Dart. Plugin Dart `getLostData():338–361` nhận cả files nhưng single-file getter là phần tử cuối; app hiện chỉ gọi single image. Không lấy kết quả một picker khác làm ảnh của owner mới.

### Đối chiếu nguồn ngoài

| Đã có và sâu hơn | Đã có nhưng nông hơn | Chưa có / điều kiện nhận |
| --- | --- | --- |
| ID/extension/original-path validators; queue, atomic manifest, .part/flush/rename; giữ source tới manifest; cache discard guard; migration fault tests | P1 giữ cache khi lỗi nhưng không có owner hay stable pageId và không sống qua OS cache eviction | Pending intent trước mọi camera/gallery/retake; sự cố có thật trong luồng reachable khi bật library: retrieveLost của A chạy từ restore của B |
| Mã plugin thật là dữ kiện về vòng đời, không chỉ thị | PageSource xoá khác biệt lỗi/cancel; cần đúng một exception đóng, không log platform payload | Không lấy kiến trúc/db/native fork từ plugin. Cửa sổ destructive-read→Dart persist còn nợ rõ, không tuyên bố exactly-once |

### API leaf được đề nghị, root chưa phê duyệt

Một lớp giá trị immutable, một queue và sáu thao tác. Không cần coordinator, enum trạng thái ghi đĩa riêng hoặc dependency mới.

```dart
final class PendingPick {
  String get docId;                 // 32 lowercase hex, immutable
  String get pageId;                // stable destination + operation token
  String? get replacePageId;        // retake only, valid and != pageId
  bool get createOwner;             // bootstrap-only reservation; default false
  String? get cacheRelativePath;    // canonical validated path below cacheDir
  String? get extension;            // same fallback/validator as existing P1
}

class PendingPickStore {
  PendingPickStore({
    required Directory dir,        // support/pending_pick, outside documents
    required Directory cacheDir,
    required int maxBytes,         // root passes 64 MiB; storage imports no imaging
  });
  Future<PendingPick?> load();
  Future<PendingPick> begin({
    required String docId,
    required String pageId,
    String? replacePageId,
    bool createOwner = false,
  });
  Future<PendingPick> remember(PendingPick pick, String resultPath);
  Future<File> stage(PendingPick pick);
  Future<void> cancel(PendingPick pick);
  Future<void> complete(PendingPick pick);
}
```

`PendingPick` có constructor private; chỉ store tạo từ begin/load/remember. Caller không ghi path journal hoặc sửa owner. Mỗi mutation đọc trạng thái hiện tại trong queue và đối chiếu tuple `(docId,pageId,replacePageId,createOwner)`; pageId đóng vai token, callback/route cũ không được clear intent mới. begin từ chối khi đã có intent, partial hoặc trạng thái không biết. Không tái sử dụng token. `createOwner` đúng chỉ cho bootstrap legacy, không retake; caller bình thường không được tạo owner thiếu bằng flag này.

Journal version1 duy nhất `intent.json`, ghi `intent.json.tmp`→flush→rename; giới hạn đọc đề nghị 8 KiB, path relative tối đa 2048 ký tự. Fields đúng kiểu, IDs dùng helper cũ; cache path và extension cùng có/cùng vắng. Không nhận đường dẫn tuyệt đối, `.`/`..`, segment rỗng, backslash, NUL hoặc đường cache sibling-prefix. Không chứa title/nội dung ảnh. Thiếu version/field, version tương lai, JSON/UTF-8 sai, journal/link, orphan part/temp hoặc cây pending không hiểu: giữ nguyên và lỗi đóng; không đoán hoặc “sửa” bằng xoá. `load()==null` chỉ khi thật sự không có pending state.

`remember` resolve cache root và resultPath, chỉ nhận regular file strictly inside canonical cacheDir. Lưu **relative** path đã kiểm và extension ngay sau khi nhận OS result, trước đọc/decode/copy. Result đã nhớ không được đổi sang path khác; gọi lại cùng path là idempotent. Trên retry phải resolve và kiểm containment/type lại, không tin journal hoặc symlink đã đổi. Không stat/đọc/copy file nằm ngoài cache trước khi boundary đã đạt. Extension dùng hành vi P1: lowercase hợp lệ, fallback jpg; không coi extension là bằng chứng định dạng ảnh.

`stage` không retrieveLost và không mở picker. Đọc file nguồn bằng stream/chunk hữu hạn, kiểm `0 < size <= maxBytes` trước copy và tổng byte trong lúc copy (file tăng cũng không vượt cap), ghi duy nhất `original.{extension}.part`, flush rồi rename `original.{extension}`. Không dùng readAsBytes cho toàn bộ nguồn, không file.copy vô hạn rồi mới kiểm. Chỉ trả file cố định thuộc dir. Partial hoặc output symlink/không rõ nguồn thì fail closed, không ghi xuyên link. Nếu crash sau rename, lần sau dùng lại original đã có, không gọi native destructive-read lần nữa. Nếu crash khi còn part, giữ part; chỉ restage từ cache còn nguyên sau kiểm source hợp lệ, không bỏ bản duy nhất còn lại. Bounded copy và exact synthetic-byte tests không phải bằng chứng chống power loss/fs corruption tuyệt đối.

`cancel` chỉ xoá empty intent mà caller vừa tạo trong lượt fresh picker/probe và nhận kết quả null không lỗi; leaf kiểm hiện tại chưa có remembered result/staged/partial. **Không** gọi cancel cho intent đã load lại rồi retrieveLost trả null hoặc error. Không cần public boolean “force cancel” hoặc API xoá dữ liệu pending. Lỗi platform trả exception đóng (`const PageSourceFailure()` là đủ), giữ intent; không đưa message/code/path của plugin ra UI/log.

`complete` là acknowledgement của caller sau manifest bền: leaf không nhận DocumentStore, không tự suy ra file đích tồn tại nghĩa là save thành công. Caller phải load/đã save manifest và xác nhận pageId + canonical original path đúng, byte khớp pending nếu đang replay. Thứ tự: manifest durable → discard cached source (best effort) khi pending copy còn → complete xoá staged/partial đã biết → xoá journal cuối. Nếu cleanup không xong, giữ journal và báo lỗi đóng; replay từ manifest đã commit chỉ cleanup, không thêm trang. Có thể xoá tmp/part **đã biết của intent** sau durable manifest, không scan/xoá unknown file hoặc original của tài liệu.

### Contract tích hợp tối thiểu

1. App sở hữu một PageSource, một PendingPickStore, một LibraryStore và DecodeGate chung. Chỉ một luồng pending hoạt động; reserve thành công trước camera, gallery **và** retake. Route/controller của docB không được global retrieveLost khi marker thuộc docA. Startup chỉ mở/recover docA đã định danh và đọc được; owner hỏng/newer/thiếu không bị thay bằng empty writable document.
2. Fresh capture: begin với stable new pageId → await picker → null không lỗi thì cancel; path thì remember → stage → decode pending file → import bằng stable pageId → save manifest → cleanup/complete. Save/decode/import thất bại giữ cache, pending original và marker; không phát picker mới. Dispose khi OS result đang về vẫn phải remember/stage result trước khi ngừng công việc UI; route không được biến dispose thành bỏ ảnh.
3. Recover: load owner manifest **trước import lại**; nếu manifest đã chứa stable pageId đúng canonical path và bytes khớp thì cleanup/complete, không decode/import/append lần hai. Nếu chưa có stable id thì stage/decode/import/save; retake chỉ thay đúng replacePageId còn hiện hữu. Stable id xung đột bytes, retake target mất hoặc owner không usable → giữ mọi dữ liệu, notice + Retry, không append/overwrite âm thầm.
4. Khi intent của owner còn unresolved, chặn mọi mutation của chính owner để retake target không thay đổi; chặn picker của toàn app vì plugin chỉ có một cache. Có thể đọc/export tài liệu khác; xử lý route/busy/dispose và cleanup export một lần startup là PR tích hợp riêng. Không cung cấp “xoá pending” tạm để né recovery (XS10 mới bàn UI/retention).

### Bootstrap ảnh P1 chưa có owner: khuyến nghị một flag, không target tuỳ ý

Khuyến nghị `createOwner` cho **reservation dành riêng bootstrap**, giữ docId immutable; ít hơn một kiểu journal unassigned, API assign-owner và phase giao quyền thứ hai. Không dùng flag này như quyền sửa owner hỏng. Quy trình:

- Chạy migration trước. MigrationFailed(io/space) chặn bootstrap/new picker và giữ mọi state, Retry như policy hiện có.
- Nếu đã có pending: tuyệt đối ưu tiên marker đó, không tạo probe khác. `createOwner=false` mà owner thiếu/hỏng/newer thì giữ và chặn, không sửa tự động.
- Nếu chưa có pending: trước một lần retrieveLost tại app startup, reserve stable pageId. `MigrationDone(docId)` dùng docId đó và `createOwner=false` (giữ cách P1 append ảnh bị mất). `MigrationNotNeeded` hoặc `MigrationSourceUnreadable` dùng docId mới, `createOwner=true`, không đổi session hỏng/rollback.
- Probe vừa reserve trong cùng call stack trả null không lỗi và không nhớ file nào: cancel empty intent, chưa tạo document nên fresh install không sinh tài liệu rỗng. Nếu crash rồi marker được load lại, null/error là ambiguous: giữ và chặn; không áp quy tắc fresh probe cho replay.
- Có path: remember/stage trước khi tạo document. Với `createOwner=true`, chỉ tạo **đúng** docId dành riêng sau khi pending original đã có. Crash giữa stage/create vẫn có flag + id để resume create. Nếu folder đã có từ lần trước thì chỉ tiếp tục khi document đọc được và rỗng hoặc đã chứa đúng stable pageId; unexpected pages/needs-update/corrupt thì fail closed. Không ghi đè folder collision. Dùng title mặc định hiện có, không thêm tên từ nội dung ảnh; không thay đổi bản P1 hỏng.
- Không cần thêm file đánh dấu “đã bootstrap” hoặc persisted provider state: một probe khi không có pending ở startup, trước UI/new picker; nil fresh probe chỉ tốn journal nhỏ, tránh thêm một cơ chế lifecycle. Root cần chốt rõ fresh retrieveLost empty có được coi empty probe hay bảo thủ giữ intent; nếu chọn giữ cho cả fresh empty thì phải có cách phân biệt fresh install để không khoá app ngay từ đầu.

Không chọn chỉ dựa vào `DocumentStore.load()==Unrecoverable(null)` để tạo owner: trạng thái đó cũng là tài liệu thật đã mất manifest. Không chọn attach vào tài liệu mới nhất/đang mở. Không chọn read native trước rồi mới tạo identity: kéo dài cửa sổ mất liên kết và không có replay target. Không chọn docId nullable: cần phase assign, journaling trước/sau assign và recovery collision, nhiều surface hơn một bootstrap flag.

### Test RED/fault plan trước source logic

Scaffolding chữ ký có thể thêm theo ngoại lệ đóng; test phải compile và fail expectation thật trước production logic. Chạy từng nhóm finite, record output đầy đủ; chưa có output ở lượt design này.

| Nhóm | Ca phải quan sát RED trước | Bằng chứng GREEN sau |
| --- | --- | --- |
| Identity | begin roundtrip doc/page/retake, reserve trước callback source; second begin/stale mutation từ chối | reload từ instance mới giữ cùng token; B không gọi retrieveLost/capture/discard của A |
| Journal boundary | bad IDs, equal retake/new id, invalid bool/type/version, non-UTF8/oversize/links/orphan temp | lỗi đã sanitize, exact bytes/tree không đổi, không auto cleanup |
| Path | outside/sibling/cache-root/.., absolute injected relative, symlink result/ancestor thoát cache, symlink output/temp | ngoài cache không bị đọc/ghi/xoá; valid camera root và gallery uuid subdir copy đúng bytes |
| Copy budget | maxBytes 4 với file4 pass/file5 fail; empty fail; source tăng sau length check fail; paused read chứng minh bounded chunk | pending .part không vượt cap; file nguồn giữ nguyên; staged bytes bằng nguồn tổng hợp nhỏ |
| Durable stages | failure trước/sau journal write/flush/rename, copy write/flush/rename, final cleanup | fresh instance replay ra một pending owner; state không biết giữ; không mất source + pending trước manifest |
| Source outcome | fresh null cancel; PlatformException và LostDataResponse.exception khác null; recovered null không cancel | no new picker khi unresolved; error không expose payload; no discard trên decode/save failure |
| Commit replay | save thành công rồi crash trước complete; import orphan rồi crash trước save; retake apply rồi crash | manifest chỉ có một stable pageId, old original chỉ mất sau save; retry reload trước import |
| Bootstrap | MigrationDone A; không manifest; unreadable P1; fresh empty; crash stage/create; create-owner existing newer/corrupt | đúng migrated A hoặc đúng reserved fresh id; không gắn B; raw legacy/rollback giữ byte; không tạo empty doc trên fresh null |

Fault harness lấy mẫu IOOverrides sẵn trong `p1_migration_test.dart`/`document_store_test.dart`; không thêm public production fault hook hoặc dependency. Kill giả bằng Error không phải FileSystemException để không chạy cleanup, sau đó dựng store mới. Fault sau manifest commit ở test integration cần xác nhận actual manifest + byte, không chỉ đếm callback. Không chạm real scans/OCR. Không fixture lớn/RSS threshold/performance claim.

### Giới hạn cần ghi ngay tại chỗ khi triển khai

`DEBT: plugin clears lost-result preferences before Dart can journal the returned path | trần: a crash between native clear and durable remember can leave an unassigned cache original | xem lại khi: a device test reproduces this handoff loss or before distributed release requires transactional picker recovery.`

Intent owner được giữ và blocker bảo thủ bảo vệ không gắn sai; nó không tự khôi phục đường dẫn chưa từng được Dart nhận/lưu. OS có thể tự thu hồi cache trước stage; disk flush+rename không hứa mọi power-loss/filesystem. Leaf chỉ đảm bảo retry từ các mốc bền quan sát được, không exactly-once tại mọi instruction, không phải camera/UAT/device evidence.

## Lần thử / blocker

Không chạy test/compiler/gate và không đổi runtime. Một lệnh cat ban đầu dùng sai đường `lib/platform/page_source.dart` báo không tồn tại; đã tìm bằng rg và đọc đúng `lib/ui/page_source.dart`, không suy ra API từ lỗi đó. Không có failure behavior được tính RED.

Root cần duyệt hoặc giản lược API/flag và fresh legacy probe empty rule trong spec/PLAN trước source. Nếu root muốn defer bootstrap auto-create, phương án an toàn còn lại là unassigned preservation fail closed; không thay bằng attach đại một document.

## Bàn giao / bước tiếp theo

Root đọc thiết kế này, chốt contract trong spec/PLAN và giao riêng source/test ownership; giữ nguyên freeze cho design record. Worker chỉ ghi file này, chưa commit, không sửa spec/root record đang thuộc root. Tiếp source chỉ sau phê duyệt cụ thể; mọi test/gate/PR/merge phải có chứng cứ mới trên head thật.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

Chưa nghiệm thu sản phẩm, chưa PR/gate/merge. Giữ `working.md`; design-only delivery không được gọi là pending preservation đã hoạt động.
