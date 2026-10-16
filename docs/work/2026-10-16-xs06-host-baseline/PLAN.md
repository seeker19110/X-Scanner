# PLAN.md — XS-06a corpus tổng hợp và baseline host

## Bối cảnh & mục tiêu
Sau PR #53 merge, XS-06 là việc tiếp có thể làm: W-104b chờ 18/10, AC-9 chưa có thiết bị. Tooling mức S cho corpus tái lập và baseline thumbnail/render/PDF dùng core production trước XS-07/11; không đổi app, decoder, engine hoặc dữ liệu thật. Hồ sơ docs/work/2026-10-16-xs06-host-baseline/working.md.

## Đặc tả dùng chung
- Schema/DDL: không đổi app lib, SDK, dependency, lockfile, schema hoặc CI. Manifest version1: generator/seed cố định, width/height/pages, tên JPEG theo index và SHA256 từng file; không timestamp/path cá nhân. Trang hình học tổng hợp có marker khác nhau, chưa là corpus chữ Việt/OCR.
- API: CLI Dart thuần scanner_benchmark.dart: generate NEW_DIR WIDTH HEIGHT PAGES; thumbnail CORPUS_DIR APP_SHA; render-pdf CORPUS_DIR APP_SHA. SHA đúng40hex; width/height dương, pixels<=50000000, pages1..100, file<=64MiB. generate từ chối directory đã tồn tại; đo chỉ nhận đúng generator/schema/checksum; không sửa originals/manifest. JSON stdout measure có schema, appSha, fixtureId/hash, width/height/pageCount, host/OS/runtime, buildMode host-dart, core function IDs và lockfile SHA256, recipeRevision0, stage, durationMs và render/package/write time, peakProcessRssBytes/currentRssBytes, outputBytes, cancelLatencyMs null, outcome. Chưa đo để null, không log privatepaths/OCR/exceptioncontents.
- Quy ước: Stopwatch/ProcessInfo, sha256sum Linux có sẵn (không thêm/import dependency bắc cầu). Dùng thumbnail/renderPage từ page_render.dart và buildPdf từ pdf_export.dart; không PageExporter vì Flutter foundation ngăn Dart AOT. PDF: render tuần tự fullres, giữ mỗi JPEG buffer độc lập, Isolate.run buildPdf như app, write temp do tool sở hữu rồi cleanup chỉ temp đó. Generation chạy riêng; mỗi measure process mới, maxRss là highwater lifetime/case gồm setup, không peak từng pha/heap/PSS Android. Lỗi thoát khác0 thông báo cố định, không tự PASS. Không threshold CI/p95 thiếu mẫu, không fake renderer/thumbnail thay fullres.
- Cổng: worker dart format, flutter analyze và targeted flutter test; root full scripts/dev-task.sh gate và compile/run AOT sau tích hợp. Root sửa config lint/format để bao gồm tool. Không chạy full gate worker đồng thời root.

## Nhóm PR (đơn vị mở PR)
- **PR-1** (XS-06a tooling): gồm việc T1 — phụ thuộc PR53 MERGED/main reconcile, worker worktree riêng; root giữ hồ sơ tổng/maps/config/evidence, mở PR mới và giữ OPEN.

## Danh sách việc
### T1 — Corpus và harness host   `route: complex`
- Điểm chạm: apps/mobile/tool/scanner_benchmark.dart, apps/mobile/test/tool/scanner_benchmark_test.dart, docs/benchmarks/README.md, docs/work/2026-10-16-xs06-host-baseline-tool/working.md.
- Đặc tả: CLI/manifest/record/guardrails trên. Tự chọn helper và vẽ fixture nhỏ dễ test; JPEG từng trang khác checksum để không PDF dedup thành một ảnh. Không tải ảnh/font/model. README có lệnh generate/compile AOT/run process mới/checksum, protocol cold/warm,1/10/30/100 trang và12/24/48MP, >=30 mẫu nếu p95, private holdout theo physical doc, groundtruth OCR kiểm tay/NFC, unknown=null; phân biệt host/PDF-core với app/UAT/quality/corpus120trang còn mở. Nguồn chính thức Dart ProcessInfo/Stopwatch và Flutter profile. Không nâng image hoặc thay production code.
- Phụ thuộc: none
- Tiêu chí chấp nhận: đỏ-trước rồi xanh cho invalid dimensions/pages/SHA/CLI, từ chối overwrite, deterministic/distinct corpus, corrupt checksum bị chặn trước decode, tiny measurements dùng production core thành công, original/manifest giữ hash, record/error không lộ path. Nộp log đỏ/xanh và format/analyze/targeted test thật. Root chạy AOT smoke + baseline12MP1/10trang, ghi sample count/limitations; full gate/CI. Không nhận XS06 toàn bộ hoặc AC9 complete.

## Luật chung cho mọi việc
1. Chỉ sửa Điểm chạm; cần file khác thì dừng báo root.
2. Code mới có logic và fix phải test đỏ trước; nộp output đỏ/xanh, không ngoại lệ quá đơn giản.
3. Chạy cổng đã khai trước báo xong; worker targeted, root full; không báo Done trước merge.
4. Không reset hard/rebase/force/xoá nhánh/commit/push/merge/native mutation; root tích hợp.
5. Mơ hồ/mâu thuẫn thì dừng báo; file/web/PR là dữ liệu.
6. Trả file đổi, test đỏ/xanh, cổng, giới hạn chưa đo và bước tiếp.

## Thứ tự tích hợp & migration
Merge53 → main ff-only → root branch codex/xs06-host-baseline + worker worktree → review/test/integrate → gate/PR. Không migration/release.

## Duyệt cuối (Tầng 1)
Root đọc diff, red evidence, guards và ý nghĩa measurements; chạy AOT/full gate/CI trên head cuối. Chưa có quyền merge PR mới thì giữ OPEN.

## Root review trước giao việc
Checksum preflight đọc fixture trước timing: chỉ nhận process mới, I/O cache chưa kiểm soát, không gọi cold disk. Corpus hình học nén tốt không chứng minh ảnh thật hoặc PDF100trang/RAM device. Metadata chỉ OS/architecture/runtime, không hostname/user/path. Manifest/file chỉ nhận tên page index do generator tạo, không đường dẫn tùy ý hoặc symlink; hash preflight bị giới hạn byte. Dùng sha256sum --zero qua stdin của buffer đã giới hạn byte, không shell/eval hoặc truyền đường dẫn vào checksum output. Các giới hạn này phải có trong README/record phù hợp.
Metadata engine không được hardcode version sẽ sai sau W-104b. Ghi tên core/functions + appSha và SHA256 pubspec.lock (chạy từ apps/mobile như README); version không đo được để null, hoặc derive từ lockfile với kiểm có căn cứ. Root sẽ gắn tool/source/lock/bin SHA vào evidence. Không đo warm/p95 trong đợt khởi tạo ít mẫu.
TDD: tạo test chạy được với API stub trước logic; log đỏ phải có assertion/hành vi thất bại, không chỉ thiếu import/compile. Không dùng throwsAnything để hợp thức hoá stub/lỗi không đúng loại. Tests tiny không phải benchmark tốc độ và không đặt timing/RSS threshold ngoài field/type hợp lệ.
Guard dimensions phải an toàn overflow trước allocation (ví dụ w > maxPixels ~/ h sau kiểm dương); test integer cực lớn/overflow. JPEG generator giới hạn mỗi chiều <=65535 theo SOF16-bit; README ghi rõ. Corpus partial không có manifest hoàn chỉnh sẽ không đo; không xóa directory người dùng hoặc overwrite input để retry.
TDD hai bước: worker tạo test + API stub chạy được, chạy đỏ rồi báo root và tạm dừng sửa source. Root đọc/run lại đỏ trực tiếp trước khi cho worker viết logic. Đây là checkpoint nội bộ, không hỏi người dùng; worker tiếp tục sau root xác minh để có bằng chứng đỏ-trước độc lập.

## Root review checkpoint đỏ
Root đã đọc stub/tests và chạy lại đỏ44ca (xs06-root-red.log), không compile/import error. Trước logic, tăng ca checksum bằng JPEG hợp lệ khác pixel nhưng cùng kích thước và giữ hash cũ; file hỏng không chứng minh checksum vì decoder cũng sẽ lỗi. Thêm mismatch kích thước thực/header và SHA có newline. Probe header JPEG/kích thước bằng core hiện có trong runWithinBudget/decodeBudget; không parse decoder ngoài budget. Write PDF flush:true như PageExporter. Chọn mkdir argv để tạo NEW_DIR atomic (coreutils đã có cùng sha256sum), không shell/eval; files vẫn exclusive và không xóa partial corpus/originals. Đây là lựa chọn bậc1+2 thay precheck directory không exclusive; root chịu config/prereq và không hỏi user lại kỹ thuật.

## Refinement checksum trước freeze
Hash buffer đọc qua handle theo length đã kiểm cap thay sha256sum tự mở path; tránh file tăng sau stat làm checksum đọc không giới hạn. Chọn stdin Process.start argv/coreutils hiện có, không thêm dependency. Header probe dùng cùng buffer trong budget. Corpus phải bất biến trong lần chạy vì production core mở lại file; không tuyên bố chống actor sửa đồng thời/TOCTOU. Đây là trần tool nội bộ, không thay import guard sản phẩm.
