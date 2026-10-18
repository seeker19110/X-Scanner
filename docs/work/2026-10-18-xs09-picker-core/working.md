# Công việc: XS09 pending picker storage core

- Work ID: 2026-10-18-xs09-picker-core
- Outcome: pure Dart pending-picker journal/copy leaf theo spec root duyệt trước source.
- State: **GREEN_TARGETED_FROZEN** trên209c808, typedfailure theo FR4 đã được root independently reproduce; chờ root review/full gates. Chưa commit/PR/merge.
- Owner: `/root/picker_contract`; root nghiệm thu/PR/gate/merge.
- Spec: `docs/specs/2026-10-18-xs09-picker-preservation.md` Approved18Oct; PLAN trong root work.
- Scope ghi: `apps/mobile/lib/storage/pending_pick_store.dart`, `apps/mobile/test/storage/pending_pick_store_test.dart`, file này. Không sửa frozen design/spec/PLAN/root docs/UI/pub/controller/main.
- Base: c50670af18b1f11af38d15051b36264e1a051cb3, checkout `/home/liend/.local/share/x-scanner/xs09-picker-preservation`.

## Kế hoạch và phân công

1. Static tests finite filesystem + IOOverrides và stub giữ đúng chữ ký/value, không logic/FS write.
2. READY_TESTS + hash; không compiler/formatter/pub/gate khi capacity root đang dùng CPU.
3. Root chạy/đọc actual behavior RED; chỉ sau GREENLIGHT mới triển khai logic và targeted checks.
4. Freeze source/tests, root review/reconcile actual capacity main và chạy gate/hook/CI/native/merge.

## Quyết định và bằng chứng

Đọc toàn bộ spec Approved và PLAN trước tạo source. Thiết kế root đã chốt sáu methods, owner immutable, createOwner bootstrap-only, cap do caller truyền và failure đóng; leaf không thay PageSource behavior.

Static test/stub checkpoint18Oct:

- Source stub65lines chỉ giữ fields/private value/signatures/closed exception; load null, begin tạo value, remember trả value, stage trả path chưa tồn tại, cancel/complete no-op. Không branch/queue/filesystem writes/production behavior.
- Test fixture dùng cache/private directories tạo trong systemTemp, ảnh giả4bytes và cap4/5; journal lớn nhất8193bytes, không dữ liệu thật hoặc stress/OOM.
- Các assertions AC1..3: durable identity/CAS/queue, invalid IDs/retake/constructor cap; strict journal/UTF8/version/path/size/link/orphan; canonical cache boundary/changed source symlinks; exact byte stage/cap/growing source/paused copy/cache eviction; partial retention, cancel/stale/complete/unknown files, sanitized errors.
- IOOverrides observe before/after filesystem mutations, reusable finite fault sweep cho begin/remember/stage/cancel/complete, kill Error và I/O error. Baseline phải thật sự thấy mutation trước khi fault sweep; không lấy no-op làm evidence.
- Source SHA256 `347147c250a37a9c6c562b82f29f2e23532e41a866315e814db1175716c28e13`.
- Tests SHA256 `3f81d198adbb01b243b87043db23d77a6488469c137f3a6981444c42c38d67b4`.
- Frozen design SHA vẫn `7a670b6f712c791604ac71c23d51e38cebb866bd7267592006f91a8c30a8857b`.
- Static `git diff --no-index --check /dev/null <source/test>` không báo whitespace errors; đọc lại toàn bộ file và đối chiếu signatures với SDK dart:io source. Không có compiler/formatter/pub/Flutter/Gradle/test/gate được chạy.

## Lần thử / blocker

Chưa chạy compiler/test hoặc RED/GREEN. Không có PR/commit/gate từ worker. “Compiling stub” là ý định/chữ ký scaffold, chưa xác minh compile; nếu root thấy setup/compile error thì sửa harness riêng và không tính lỗi đó là behavior RED.

## Root contract correction before RED — FR8 retained rejection

Root phát hiện trước logic: giữ active marker khi decode/oversize input bị từ chối sẽ chặn mọi capture về sau, trái P1AC7. Root đã duyệt FR8/AC3 và PLAN bổ sung **method thứ bảy** `retainRejected` trước khi worker đổi stub/tests. Frozen design sáu methods là lịch sử và không bị sửa. Chỉ thêm chữ ký no-op vào source, chưa rename/archive behavior.

Test bổ sung: archive nguyên journal/staged/part rồi begin mới; staged surviving cache eviction; unstaged5bytes với cap4 vẫn giữ cache/path; empty/solepartial-missing-source/unknown active/wrongtoken bị chặn; collision directory/file/link không overwrite; IOOverrides quan sát directory rename và before/after fault sweep thêm retainRejected. Không generic framework, recovery UI hoặc discard API.

Checkpoint READY_TESTS mới (chưa compiler/formatter/test):

- Source67lines SHA256 `080feabd1613c39ae3aaacdaa082787f2560fb3add97487d75c31b302d54b3a7`.
- Tests1012lines SHA256 `170742ffb10767efbcfd39e02b2b6de13a622c9d72c1e38698759a049ee6c974`.
- Frozen design vẫn `7a670b6f712c791604ac71c23d51e38cebb866bd7267592006f91a8c30a8857b`.
- Static diff check không báo whitespace errors. Không claim compile/RED/GREEN. Chờ root CPU grant và actual RED độc lập.

Khi root GREENLIGHT logic, đặt đúng debt FR8 tại retainRejected: `DEBT: rejected picker inputs are retained outside the active intent without recovery UI | trần: private retained data until XS10/manualreview; unstaged oversized source still relies on OS cache | xem lại khi: XS10 defines retention/recovery or before distributed release.` Source stub hiện không chứa implementation nên chưa giả ghi retention đã chạy.

## Bàn giao

Root đọc checkpoint GREEN dưới đây, verify hashes và review nguồn/test delta trước full gates. Chỉ ba file thuộc scope worker được ghi; design/root/spec/PLAN/UI/pub/controller/main giữ nguyên. Chưa full gate/commit/PR/merge.

## Actual RED → GREENLIGHT → implementation — 2026-10-18

Root đã tự chạy compiling RED rồi cho phép logic bằng message giao việc. Proof `/home/liend/.local/share/x-scanner/picker-root-red-proof.json`: **86cases=2PASS/84FAIL**, gồm62 assertion failures,14 stub-null,7 stub-dependent missing path,1 bounded source-read timeout. **Không gọi84lỗi đó là84assertions**. Proof ghi không có compile failure; root log `/home/liend/.local/share/x-scanner/downloads/picker-root-red.log`. Root chỉ format test trước RED: canonical test SHA `db9c42c6003873cdd44b7e14162263cdee269088c33f6d82dcae180ea15641be`, stub080fea không đổi.

Implementation sau GREENLIGHT: một queue cho bảy methods; strict IDs/CAS/metadata/known file names; bounded read8193 để nhận tối đa8192; atomic `.tmp`/flush/rename; canonical cache-relative source, cap trước và trong copy64KiB qua `.part` giữ source; giữ staged khi cache mất; không xoá unknown; complete xoá journal cuối; rejected giữ nguyên whole directory bằng sibling rename, không overwrite. Không runtime dependency, không nối app hoặc thay picker/P1 behavior. Caller protocol/durable manifest verification thuộc PR tích hợp, leaf không giả xác minh chúng.

### Lượt GREEN đầu và correction harness

- `picker-core-green-attempt1.log`:84/86 PASS; hai fault-sweep begin báo injection index11 không đạt (chỉ10events). Nguyên nhân ở fixture: baseline tạo support parent, các iteration sau chỉ xoá pending nên parent đã tồn tại; số mkdir events khác nhau. Không phải lỗi production cần sửa để né test.
- Worker báo root chính xác delta harness trước khi sửa/rerun; root đã phản hồi đồng ý correction: trong `prepare`, chỉ khi phase begin thì reset cả support parent thuộc systemTemp fixture. Giữ mọi before/after fault indices, source/afterstate assertions và đủ ancestor mkdir coverage; không giảm số injection theo lượt thất bại. Mọi fixture khác giữ nguyên.
- `picker-core-green-attempt2.log`:**86/86 PASS**, exit0, full output đã đọc. Không thay expectation86cases gốc. Canonical hash trước correction làdb9c42c ở trên; final test hash dưới đây gồm correction5lines và hai regression mới.

### Hai regression phát hiện khi tự review

Trước sửa thêm, relativepath<=2048 có nhiều control chars hợp lệ trên filesystem có thể JSON-escape vượt journal8192; directory config có trailing slash dựng rejected path thành child thay vì sibling. Thêm hai test finite (synthetic4bytes;10pathsegments), chạy actual RED trước branch sửa:

- `picker-core-edge-red.log`:0/2 PASS, exit1, không compile error. Một assertion báo remember đã chấp nhận journal quá cỡ; một PendingPickFailure khi trailing directory rename vào child.
- Source trước hai fix SHA `f5a9d88548b6e9f2779d428867b9eeaa812927ef328dfbf528095008656353c9`; test edge RED SHA `f5e5a24fe6d5c84cfd44428d7506b52a469f34a174ab9b752c5891e457af2278` giữ nguyên qua GREEN.
- Sửa tối thiểu: kiểm encoded UTF8 journal length trước tạo tmp; lấy folder cuối và dir.parent để tạo đúng sibling, kể cả trailing separator.
- `picker-core-green-final.log`:**88/88 PASS**, exit0, đọc toàn bộ output, không test failure. Không suy ra device/UAT/power-loss hoặc exactly-once.

### Final targeted freeze

- Source381lines SHA `7c591c068a1537e52c5ad6c720c3d016297c642b9d593155452545d149a285bb`.
- Tests1157lines SHA `f5e5a24fe6d5c84cfd44428d7506b52a469f34a174ab9b752c5891e457af2278`.
- `bash scripts/dev-task.sh typecheck` exit0: Flutter analyze fatal-infos, **No issues found**,5.0s; full log `picker-core-analyze.log` read. Pub resolution chạy theo dispatcher, pubspec/lock không có diff.
- `dart format --output=none --set-exit-if-changed <2files>` exit0:2files/0changes. Dispatcher format-file đã chạy nhưng no-op vì không có per-file mapping.
- Full source/self-review và git diff whitespace check không có lỗi. Frozen design vẫn7a670b6. Không full gate/commit/push/merge/subagent từ worker.

Raw logs ngoài repo tại `/home/liend/.local/share/x-scanner/downloads/`:

| File | SHA256 |
| --- | --- |
| picker-core-green-attempt1.log | `2996a6608feaa76904a17542a6f067f757f48036f640c3446889fb2af21eae2b` |
| picker-core-green-attempt2.log | `ed6e2b78cf5154a78c4035c39409aaf00b1ccbbd058e32eaba170ef223e7192e` |
| picker-core-edge-red.log | `77f4e82a62a899b3a8ca004c760b4f89c401254bfd68a4411727e800522b2586` |
| picker-core-green-final.log | `f940cd0a26b849bf192ad9f53d126b5aee951af65df614d68cfc87978eb2e6c6` |
| picker-core-analyze.log | `e28cbe4ac46fd1293b34d4e2e4b077800405d9ce24e97d170936abdc41a3cb2f` |

## Root refinement FR4: classify size rejection — 2026-10-18

Root duyệt specFR4 trước thay đổi: boolean `PendingPickFailure.sizeRejected` defaultfalse, message vẫn static, phân biệt input empty/over-cap để park reject với I/O/identity/journal/path phải giữ active cho Retry. Không enum, string parsing hoặc error framework.

Worker thêm field/default scaffolding và8classificationcases trước true throws. `picker-core-classification-red.log` exit1, **3PASS/5FAIL**, cả5 là actual assertions `sizeRejected` expectedtrue/actualfalse (source0/5bytes, staged0/5bytes, actualtotalgrow-overcap). Ba ca false đã PASS: shortened source, injectedI/O, identity/journal/path. Không compile/setup error. Source lúc RED933e356553e1ec75e78329207ecb169e2b455c2b21200cfe49f1e1aba47594fc; tests34c111806ea21d02e9953cc5f3be05bcabea039518a85fdb363e116f36884254.

Theo brief trước, worker đã đổi đúng2throw sites và chạy **96/96 PASS** exit0, log `picker-core-classification-green.log`, trước khi message root yêu cầu tạm dừng tại classificationRED được nhận. Worker đã báo thẳng root việc thứ tự này. Không nói root đã independently xác minh classification RED ở thời điểm đó.

Theo message mới, worker đưa riêng2throw về `PendingPickFailure()` defaultfalse bằng apply_patch, giữ nguyên field/tests/expectations/harness và mọi implementation khác. Không git reset/restore, không mất uncommitted work. Đóng băng snapshot mặc định false cho root rerun/verify trước GREENLIGHT mới; không claim snapshot này GREEN96.

- Current source SHA `669a8785327794de1f0fc82607151678b6187fc81ef500deff51b8b8a539656e`.
- Current tests SHA `34c111806ea21d02e9953cc5f3be05bcabea039518a85fdb363e116f36884254`.
- RED log SHA `f49cc128d359a02acdb108a6a31a12c7067d2f93b0d3cabc17b03cf924fc0238`.
- Historical GREEN96 log SHA `837fca0faa99fa2e5eb66d32a39e1b3d3380dcf2f66abea718c3c9b6022df3fc`.
- Formatter source/test0changes; no fullgate/commit/push/merge. Frozen design unchanged7a670b6.

Root rerun command already exercised by worker: `flutter test --no-pub test/storage/pending_pick_store_test.dart --reporter expanded --name 'closed failure classification'` from apps/mobile under pinned env. Chỉ sau root GREENLIGHT mới bật2true throws tại `_checkSize` (empty/overcaporiginal) và actualtotal>cap; shortened/otherI/O giữfalse. Full96/targeted analyze sau đó phải chạy mới trước finalfreeze.

## Root sensitivity reproduction và freeze sau capacity merge

Root giao việc xác nhận đã independently reproduce classification trên fresh main209c808:8cases3PASS/5assertionFAIL, actualsizeRejectedfalse/expectedtrue. Root cũng ghi một lần filter sai exit79/no tests **không phải RED**; worker không dùng lượt đó làm chứng cứ. Đây là sensitivity reproduction sau development, không đổi lịch sử worker đã RED trước2typedthrows đầu.

Root reconcile branch sang actual capacity merge `209c808ec20b4df9ca75e64c0c8d037e150aae7c`, giải parent spec conflict, kiểm12file khác giữ hash, rồi GREENLIGHT đúng2typedthrows. Worker tự đọc HEAD209c808 và hashes669a878/34c111 trước sửa; chỉ restore2sizeRejectedtrue sites, không thay test hoặc logic khác.

- Fresh final target: `flutter test --no-pub test/storage/pending_pick_store_test.dart --reporter expanded` exit0, **96/96 PASS**, đọc toàn bộ output. Log `/home/liend/.local/share/x-scanner/downloads/picker-core-final-209c808.log`, SHA `5985c7459740171b7fca2c7b4a753b039fb8e6a779c138dac0ad4c2638450253`.
- Fresh `bash scripts/dev-task.sh typecheck` exit0, `flutter analyze --fatal-infos`:**No issues found**,5.3s. Log `picker-core-analyze-209c808.log`, SHA `2caa8384d4e24367f1fd16ac5ea8356fa00a0f53167b0057532cc091f4e58f44`.
- `dart format --output=none --set-exit-if-changed <2files>` exit0,2files/0changes; git diff whitespace sạch, pubspec/lock không diff.
- Final source SHA **`84997dc8065084bb5b3a0c90b7b25b322f3576ec1ebb48d665d0ded859d1c912`**.
- Final tests SHA **`34c111806ea21d02e9953cc5f3be05bcabea039518a85fdb363e116f36884254`**.
- Source/test frozen. Chỉ storageleaf +tests+ownrecord; không main/UI/PageSource/controller/dependency đổi, không fullgate/commit/push/merge từ worker. Full gates, independent review, PR và actual merge thuộc root; không gọi outcome Complete từ targeted96.
