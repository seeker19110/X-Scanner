# Công việc: XS-07b — gray-alpha core (T1)

- Work ID: 2026-10-17-xs07b-gray-alpha-core
- Yêu cầu / outcome: XS07b T1 giữ gray/alpha độc lập qua generic rectify và render quarter turns, sau PR55 merge thật.
- Trạng thái: Done — root final gates/CI/actual56merge verified18Oct below; worker did not claim root gates.
- Chủ trì / writer: worker chỉ core/test/hồ sơ riêng; root giữ spec/PLAN/docs/maps/reconcile/gates/PR.
- Mức rủi ro / số PR: M thận trọng, một PR tổng do root tích hợp/mở, giữ OPEN.
- Scope / non-goal: ba file T1, không public API/schema/UI/tool/decoder/dependency/lock/SDK/cap/budget/isolate; không real documents/OCR/API/commit/push/merge/fullgate/subagent.
- Spec / goal / issue: root `docs/specs/2026-10-17-xs07b-gray-alpha-render.md` Approved và `docs/work/2026-10-17-xs07b-gray-alpha-render/PLAN.md` check-plan trước dispatch; worker đọc đầy đủ trước sửa.
- Nhánh / base SHA / thời điểm reconcile: `codex/xs07b-gray-alpha-core` @ `9d44fc9` · 2026-10-17T02:09:59Z

## Kế hoạch và phân công

1. Đọc luật/context/spec/PLAN/TRAPS/core và cached image4.10.1 thật; tạo ownwork bằng new-work.sh.
2. Tests-only raw2channel fixtures: analytical crop/cap/skew, uint16, ownership/metadata, PNG manual matrices/full/crop/quarter turns/edge shapes/modulo và JPEG policy. Chạy actual RED, pause.
3. Chỉ sau root rerun RED/GREENLIGHT: sửa generic storage mapping, helper byte rotation2channel theo contract, các channel khác giữ copyRotate; remove resolved DEBT.
4. Targeted format/analyze/imaging+export+tool, self-review và freeze; root fullgate/hook/AOT/CI/PR.

Writer scope: `apps/mobile/lib/imaging/page_render.dart`, `apps/mobile/test/imaging/page_render_test.dart`, hồ sơ này. Worktree `/home/liend/.local/share/x-scanner/xs07b-gray-alpha-core`, branch `codex/xs07b-gray-alpha-core`, base đầy đủ `9d44fc9b39cee2d4cac7871f8ee590882e4681e5`, ban đầu sạch.

## Quyết định và bằng chứng

- Reuse helpers/imports và tạo raw gray/alpha byte fixture · loại dựng fixture qua RGBA setter đã có lỗi · bậc1+2. Expected là analytical ramp/manual cell-order tables, không production transform/copyRotate.
- Cached image4.10.1: getPixelLinear tạo logical RGBA; Image.setPixel→ImageDataUint8.setPixelRgba ghi g vào storage byte1; rotate90/180/270 gọi setPixel. convertColor uint16→uint8 cùng2channels dùng từng raw channel; JPEG chỉ blend alpha nếu pixel.length>3. Tests JPEG dùng manually rotated2channel expected để giữ policy, không RGBA compositing.
- Doctor READY4, chưa gate PASS; core.hooksPath đọc lại scripts/githooks. Flutter pub get --enforce-lockfile phục hồi package config worktree, không nâng dependency; lock và production phải giữ nguyên ở RED.
- RED: `flutter test --no-pub --reporter expanded test/imaging/page_render_test.dart`, exit1,78ca=63PASS/15FAIL, đã đọc toàn output; log `/home/liend/.local/share/x-scanner/xs07b-worker-red.log`. Crop alpha expected30 actual50, cap expected45 actual20, skew expected30 actual13; uint16 expectedalpha0 actual10. PNG full/crop/edge/modulo lỗi alpha thật, không compile/setup errors.57oldcases giữ xanh;21newcases gồm15fail và6pass (ownership, full-frame turn0, JPEG4turns).
- Fixture non-square/manual cells có alpha0/40/80/120/200/255; singlepixel/row/column, negative/repeatedmod4 và encoded originals preservation có test. Không timing/golden/real documents hoặc production expected-image transforms.
- Root đọc toàn300line test diff/workerRED và chạy lại trên production/pubspec/lock chưa đổi: exit1,78=63PASS/15FAIL actual pixel assertions, rồi GREENLIGHT trước logic. Test hash `88a3c3ff382e49e775368e1f7e4910c7e3949b52f272cb8bb65c179028e1b89b` giữ nguyên qua implementation.
- Chọn generic sample RGBA rồi ghi storage r/a riêng cho2kênh qua setter hiện có · loại đổi sampler/homography/clamp/normalize/cap · bậc1+2. Chỉ thêm boolean ngoài loop; kênh1/3/4 giữ cùng giá trị setter như trước. Resolved generic DEBT đã bỏ, comment giải thích storage mapping.
- Chọn private raw2byte quarter-turn helper theo PLAN, turns%4, một output hai kênh và byte views · loại RGBA promotion/thêm fullsize intermediate buffers/per-pixel Point/record · bậc1+2. Mod4=0 trả page đã do rectify sở hữu; các kênh khác giữ copyRotate cũ. Comment giải thích setter/JPEG policy.
- GREEN targeted: `flutter test --no-pub --reporter expanded test/imaging test/export test/tool`, exit0,179/179, đọc đầy đủ output; log `/home/liend/.local/share/x-scanner/xs07b-worker-green.log`. Bao gồm78page-render cũ+mới và old imaging/export/tool. Không đổi expected hoặc test sau rootRED.
- Format2Dartfiles và check `--output=none --set-exit-if-changed`, exit0,2file/0đổi; log `/home/liend/.local/share/x-scanner/xs07b-worker-format.log`. `flutter analyze --no-pub --fatal-infos`, exit0,0issues; log `/home/liend/.local/share/x-scanner/xs07b-worker-analyze.log`.
- Self-review source/test/contract: signatures/API/decoder/caps/budgets/isolates/identity/normalization unchanged, no deps/lock/SDK/otherfile edits. Byte rotation output không metadata/alias, không RGBA conversion; integer destination formulas khớp manual matrices gồm edge shapes/modulo; JPEGpolicy tests giữ xanh. Whitespace diff sạch, test vẫn hash của RED.

## Lần thử / blocker

- RED chủ đích bằng pixel assertion đã được root xác minh độc lập trước production edits; implementation đạt179/179 targeted ngay lần đầu, không giảm tiêu chí. Chưa fullgate/AOT/CI ở worker.

## Bàn giao / bước tiếp theo

- Root review/integrate đúng3file theo hash, docs/maps/TRAPS và fullgate/hook/AOT/CI/PR. Worker source/test freeze sau targeted GREEN; chỉ sửa tiếp nếu root nêu finding cụ thể. Không commit/push/discard/fullgate hoặc tự mở PR.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Ready for root gate, chưa Done; giữ working.md. Root AC5/gates/CI/PR riêng, không nhận device/UAT/scan/OCR/iOS/release từ host checks. New PR giữ OPEN theo quyền đã giao.

## Actual merge reconciliation — 2026-10-18

Done after PR56 MERGED561a5cf05f12ccba03d536f5b522ad0e046f6255 at2026-10-18T01:40:12Z, reviewedheadcc5bb448523775a501e9f9bc32813a988d145005. Freshrootgate+normalhook4/4 each628/628, freshAOT12cases, finalCI39086812105SUCCESS628/628. Native5exactrules/app15368/strict/no bypass, ownerbypassnever, threads0, dependencycompareHTTP200/0changes/no snapshotwarning; artifact12121227969build0c5b04d exactparents/tree. Rootmainff-only and actualmergetree equals reviewedhead; no unresolvedfinding. Renameperformedonlyafterthisreadback in nextPR.

Historical OPEN-only/checkpoint17Oct limits preceded owner's18Octcontinuation; completedwithincontinuedreview/repair/guardedmergeauthority. No device/UAT/iOS/OCR/release/performance acceptance. W104b owns newdecoder separately and may replace workaround with provenupstreamfix while retaining allregressions.
