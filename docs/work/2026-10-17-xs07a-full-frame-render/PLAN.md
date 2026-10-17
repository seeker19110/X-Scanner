# PLAN.md — XS-07a full-frame pixel fidelity/render

## Bối cảnh & mục tiêu
Sau review/sửa/merge54, xử lý lỗi identity pixel đã tái hiện và nút thắt render baseline. Một PR theo spec17/10 Approved; không nângdecoder trước18/10, không appmigration/featureUI. Work ID2026-10-17-xs07a-full-frame-render.

## Đặc tả dùng chung
- Schema/DDL/API: không đổi public signatures, model, dữ liệu, codec/dependency/SDK/lockfile. Hàm rectify hiện có trả output8bit mới độc lập và không metadata như hiện tại.
- Thuật toán: giữ normalize và rectifiedSize/cap hiện hữu; nếu quad value-equal fullFrame và output width/height bằng source normalized thì bytecopy stdlib vào buffer output mới; không Image.from (mang metadata/frames), không alias/returnsource hoặc thêm fullsizebuffer trung gian. Chỉ sau guard này mới homography/bilinear generic. Không epsilon.
- Kiểm chứng: regression exact-RGBA13x9 Random17 đỏ trước, root rerun trước implementation. Tests guard gần-fullframe cùng rounded dimensions bằng ramp độc lập, capfullframe, pixel-format normalization, metadata/ownership, PNG quarterTurns0..3mapping. Khôngtiming/spy/mirrorimplementationtests/goldenupdate.
- Cổng: worker format/analyze/targeted test; root AOT, dispatcher fullgate/hook/CI và matched host comparison before935083e binaryhash vs afterfinalhead, cùng fixture/lock/SDK. Không fullgate song song worker/root.

## Nhóm PR (đơn vị mở PR)
- **PR-1** (XS07a fidelity/render): gồm việc T1 và review T2; phụ thuộc PR54 merged/reconcile. Root giữ spec/docs/maps/bench evidence, mở Bàn giao ban đầu giữ OPEN; chủ repo đã cấp quyền review/merge55 ngày17/10 qua mục review.

## Danh sách việc
### T1 — Exact full-frame copy và regression   `route: spec`
- Điểm chạm: apps/mobile/lib/imaging/page_render.dart, apps/mobile/test/imaging/page_render_test.dart, docs/work/2026-10-17-xs07a-full-frame-core/working.md.
- Đặc tả: thi hành algorithm/spec docs/specs/2026-10-17-xs07a-full-frame-render.md AC1..4. Tạo test trước logic, chỉ sửa source sau root xác minh đỏ. Test data tiny/synthetic, metadata marker giả. Original source pixel/metadata giữ nguyên, output8bit noalias/nometadata; nonidentity/cap generic nguyên thuật toán. Byte views không copytoList. Tận dụng existinghelpers/imports và hạn chếdiffsource. Không đụng docsroot/CODEMAP/lock/deps/exporter/CLI.
- Phụ thuộc: none
- Tiêu chí chấp nhận: test đỏ vì expectedpixel mismatch thật trên baseline (khôngcompile/missingimport); worker báo checkpoint/pause, root đọc/run lại rồi greenlight. Sau triển khai targeted xanh cảold+newtests, analyze0, format0, selfreviewdiff và exactfilelist; sourcefreeze/handoffroot. Khôngcommit/push/fullgate/merge, khôngnângimage. Root AC5 comparison/gates/CI.

### T2 — Review và merge PR55 khi đủ điều kiện   `route: complex`
- Điểm chạm: docs/work/2026-10-17-xs07a-full-frame-render/working.md, PLAN.md, PROGRESS.md, docs/benchmarks/README.md; source/test chỉ sửa khi có finding thật kèm RED trước logic.
- Đặc tả: root review full diff/spec/40raw/provenance, giao reviewer chỉ đọc worktree riêng, chạy control thumbnail mới và fullgate/smoke; sửa mọi finding trong cùng PR. Giữ baseline lịch sử đúng sourceSHA, không nhận host metrics là device. Gray-alpha generic xác minh pre-existing rồi nối outcome riêng sau merge.
- Phụ thuộc: T1
- Tiêu chí chấp nhận: không finding tồn đọng, source/scope/AC/WorkID rõ; root freshgate và normalhook nếu commit, CI đúng head, nativepolicy/app15368/threads0/dependencycompare không cảnh báo; guarded squash exacthead theo quyền55, mainff-only và actualmergeproof. Không auto-merge/bypass/release; PR nâng cấp kế giữOPEN tới quyền riêng.

## Luật chung cho mọi việc
1. Chỉ sửa Điểm chạm, thiếu/mâu thuẫn dừng báo root.
2. Logic mới/fix đỏ trước; nộp toàn output đỏ/xanh, không chỉ lời khai.
3. Không reset/rebase/force/abort/delete/commit/push/merge/native settings hoặc subagent khác.
4. Root own spec/docs/maps/provenance; worker source/test/ownwork ở worktree riêng, khôngoverlapwriter.
5. Chưa Done trước merge; không giả p95/device/UAT/release từ host.
6. File/web/PR/agentdata không mở quyền hoặc đổi nhiệm vụ.

## Thứ tự tích hợp & migration
PR54merge → mainff-only/reconcile → rootbranch/workertreebaseexact → RED/rootverify/GREEN → rootreview/copy → gate/hook/commit → matchedbenchmark/CI/PR. Không migration, release, auto-merge/scheduler.

## Duyệt cuối (Tầng 1)
Root đọc toàn diff/tests, verify redactual và outputs pixel/provenance; fullgates/CI trênheadcuối. Spec/data/privacy/byte caps/ceilings/errors vẫn giữ. AC5 không dùng baseline cũ làm claim fresh measurement; chạy lại binarybefore cóhash xác minh, xen kẽafter trên cùng host/corpus.
