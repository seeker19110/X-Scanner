# Công việc: XS09 capacity — Dart boundary and Android handler

- Work ID: 2026-10-18-xs09-capacity-core
- Yêu cầu / outcome: test và implementation leaf dung lượng Android cho XS09 PR-4b, chưa bật migration/UI.
- Trạng thái: Ready — implementation + targeted verification đóng băng, root review/tích hợp/full gate tiếp.
- Chủ trì / writer: worker /root/w104b_research; root giữ spec/PLAN/dispatcher/review/gates/PR/merge.
- Mức rủi ro / số PR: M leaf thuộc outcome L XS09; một PR foundation do root tích hợp.
- Scope / non-goal: chỉ android_storage.dart/test, StorageHandler.kt/Test, MainActivity.kt, app/build.gradle.kts và hồ sơ này; không main.dart/schema/permission/pub/runtime dependency, không commit/push/merge/subagent.
- Spec / goal / issue: docs/specs/2026-10-18-xs09-android-capacity.md Approved root18Oct theo owner PR4b; root PLAN và docs/work/2026-10-18-xs09-android-capacity/working.md.
- Nhánh / base SHA / thời điểm reconcile: `codex/xs09-android-capacity` @ `561a5cf` · 2026-10-18T01:52:39Z

## Kế hoạch và phân công

1. Đọc CLAUDE/PROJECT/PROGRESS/standard-delivery, exact spec và root PLAN/authority trên base561a5cf; local hooksPath=scripts/githooks có sẵn.
2. Viết test boundary Dart và pure JVM, baseline biên dịch được: Dart trả0; Kotlin trả notImplemented cho mọi call. Không wiring MainActivity trước RED.
3. Không Dart/Flutter/pub/Gradle/compiler/formatter trước CPU grant từ root. Static review + hash rồi gửi READY_TESTS; root kiểm assertion RED, compile/setup failure không tính RED.
4. Chỉ sau root GREENLIGHT mới viết hành vi và wiring, targeted tests theo CPU slot; freeze để root tích hợp sau actual W104 merge.

## Quyết định và bằng chứng

- Exact fixed-volume contract thắng proposal cũ nhận path: kênh org.xscanner/storage, availableBytes, arguments null; native chỉ đo applicationContext.filesDir.path · loại arbitrary path argument · bậc đúng+bảo mật.
- Dart nhận Directory appRoot và injectable MethodChannel; tests dùng Storage interface, so sánh absolute path và reject mismatch trước call · reuse seam có sẵn, không abstraction mới · bậc ít hơn.
- Lỗi Dart cố định FileSystemException('Storage capacity is unavailable.') không path/osError; Kotlin static capacity_unavailable/invalid_arguments và details null; JVM Error không catch · giữ biên tin cậy.
- JUnit4.13.2 chỉ testImplementation đúng spec; root audit artefact/graph/OSV và dispatcher, worker không tự thêm runtime/plugin/quyền.
- Đã đọc source Flutter3.47.7 MethodChannel.invokeMethod và TestDefaultBinaryMessenger.setMockMethodCallHandler: mock encode codec thật, PlatformException được encode error envelope, MissingPluginException trả null; generic Object? khi implementation tránh cast runtime trước validation.
- Đã viết 19 Dart cases và 11 JVM @Test: exact noargs method/default+injectedchannel,0/ordinary/5GiB/freshread, relative/absolute root, wrongroot, invalid results, sanitized failures; Kotlin success/negative/Runtime+checked Exception/not-catch Error/nonnullargs/unknown.
- Tại READY_TESTS, tests giữ assertion contract ngay từ baseline; chưa có output compiler/analyze/test nên chưa khẳng định stub biên dịch hay RED thực tế.
- Tại READY_TESTS, đã đọc lại toàn bộ sáu source/test/config files; git diff --check exit0. MainActivity giữ nguyên lúc đó. Baseline dự kiến 18/19 Dart và9/11 JVM assertion fail; kết quả thực được ghi bên dưới.

### READY_TESTS frozen SHA-256 (2026-10-18)

| Path | SHA-256 |
| --- | --- |
| apps/mobile/lib/storage/android_storage.dart | da199398487037eb20bcd4aaa7a7192a40fc1403fb30ebcd7f354c7782e5fbbb |
| apps/mobile/test/storage/android_storage_test.dart | 985c4c1fef84e908ca9ffdb95ac4c2024bd099c7135e384993091a09a3bfb25a |
| apps/mobile/android/app/src/main/kotlin/org/xscanner/x_scanner/StorageHandler.kt | d723942628c4c1933317db6a3323a7d7361c41739cc6cf4e9a16bbe10de249ca |
| apps/mobile/android/app/src/main/kotlin/org/xscanner/x_scanner/MainActivity.kt (unchanged) | ca14cd277d441cd988283e1c6333f0efa4fa9f4a825565db0d527a58a06a9b13 |
| apps/mobile/android/app/src/test/kotlin/org/xscanner/x_scanner/StorageHandlerTest.kt | 0cdb93ba3fe64b24c422cb27621be87e4886045302787a00a0960547d414feee |
| apps/mobile/android/app/build.gradle.kts | 32ad59e94a693df985018d2cecda8d246f6d8745436eb9048e629c9af37975c4 |

## Lần thử / blocker

- Checkpoint READY_TESTS chưa chạy test/compiler/gate; root CPU đang dùng bounded emulator UAT nên worker chờ grant, không tranh tài nguyên.
- Source SDK path thực có thêm thư mục flutter/; lần đọc path thiếu thư mục trả No such file, đã dò rg --files và đọc đúng source, không coi là kết quả test.

### Root RED và GREENLIGHT

- Parent cấp GREENLIGHT sau khi thực chạy exact frozen stubs. Worker tự đọc toàn bộ capacity-root-red-dart.log (184 dòng), capacity-root-red-jvm.log (267 dòng) và capacity-root-red-status.json dưới /home/liend/.local/share/x-scanner: Dart1PASS/18 assertion FAIL; JVM11 cases,2PASS/9 assertion FAIL, không lỗi compile. Hash hai test vẫn nguyên985c4c1f… và0cdb93ba… trước behavior edit.
- JVM lần setup đầu exit127 do thiếu generated wrapper không phải RED; root dispatcher build tạo wrapper/build APK/release guard rồi mới chạy suite. Không gộp setup failure thành RED.
- Implementation Dart bind absolute root, gọi invokeMethod<Object?> mỗi lần, check int>=0 và chuyển đúng PlatformException/MissingPluginException sang lỗi static. Kotlin chỉ catch Exception quanh supplier, không catch Result callback hoặc JVM Error; nonnullargs/unknown không đọc dung lượng. MainActivity gọi super, chỉ capture filesDir.path String rồi StatFs mỗi invocation.

### Implementation verification và giới hạn

- Worker nhận CPU grant/GREENLIGHT của root trước behavior. Dart lượt đầu7PASS/12FAIL: FileSystemException bỏ path argument có default chuỗi rỗng, khác null mà contract/test yêu cầu. Đã đọc SDK lib/io/file.dart:1068, sửa production truyền null tường minh, giữ assertion.
- Analyzer lượt đầu1 info prefer_initializing_formals; đổi channel constructor sang this._channel đúng mẫu SessionController hiện có, public named argument channel vẫn hoạt động. Không ignore/suppress lint.
- scripts/dev-task.sh format-file cho hai Dart file đều skip vì dispatcher chưa resolve formatter per-file cho app nested. Fallback đúng lệnh dart format đã khai ở project-commands, thu hẹp hai own files; format cuối2files/0changed, exit0. Không sửa dispatcher.
- Dart cuối: flutter test --no-pub --reporter expanded test/storage/android_storage_test.dart, exit0,19/19PASS trên source cuối. JVM: ./gradlew --console=plain :app:testDebugUnitTest --tests org.xscanner.x_scanner.StorageHandlerTest, exit0, BUILD SUCCESSFUL18s; XML tests11/failures0/errors0/skipped0. App compileDebugKotlin thực thi gồm MainActivity wiring; không suy ra native StatFs chạy trên thiết bị.
- Typecheck qua bash scripts/dev-task.sh typecheck: exit0, No issues found,3.0s. Pub resolution giữ nguyên pubspec/lock image4.10.1 trên base561a5cf; root phải re-run gate sau tích hợp W104 actualmain.
- Đã đọc toàn output targeted/analyze, toàn source/test/config file; git diff --check exit0. Main.dart/pubspec/lock/manifest/P1Migration không đổi. Không runtime pub dependency/permission/UI/migration activation, không fullgate/commit/push/merge.
- Gradle hiện vẫn in deprecated builtInKotlin/newDsl/plugin warnings có nguyên trong root RED baseline; không gọi đây là0 Gradle warnings và không mở rộng leaf để đổi build architecture.

### Dart test formatting-only delta

Formatter chỉ đổi đoạn sau. Đã tái dựng bản trước format trong bộ nhớ và SHA-256 khớp985c4c1fef84e908ca9ffdb95ac4c2024bd099c7135e384993091a09a3bfb25a; không thêm/xoá/sửa assertion. JVM test byte-for-byte unchanged.

```diff
-  test('compares absolute root paths without requiring filesystem IO', () async {
-    final relativeRoot = Directory('$_sensitiveMarker/app-support');
-    final relative = AndroidStorage(appRoot: relativeRoot);
-    messenger.setMockMethodCallHandler(_channel, (_) async => 73);
+  test(
+    'compares absolute root paths without requiring filesystem IO',
+    () async {
+      final relativeRoot = Directory('$_sensitiveMarker/app-support');
+      final relative = AndroidStorage(appRoot: relativeRoot);
+      messenger.setMockMethodCallHandler(_channel, (_) async => 73);

-    expect(await relative.freeBytes(relativeRoot.absolute), 73);
-  });
+      expect(await relative.freeBytes(relativeRoot.absolute), 73);
+    },
+  );
```

### Final frozen SHA-256

| Path | SHA-256 |
| --- | --- |
| apps/mobile/lib/storage/android_storage.dart | 831052d44674b7fa7235b4f9a9db5fe230647b56271a2d489ebfcd222fbda37f |
| apps/mobile/test/storage/android_storage_test.dart | bf4bd98e5e269424be7788e72861a36c5d907248eebb51c6c1dbf4c8a3b71e7f |
| apps/mobile/android/app/src/main/kotlin/org/xscanner/x_scanner/StorageHandler.kt | 7ec1e0e74d7f542737565aac91d010d9769b3f80b009e51ad71d44b6af846e15 |
| apps/mobile/android/app/src/main/kotlin/org/xscanner/x_scanner/MainActivity.kt | 63d340d64d44b2952e04ddf4e95e50580b7cfe94b223bb76bf5ea6705ceef098 |
| apps/mobile/android/app/src/test/kotlin/org/xscanner/x_scanner/StorageHandlerTest.kt | 0cdb93ba3fe64b24c422cb27621be87e4886045302787a00a0960547d414feee |
| apps/mobile/android/app/build.gradle.kts | 32ad59e94a693df985018d2cecda8d246f6d8745436eb9048e629c9af37975c4 |

Logs dưới /home/liend/.local/share/x-scanner/downloads/:

| Log | SHA-256 |
| --- | --- |
| capacity-worker-green-dart-final.log | 600f7db1e9f03e5bf572fad0449c070befbb688981281fbfffe3fd87c1ab2115 |
| capacity-worker-green-jvm.log | 3daab9dff87cb656d00b1c1074bed1cbf58810b4ada6f5a85b8e15b6c0086d49 |
| capacity-worker-analyze-final.log | 6f2767d4ba4bf44e8c9788b7ca3308df9ef47e1c8939a5d679ca20eafc7ec2a3 |
| capacity-worker-format-final.log | 86cbe6234237454cd872d2340a34541d75abeb076ec9f849ac6f88fbd2f5cdeb |

## Bàn giao / bước tiếp theo

- Worker đóng băng sáu files và hồ sơ này; không tự git merge/commit. Root review exact hashes rồi reconcile từ actual main sau PR58; chạy đủ dispatcher gate/hook/CI/native trước PR/merge theo phạm vi root.
- AC1/2 có actual RED→GREEN trên cùng assertions; AC3/4 còn full integrated gate/docs/rootreview/merge, chưa Done. Không coi targeted-only là fullgate.
- Root docs/spec/PLAN và PR4b-design là file mang sẵn chưa commit; worker chỉ tạo/chỉnh đúng own files, không sửa các hồ sơ đó.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

Chưa nghiệm thu; không có PR/merge/test runtime của leaf này. Mock/JVM/build không phải bằng chứng StatFs trên thiết bị; không tuyên bố AC13/UAT/Complete.
