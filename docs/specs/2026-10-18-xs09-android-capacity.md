# XS-09 PR-4b.1 — Android internal-storage capacity

| Thuộc tính | Giá trị |
| --- | --- |
| Work ID | 2026-10-18-xs09-android-capacity |
| State | **Approved for implementation** |
| Approver / date | Root theo chủ repo duyệt PR-4b và §3d, 2026-10-18 trước source |
| Risk | M leaf của outcome L XS09; một PR chưa bật migration |

## 1. Problem and evidence

P1Migration gọi Storage.freeBytes(appRoot) trước copy +10% (FR6/AC8), nhưng chưa có platform implementation. Owner18Oct duyệt PR4b/P1 chưa phân phối. Dùng giá trị giả hoặc đo nhầm volume có thể chấp nhận copy khi không đủ dung lượng. Không mở migration trong slice này.

## 3. Research and choice

| Comparison | Evidence | Decision |
| --- | --- | --- |
| Đã có và sâu hơn | Storage seam, migration space/fault-injection tests | Reuse, không sửa migration |
| Đã có nhưng nông hơn | Flutter MethodChannel có sẵn trong SDK; app chưa gọi capacity | StandardMessageCodec int/Long, channel nhỏ |
| Chưa có, sự cố thật | App chưa thể nối migration AC8 vì thiếu free-space adapter | Android StatFs.availableBytes trên filesDir cùng app support volume |

[Android StatFs](https://developer.android.com/reference/android/os/StatFs): availableBytes có từ API18, phản ánh phần app truy cập được; app minSdk24. [Flutter channel](https://docs.flutter.dev/platform-integration/platform-channels): codec Long ↔ Dart int. Installed path_provider_android support root là applicationContext.filesDir. Chọn native API sẵn có thay plugin/FFI/shell/quyền mới. [JUnit4.13.2](https://github.com/junit-team/junit4/releases/tag/r4.13.2) published2021-02-13T16:56:53Z qua official release API18Oct; EPL1.0, test-only plus Hamcrest1.3 BSD. Kiểm artefact/graph/OSV thực trước merge, không runtime dependency.

## 7. Contract

- FR-1: Channel `org.xscanner/storage`, method `availableBytes`, arguments null. Native đo `StatFs(applicationContext.filesDir.path).availableBytes` mỗi lần gọi; không nhận arbitrary path. Unknown method → notImplemented; nonnull arguments → static invalid_arguments; Runtime/Exception → static capacity_unavailable/null details. Không log path/errors, không catch JVM Error. Negative native capacity cũng fail closed.
- FR-2: AndroidStorage implements existing Storage; constructor binds Directory appRoot (actual getApplicationSupportDirectory at integration) + injectable MethodChannel. freeBytes chỉ nhận cùng absolute root path; mismatch → sanitized FileSystemException trước platformcall. Result chỉ int>=0; giữ0 và >32bit chính xác. null/double/string/negative/PlatformException/MissingPluginException → sanitized FileSystemException không path/details/nội dung lỗi. Không giả unlimited hoặc0. Không cache dung lượng.
- FR-3: Thin MainActivity wiring gọi super.configureFlutterEngine, capture applicationContext.filesDir.path string để handler không giữ Activity. Pure Kotlin MethodCallHandler với injected ()->Long là seam test; không Android framework mock/plugin mới.
- FR-4: JUnit4.13.2 testImplementation, Hamcrest1.3 transitive, chỉ debug JVM tests. Dispatcher test thêm :app:testDebugUnitTest nên full gate/CI thật chạy. Không sửa minSdk/permission/schema/pub lock/main.dart hoặc activate migration.

## 9. Acceptance

- AC-1: Dart mocked channel tests exact method/args, repeated fresh reads,0/5GiB and ordinary int preserved; known failure/bad values/wrong root sanitized. Tests on compiling minimal stub fail assertions BEFORE behavior.
- AC-2: Native JVM tests use Result recorder: Long0/5GiB, exception with synthetic sensitive marker, negative value, invalid arguments and unknown method. Compiling stub (all notImplemented) yields actual assertion RED, then same tests GREEN. Compile/setup errors not RED.
- AC-3: Existing migration AC8 and every existing Flutter/repo test preserved; no runtime dependency/permissions change; Android build + release mergedmanifest check + zero analyze/format + JVM tests pass in dispatcher and normal hook, final-head CI/native/threads proof before guarded merge.
- AC-4: Root review exact frozen files/graph and records, maps/PROGRESS/samePR docs. Mock/JVM/debug build are not actual StatFs device evidence; no UAT/device/AC13 Complete claim.

## 11. Architecture và code touchpoints

- `apps/mobile/lib/storage/android_storage.dart` — new leaf.
- `apps/mobile/test/storage/android_storage_test.dart` — Dart boundary regression.
- `apps/mobile/android/app/src/main/kotlin/org/xscanner/x_scanner/MainActivity.kt` — channel registration.
- `apps/mobile/android/app/src/main/kotlin/org/xscanner/x_scanner/StorageHandler.kt` — pure handler.
- `apps/mobile/android/app/src/test/kotlin/org/xscanner/x_scanner/StorageHandlerTest.kt` — JVM behavior.
- `apps/mobile/android/app/build.gradle.kts`, `.claude/project-commands.sh` — test dependency/dispatcher.
- `docs/work/2026-10-18-xs09-android-capacity/done.md` — root proof/decisions.

## 16. Evidence

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `apps/mobile/test/storage/android_storage_test.dart` |
| AC-2 | `apps/mobile/android/app/src/test/kotlin/org/xscanner/x_scanner/StorageHandlerTest.kt` |
| AC-3 | `.claude/project-commands.sh`; `apps/mobile/test/storage/p1_migration_test.dart` |
| AC-4 | `docs/work/2026-10-18-xs09-android-capacity/done.md` |

New paths must exist before contract acceptance; no fake evidence or empty exemption. Root separately approves library/picker wiring contract before source in next slice. Rollback via PR, no app data touched by this slice.
