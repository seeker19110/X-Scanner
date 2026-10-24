---
title: RUNBOOK — X-Scanner
updated: 2026-10-24
owner: chủ repo (@seeker19110)
last_drilled: chưa diễn tập
---

# RUNBOOK — X-Scanner app Android · cập nhật 2026-10-24 · chủ: @seeker19110

> WF-DOC-008, PM-HANDOVER-002/005, OPS-IR-001/010, SEC-SECRET-011, CMP-AUDIT-010. Mẫu: `.xtemplates/framework/templates/RUNBOOK.md`.
> Chỉ ghi **lệnh đang chạy được hôm nay**. Phần phát hành/rollback/ký số **chưa quyết định** và được đánh dấu như vậy;
> không có lệnh giả. Không ghi bí mật ở đây — chỉ ghi *nơi* lấy.
> `last_drilled: chưa diễn tập` — chưa mục nào được diễn tập theo lịch; xem §9.

## 0. Thông tin nhanh

| Mục | Giá trị |
|---|---|
| Sản phẩm | App Flutter offline `apps/mobile`, Android trước (ADR-0002); **chưa phát hành**, chưa có người dùng thật |
| Môi trường | không có server/staging/production; chỉ máy dev, CI GitHub Actions, emulator/thiết bị thử |
| Repo / nhánh chính | https://github.com/seeker19110/X-Scanner · `main` (ruleset: PR + check `Framework and Android app gate`, không bypass — `docs/ops/x-scanner-repository-guards.md`) |
| CI | workflow `Repository checks` (`.github/workflows/ci.yml`) |
| Dashboard / log / trace | không có (app không có telemetry theo thiết kế) |
| Kho secret | không có secret lúc chạy; CI không đọc secret riêng (chỉ `GITHUB_TOKEN` quyền `contents: read`, xem log run). Khoá ký phát hành: **chưa tồn tại** |
| Kênh người dùng | GitHub Issues; báo lỗ hổng: `SECURITY.md` |

## 1. Build và kiểm tra (chép-chạy)

Yêu cầu: Git, Bash ≥ 4, Python 3, jq, Flutter 3.47.7, Android SDK (compileSdk 36, Java ≥ 17) — `README.md`.

```bash
git config core.hooksPath scripts/githooks      # một lần mỗi checkout
bash scripts/dev-task.sh doctor
bash scripts/dev-task.sh gate                    # build → typecheck → lint → test; CI chạy đúng lệnh này
```

Lệnh từng bước (bản gốc ở `.claude/project-commands.sh`, bản sao ở `xt.yaml`; `scripts/check-xt-yaml-sync.sh` kiểm khớp):

```bash
bash scripts/dev-task.sh build       # flutter pub get --enforce-lockfile, flutter build apk --debug, kiểm manifest release
bash scripts/dev-task.sh typecheck   # flutter analyze --fatal-infos
bash scripts/dev-task.sh lint        # check-adoption --lint + dart format --set-exit-if-changed
bash scripts/dev-task.sh test        # repo checks + flutter test + :app:testDebugUnitTest
```

APK debug cục bộ: `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk` (sau `build`).

## 2. UAT trên emulator/thiết bị

Quy trình đầy đủ: `docs/ops/android-uat.md`. Tóm tắt lệnh:

```bash
gh run list --workflow "Repository checks" --branch main --limit 5   # chọn run xanh
gh run download <run-id> --dir uat-<run-id>                           # artifact giữ 14 ngày
cd uat-<run-id>/x-scanner-android-debug-* && sha256sum --check SHA256SUMS
adb install -r X-Scanner-debug.apk
```

Chỉ dùng tài liệu tổng hợp (`docs/compliance/test-data-policy.md`). Ghi bằng chứng vào hồ sơ `docs/work/<id>/`.

## 3. Phát hành, rollback, ký số — **chưa quyết định**

| Việc | Trạng thái | Ai quyết | Ghi chú |
|---|---|---|---|
| Kênh phát hành (Play, APK trực tiếp, F-Droid…) | chưa quyết định | chủ repo | `PROJECT.md` non-goal hiện tại: không tự phát hành |
| Ký số release | chưa có khoá; `android/app/build.gradle.kts` bản release vẫn dùng `signingConfigs.getByName("debug")` | chủ repo | phải đổi trước phát hành; khoá không bao giờ vào repo |
| Rollback | mobile **không rollback được** bản đã cài; chỉ phát hành bản sửa mới (version code tăng) | chủ repo | cần quy trình khi chọn kênh |
| Giấy phép sản phẩm | chưa chọn | chủ repo | `docs/RISKS.md` RK-005 |
| Checklist trước phát hành | `docs/ops/release-readiness.md` | — | chưa mục nào được tick cho app |

## 4. Dữ liệu người dùng: sao lưu và khôi phục

- Không có backup phía server (không có server). Sao lưu đám mây/chuyển thiết bị của Android **bị tắt có chủ đích**
  (`AndroidManifest.xml`, `data_extraction_rules.xml`; THREAT-MODEL TM-03).
- Bản quay lại duy nhất là `session.migrated*` sau migration P1 (ADR-0011); app không tự xoá. Khôi phục thủ công trên thiết bị thử:
  chỉ khi có quyền debug (`adb shell run-as org.xscanner.x_scanner ls files`) — **không dùng trên máy của người dùng thật**.
- Tài liệu hỏng được cách ly (`document.corrupt-*.json`), không bị xoá; chưa có UI khôi phục (`DEBT:` trong `document_store.dart`).

## 5. Xử lý sự cố (bản riêng cho X-Scanner)

Quy trình chung (các bước, mẫu post-mortem): `docs/ops/incident-response.md` (bản của khung, giữ nguyên). Mục này cụ thể hoá cho app.

**Ai được tuyên bố sự cố:** chủ repo; bất kỳ người đóng góp hay phiên AI nào thấy dấu hiệu đều mở issue template `incident`
(hoặc báo riêng theo `SECURITY.md` nếu là lỗ hổng) và **đề xuất** mức SEV — chủ repo xác nhận mức và là incident lead.
Chưa có người thứ hai; khi vắng chủ repo, sự cố SEV1/SEV2 chờ chủ repo (rủi ro RK-007).

| SEV | Định nghĩa | Ví dụ cụ thể của X-Scanner | Phản hồi đầu tiên | Xử lý |
|---|---|---|---|---|
| SEV1 | Mất/lộ dữ liệu người dùng, bí mật bị lộ, bản build bị cài cắm | (a) migration P1 xoá hoặc ghi sai byte ảnh gốc; (b) phát hiện app gửi dữ liệu ra mạng hoặc file xuất lộ ra ngoài sandbox; (c) khoá ký/ token bị commit; (d) dữ liệu thật của người dùng bị đưa vào repo/issue | ngay khi biết | dừng phân phối bản lỗi (nếu có), nhánh bảo mật bên dưới, post-mortem bắt buộc |
| SEV2 | Luồng chính hỏng, không mất dữ liệu | (a) không chụp/nhập được ảnh trên Android phổ biến; (b) xuất PDF lỗi với mọi tài liệu; (c) app crash khi mở thư viện; (d) `main` đỏ do gate hỏng làm không merge được | ≤ 1 ngày | sửa qua `fix/...` + gate; post-mortem bắt buộc |
| SEV3 | Lỗi ngoài luồng chính, có cách lách | (a) ảnh xem trước không tải, "Tải lại" được; (b) chữ dài tràn ở cỡ chữ lớn; (c) một định dạng ảnh hiếm báo "không đọc được" | ≤ 7 ngày | lên lịch |
| SEV4 | Không ảnh hưởng người dùng | (a) tài liệu/link sai; (b) cảnh báo Dependabot mức thấp cho dev dependency; (c) artifact UAT hết hạn 14 ngày | khi tiện | backlog |

### 5.1 Nhánh sự cố bảo mật (luôn SEV1)

Áp cho: lộ dữ liệu người dùng, lộ bí mật, xâm nhập repo/CI, APK bị thay. Làm **đủ cả ba** mục trước khi đóng:

1. **Bảo toàn chứng cứ:** không xoá/force-push ngay; ghi lại SHA commit, link run CI, thời điểm (UTC), ảnh chụp cảnh báo
   secret scanning, bản sao log run (`gh run view <id> --log > incident-<ngày>.log` lưu **ngoài repo** nếu có dữ liệu nhạy cảm).
2. **Thu hồi/xoay bí mật:** theo §6.
3. **Đánh giá nghĩa vụ thông báo:** nếu dữ liệu cá nhân của người dùng thật bị lộ, chủ repo liên hệ luật sư để xác định
   nghĩa vụ thông báo cơ quan/chủ thể theo Luật 91/2025/QH15, Nghị định 356/2025/NĐ-CP và GDPR (nguồn: `PROJECT.md` mục
   "Khung pháp lý"). **Đầu mối pháp lý: chưa có** — chủ repo chỉ định trước phát hành. Hiện app chưa phát hành nên chưa có
   người dùng thật để thông báo.

Ghi sự cố vào sổ `docs/ops/incidents/README.md`; post-mortem theo mẫu cuối `docs/ops/incident-response.md`, lưu tại
`docs/ops/incidents/<YYYY-MM-DD>-<slug>.md`.

## 6. Lộ bí mật — thu hồi và xoay (SEC-SECRET-011)

**Không chỉ xoá commit**: coi bí mật đã lộ là đã bị dùng. Repo đang bật GitHub secret scanning + push protection (đọc qua
`gh api repos/seeker19110/X-Scanner` ngày 2026-10-24); pre-commit chặn mẫu khoá (`scripts/_commit-guard.sh`).

| Loại | Có trong dự án hôm nay? | Thu hồi / xoay | Rà sử dụng trong khoảng lộ |
|---|---|---|---|
| GitHub personal access token / fine-grained token của người đóng góp | có thể (máy dev) | GitHub → Settings → Developer settings → Tokens → Revoke; tạo token mới phạm vi tối thiểu | Security log của tài khoản (`https://github.com/settings/security-log`) |
| `GITHUB_TOKEN` của Actions | có, tự hết hạn khi job xong | không cần xoay; nếu workflow bị sửa độc → revert qua PR, xem lại `permissions:` | log run liên quan |
| Repository/Actions secret | không thấy dùng trong `ci.yml` (2026-10-24); phiên AI không đọc được danh sách secret qua proxy | Settings → Secrets and variables → Actions → xoá/tạo lại | audit log repo |
| Khoá ký APK (keystore) / Play upload key | **chưa tồn tại** | khi có: keystore lộ = thay khoá theo quy trình của kênh phát hành (Play App Signing hỗ trợ đổi upload key); quy trình cụ thể chốt cùng quyết định §3 | lịch sử phát hành |
| SSH deploy key | không có | — | — |

Sau khi xoay: mở sự cố SEV1 (§5.1), post-mortem, thêm một hàng rào mới (mẫu regex, quét toàn lịch sử…).
Làm sạch lịch sử Git chỉ khi chủ repo duyệt (ruleset cấm force-push `main`).

## 7. Tài khoản và dịch vụ (không chứa secret)

| Dịch vụ | Dùng để | Chủ / quyền | Ghi chú |
|---|---|---|---|
| GitHub repo `seeker19110/X-Scanner` | mã, issue, PR, ruleset | @seeker19110 (owner, CODEOWNERS `*`) | public; private vulnerability reporting **đang tắt** (2026-10-24) |
| GitHub Actions | CI gate, artifact APK debug (14 ngày) | theo repo | runner `ubuntu-24.04` của GitHub |
| Dependabot | PR nâng `pub` và Actions hằng tuần | theo repo | `.github/dependabot.yml`, `docs/ops/dependency-updates.md` |
| pub.dev, Maven Central/Google Maven, storage.googleapis.com (Flutter SDK) | tải dependency/SDK | không cần tài khoản | ghim phiên bản + sha256 (ADR-0002) |
| Context7 (MCP) | tra tài liệu dev | tài khoản người dùng agent | chỉ tài liệu dev, không gửi scan/OCR (`AGENTS.md`) |
| Google Play Console / cửa hàng khác | — | **chưa có** | chờ §3 |
| Tên miền, email dự án | — | **chưa có** | — |

## 8. Thu hồi quyền khi người rời dự án (PM-HANDOVER-005)

Tạo `docs/handover/offboarding-<tên>.md` từ checklist dưới, tick **trong ngày rời**, ghi ngày và người làm:

- [ ] GitHub: gỡ khỏi collaborator/team của `seeker19110/X-Scanner` (Settings → Collaborators) — kiểm lại danh sách collaborator.
- [ ] Gỡ khỏi CODEOWNERS nếu có tên; cập nhật người duyệt bắt buộc trong ruleset nếu đổi.
- [ ] Thu hồi token/SSH key người đó dùng cho repo (nếu do dự án cấp); xoay mọi secret họ từng xem (§6).
- [ ] Đóng hoặc chuyển giao PR/issue/worktree/nhánh đang mở; chuyển hồ sơ `docs/work/<id>/` đang `working.md`.
- [ ] (Khi có) Play Console/cửa hàng: gỡ người dùng; khoá ký: xác nhận họ không giữ bản sao.
- [ ] (Khi có) tên miền, email, dịch vụ trả phí: đổi chủ/thu hồi.
- [ ] Thiết bị thử có dữ liệu tổng hợp: xoá dữ liệu app hoặc trả máy.
- [ ] Ghi một dòng vào `PROGRESS.md` mục "Quyết định".

Hôm nay dự án chỉ có một người (chủ repo); chưa có hồ sơ offboarding nào.

## 9. Việc định kỳ

| Việc | Nhịp | Lệnh/nơi | Chủ | Lần gần nhất |
|---|---|---|---|---|
| Nâng dependency patch/minor | tuần | Dependabot PR + `docs/ops/dependency-updates.md` | chủ repo / phiên AI theo luật trong file đó | theo lịch sử PR |
| Rà sổ rủi ro, threat model | mỗi lát hoặc trước phát hành | `docs/RISKS.md`, `docs/THREAT-MODEL.md` | chủ repo | 2026-10-24 (lập) |
| Diễn tập ứng phó sự cố | ≥ 1 lần/năm | `docs/ops/incidents/DRILL-TEMPLATE.md` | chủ repo | chưa diễn tập |
| Diễn tập lộ bí mật (giả lập, khoá giả) | ≥ 1 lần/năm | §6 | chủ repo | chưa diễn tập |
| Đo baseline tài nguyên | mỗi lát | `docs/perf/baseline-2026-10-24.md` | phiên AI | 2026-10-24 |

## 10. Lịch sử thay đổi runbook

| Ngày | Gì | Vì sao |
|---|---|---|
| 2026-10-24 | Bản đầu | thiếu runbook vận hành/bàn giao (blueprint WF-DOC-008, PM-HANDOVER-002/005, OPS-IR-*) |
