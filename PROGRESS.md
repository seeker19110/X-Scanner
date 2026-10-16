# X-Scanner — Tiến độ

Ngày cập nhật: 2026-10-16

## 2026-10-16: nghiên cứu nâng cấp

Hồ sơ: [2026-10-16-upgrade-research](docs/work/2026-10-16-upgrade-research/working.md).
Kết quả: [nghiên cứu từ code, repo sở hữu và nguồn chính thức](docs/research/2026-10-16-upgrade-research.md), đối chiếu trên `cda650f`.
Giai đoạn nghiên cứu chỉ thay tài liệu; chưa sửa app, dependency, settings hoặc bật XS-09 PR-4b. Khi nghiên cứu, full gate cục bộ thiếu Flutter; phần triển khai dưới đây đã cài toolchain để chạy lại.

## 2026-10-16: triển khai ưu tiên XS-04

Hồ sơ: [2026-10-16-android-uat-artifacts](docs/work/2026-10-16-android-uat-artifacts/working.md).
Theo yêu cầu triển khai tiếp của chủ repo: cài toolchain đúng pin, bổ sung APK UAT kiểm chứng được sau gate CI và [hướng dẫn AC-9](docs/ops/android-uat.md).
W-104b giữ mốc đủ tuổi từ 18/10 theo EX-1; chưa bật migration XS-09 PR-4b. Kết quả gate/PR cập nhật trong hồ sơ.
Gate cục bộ trên snapshot cố định PASS 4/4, Flutter 546/546, analyze sạch và format 55 file/0 thay đổi; AC-9 vẫn chờ UAT thật. PR đang chuẩn bị, chưa merge.

## 2026-10-11: lưu gợi ý và áp dụng bộ khung

Lưu nghiên cứu ở docs/research/2026-10-11-scanner-product-suggestions.md.
Nhập projects-template theo bản ghim; project brief, hướng dẫn agent và gate riêng.
Bằng chứng thực tế: GitHub Actions và docs/adoption/VERIFICATION.md khi có.

## Đã xong: P0 nền (2026-10-11)

Hồ sơ: `docs/work/2026-10-11-p0-foundation/done.md` · goal `docs/goals/2026-10-11-p0-foundation.md` (COMPLETE).
PR seeker19110/X-Scanner#1 (`cf620cf`), seeker19110/X-Scanner#2 (`37658f9`).
Stack chốt ở ADR-0002 (Flutter 3.47.7, Android trước); spec P0 nền Approved bởi chủ repo 2026-10-11.
App nền `apps/mobile` + lõi `PageQuad`/`ScanPage`: build APK debug, analyze, test chạy trong gate/CI (PR-2).

## Code xong, chờ UAT: P1 scan và xuất (2026-10-12)

Hồ sơ `docs/work/2026-10-11-p1-scan-export/working.md` · goal `docs/goals/2026-10-11-p1-scan-export.md` (gap: S5 = AC-9).
Spec P1 `docs/specs/2026-10-11-p1-scan-export.md` Approved bởi chủ repo (D1 camera hệ thống, D2 5 dependency,
D3 tắt backup, D4 UAT emulator do chủ repo chạy); ADR-0003. Chuẩn bị: #4 ghim Flutter, #5 spec (hồ sơ `2026-10-11-p1-readiness` done).
PR seeker19110/X-Scanner#6 (`a1549c5`), #7 (`df902de`), #8 (`1cc15e3`), #9 (`99027ba`), #10 (`6177e29`). AC-1..8 có test trên `main`.
Spike camera/ARCore depth trên thiết bị thật vẫn cần thiết bị.

## Chờ điều kiện: hoàn thiện P1 (`/completion`, 2026-10-12)

Hồ sơ `docs/work/2026-10-12-p1-completion/working.md` · kế hoạch `docs/ops/COMPLETION-PLAN.md` · audit `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`
(62 phát hiện sau ba lượt quét lại Pha 4: 3 Cao, 16 Trung, 43 Thấp; lần quét đầu 42). Nợ có chủ đích: mục "Phát hiện dời đợt sau" của kế hoạch; exception `docs/ops/supply-chain-exceptions.md`.
PR seeker19110/X-Scanner#11–#22, #24 (`0327ab7`) merged; quét lại hội tụ, Definition of Complete có bằng chứng.
W-104a hàng rào ảnh đầu vào (JPEG/PNG/WebP theo nội dung, trần 64 MiB, ngân sách 60 s có kill isolate; WebP động bị từ chối): merged #28 `474fa28`. WAITING: W-104b nâng `image` từ 2026-10-18 (EX-1); branch protection/dependency review (F-014, F-009) và UAT AC-9 cần chủ repo.
Dependabot (chủ repo duyệt 2026-10-13, F-009 phần version updates): `.github/dependabot.yml` cho pub + github-actions, cooldown 7 ngày; #47 `81cae78`, hồ sơ `docs/work/2026-10-13-dependabot/done.md`. Alerts/dependency review (EX-2) vẫn cần chủ repo bật. #48 `f188b14` (`image_picker` 1.2.4) merge sau kiểm; luật tự merge PR bot patch/minor: `docs/ops/dependency-updates.md`, #50 `cd1f53b`, hồ sơ `docs/work/2026-10-13-dependabot-merge-rule/done.md`.

## Chưa thực hiện

Chưa build iOS; chưa chạy chụp/xuất trên thiết bị (AC-9 chờ chủ repo), OCR, depth hoặc benchmark trên thiết bị.
Branch protection/ruleset và security gates theo stack chưa xác minh áp dụng.
Release, tự merge, dịch vụ ngoài và tác vụ định kỳ chưa bật. P0–P4 chỉ là gợi ý.

## Bằng chứng bộ khung

Doctor/gate đã chạy thành công: https://github.com/seeker19110/X-Scanner/actions/runs/38146360953
Chỉ xác nhận repository/framework, không xác nhận app.

## 2026-10-12: kế hoạch phát triển toàn diện

Hồ sơ: [2026-10-12-comprehensive-development-plan](docs/work/2026-10-12-comprehensive-development-plan/done.md).
Tài liệu: [Kế hoạch M0–M5 và nhánh depth](docs/plans/2026-10-12-comprehensive-development-plan.md), gồm 33 đầu việc XS-01..XS-33.
Chủ repo merge seeker19110/X-Scanner#23 (`ac2c435`); M0 trùng việc đang làm: XS-01 = W-502 (#22), XS-02 = W-504 (#24), XS-03 = W-104.
Kế hoạch giữ trạng thái DRAFT/đề xuất, các chỉ tiêu là mục tiêu chưa nghiệm thu; không thay thế trạng thái thực trong hồ sơ P1.
XS-08: spec [hợp đồng tài liệu, revision và xuất](docs/specs/2026-10-12-document-revision-export-contract.md) Approved 2026-10-12 theo ủy quyền §3d (#27 `8d7c356`), D-1 = A ([ADR-0004](docs/adr/0004-document-revision-export-contract.md): code đi cùng consumer đầu tiên); hồ sơ `docs/work/2026-10-12-xs08-document-contract-spec/done.md`. XS-09: spec [thư viện nhiều tài liệu + migration P1](docs/specs/2026-10-12-document-library-migration.md) (nháp #29 `ed06e58`, duyệt #30 `508f057`) Approved 2026-10-12 theo ủy quyền §3d **chỉ cho PR-1..PR-3** (không nối vào app, không chạm dữ liệu thật), D-2..D-5 chốt (D-5: giữ `session.migrated/`), [ADR-0011](docs/adr/0011-document-library-layout-and-migration.md); PR-4 (bật migration trên dữ liệu thật) chờ chủ repo; hồ sơ spec `docs/work/2026-10-12-xs09-document-library-spec/done.md`, code PR-1..PR-3 (#31 `c1bdcad`, #32 `8aa493e`, #33 `b77e926`) `docs/work/2026-10-12-xs09-document-library/done.md`. XS-13: spec [xem trước đã cắt + trình chỉnh góc](docs/specs/2026-10-12-preview-and-corner-editor.md) (F-026, F-032) Approved 2026-10-12 theo ủy quyền §3d (mức M, không đổi dữ liệu) (#35 `29e868f`); code PR-1 #36 `f7dc45c` (xem trước đã cắt), PR-2 #37 `9fbe2fd` (trình chỉnh góc); hồ sơ `docs/work/2026-10-12-xs13-preview-corner-editor/done.md`. XS-12a: spec [tác vụ xuất có tiến độ và huỷ](docs/specs/2026-10-12-export-progress-cancel.md) (F-033) Approved 2026-10-12 theo ủy quyền §3d (mức M, không đổi dữ liệu/định dạng); code PR-1 #40 `614b5b4` (tiến độ i/N, huỷ ở ranh giới trang); hồ sơ `docs/work/2026-10-12-xs12a-export-progress/done.md`. XS-09 PR-4 tách PR-4a (màn thư viện, chưa nối app — chủ repo duyệt 2026-10-12) / PR-4b (nối app + migration dữ liệu thật — chờ chủ repo); PR-4a #43 `26d3d39`, hồ sơ `docs/work/2026-10-12-xs09-pr4a-library-screen/done.md`.
