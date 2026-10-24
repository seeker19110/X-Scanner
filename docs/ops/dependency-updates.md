# Cập nhật dependency — X-Scanner

> Luật riêng của X-Scanner (file của dự án; `docs/ops/supply-chain.md` là file khung, không sửa).
> Cấu hình: `.github/dependabot.yml`. Ngoại lệ: `docs/ops/supply-chain-exceptions.md`.

## Dependabot PR: tự merge bản nâng nhỏ

Chủ repo duyệt 2026-10-13: phiên AI **tự merge** PR của `dependabot[bot]` nâng **patch/minor** khi đạt **đủ** các
bước dưới; thiếu một bước, hoặc gặp dấu hiệu ở mục "Hỏi chủ repo", thì báo chủ repo, không merge. Đây là phiên AI merge
sau khi tự kiểm, **không** phải bật auto-merge của GitHub.

1. **Tuổi:** bản mới phát hành ≥ 7 ngày (pub.dev `published`; action: ngày release/tag). Cùng luật EX-1.
2. **Nguyên vẹn:** `sha256` trong `pubspec.lock` khớp `archive_sha256` của pub.dev; action: SHA trỏ đúng commit của
   tag trong repo upstream.
3. **Đọc thay đổi:** CHANGELOG/release notes từ bản cũ tới bản mới, và diff phần được đóng gói (gói pub: `lib/`,
   `android/`, `ios/`; action: `action.yml` + mã chạy), không chỉ đọc mô tả PR.
4. **Tương thích:** ràng buộc SDK của bản mới thoả Flutter đã ghim (`environment.flutter` trong `apps/mobile/pubspec.yaml`,
   nguồn duy nhất mà CI đọc qua `scripts/flutter-version.sh`; ADR-0002).
5. **Phạm vi lock:** `pubspec.lock` chỉ đổi đúng gói được nâng; thêm/đổi gói bắc cầu thì mỗi gói cũng phải qua 1–4.
6. **CI:** "Framework and Android app gate" xanh trên head hiện tại (APK, analyze, test, kiểm quyền manifest release
   đã gộp) và PR mergeable.
7. **Ghi lại:** squash merge; commit message liệt kê kết quả 1–6 và `Work ID`.

**Hỏi chủ repo, không tự merge:** bản major (đã bị bỏ qua trong `.github/dependabot.yml`); gói `image` (giải mã ảnh
không tin cậy — F-004, đi `/deps-upgrade` kèm test hồi quy); thêm gói phụ thuộc mới; quyền Android/component mới
trong manifest; mã mạng/telemetry mới; đổi license hoặc publisher; action đổi `permissions`/cần secret; CI đỏ.
Security update của Dependabot vẫn qua đủ 2–7 (bỏ bước 1 khi bản vá lỗ hổng đã công bố) và báo chủ repo sau khi merge.

## Gradle: lockfile và Dependabot `gradle`

Mọi cấu hình Gradle của `:app` khoá theo `apps/mobile/android/app/gradle.lockfile`; classpath plugin (AGP, Kotlin) khoá
theo `apps/mobile/android/settings-gradle.lockfile`. Build thấy gói không có trong lock thì đỏ
(`Resolved '...' which is not part of the dependency lock state`). Sau khi đổi dependency/plugin Gradle **hoặc nâng
Flutter** (artefact `io.flutter:*` mang hash engine), sinh lại lock rồi xem diff như một thay đổi dependency:

```bash
cd apps/mobile && flutter build apk --debug   # tạo local.properties
cd android && ./gradlew -q :app:dependencies buildEnvironment --write-locks
```

PR Dependabot `gradle` có thể không cập nhật lockfile; khi cổng đỏ vì lock, đẩy commit sinh lại lock vào chính PR đó,
rồi qua đủ bước 1–7 ở trên. JDK ghim trong `.java-version` (CI dùng `actions/setup-java` đọc file này).

## License và SBOM

`scripts/check-licenses.py` (trong gate) kiểm license mọi gói pub và mọi gói Maven của `releaseRuntimeClasspath`
theo `docs/ops/license-policy.json`; gói thêm mới có license ngoài allow-list hoặc không rõ license làm cổng đỏ.
CI ghi SBOM CycloneDX (`x-scanner-sbom.cdx.json`) cạnh báo cáo coverage trong artifact của mỗi lần chạy.
