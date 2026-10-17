# Công việc: XS-06a — corpus tổng hợp và baseline host

- Work ID: 2026-10-16-xs06-host-baseline
- Yêu cầu / outcome: sau review/sửa/merge PR53, tiếp tục ưu tiên báo cáo16/10, tự quyết kỹ thuật, chạy đủ gate. Đơn vị này tạo fixture/harness tái lập để so thumbnail/render/PDF trước tối ưu.
- Trạng thái: Done — PR #54 merged, root xác minh17/10.
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
- Checkpoint khởi tạo chưa có baseline; sau source commit935083e đã chạy20mẫu thành công (bằng chứng trên PR54). W104b/AC9/PR4b độc lập vẫn mở.

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

## Review/merge theo yêu cầu chủ repo — 2026-10-17

- Chủ repo trực tiếp cấp quyền review, sửa mọi vấn đề và merge PR #54 khi đủ điều kiện; thay giới hạn bàn giao PR mở trước đó. Sau đó tiếp tục một outcome/PR theo thứ tự báo cáo, tự quyết kỹ thuật; không mở quyền release/auto-merge/PR-4b.
- Head ban đầu `935083e698b64de213caa293fa13231ef22f0080`, base `3f49039c216b15a3827a06afb92ee25027cbf571`, nhánh sạch. Đọc lại source/contract/provenance/raw và full diff; reviewer chỉ đọc ở worktree riêng. Gate/smoke chạy lại trong lượt này; không dùng kết quả cũ làm bằng chứng gate mới.
- Request gồm PR54 hiện có + PR nâng cấp tiếp nên giao reviewer/worker theo §3c, separate worktrees, writer disjoint. Root nghiệm thu/merge; chưa chọn source nâng cấp tiếp trước xác minh nút thắt/contract.

- Root review17/10: đã đọc tool/test/README/full diff và nguồn production; script đối chiếu20raw JSONL trên PR với bản lưu, binary/tool/lock/manifest/JPEG hashes, nhóm5sample/case và median đều khớp. Đây là xác minh bằng chứng baseline lịch sử, không gọi nó là một baseline mới. Hai dòng trạng thái tooling chưa chạy đã được chỉnh rõ thời điểm.
- Ưu tiên sau54: xác minh API Pub chính thức17/10, image4.12.0 vẫn chưa đủ7ngày tới18/10 07:28 giờ Việt Nam; adb devices rỗng. Chọn điều tra full-frame render trong XS07/11 · loại decoder sớm/PR4b hoặc UAT giả · bậc1+2. Probe Dart trên code hiện tại: ảnh tổng hợp13×9 bị đổi16kênh 1LSB do vòng homography/nội suy dù fullFrame, 97×53 đổi1015kênh; đây là lỗi có trước54 (lib không đổi trong PR54), cần regression đỏ và sửa trong PR nâng cấp kế tiếp. Chưa thay source sản phẩm từ probe này.

- Independent review17/10 phát hiện F1/P2: test directory newline/backslash tạo trước invoke không hợp lệ trên Windows. Root tái hiện trực tiếp Windows Directory.CreateDirectory → ArgumentException, existsAfter=false (pr54-windows-lf-proof.json); lượt probe ban đầu Path.Combine từ chối trước CreateDirectory đã được sửa probe, không dùng làm bằng chứng API CreateDirectory. Không có native Windows Flutter gate ở lượt này.
- Chọn `testOn: '!windows'` riêng ca filename POSIX bằng test_api hiện có · loại skip cả suite/conditional runtime hoặc mở rộng host CLI đa nền tảng · bậc1+2. TDD ngoại lệ3: metadata test platform thuần + docs, không thêm runtime/product logic; lỗi đã tái hiện trên API Windows, không giả Flutter Windows đỏ. Linux vẫn phải46/46; README/TRAPS cập nhật trong cùng PR54.
- Fresh AOT compile và5smoke CLI cases PASS, originals/manifest hash giữ nguyên; pr54-review-smoke.json. Gate trước sửa metadata đã PASS4/4/592, analyze0/format57/0; không dùng gate này thay lần chạy sau sửa. SDK XML compatibility warning không làm build fail; không tắt warning hoặc đổi source để giấu nó.

- Sau sửa platform metadata: Linux targeted46/46PASS, format57file/0đổi, đọc toàn pr54-review-targeted.log. Có một lần targeted chạy từ repo root thiếu pubspec.yaml nên chưa chạy test; đã chuyển apps/mobile và rerun thật. Không tính exit1 setup là test đỏ.
- Reviewer delta6file xác nhận F1resolved, findings=[], không vấn đề mới. Root review-check dùng report mới pr54-review-findings.json, không dùng report[] của lượt trước; source runtime/lock unchanged nên20baseline935083e vẫn là evidence lịch sử đúng source, không thay appSha để giả finalhead.
- Đóng freeze review: sửa duy nhất metadata test platform + README/TRAPS/PROGRESS/PLAN/workrecord; TDD ngoại lệ3. Root fullgate sau sửa, normal hook và CI trên head cuối phải xanh trước guarded squash; execution trên PR54, không tự ghi Done trước merge.

## Nghiệm thu sau merge — 2026-10-17

- [PR #54](https://github.com/seeker19110/X-Scanner/pull/54) MERGED `8b99c511e1134534a05b3c93667239c50abf84c9` lúc2026-10-16T23:20:17Z, reviewedhead `95dad0d6688ced6be427ff1d49e9a96bab88abc8`. Main ff-only và tree exact reviewedhead; guarded squash, không bypass/auto-merge.
- Root review sửa F1/POSIX filename testcase; Linux46/46, fullgate4/4 và normal hook4/4, Flutter592/592, analyze0/format57/0, fresh AOT+5smoke PASS, input hashes unchanged. [CI cuối38980161272](https://github.com/seeker19110/X-Scanner/actions/runs/38980161272) SUCCESS trên95dad0d; log đếm592testpass/0failure. Native5rules exact/no bypass, requiredapp15368, threads0, dependencycompareHTTP200/0change/emptywarnings.
- Root kiểm20raw/provenance lịch sử935083e, hash tool/lock/bin/corpus/median đều khớp; không relabel source. Artifact12080842859 build6fe17bd parents đúng base/head, API metadata/ancestry only, chưa cài thiết bị.
- DoD đơn vị XS06a tooling/host baseline đạt theo ủy quyền; rename done sau mergeproof và đưa vào PR kế. XS06 corpus/device đầy đủ, AC9/UAT, EX1/decoder, OCR/iOS/release và PR4b vẫn mở.
