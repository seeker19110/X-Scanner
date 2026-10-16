# Công việc: XS-07a — full-frame pixel fidelity and render cost

- Work ID: 2026-10-17-xs07a-full-frame-render
- Yêu cầu / outcome: sau review/sửa/merge54, tiếp tục ưu tiên báo cáo16/10, tự quyết kỹ thuật và chạy đủ gate. Sửa lỗi pixel identity có trước54, đo chi phí render trước/sau.
- Trạng thái: Ready for commit gates — source/test freeze sau root RED→GREEN và review; còn normal hook, benchmark/CI của commit sạch trước bàn giao PR.
- Chủ trì / writer: phiên chính giữ spec/PLAN/docs/maps/benchmark/gate/PR; worker source/test/hồ sơ riêng, reviewer chỉ đọc.
- Mức rủi ro / số PR: M thận trọng, một PR nhỏ thay core hiện có; request gồm54+PR kế nên giao subagent theo §3c.
- Scope / non-goal: chỉ fast path exact fullFrame và regression; không decoder/dependency/SDK/lock, engine/cap/budget/isolate/UI/schema/migration, real documents/OCR, paidAPI, release/scheduler/auto-merge. PR mới giữ OPEN.
- Spec / goal / issue: docs/specs/2026-10-17-xs07a-full-frame-render.md Approved; XS07/11 từ research16/10 §6, F006/F033; PLAN.md contract, một outcome/PR không roadmap mới.
- Nhánh / base SHA / thời điểm reconcile: codex/xs07a-full-frame-render @8b99c511e1134534a05b3c93667239c50abf84c9 · 2026-10-16T23:20Z (17/10 local).

## Kế hoạch và phân công

1. Reconcile54 MERGED8b99c51, main ff-only, tree exact reviewed95dad0d; chốt hồ sơ XS06 sang done theo bằng chứng.
2. T1 worker xs06_tool ở worktree /home/liend/.local/share/x-scanner/xs07a-full-frame-core, branch codex/xs07a-full-frame-core, base8b99c51; chỉ ba file PLAN chỉ định, không commit/push/fullgate. Tests-only RED rồi pause; root đọc/chạy lại trước GREENLIGHT logic.
3. Root review/tích hợp ba file sau freeze; docs/maps/TRAPS/CHANGELOG cùng PR; fullgate và normal hook trên snapshot cuối.
4. Commit sạch rồi matched AOT40process xen kẽ before935083e binary đã xác minh hash và afterfinalhead, cùng tool/lock/corpus; min/median/max/RSS/raw/provenance trên PR, không tự ghi SHA/CI vào commit đó.
5. CI final-head/requiredapp15368/native/thread/compare phải xanh; PR mới giữ OPEN, không merge từ quyền54.

## Quyết định và bằng chứng

- Approved for implementation — phiên chính duyệt theo ủy quyền chủ repo ngày2026-10-07, duyệt thực tế17/10 cho outcome nhỏ hiện có. Chọn exact identity bytecopy · loại tối ưu homography tổng quát/engine/dependency mới · bậc1+2.
- Lỗi thật: probe code cũ13×9RGBA Random17 đổi16kênh−1LSB;97×53 đổi1015kênh; source sản phẩm không đổi trong54. Baseline935083e PDF12MP10trang median82.413s/render82.344s là lịch sử, không số đo của code mới.
- Chọn buffer output8bit mới + Uint8List view/setRange, guard exact value-equality fullFrame và dimensions sau normalize/cap · loại Image.from mang EXIF/text/ICC/frames hoặc returnsource alias · bậc1. Nguồn chính: dependency image4.10.1 source và Dart SDK3.13.5 List.setRange docs; không đoán API.
- Reuse normalize, rectifiedSize, geometry, budget/isolate, thumbnail/render/PDF và existing tests · loại abstraction/cache/UI/model mới · bậc2. Research ba cột trong spec, ứng với lỗi pixel/nút thắt render thực.
- Image4.12.0 chưa đủ7×24h tới18/10 07:28local (Pub API chính thức đã kiểm trong lượt); adb devices rỗng; chọn XS07a đủ điều kiện, giữ EX1/AC9/PR4b mở · loại decoder sớm/UAT giả/migration thiếu duyệt · bậc1.
- Review thiết kế độc lập review_pr53 trên draft spec/PLAN: findings=[]; đối chiếu source buffer layout/metadata thật. Đây không thay review implementation hoặc gate.

## Lần thử / blocker

- Chưa chạy test XS07a, gate/benchmark mới; không dùng gate54 làm bằng chứng cho source sắp đổi. Giới hạn device/real corpus/100page/OCR giữ nguyên.

## Bàn giao / bước tiếp theo

- Worker tests-only RED/pause; root xác minh assertion pixel thật trước logic. Không dùng compile/setup error làm RED.

## Nghiệm thu cuối

- Chưa Done, chưa PR/merge; giữ working.md. Bằng chứng execution/CI source cuối đặt trên PR. PR54 đã MERGED nhưng không đồng nghĩa XS07a hoặc P1 hoàn tất.

- Check-plan thực tế: lệnh đoán scripts/check-plan.sh không tồn tại; _plan_check.py là module thuần nên --help không kiểm gì. Đã đọc entrypoint thật và chạy python3 scripts/subagent-dispatch.py --check-plan docs/work/2026-10-17-xs07a-full-frame-render/PLAN.md, PASS1task trước dispatch. Không dùng lần setup lỗi làm bằng chứng gate hoặc RED.
- Giao T1 qua followup_task xs06_tool, exact3files và hai mốc RED/GREEN; worker không fullgate/commit/push. Root ghi spec/docs/maps riêng, không overlap source/test ở worktree worker.

- CI main sau merge54: [38980887862](https://github.com/seeker19110/X-Scanner/actions/runs/38980887862) SUCCESS trên8b99c51. Không dùng CI này thay gate/CI source XS07a. Doctor root READY4, Markdown19targets checked/no missing, diff whitespace sạch. Review worktree54 đã sạch và remove thường, không force; bằng chứng/log bên ngoài giữ nguyên.

- Root đọc toàn diff149dòng/test/log worker, production+lock diff rỗng, test hash f5383eac679d63a7920322db1ec98d2651b28d3cea5b451ca195a30202114df9. Root rerun flutter test --no-pub --reporter expanded test/imaging/page_render_test.dart trên worker worktree: exit1,57cases=47PASS/10FAIL, đọc toàn472lines xs07a-root-red.log. RGBA/PNG0..3 expectedblue218 actual217; gray-alpha byte1 expected71 actual214, regression byte fidelity có thật; cap/near-full/ownership/metadata và42testcũ xanh. Không compile/import/setup failure. GREENLIGHT exact fastpath theo spec, generic giữ nguyên.

- T1 sourcefreeze: tích hợp đúng3file bằngSHA256 (core19fe394d,testf5383eac,workerrecordff9beed8). Đọc source15thêm/5bỏ,149dòngtest và hồ sơ; core chỉ dời allocation có sẵn, guard exact fullFrame+dimensions và setRange/view. Không Image.from/alias/full-size intermediary; normalize/cap/generic/budget/decoder/lock nguyên hành vi.
- Root đọc toàn worker log cuối: targeted imaging/export/tool158/158PASS, analyze0,format2file/0đổi; testhash giữ nguyên từRED. Genericgrayalpha cũ: cached source2channels.g=gray + generic RGBA→setPixelRgba ghi g vào bytealpha; không sửa ngoài exactfullFrame. Dấu DEBT tại sampling với điều kiện xem lại W104b18/10 hoặc công việc cropgrayalpha, không nhận crop/cap2channel đã sửa.
- Giao reviewer chỉ đọc frozenworkerworktree, không fullgate/compiler/test đồng thời root. Root tiếp fullgate/hook/benchmark/CI, không dùng targetedworker thay gate.

- Review implementation độc lập review_pr53: findings=[], đọc3file/callers/pinnedlibrary, hash trước/sau khớp; reviewer không test/build đồng thời root. Root review-check report mới xs07a-review.json CLEAN; không dùng draft-review thay implementation review.
- Root fullgate vòng đầu sau tích hợp PASS4/4,607/607, analyze0/format57/0, syntax47checks/adoption7/7/manifest10/10/hooksPASS; đọc868lines xs07a-root-gate.log. evidence-check VERIFIED với snapshot trước checkpoint docs này. Dòng FAIL missingmanifest là negative selftest dự kiến; helper đọc status nhầm PASSED đã sửa về schema PASS, không coi đó là gate fail.
- Checkpoint này chỉ cập nhật hồ sơ/PROGRESS sau kết quả thật; source/test không đổi. Rerun gate cuối trên snapshot staged trước commit và normal precommit hook bắt buộc, không bypass. Execution/benchmark/CI final-head ghi trên PR để tránh commit tự ghi SHA/CI chính nó. Test/run trước checkpoint không được dùng thay gate final snapshot.
- Mốc bàn giao dự kiến: mở PR mới khi gate/hook đã xanh; benchmark matched40process và CI finalhead phải đạt mới Ready review. Giữ OPEN, working.md và EX1/AC9/PR4b; không tự merge từ quyền54.
