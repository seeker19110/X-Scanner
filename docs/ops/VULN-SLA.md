# Vulnerability SLA — X-Scanner

> Chính sách xử lý lỗ hổng dependency (OPS-MAINT-004, SEC-SUPPLY-006, BASE-DEP-004). File của dự án;
> `docs/ops/supply-chain.md` là file khung, không sửa. Ngoại lệ license/supply-chain khác: `supply-chain-exceptions.md`.

## Quét

- `.github/workflows/supply-chain.yml`: OSV-Scanner trên mọi PR và thứ Hai hằng tuần, đọc `apps/mobile/pubspec.lock`,
  `apps/mobile/android/app/gradle.lockfile`, `apps/mobile/android/settings-gradle.lockfile`, `scripts/requirements-ci.txt`.
  Cùng lịch tuần: `scripts/eol-check.py` (JDK, Gradle, Kotlin plugin, Flutter/Dart).
- PR còn qua `actions/dependency-review-action` trong cổng bắt buộc (`ci.yml`).
- Hai job tuần/PR này **không** phải required check: muốn chặn merge cần admin repo thêm vào ruleset.

## Hạn xử lý (tính từ ngày phát hiện)

| Mức (CVSS / OSV) | Thành phần có trong APK hoặc chạy trong gate | Chỉ là công cụ build/test không chạy trong gate |
| --- | --- | --- |
| Critical | 7 ngày | 30 ngày |
| High | 30 ngày | 30 ngày |
| Medium | 90 ngày | 90 ngày |
| Low / chưa chấm | lần nâng dependency kế tiếp | lần nâng dependency kế tiếp |

"Xử lý" = nâng lên bản đã vá (PR riêng qua `/deps-upgrade` hoặc Dependabot, theo `dependency-updates.md`), gỡ thành phần,
hoặc ghi ngoại lệ có hạn trong `osv-scanner.toml` (`reason`, người duyệt, `ignoreUntil`/`effectiveUntil` không quá
hạn ở bảng trên). Hết hạn thì OSV-Scanner tính lại finding và job đỏ; không gia hạn ngầm.

## Theo dõi

- Job tuần đỏ = việc mở: ghi vào hồ sơ `docs/work/<id>/` hoặc issue, kèm hạn theo bảng.
- Review tháng (chủ repo): số finding quá hạn phải bằng 0; ngoại lệ sắp hết hạn được quyết định trước ngày hết hạn.
- Ngoại lệ đang mở: EXC-OSV-1 (công cụ UTP nội bộ của AGP, hạn 2027-01-22) và EXC-OSV-2 (classpath build và lint của AGP,
  hạn 2026-11-23), cả hai chờ chủ repo xác nhận — chi tiết trong `osv-scanner.toml`.
