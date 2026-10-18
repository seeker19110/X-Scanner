# Công việc: XS-07a — exact full-frame core (T1)

- Work ID: 2026-10-17-xs07a-full-frame-core
- Yêu cầu / outcome: XS-07a T1, sửa pixel full-frame không resample theo spec Approved trước source.
- Trạng thái: Done — tích hợp PR55, root nghiệm thu và actualmerge; xem reconcile cuối hồ sơ.
- Chủ trì / writer: worker T1 chỉ core/test/hồ sơ riêng; root giữ spec/PLAN/docs/maps/gate/benchmark/PR.
- Mức rủi ro / số PR: M gọn, một PR tổng XS-07a do root tích hợp/mở.
- Scope / non-goal: chỉ ba điểm chạm được giao, không API/schema/dependency/SDK/lock/decoder/budget/CI/tool changes; không fullgate/commit/push/merge/subagent.
- Spec / goal / issue: `docs/specs/2026-10-17-xs07a-full-frame-render.md`, `docs/work/2026-10-17-xs07a-full-frame-render/PLAN.md` ở checkout root, Approved/check-plan trước dispatch. Root đối chiếu PR54 merge thật.
- Nhánh / base SHA / thời điểm reconcile: `codex/xs07a-full-frame-core` @ `8b99c51` · 2026-10-16T23:27:46Z

## Kế hoạch và phân công

1. Đọc laws/PROJECT/PROGRESS/TRAPS/spec/PLAN và core/tests/source dependency đã ghim.
2. Tests-only cho exact Random17 13×9, channels1..4, value-equal quad, one pixel/row/column, ownership/metadata, capped/near-full ramp và PNG quarter turns; chạy RED rồi pause.
3. Sau root tự đọc/rerun RED và greenlight, triển khai exact fullFrame/dimensions guard + byte view copy vào buffer mới, không alias/metadata/intermediate full-size copy; generic giữ nguyên.
4. Targeted format/analyze/test và tự review, freeze; root integration/AOT/comparison/fullgate/hook/CI/PR.

Điểm chạm: `apps/mobile/lib/imaging/page_render.dart`, `apps/mobile/test/imaging/page_render_test.dart`, hồ sơ này. Worktree riêng `/home/liend/.local/share/x-scanner/xs07a-full-frame-core`, nhánh `codex/xs07a-full-frame-core`, base đầy đủ `8b99c511e1134534a05b3c93667239c50abf84c9`.

## Quyết định và bằng chứng

- Chọn Random17 byte fixture + independent coordinate mapping/ramp · loại solid-only, spy/timing hoặc gọi cùng production transform để tạo expected · bậc 1+3. Reuse existing quad/png helpers; cached image4.10.1 API/source đã đọc trước dùng.
- Mở test formats1..4 cùng helper ngắn theo refinement root, gồm gray/gray-alpha, RGB/RGBA; metadata chỉ synthetic EXIF orientation/text marker, không dữ liệu thật.
- `bash scripts/dev-task.sh doctor`: READY4, không phải gate PASS. Hook path đọc lại `scripts/githooks`; working tree ban đầu sạch, base/branch khớp task.
- RED: `flutter test --reporter expanded test/imaging/page_render_test.dart`, exit1, 57 ca thực thi:47PASS/10FAIL. PNG0..3 và RGBA13×9 sai pixel nguồn(7,0): expected blue218, actual217. RGB/value-equal/gray/row cũng fail pixel thật. Gray-alpha fullFrame còn lộ alpha71 thành214 qua generic interpolation; test yêu cầu giữ đúng byte, không sửa generic ngoài scope.
- Cap/near-full ramp, metadata/ownership và old border/skew/16bit/palette giữ xanh trong cùng lượt RED. Không compile/import/setup failure. Log đầy đủ ngoài repo `/home/liend/.local/share/x-scanner/xs07a-worker-red.log`, đã đọc toàn output.
- Checkpoint RED trước implementation: production source chưa sửa, không đổi dependency/lock. Test được format; lần format trước pub resolution chỉ cảnh báo include flutter_lints chưa resolve, sau Flutter test dependencies có sẵn và test thực thi đầy đủ. Không dùng cảnh báo setup đó làm RED.
- Root đọc diff/log và rerun RED độc lập trước GREENLIGHT, 57 ca=47PASS/10FAIL, exit1, không setup/compile failure; log root `/home/liend/.local/share/x-scanner/xs07a-root-red.log`. Test giữ nguyên hash `f5383eac679d63a7920322db1ec98d2651b28d3cea5b451ca195a30202114df9` qua implementation.
- Chọn exact value-equal fullFrame + output dimensions bằng normalized source, copy Uint8List view bằng setRange vào Image mới · loại epsilon/object identity/Image.from/source alias/full-size intermediate copy · bậc1+2. Giữ normalize/cap trước guard; thuật toán generic giữ nguyên. Source diff15 thêm/5 bỏ (dời allocation hiện có), doccomment giải thích identity không resample và một DEBT comment tại generic theo yêu cầu root.
- GREEN targeted sau cả DEBT comment cuối: `flutter test --no-pub --reporter expanded test/imaging test/export test/tool`, exit0,158/158, đã đọc đầy đủ output; log `/home/liend/.local/share/x-scanner/xs07a-worker-green.log`. Bao gồm57 ca page_render cũ+mới, async JPEG/export PDF/tool và guard/budget/geometry.
- Format: `dart format lib/imaging/page_render.dart test/imaging/page_render_test.dart` và check `--output=none --set-exit-if-changed`, đều exit0,2file/0đổi; log `/home/liend/.local/share/x-scanner/xs07a-worker-format.log`. Analyze `flutter analyze --no-pub --fatal-infos`, exit0,0issues; log `/home/liend/.local/share/x-scanner/xs07a-worker-analyze.log`.
- Self-review diff: production chỉ dời allocation trước guard và copy byte cho identity exact, không Image.from/toList/intermediate pixel buffer, không sửa generic loop/clamp/normalization/cap/budget. Tests không đổi sau root xác minh RED; dữ liệu tiny/synthetic, không golden/timing/spies/dependency/lock change. Fullgate/host comparison do root giữ, không suy ra hiệu năng từ targeted tests.

## Lần thử / blocker

- RED chủ đích đã được root xác minh trước implementation; targeted GREEN ngay lần đầu, không giảm tiêu chí hoặc đổi test.
- Observed baseline: gray-alpha identity generic làm alpha71→214. Cached image4.10.1 đã xác minh nguyên nhân: PixelUint8.g cho2kênh trả gray; getPixelLinear tạo RGBA color; Image.setPixel gọi ImageDataUint8.setPixelRgba, hàm này ghi g vào byte thứ2 thay vì a. Fast path sửa identity trong scope; thuật toán generic cho crop/cap giữ nguyên, không nhận toàn generic gray-alpha fidelity đã đạt. Root yêu cầu chỉ thêm dấu DEBT ngay generic, không mở rộng thuật toán/tests.
- DEBT: chưa sửa mapping gray-alpha ở nhánh nội suy generic quan sát từ baseline | trần: XS-07a chỉ exact full-frame không downsize | xem lại khi: W-104b decoder upgrade ngày2026-10-18 hoặc gray-alpha crop regression work.

## Bàn giao / bước tiếp theo

- Root review độc lập/tích hợp đúng ba file theo hash, AOT/matched comparison/fullgate/hook/CI và PR. Source/test freeze sau158/158 xanh; không commit/push/discard. Chỉ core/test/hồ sơ riêng thay đổi; root docs/maps/spec/CLI không bị worker sửa.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Ready for root gate, chưa Done; giữ working.md. Root chịu AC5 comparison/fullgate/CI và quyền PR. Chưa chạy full Android gate hoặc benchmark ở worker, không có claim hiệu năng/device/UAT/OCR/release.

## Reconcile thực sau review/merge55 —17/10

- PR55 MERGED squash `9d44fc9b39cee2d4cac7871f8ee590882e4681e5` lúc2026-10-17T02:08:56Z; root mainff-only và tree khớp reviewhead cuối. Gate mới và normalhook mỗi4/4,607/607; CI finalhead/requiredapp15368/dependencyreview/UATbundle SUCCESS, native5rules exact/no bypass, threads0/compare0changes/no warnings. Chi tiết sourcehead/CI/artifact readback trênPR55 và localreviewproof, không dùng lời khai worker làm nghiệm thu.
- Review mới findings=[]; control replay10success/0failure không tái hiện31.5% (13.237269→13.375609s), giữ nguyên40mẫu cũ và giới hạn sharedhost. Runtime giữ5890c2f qua reviewdocs.
- DoD phạm vi XS07a đạt, root nghiệm thu theo quyền review/repair/merge55 trực tiếp17/10; rename done chỉ sau actualmerge. Không đóng EX1/AC9/PR4b hoặc nghiệm thu iOS/device/scan/OCR/release. Nợ gray-alpha crop/downsize/rotation nối outcomeXS07b, không sửa ngược lịch sử55.
