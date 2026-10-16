# Công việc: XS-06a — corpus tổng hợp và baseline host

- Work ID: 2026-10-16-xs06-host-baseline
- Yêu cầu / outcome: sau review/sửa/merge PR53, tiếp tục ưu tiên báo cáo16/10, tự quyết kỹ thuật, chạy đủ gate. Đơn vị này tạo fixture/harness tái lập để so thumbnail/render/PDF trước tối ưu.
- Trạng thái: Active — PR53 đã merge, contract/worker riêng; chưa nghiệm thu tooling hoặc benchmark.
- Chủ trì / writer: phiên chính giữ hồ sơ tổng/config/maps/evidence; worker chỉ4file T1, reviewer chỉ đọc.
- Mức rủi ro / số PR: S, một PR tooling nội bộ; không thay API/hành vi sản phẩm. Request gồm PR53 hiện có + PR kế nên giao worker theo §3c, tuần tự từ main đã merge.
- Scope / non-goal: Dart CLI/corpus hình học/checksum/metadata đo host, protocol cho device/corpus riêng sau; không đổi app lib/SDK/dependency/lockfile/schema, thêm engine/font/data thật, dùng paidAPI, bật migration/release/scheduler/auto-merge. PR mới giữ mở trừ khi được cấp quyền merge riêng.
- Spec / goal / issue: XS06 theo research16/10 §5–6; F006/F033; tooling mứcS không cần feature spec sản phẩm; PLAN.md là contract.
- Nhánh / base SHA / thời điểm reconcile: codex/xs06-host-baseline @3f49039c216b15a3827a06afb92ee25027cbf571; main ff-only sau53 lúc2026-10-16T16:26:51Z.

## Kế hoạch và phân công
1. Reconcile53/native/workflow trên main, đóng EX2 theo bằng chứng; chốt hai hồ sơ53 sang done trong PR kế theo §3e.
2. Worker T1 ở /home/liend/.local/share/x-scanner/xs06-baseline-tool, nhánh codex/xs06-baseline-tool; chỉ tool/test/README/hồ sơ riêng. Stub+tests runnable, worker báo đỏ và tạm dừng; root đọc/chạy lại đỏ trước logic.
3. Root nghiệm thu code xanh/tích hợp, mở rộng format/lint tới tool, cập nhật docs/maps; AOT smoke, full gate/normal hook, source freeze.
4. Chạy baseline AOT trên head source cuối và lưu raw/số đo/provenance trong PR; không tạo commit chỉ để tự ghi SHA/CI của chính commit. Một case/process mới, I/O cache không kiểm soát, không nhận device/p95/quality từ ít mẫu.

## Quyết định và bằng chứng
- Chọn XS06a · loại nâng decoder sớm/PR4b/UAT giả · bậc1: 4.12.0 chưa đủ7ngày tới18/10, adb devices rỗng trong lượt này, migration cần duyệt rõ theo spec.
- Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày2026-10-07, áp yêu cầu trực tiếp16/10 tiếp tục ưu tiên/tự quyết; chỉ tooling S, không feature app/dependency/dữ liệu thật · chọn core/stdlib/công cụ đã cài, loại engine/framework mới · bậc1+2.
- Reuse thumbnail/renderPage/buildPdf + Isolate.run như exporter, bỏ lớp Flutter UI/ExportJob khỏi harness Dart AOT · loại renderer giả hoặc benchmark gọi là app E2E · bậc1+2.
- Học nguồn ngoài: đã có sâu hơn = geometry/revision/budget/gate app, giữ nguyên; đã có nhưng nông hơn = renderer/export tuần tự chưa metric; chưa có = rg code/CI xác minh chưa benchmark/corpus, ứng với nợ F006/F033. Chỉ bổ sung công cụ đo, không framework/dependency/dữ liệu ngoài.
- Dart3.13.5 ProcessInfo.maxRss/Stopwatch và Flutter performance docs đã đọc nguồn chính thức; maxRss là highwater byte của process, không per-stage peak/Android PSS. Reviewer đọc plan/core: không blocker; đã thêm cache uncontrolled, corpus nén tốt/không đại diện ảnh thật, metadata không hostname/user/path.
- PLAN check-plan PASS1task; trần inputs/overflow/JPEG16bit/checksum/symlink/error privacy/TDD hai bước được chốt trước giao.
- PR53 MERGED3f49039 lúc16:26:11Z; reviewedhead51af8e0, CI38930758793 SUCCESS, local/precommit4/4/546; readback16:26Z main protected, native exact và workflow main giống reviewedhead. Không dùng gate đó thay gate tooling sắp thêm.

## Lần thử / blocker
- Chưa có failure tooling; chưa chạy baseline/performance. W104b/AC9/PR4b độc lập vẫn mở.

## Bàn giao / bước tiếp theo
- Source đã freeze và tích hợp đúng bốn file T1 bằng hash; root chạy lại targeted tests/AOT smoke thành công. Review độc lập và full gate trước commit; sau commit sạch mới chạy baseline 12 MP một/mười trang, năm mẫu mỗi stage/case và ghi execution evidence trên PR.

## Nghiệm thu cuối
- Chưa Done; tooling/PR mới chưa merge. Bằng chứng execution của head cuối đặt trên PR; không đóng XS06 corpus/device đầy đủ, P1 hoặc các exception khác từ smoke host.

- Root TDD checkpoint: đọc toàn stub/test44ca, chạy trực tiếp trên worker worktree, exit1/assert Expected2 Actual0, không compile/import failure; log xs06-root-red.log. Chưa logic. Yêu cầu tăng ca valid-JPEG checksum và header/metadata mismatch để không nhận lỗi decoder thành bằng chứng hash; chọn mkdir atomic có sẵn thay directory precheck race, header probe trong budget và write flush:true. Plan đã bổ sung/check-plan trước implementation.

- Sau merge: CI main 38931930723 SUCCESS trên đúng 3f49039; dependency-review skip ở push là điều kiện workflow dự kiến, bước này đã SUCCESS trên PR final-head. Không dùng CI main thay gate XS-06a.

- Root xác minh checkpoint bổ sung: flutter test --no-pub --reporter expanded test/tool/scanner_benchmark_test.dart exit1, 46/46 đỏ; đọc toàn output, assertion checksum/dimensions/SHA newline đúng, không compile error. Log xs06-root-red-review.log; cho phép worker viết implementation sau mốc đỏ này.

- Duyệt refinement checksum theo §3d: hash stdin buffer đã đọc bounded, tránh sha256sum file path tăng không giới hạn sau stat; coreutils/argv không shell/dependency mới. Yêu cầu corpus bất biến, ghi giới hạn preflight→core reopen (không bảo đảm chống sửa đồng thời). PLAN được cập nhật trước source freeze.

- Nghiệm thu tích hợp trước gate: so hash/copy đúng bốn file T1; tool SHA256 `8fd922b3a07ed90e51ecf94f48b33c20611ccf16e94001abad141e31aef5bf81`. Root đọc source/tests/README/hồ sơ, chọn core/stdlib/coreutils, không abstraction/dependency mới hoặc app lib đổi. Render timer đã tách tạo tempdir.
- Root targeted green: 46/46, exit0, đọc toàn log xs06-root-green.log. Dispatcher format lib/test/tool:57file,0đổi. AOT compile Linux thành công; smoke5case (CLI sai, generate mới, từ chối overwrite, thumbnail, render-pdf) PASS, hashes originals/manifest giữ nguyên; evidence xs06-aot-smoke.json. Đây là smoke trước commit, không gán baseline cho base3f49039 của cây đang sửa.
- Full gate và normal hook phải đạt trên snapshot cuối trước commit. Baseline AOT riêng chạy sau source commit sạch,5mẫu ×2stage ×2corpus=20process nếu mọi case thành công; chỉ báo min/median/max, không p95/device hoặc target đã đạt. Bằng chứng thực thi/CI final-head đặt trên PR để không tạo commit tự ghi SHA của chính nó.

- Review độc lập review_pr53 sau source freeze: review-findings/1 findings=[], đọc đủ4file+PLAN/core/TRAPS, hash trước/sau khớp; targeted46/46PASS trực tiếp ở worktree riêng (xs06-independent-review-test.log). Root review và relative Markdown links48target/17file PASS, diff whitespace sạch; app lib/SDK/dependency/lockfile/workflow không đổi. Chưa dùng review này thay full gate/baseline.
