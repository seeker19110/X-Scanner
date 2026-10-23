# Công việc: Nâng chất lượng trải nghiệm và hiệu năng X-Scanner

- Work ID: 2026-10-23-scanner-experience
- Yêu cầu / outcome: Chủ repo yêu cầu nâng chất lượng, hiệu năng, UI đẹp/UX dễ và giữ toàn bộ tính năng đang có.
- Trạng thái: Ready for local review; research/spec/PLAN được phiên chính duyệt theo §3d trước source; chưa merge.
- Chủ trì / writer: Phiên chính; ba audit chỉ đọc; T2 và T3 giao worker tuần tự, một source writer tại một thời điểm.
- Mức rủi ro / số PR: M; một outcome/PR nâng trải nghiệm workflow hiện có, không schema/dependency/migration mới.
- Scope / non-goal: Theo spec; không kích hoạt library/OCR/depth/cloud; không merge/deploy.
- Spec: `docs/specs/2026-10-23-scanner-experience.md`; research cùng ngày; `PLAN.md` trong thư mục này.
- Nhánh / base SHA: `feat/scanner-experience` từ `30b47dadf4323d5d4744c78c0f57ea1c26cfc170`; Git read thực tế xác nhận upstream main cùng SHA ngày 23/10.

## Kế hoạch và phân công

PLAN check đã chạy, exit 0: 3 việc, đủ trường/không placeholder/phụ thuộc hợp lệ/mỗi việc thuộc PR-1. T1 root: lifecycle và cancellation. T2 worker hiệu năng chỉ 3 file imaging/tests, đã freeze. T3 worker UI chỉ theme/review/editor và test tương ứng; root không sửa source đồng thời. Root giữ review, benchmark, tài liệu và full gate sau tích hợp.

## Quyết định và bằng chứng

- Giữ cấu trúc P1 · loại kích hoạt library/migration qua UI · bậc 1: bảo toàn dữ liệu và hợp đồng hiện tại; công việc XS09 có spec/hồ sơ riêng.
- Dùng Material 3/ColorScheme/dependency đã cài · loại thêm UI kit/font/network dependency · bậc 2: ít dependency/bảo trì, đủ typography/contrast/48dp.
- Scaled JPEG thumbnail với original-header cap và full-resolution export mặc định · loại nới cap ảnh hoặc đổi renderer xuất · bậc 1 rồi 2: đúng/an toàn và tiết kiệm RAM.
- Guard trước khi bắt đầu operation sau dispose · loại huỷ ngang thao tác đang lưu · bậc 1: không mở picker/share muộn nhưng giữ commit đang chạy hoàn tất an toàn.
- Huỷ trước PDF packaging · loại chỉ kiểm sau ghi PDF · bậc 1: cancellation không bị biến thành packaging failure.
- Chạm chọn góc + dùng lại _nudge/history · loại hệ chỉnh góc riêng · bậc 2: cùng hình học/validate/undo.

### T1 — bằng chứng thực thi

3 test assertion RED trước source: queued picker/export sau dispose, operation mới sau dispose, huỷ ở final progress; log `/workspace/.x-scanner/experience/safety-red-actual.log`. Hai lượt đầu runner bị sandbox chặn loopback trước test; không tính là RED. Sau phép chạy có loopback và trước source, 3 assertion lỗi đúng hành vi. Sau guard nhỏ, toàn bộ controller/exporter suites **75/75 PASS**, log `safety-green.log`.

### T2 — bằng chứng thực thi

Optional `decodeOriented(jpegScale: 1)` scaffolding compile được nhưng chưa dùng scale: test raster scale2 expected(17,33), actual(33,65), assertion RED thật trong `jpeg-red.log`. Sau nối scale, hai imaging/security suites **113/113 PASS**, `jpeg-green.log`. Bao gồm 8 hướng EXIF, cạnh lẻ/ảnh dài/ảnh nhỏ, original cap, invalid scale/maxSide, progressive/truncated JPEG và giữ original bytes. Không đổi dependency/lock/cap.

### Review imaging độc lập

Review phát hiện raster gần vuông làm tròn thành vuông có thể đảo tỷ lệ (65×72, maxSide8); 16 regression hướng có **8 assertion RED** (`jpeg-near-square-red.log`). Bản đọc EXIF riêng sửa ca thường nhưng review tiếp phát hiện first-APP1 của utility khác effective-APP1 decoder. Hai fixture conflicting EXIF **2 assertion RED** (`jpeg-duplicate-exif-red.log`). Bản cuối bỏ đọc EXIF riêng; giảm scale đến khi raster phân biệt trục, giữ long/short target từ header và lấy hướng thực tế của decoder. Không double pixel decode. Phiên chính duyệt ngoại lệ scale correctness trong spec trước sửa. Toàn bộ imaging/security **147/147 PASS** (`jpeg-duplicate-exif-green.log`); malformed/cyclic EXIF, 8 hướng, cap/export vẫn PASS. Reviewer chỉ đọc xác nhận hai finding đã giải quyết, không blocker khác.

### Benchmark host / fidelity — bản cuối sau review

Binary before compile từ core/tool/lock chưa sửa của base SHA; after từ working tree sau bản sửa near-square/duplicate-EXIF cuối, ghi hash source và binary. 5 process mới mỗi phiên bản, thứ tự before/after luân phiên, ảnh tổng hợp 4000×3000 một trang; không chạy gate/test/compiler khác trong cửa sổ đo. Raw10sample: `/workspace/.x-scanner/experience/thumbnail-accepted-samples.jsonl`; metadata đầy đủ cùng raw được lưu trong `host-thumbnail-benchmark.json` của hồ sơ. Hai chuỗi tạm trước review (`thumbnail-samples.jsonl`, `thumbnail-final-samples.jsonl`) giữ riêng, không trộn mẫu vào số đo cuối. CLI nhận base SHA; metadata phân biệt rõ after là working tree theo hash, không giả là source base đã commit.

| Chỉ số | Before min / median / max | After min / median / max |
| --- | --- | --- |
| Thumbnail ms | 569.492 / 578.921 / 675.108 | 421.384 / 461.563 / 524.267 |
| Peak process RSS bytes | 48275456 / 48443392 / 48549888 | 22405120 / 22474752 / 22536192 |

Median giảm **20.27%** thời gian và **53.61%** RSS. Đây là host AOT/synthetic, không p95, cold disk, UI frame, real document/camera/device hoặc tài liệu dài.

Probe riêng bằng ảnh chữ/đường kẻ/màu tổng hợp: cả hai preview1024×768; RGB MSE84.1896, PSNR28.878dB so với đường full-decode→average-resize→JPEG85. Xem hai PNG thực tế xác nhận bố cục/hướng/chữ của fixture còn đọc được; byte/pixel thumbnail thay đổi do reduced decode, không gọi pixel-identical hoặc nghiệm thu chất lượng tài liệu thật. File export tiếp tục giải mã bản gốc full resolution. Probe và ảnh ở `/workspace/.x-scanner/experience/preview-*`.

### T3

Worker đã chạy 6 regression RED có assertion trước source: thiếu summary/export/tap controls và overflow ở landscape/200% text; thêm 2 regression phase PDF/finalizing RED thật. `ui-red.log`, `ui-phase-red.log`; lượt filter sai không chạy test không tính là RED. Editor **22/22 PASS**, toàn bộ UI/app **163/163 PASS**, analyze **0 issues** (`ui-editor-green.log`, `ui-green.log`, `ui-analyze.log`). Drag regression do thêm tap đã được sửa bằng DragStartBehavior.down, giữ assertion kéo cũ.

Root đã xem ảnh Dark/Light/crop bằng fixture tài liệu tự tạo, không dữ liệu thật. Harness ngoài repo dùng production theme/screens và controller giả lập, tải font hệ thống, precache provider ảnh thật, xác nhận RawImage đã decode; **1/1 PASS**, `ui-static-preview.log`. Ảnh `scanner-empty-dark.png`, `scanner-document-dark.png`, `scanner-document-light.png`, `scanner-editor-light.png` dưới `/workspace/.x-scanner/experience/`. Các lượt harness IO trước bị fake-async treo/đã dừng không tính PASS; đây là ảnh widget, không nghiệm thu camera/share/device.

## Lần thử / blocker

- Sandbox mới chặn socket loopback của Flutter; thực thi test bằng scope có loopback, TLS/checksum không bị tắt.
- `gh api` dùng auth sẵn có bị Forbidden trên api.github.com; không yêu cầu token mới. Đã lưu thêm hostname vào draft network, giữ storage.googleapis.com. Draft save không chứng minh API/runtime đã được cập nhật. Local code/test không bị chặn; PR cần kiểm lại sau meaningful config change.
- Không có KVM/device được cấu hình; không suy kết quả widget/JVM thành UAT mới.

## Bàn giao / bước tiếp theo

Tất cả source đã freeze; root và reviewer đã đọc diff, xem ảnh UI, giải quyết findings imaging, đo lại bản cuối. Full gate đã PASS và JUnit mới được xác minh. Tiếp: commit qua hook chuẩn và bàn giao nhánh; PR bị chặn bởi API network chưa được publish. Cập nhật CODEMAP/FEATURE-MAP/TRAPS/PROGRESS cùng thay đổi; không commit/PR khi gate đỏ. Không Done trước actual merge; quyền merge/deploy chưa được cấp bởi yêu cầu này.

## Nghiệm thu cuối

`source /workspace/.x-scanner/env.sh && bash scripts/dev-task.sh doctor`: READY đúng 4 gate. `bash scripts/dev-task.sh gate`: **PASS**, exit 0; log `/workspace/.x-scanner/experience/final-gate-formatted.log`. Lượt đầu dừng đúng tại lint vì controller chưa format; đã áp Dart formatter (chỉ định dạng), rồi chạy lại toàn gate.

- Build APK debug thành công, release merged-manifest guard PASS; không thêm quyền/backup/exported component.
- Analyze **0 issues**; adoption lint **47 checks PASS**; format **62 files, 0 changed**.
- Adoption **7/7**, manifest self-tests **10/10**, toàn bộ hook/guard tests PASS. Dòng FAIL missing-manifest là negative self-test có chủ đích, không phải lỗi gate.
- Flutter **808/808 PASS** (baseline 754, thêm 54 regression); không skip/lỗi. JVM `StorageHandlerTest` **11/11 PASS**, skipped/errors/failures0; XML thực tế timestamp `2026-10-23T13:16:47.016Z`, file mtime hiện tại, lệnh Gradle `--rerun`.
- APK `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`: 190581193 bytes, SHA256 `72fea4dbf57114060661121e8a6e8eab3afa2711c29e2133dc16729b298401f0`. Đây là debug artifact, không release signing/publish.
- `git diff --check` PASS; dependency/lock/schema/wiring không đổi. Không fixture/log tài liệu thật.

Báo cáo trước commit: Build ✅ | Type ✅ (0 lỗi) | Lint ✅ | Format ✅ | Test ✅ (808 Flutter +11 JVM). Tái hiện RED ✅; logic mới RED-trước ✅; golden n-a. Review diff ✅; không bí mật/rác ✅; AC1–8 có bằng chứng local ✅. DoD code/local gates ✅; PR/CI/merge và UAT mới chưa thực hiện. Rủi ro còn lại: số đo host/synthetic 5 mẫu, ảnh thumbnail lossy khác pixel; không suy thành p95/device/100-page/export-quality UAT. Rollback revert code, không migration.

Không có PR/merge mới tại thời điểm ghi hồ sơ; GitHub API Forbidden, draft đã thêm api.github.com nhưng runtime policy chưa áp cấu hình đó. Giữ working.md; không đánh Done trước merge. Bằng chứng cloud install/startup được lưu ở bản nháp môi trường, không commit cache/toolchain.

## Checkpoint /autopilot — 2026-10-24

- Product commit: `2a3220cafae4f2e72e6dac492083ecada61a7ba1` đã push lên `feat/scanner-experience`; đọc remote lần này xác nhận đúng SHA, upstream main vẫn `30b47dadf4323d5d4744c78c0f57ea1c26cfc170`. Working tree sạch khi tiếp tục.
- Hook commit đã chạy lại toàn gate và PASS: `/workspace/.x-scanner/experience/commit-gate.log`; Flutter **808/808**, JVM **11/11**, skipped/errors/failures0. XML của lượt hook có timestamp UTC `2026-10-23T13:19:29.811Z`. Hash source của benchmark vẫn khớp product commit.
- Audit chỉ đọc lần tiếp tục không thấy coding blocker; mô tả PR đã lưu bền vững trong `pull-request.md` cùng thư mục hồ sơ, đủ Work ID/spec/validation/risk và phân biệt local gate với CI/UAT còn chờ.
- Gate của lượt /autopilot cũng **PASS**, exit0 (`/workspace/.x-scanner/experience/autopilot-gate.log`): build/manifest/analyze/format/adoption/hooks xanh, **808 Flutter +11 JVM**. Không sửa source; hash benchmark vẫn khớp. Đọc Git pull refs không thấy head nào trùng product commit; chưa có bằng chứng PR/CI mới.
- Trạng thái: **WAITING — áp dụng cấu hình mạng để tạo draft PR**. Runtime vẫn spec revision1, danh sách hostname hiện tại chưa có api.github.com; draft revision7 đã chứa api.github.com và storage.googleapis.com. Retained network diagnostics chưa có record. Công cụ môi trường hiện chỉ lưu draft, không có thao tác publish/apply runtime.
- Quyết định: giữ nhánh đã kiểm chứng và chờ runtime nhận cấu hình · loại lặp lại cùng request API khi policy chưa đổi · bậc2: giảm thao tác thừa, giữ nguyên bằng chứng và giới hạn quyền. Không sửa source hoặc đổi số đo hiệu năng trong checkpoint này.
- Tiếp theo: publish bản nháp cấu hình môi trường; xác nhận runtime đã nhận hostname; dùng auth GitHub sẵn có để đọc PR đang mở/WIP, tạo draft PR bằng `docs/work/2026-10-23-scanner-experience/pull-request.md` và theo dõi CI của đúng head. Chưa có PR nên chưa có link/CI/merge mới; tiếp tục giữ working.md.
