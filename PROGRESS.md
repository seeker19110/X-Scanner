# X-Scanner — Tiến độ

Ngày cập nhật: 2026-10-23

## 2026-10-23: merge #61, #57 và XS-09 PR-4b.2 nối thư viện vào app

Theo yêu cầu chủ repo ("merge các PR đang mở", "/autopilot"): [#61](https://github.com/seeker19110/X-Scanner/pull/61) squash `e21e2cb` và [#57](https://github.com/seeker19110/X-Scanner/pull/57) squash `4ce9a76`, cả hai sau CI bắt buộc xanh trên head cuối.
PR-4b.2 (hồ sơ [2026-10-18-xs09-pr4b-integration](docs/work/2026-10-18-xs09-pr4b-integration/done.md), contract C1–C6 trong spec XS-09): app mở vào Thư viện, migration P1 + khôi phục ảnh picker một lần khi khởi động, màn tài liệu trên `DocumentStore`, gỡ `SessionStore`. [#62](https://github.com/seeker19110/X-Scanner/pull/62) squash `4956064` sau CI [40039328590](https://github.com/seeker19110/X-Scanner/actions/runs/40039328590) SUCCESS; review độc lập tìm 2 lỗi (F1 `.part` sót, F2 mở lại khi đang lưu), đã sửa có RED trước khi merge.
`/completion` Pha 4 lần 4 (F-073..F-079, 0 Cao): đóng kế hoạch hoàn thiện P1 và 8 hồ sơ đã xong; goal P1 COMPLETE. **Đang chờ (WAITING, W-602):** chạy APK có thư viện trên emulator/thiết bị — container AI không có KVM. Chờ chủ repo: 5 điểm mở của #57 (gate chạy 2 lần mỗi commit, `@AGENTS.md` trong `CLAUDE.md` để dùng skill `autopilot`, …).

## 2026-10-23: nâng trải nghiệm và hiệu năng, giữ workflow P1

Hồ sơ: [scanner-experience](docs/work/2026-10-23-scanner-experience/done.md); [spec Approved theo §3d trước source](docs/specs/2026-10-23-scanner-experience.md). Phạm vi: theme/viewport/chữ lớn, xuất rõ ràng, chỉnh góc bằng chạm, scaled JPEG thumbnail và guard dispose/huỷ PDF. Giữ schema/bản gốc/dependency và app wiring P1. Local gate PASS: 808 Flutter +11 JVM, APK debug; benchmark host thumbnail giảm median20.27% thời gian/53.61% peak RSS. Đã merge qua [#61](https://github.com/seeker19110/X-Scanner/pull/61) `e21e2cb` sau CI [40031189744](https://github.com/seeker19110/X-Scanner/actions/runs/40031189744) xanh; chưa UAT thiết bị. Trạng thái và số đo chính xác nằm trong hồ sơ, không dùng checkpoint cũ làm bằng chứng cho bản nâng cấp.

## 2026-10-16: nghiên cứu nâng cấp

Hồ sơ: [2026-10-16-upgrade-research](docs/work/2026-10-16-upgrade-research/done.md).
Kết quả: [nghiên cứu từ code, repo sở hữu và nguồn chính thức](docs/research/2026-10-16-upgrade-research.md), đối chiếu trên `cda650f`.
Giai đoạn nghiên cứu chỉ thay tài liệu; chưa sửa app, dependency, settings hoặc bật XS-09 PR-4b. Khi nghiên cứu, full gate cục bộ thiếu Flutter; phần triển khai dưới đây đã cài toolchain để chạy lại.

## 2026-10-16: triển khai ưu tiên XS-04

Hồ sơ: [2026-10-16-android-uat-artifacts](docs/work/2026-10-16-android-uat-artifacts/done.md).
Theo yêu cầu triển khai tiếp của chủ repo: cài toolchain đúng pin, bổ sung APK UAT kiểm chứng được sau gate CI và [hướng dẫn AC-9](docs/ops/android-uat.md).
W-104b giữ mốc đủ tuổi từ 18/10 theo EX-1; chưa bật migration XS-09 PR-4b. Kết quả gate/PR cập nhật trong hồ sơ.
Gate cục bộ trên snapshot cố định và pre-commit PASS 4/4, Flutter 546/546, analyze sạch và format 55 file/0 thay đổi; AC-9 vẫn chờ UAT thật. [PR #52](https://github.com/seeker19110/X-Scanner/pull/52) đã squash merge `f753933` sau review độc lập, local gate và CI head cuối xanh (run 38921846662).

## 2026-10-16: triển khai XS-05 sau review/merge #52

Hồ sơ: [2026-10-16-xs05-repository-guards](docs/work/2026-10-16-xs05-repository-guards/done.md).
Ruleset [25250032](https://github.com/seeker19110/X-Scanner/rules/25250032) đã active, main protected=true, 5 rule khớp JSON, không bypass; required check đúng app GitHub Actions. Alerts bật, graph 86/86 Pub khớp lockfile; [PR #53](https://github.com/seeker19110/X-Scanner/pull/53) có dependency review step SUCCESS và negative control CI cancelled→BLOCKED. PR #53 đã squash merge `3f49039`; [CI cuối PR](https://github.com/seeker19110/X-Scanner/actions/runs/38930758793) trên head `51af8e0` và [CI trên main](https://github.com/seeker19110/X-Scanner/actions/runs/38931930723) đều SUCCESS. Workflow đã vào main và EX-2 đã đóng. [Bằng chứng native](docs/ops/evidence/2026-10-16-xs05-native.json). Không bật auto-merge/release hoặc migration PR-4b.

## 2026-10-16: XS-06a corpus và baseline host

Hồ sơ: [2026-10-16-xs06-host-baseline](docs/work/2026-10-16-xs06-host-baseline/done.md).
Tooling nội bộ dùng ảnh hình học tổng hợp/checksum và core thumbnail/render/PDF hiện có; không đổi app/dependency. [PR #54](https://github.com/seeker19110/X-Scanner/pull/54) có 20 mẫu host AOT thành công trên source935083e; đã review/sửa ca filename Windows và squash merge `8b99c51` sau fullgate/hook4/4,592/592 và [CI cuối](https://github.com/seeker19110/X-Scanner/actions/runs/38980161272) SUCCESS trên95dad0d. Corpus thiết bị/120 trang/OCR và target latency/RAM vẫn chưa nghiệm thu; W-104b chờ 18/10, AC-9 cần thiết bị.

## 2026-10-17: XS-07a pixel toàn khung và chi phí render

Hồ sơ: [2026-10-17-xs07a-full-frame-render](docs/work/2026-10-17-xs07a-full-frame-render/done.md).
Sau review/merge54, [spec XS-07a](docs/specs/2026-10-17-xs07a-full-frame-render.md) Approved theo ủy quyền §3d: sửa lệch pixel khi rectify fullFrame không resize bằng copy byte vào output độc lập. [PR #55](https://github.com/seeker19110/X-Scanner/pull/55) đã review độc lập, gate/hook607/607 và [CI cuối](https://github.com/seeker19110/X-Scanner/actions/runs/38993226283) SUCCESS trên6a3d648; squash merge `9d44fc9`. Main có tree khớp bản review; hồ sơ root/worker chỉ chốt Done sau actual merge. Giữ40mẫu lịch sử và10mẫu đối chứng mới, không suy ra hiệu năng thiết bị. EX1/AC9/PR4b vẫn mở.

## 2026-10-17: XS-07b giữ alpha khi cắt và xoay ảnh xám

Hồ sơ: [2026-10-17-xs07b-gray-alpha-render](docs/work/2026-10-17-xs07b-gray-alpha-render/done.md).
Sau khi PR55 merge, spec XS-07b được duyệt theo §3d để sửa lỗi hai kênh có trước55. Giữ21 regression độc lập và bằng chứng RED15 lỗi pixel. [PR56](https://github.com/seeker19110/X-Scanner/pull/56) đã được review mới ngày18/10, không còn finding; gate/hook628/628, AOT12 và [CI39086812105](https://github.com/seeker19110/X-Scanner/actions/runs/39086812105) SUCCESS trêncc5bb44. Squash merge561a5cf; main/tree khớp bản review. Hồ sơ root/worker chỉ chốt Done sau actual merge.

## 2026-10-18: W104b và tiếp tục hoàn thiện

Hồ sơ: [W104b](docs/work/2026-10-18-w104b-decoder-upgrade/done.md); [goal tiếp tục](docs/goals/2026-10-18-upgrade-completion.md). Sau khi56 merge, root duyệt spec nhỏ trước source: pin `image 4.12.0` đủ7ngày với hash chính thức; lock chỉ đổi `image`, giữ `archive 4.5.1`. Truyền cap theo từng decoder trước parse, kiểm header/output và giữ hợp đồng nullable của `imageSizeOf`. Hai lượt TDD phân biệt dependency với wiring: RED trên4.10.1, rồi RED sau pin/trước sửa core; fixed targeted240/240. Giữ21 regression gray-alpha, bỏ workaround đã được upstream sửa. [PR58](https://github.com/seeker19110/X-Scanner/pull/58) đã mergec50670a sau rootgate/hook639+639, CI39088067553 SUCCESS, AOT12/CLI và nativeproof; main/tree khớp reviewedheadb227825. F004/EX1 đã đóng bằng actualmerge.

Chủ repo ngày18/10 xác nhận “Duyệt PR-4b; P1 chưa phân phối”. Thiết kế tiếp theo giữ copy/verify/rollback và bổ sung ownership của picker, vòng đời màn tài liệu theo AC13; không duyệt OCR/depth/release hoặc toàn roadmap. UAT Android36 chưa chạy: software boot bị guard dừng vì runtime ép2560MiB làm RAM cạn; chưa cài APK. Android24 đúng1024MiB cũng bị memoryguard dừng trước boot; chưa cài APK/UAT. Owner18Oct giao tự cài môi trường Android có tăng tốc; đang chuẩn bị Windows riêng, không đổi quyền KVM hoặc dừng process người dùng.

## 2026-10-11: lưu gợi ý và áp dụng bộ khung

Lưu nghiên cứu ở docs/research/2026-10-11-scanner-product-suggestions.md.
Nhập projects-template theo bản ghim; project brief, hướng dẫn agent và gate riêng.
Bằng chứng thực tế: GitHub Actions và docs/adoption/VERIFICATION.md khi có.

## Đã xong: P0 nền (2026-10-11)

Hồ sơ: `docs/work/2026-10-11-p0-foundation/done.md` · goal `docs/goals/2026-10-11-p0-foundation.md` (COMPLETE).
PR seeker19110/X-Scanner#1 (`cf620cf`), seeker19110/X-Scanner#2 (`37658f9`).
Stack chốt ở ADR-0002 (Flutter 3.47.7, Android trước); spec P0 nền Approved bởi chủ repo 2026-10-11.
App nền `apps/mobile` + lõi `PageQuad`/`ScanPage`: build APK debug, analyze, test chạy trong gate/CI (PR-2).

## Đã xong: P1 scan và xuất (2026-10-12; AC-9 nghiệm thu 18/10)

Hồ sơ `docs/work/2026-10-11-p1-scan-export/done.md` · goal `docs/goals/2026-10-11-p1-scan-export.md` (COMPLETE 23/10).
Spec P1 `docs/specs/2026-10-11-p1-scan-export.md` Approved bởi chủ repo (D1 camera hệ thống, D2 5 dependency,
D3 tắt backup, D4 UAT emulator do chủ repo chạy); ADR-0003. Chuẩn bị: #4 ghim Flutter, #5 spec (hồ sơ `2026-10-11-p1-readiness` done).
PR seeker19110/X-Scanner#6 (`a1549c5`), #7 (`df902de`), #8 (`1cc15e3`), #9 (`99027ba`), #10 (`6177e29`). AC-1..8 có test trên `main`.
Spike camera/ARCore depth trên thiết bị thật vẫn cần thiết bị.

## Đã xong: hoàn thiện P1 (`/completion`, 2026-10-12 → đóng 2026-10-23)

Hồ sơ `docs/work/2026-10-12-p1-completion/done.md` · kế hoạch `docs/ops/COMPLETION-PLAN.md` · audit `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`
(62 phát hiện sau ba lượt quét lại Pha 4: 3 Cao, 16 Trung, 43 Thấp; lần quét đầu 42). Nợ có chủ đích: mục "Phát hiện dời đợt sau" của kế hoạch; exception `docs/ops/supply-chain-exceptions.md`.
PR seeker19110/X-Scanner#11–#22, #24 (`0327ab7`) merged; quét lại hội tụ, Definition of Complete có bằng chứng.
W-104a hàng rào ảnh đầu vào (JPEG/PNG/WebP theo nội dung, trần 64 MiB, ngân sách 60 s có kill isolate; WebP động bị từ chối): merged #28 `474fa28`. W-104b/EX1 đã đóng ở PR58/c50670a18Oct. AC-9 nghiệm thu 18/10 (báo cáo merged #60); F-014 native đã kiểm ở XS-05, F-009 alerts/graph/review đã kiểm sau merge PR #53, EX-2 đóng16/10.
Dependabot (chủ repo duyệt 2026-10-13, F-009 phần version updates): `.github/dependabot.yml` cho pub + github-actions, cooldown 7 ngày; #47 `81cae78`, hồ sơ `docs/work/2026-10-13-dependabot/done.md`. Alerts/graph đã bật ở XS-05; workflow review đã merge PR #53, EX-2 đóng16/10. #48 `f188b14` (`image_picker` 1.2.4) merge sau kiểm; luật tự merge PR bot patch/minor: `docs/ops/dependency-updates.md`, #50 `cd1f53b`, hồ sơ `docs/work/2026-10-13-dependabot-merge-rule/done.md`.

## Chưa thực hiện

Chưa build iOS; chưa chạy bản có thư viện (#62) trên emulator/thiết bị; chưa camera vật lý, OCR, depth hoặc benchmark trên thiết bị (P1 AC-9 đã chạy trên emulator 18/10).
Ruleset/alerts native đã được kiểm ở XS-05; CI dependency review và phép kiểm trạng thái chặn merge xem hồ sơ XS-05. Không suy ra full security audit từ các controls này.
Release, auto-merge, cloud ứng dụng và tác vụ định kỳ chưa bật. P0–P4 chỉ là gợi ý.

## Bằng chứng bộ khung

Doctor/gate đã chạy thành công: https://github.com/seeker19110/X-Scanner/actions/runs/38146360953
Chỉ xác nhận repository/framework, không xác nhận app.

## 2026-10-12: kế hoạch phát triển toàn diện

Hồ sơ: [2026-10-12-comprehensive-development-plan](docs/work/2026-10-12-comprehensive-development-plan/done.md).
Tài liệu: [Kế hoạch M0–M5 và nhánh depth](docs/plans/2026-10-12-comprehensive-development-plan.md), gồm 33 đầu việc XS-01..XS-33.
Chủ repo merge seeker19110/X-Scanner#23 (`ac2c435`); M0 trùng việc đang làm: XS-01 = W-502 (#22), XS-02 = W-504 (#24), XS-03 = W-104.
Kế hoạch giữ trạng thái DRAFT/đề xuất, các chỉ tiêu là mục tiêu chưa nghiệm thu; không thay thế trạng thái thực trong hồ sơ P1.
XS-08: spec [hợp đồng tài liệu, revision và xuất](docs/specs/2026-10-12-document-revision-export-contract.md) Approved 2026-10-12 theo ủy quyền §3d (#27 `8d7c356`), D-1 = A ([ADR-0004](docs/adr/0004-document-revision-export-contract.md): code đi cùng consumer đầu tiên); hồ sơ `docs/work/2026-10-12-xs08-document-contract-spec/done.md`. XS-09: spec [thư viện nhiều tài liệu + migration P1](docs/specs/2026-10-12-document-library-migration.md) (nháp #29 `ed06e58`, duyệt #30 `508f057`) Approved 2026-10-12 theo ủy quyền §3d **chỉ cho PR-1..PR-3** (không nối vào app, không chạm dữ liệu thật), D-2..D-5 chốt (D-5: giữ `session.migrated/`), [ADR-0011](docs/adr/0011-document-library-layout-and-migration.md); PR-4 (bật migration trên dữ liệu thật) chờ chủ repo; hồ sơ spec `docs/work/2026-10-12-xs09-document-library-spec/done.md`, code PR-1..PR-3 (#31 `c1bdcad`, #32 `8aa493e`, #33 `b77e926`) `docs/work/2026-10-12-xs09-document-library/done.md`. XS-13: spec [xem trước đã cắt + trình chỉnh góc](docs/specs/2026-10-12-preview-and-corner-editor.md) (F-026, F-032) Approved 2026-10-12 theo ủy quyền §3d (mức M, không đổi dữ liệu) (#35 `29e868f`); code PR-1 #36 `f7dc45c` (xem trước đã cắt), PR-2 #37 `9fbe2fd` (trình chỉnh góc); hồ sơ `docs/work/2026-10-12-xs13-preview-corner-editor/done.md`. XS-12a: spec [tác vụ xuất có tiến độ và huỷ](docs/specs/2026-10-12-export-progress-cancel.md) (F-033) Approved 2026-10-12 theo ủy quyền §3d (mức M, không đổi dữ liệu/định dạng); code PR-1 #40 `614b5b4` (tiến độ i/N, huỷ ở ranh giới trang); hồ sơ `docs/work/2026-10-12-xs12a-export-progress/done.md`. XS-09 PR-4 tách PR-4a (màn thư viện, chưa nối app — chủ repo duyệt 2026-10-12) / PR-4b (nối app + migration dữ liệu thật — chờ chủ repo); PR-4a #43 `26d3d39`, hồ sơ `docs/work/2026-10-12-xs09-pr4a-library-screen/done.md`.


## 2026-10-18: XS09 PR4b capacity foundation

Hồ sơ [capacity](docs/work/2026-10-18-xs09-android-capacity/done.md); spec Approved trước source theo ownerPR4b18Oct. Leaf Android dùng StatFs/filesDir và channel không nhận path, kiểm int/0/64bit/lỗi sanitize; JUnit chỉ test dependency, JVM tests được nối vào dispatcher. Mã và targeted tests sẵn sàng; root đã reconcileactualmainc50670a, fullgate/CI/merge đang thực hiện. App vẫn dùng bố cục P1 tới slice tích hợp; giữcopy/verify/session.migrated. Pending-picker ownership cần contract trước app switch.


## 2026-10-18: capacity đã merge, AC9 đã có bằng chứng, pending-original đang tích hợp

[Capacity Done](docs/work/2026-10-18-xs09-android-capacity/done.md): [PR59](https://github.com/seeker19110/X-Scanner/pull/59) đã merge209c808 sau review29files/findings[], gate/hook4/4 với658Flutter+11freshJVM và CI39121270944 SUCCESS/native/treeproof. Adapter chưa được app gọi, không suy runtime từ mocks/JVM.

[UAT AC9](docs/work/2026-10-18-p1-android-uat/done.md): WindowsWHPX/API36 đã boot và chạy exactCI58APK; ba lần camera→crop/rotate/reorder→PDF/share→Librera đủ3trang. Root nghiệm thu theo§3d, agent thực hiện, không ghi chủ repo tự chạy. Kiểm bản gốc trước/sau bằng byte/hash, cancel/restart UI/manifest, Dark/Light và offline export/viewer. [Proof](docs/ops/evidence/p1-android-uat-2026-10-18/ac9.json); report/reconciliation đang vào PR tiếp. Các đoạn chờ AC9/môi trường phía trên là checkpoint lịch sử trước bằng chứng18Oct, không còn blocker của narrowAC9. Chưa physicalcamera/OCR/depth/iOS/release.

[Pending preservation](docs/work/2026-10-18-xs09-picker-preservation/done.md): spec Approved trước behavior, rootactualRED86case trướclogic; durableowner/journal/copy/retainedrejection leaf đangreview trênmain209c808. Chưa nối app/library/migration. XS09AC13 và parentgoal còn ACTIVE; bước tiếp là mergeleaf đủgates rồi tích hợp app bằng contract/test, giữsession.migrated và synthetic3pageAVD cho UATmigration.
