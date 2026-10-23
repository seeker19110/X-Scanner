# Công việc: XS-09 PR-4b — nối thư viện và migration

- Work ID: 2026-10-18-xs09-pr4b-integration
- Yêu cầu / outcome: chủ repo18Oct trả lời trực tiếp “Duyệt PR-4b; P1 chưa phân phối” sau câu hỏi cụ thể về copy/kiểm từngbản gốc, giữ session.migrated và phục hồi khi bịngắt. Tích hợp thư viện/documentstore với app, hoàn tất XS09AC13 và capacityadapter; không hỏi lại quyền này.
- Trạng thái: PR-4b.2 implemented 23/10 trên `main` `4ce9a76` (sau #61, #57); gate/PR/merge đang chạy. Chưa Done.
- Chủ trì / writer: root giữ spec/approval/PLAN/docs/gates/PR/merge; worker riêng sau contract. Chỉđọc thiết kế trước sourceapproval.
- Mức rủi ro / số PR: L (migration dữ liệu thật), satu outcome/PR cuối của XS09 sauPR1..3/4a đãmerge; goal18Oct và XS09spec/ADR0011.
- Scope / non-goal: reuseLibraryStore/DocumentStore/P1Migration/LibraryScreen/Controller, nối main/sessioncontroller/review, free-spaceAndroidadapter; giữ toàn P1flow và rollback. Không xoá document/quarantine/rollback, không cloud/OCR/paidAPI/release/deploy/auto-merge.
- Spec / goal: docs/specs/2026-10-12-document-library-migration.md (PR4bapproval update bởiroottrướclogic), docs/goals/2026-10-18-upgrade-completion.md.
- Nhánh/base: readonlydesign codex/xs09-pr4b314a296; PR-4b.2 thực thi trên `claude/serene-ramanujan-h6674j` từ `main` `4ce9a76`.

## Kế hoạch và phân công

1. Read priorXS09PR1..3/4adone, fullspec/currentmain callchain andstorage seams. Rootdesignonly untilspec/PLANcomplete.
2. Delegate worker separateworktree/disjointfiles aftercontract. Root independentlyreruns tests-onlyRED beforelogic; keeperror/recovery/originalguards.
3. Androidcapacity reuse platformStatFs ratherthan dependency/Process/permission; exactAPI/staticruntime verification beforecode. Platformerrors map only sanitizedFileSystemException; don't inventfreebytes0 or assume infinitecapacity.
4. Rootreview/integrate/fullgate/hook/CI/native; exactAPKsyntheticUAT ifenvironment works. Guardedsquash onlyafterconditions; postmerge re-audit/docs/reconciliation.

## Quyết định và bằng chứng

- Explicitownerapproval18Oct includesP1notdistributed, authorizesPR4bdata-layoutswitch andcopy/check/retainrollback. No automaticdowngrade selected; fallback perexisting§18 remainsmanualrename andneverdelete.
- Reuse existinglibrary/migration instead ofnewdatabase/transactionframework · bậc1+2: originalpreservation alreadytested, leastnewlogic.
- Oldroot/workerhistoryDone describes12Octapprovallimit; do notrewritehistoricalclaims. Appendfreshapprovalto currentspec beforelogic, recordactualdate/ownerresponse ratherthan self-approvalfiction.

## Lần thử / blocker

Chưa tests/code/gates. W104bbasepending; UATdevice/KVMavailability separate. No releaseornewdependencyapproval needed forplatformadapter ifstandardAPIadequate.

## Bàn giao / bước tiếp theo

Rootapproveconcretecontract afterreadonlydesign thenworkerREDonfreshbase. Preserveoriginals/session.migrated andall unfinishedrecords. NoDonebeforeactualmerge andACevidence.


## PR-4b.2 — 2026-10-23 (`/auto-complete`, phiên chính)

Contract C1–C6 ghi ở spec cha mục "PR-4b.2 contract", Approved theo §3d trước source. Một PR, phiên chính tự làm (§3c: một PR không bắt buộc giao subagent).

### Quyết định và bằng chứng (chọn · loại · bậc)

- FIFO trước: mở/merge #61 (`e21e2cb`) rồi #57 (`4ce9a76`) trước PR này vì #61 sửa cùng `session_controller.dart`/`review_screen.dart` · loại làm song song rồi giải xung đột · bậc 1 (không làm hỏng việc người khác) + 2.
- Một `PickImporter` dùng chung cho controller và khởi động · loại hai luồng import riêng · bậc 2.
- C5a: marker rỗng + probe khởi động `null` → `cancel` · loại giữ marker (khoá vĩnh viễn mọi lần chụp, không cứu byte nào) · bậc 1 (hồi quy P1 AC-7).
- C5b: owner `NeedsUpdate`/`Unrecoverable`/thiếu, hoặc trang cần chụp lại đã mất → `retainRejected` (byte giữ nguyên) · loại khoá toàn cục vĩnh viễn · bậc 1.
- C5c: `pageId` đặt trước có trong manifest = đã commit → chỉ dọn · loại so byte lần hai · bậc 2 (id 128 bit sinh trước picker).
- Kết quả picker không đọc được trong cache (file mất) → huỷ đặt chỗ rỗng + `decodeFailed` (giữ hành vi P1 F-028) · loại để đặt chỗ rỗng khoá tới lần mở sau · bậc 1.
- Controller giữ `ScanSession session` làm kiểu giá trị danh sách trang + thêm `document` · loại đổi toàn bộ UI/test sang `document.pages` · bậc 2.
- `_DocumentPage` tự tạo controller một lần (`late final`) và huỷ khi đóng · loại tạo trong builder của route (route dựng lại sẽ rò controller) · bậc 1.
- Theme dùng `ValueNotifier` để màn tài liệu đã đẩy vẫn đổi Dark/Light · loại truyền `themeMode` lúc push (đứng yên) · bậc 1 (đúng hành vi FT-11).
- Gỡ `SessionStore` + test: so tên test, mọi bảo đảm có bản tương đương trong `document_store_test.dart` · bậc 2.
- Không chuyển sang skill `autopilot` của X-Templates (#57) giữa chừng: `doctor --fix` sẽ chèn `@AGENTS.md` vào `CLAUDE.md`, đúng điểm #57 để chủ repo quyết · bậc 1 (không vượt quyền).

### Bằng chứng TDD/kiểm

- `pick_import_test.dart`: stub `UnimplementedError` → 15/15 fail (hành vi vắng, chưa phải assertion RED) → triển khai → 15/15 PASS.
- Test controller/library mới viết sau code; độ nhạy kiểm bằng đột biến tạm thời trên source rồi khôi phục byte-identical (`cmp`): controller 4/4 đột biến có nghĩa làm test đỏ (dispose, resume khi restore, read-only, updatedAt); một đột biến tự viết không đổi hành vi nên không tính. Library 3/3 (bỏ recover, bỏ catch, bỏ notice kept).
- Treo widget test do trộn fake-async/`runAsync` → ghi `TRAPS.md`, sửa harness `test/ui/document_test_app.dart`.
- Cục bộ trên cây làm việc: `flutter analyze --fatal-infos` No issues; `dart format` 62 file 0 đổi; `flutter test` 803/803 PASS (trước bản sửa import trùng của a11y test — chạy lại trong gate).
- Chưa có: full gate có build APK, CI, chạy APK mới trên emulator/thiết bị (migration thật, StatFs thật, picker thật).

### Review độc lập (subagent reviewer, chỉ đọc) — 2 phát hiện, đã sửa trước commit

- F1: crash trong `LibraryStore.create` để lại `{docId}.part` → lần khởi động sau `create` ném `StateError` → `kept` mãi → mọi lần chụp báo `pendingImage` (hồi quy AC-7). Sửa: nhánh `createOwner` xoá `{docId}.part` sót (id chỉ marker này sở hữu, thư mục chưa có bản gốc). RED assertion `kept`≠`added` trước sửa → xanh.
- F2: đóng màn khi controller cũ đang import, mở lại cùng tài liệu → hai controller đọc/ghi chéo, lần lưu cũ có thể bỏ trang mới và xoá bản gốc của nó. Sửa: `SessionController(after:)` chờ `idle` của controller trước của cùng tài liệu trước khi `restore` đọc; `XScannerApp` giữ controller cuối theo docId. Chọn · loại đọc lại trong `importInto` (vẫn ghi đè chéo ở lần `_commit` sau) · bậc 1. RED: thêm scaffolding `after`/`idle` không dùng → assertion trang = 0 thay vì 1; sau sửa xanh.
- Ghi chú không chặn của reviewer: `retrieveLost` chỉ bắt `PlatformException`; lỗi khác để marker rỗng tới lần khởi động sau (tự hết) — giữ nguyên, ghi nhận.
