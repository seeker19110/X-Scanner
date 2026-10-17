# Công việc: XS-07b — giữ alpha khi cắt và xoay ảnh xám

- Work ID: 2026-10-17-xs07b-gray-alpha-render
- Yêu cầu / outcome: sau review/sửa/merge55, tiếp tục ưu tiên4 của báo cáo16/10; sửa lỗi pixel hai kênh có trước55 trong core hiện tại.
- Trạng thái: Implementation freeze — root đã xác minh RED, tích hợp source/test và review độc lập sạch. Execution gates/CI cuối trên PR cùng Work ID; chưa Done trước actual merge.
- Chủ trì / writer: root giữ spec/PLAN/docs/maps/reconcile/gate/PR; worker giữ core/test/hồ sơ riêng trên worktree tách; reviewer chỉ đọc.
- Mức rủi ro / số PR: M thận trọng, một PR nhỏ. Yêu cầu gồm55+PR kế nên giao subagent theo§3c.
- Scope / non-goal: giữ hai kênh qua generic rectify và xoay render; không dependency/SDK/lock/tool/decoder/caps/budget/API/UI/schema/migration. Không tài liệu thật/OCR, release, paidAPI hoặc auto-merge. PR mới giữ OPEN.
- Spec / goal / issue: docs/specs/2026-10-17-xs07b-gray-alpha-render.md Approved; PLAN.md; ưu tiên XS07 của báo cáo16/10§6 và DEBT tại generic rectify.
- Nhánh / base SHA / thời điểm reconcile: codex/xs07b-gray-alpha-render @ 9d44fc9b39cee2d4cac7871f8ee590882e4681e5 · 2026-10-17T02:09:16.671038+00:00.

## Kế hoạch và phân công

1. Đối chiếu55 actual merge và main/tree; chốt hồ sơ root/worker55 sang done bằng chứng thật.
2. Worker xs06_tool ở /home/liend/.local/share/x-scanner/xs07b-gray-alpha-core chỉ sửa core/test/hồ sơ riêng theo PLAN. Tests-only RED rồi pause; root tự chạy lại trước source.
3. Root review/tích hợp/docs, full gate/hook, AOT smoke và CI finalhead; mở một PR giữ OPEN.

## Quyết định và bằng chứng

- Approved for implementation — root duyệt theo ủy quyền chủ repo7/10§3d, thực tế17/10. Chọn sửa lỗi pixel đã ghi, tái dùng core/dependency; không mở roadmap/engine mới.
- Pub API17/10 xác minh image4.12.0 chưa đủ7 ngày tới18/10T00:28Z; adb không có thiết bị. Chọn XS07b đủ điều kiện theo ưu tiên4; EX1/AC9/PR4b giữ mở.
- Đọc source image4.10.1: PixelUint8.g cho hai kênh trả gray; Image.setPixel→ImageDataUint8.setPixelRgba ghi g vào byte1. Generic interpolation trả RGBA; copyRotate90/180/270 cũng dùng setPixel. PNG giữ hai kênh.
- Chọn sample rồi ghi r,a vào hai storage channels qua setter sẵn có; các kênh1/3/4 giữ giá trị như cũ. Tái dùng geometry/clamp/normalize/cap/identity copy — bậc2+5.
- Chọn helper byte rotation riêng cho hai kênh, turns%4 và một output hai kênh như trước — bậc1+3. Loại RGBA promotion: cần hai buffer bốn kênh và JPEG encoder chỉ blend alpha khi length>3, gây thay màu theo góc xoay. Reviewer đọc source và xác minh công thức; chưa coi đó là test/gate.
- Ưu tiên đúng/bảo toàn pixel → ít code/bộ nhớ → kiểm được → tốc độ. Thêm helper nhỏ để tránh buffer lớn và giữ JPEG policy, không tạo framework hay Point/record mỗi pixel.

## Lần thử / blocker

- Checkpoint trước triển khai: chưa chạy RED/gate XS07b; không dùng gate55 thay thế. Đây là nợ có trước55, test sẽ tái hiện trước sửa.

## Bàn giao / bước tiếp theo

- Giao worker sau check-plan và doctor; pause tại RED để root xác minh độc lập. File của root và worker tách biệt.

## Nghiệm thu cuối

- Chưa Done. Quyền merge chỉ55; PR XS07b giữ OPEN. Device/iOS/OCR/release và chính sách JPEG alpha mới nằm ngoài nghiệm thu.

- Reconcile55: MERGED9d44fc9 lúc2026-10-17T02:08:56Z; root mainff-only và tree khớp reviewed6a3d648. CI38993226283 SUCCESS607, required app15368, artifact12086181981 buildc05c32c exactparents/tree; native5rules/no bypass, graphcompareHTTP200/0changes/no warnings, threads0. Hồ sơ root/worker55 rename done trong PR kế này, giữ lịch sử.
- Giao T1 xs06_tool trên worktree/branch riêng exactbase9d44fc9 sau check-plan PASS1 và doctor READY4. Root chỉ viết docs; không chạy Flutter/compiler/gate cùng worker. Source phải nguyên baseline tại checkpoint RED. Reviewer thiết kế đọc source, phát hiện RGBA promotion làm JPEG đổi nền theo góc và tăng buffer; root chọn helper byte hai kênh theo thứ tự ưu tiên đã duyệt.

- Root trace spec AC1..5 MAPPED và21 local Markdown targets tồn tại sau rename; mapping không thay acceptance. Main CI38993777041 đang chạy trên9d44fc9, chưa ghi PASS khi chưa có readback. Không chạy Flutter tại root khi worker đang RED.

- Root đọc toàn300dòng test mới và toàn log worker, xác minh production/pubspec/lock diff rỗng. Root tự chạy lại page_render_test trên worker worktree: exit1,78cases=63PASS/15FAIL; các lỗi actualalpha50vs30 crop,20vs45 cap,13vs30 skew, uint16byte1=10vs0 và PNG matrices. Không setup/import/compile failure;57case cũ xanh và4 JPEG policy guard xanh. Root log xs07b-root-red.log; testSHA88a3c3ff382e49e775368e1f7e4910c7e3949b52f272cb8bb65c179028e1b89b.
- GREENLIGHT theo§3d: chỉ triển khai mapping generic và private2channelbytequarterturn helper như PLAN. Giữ nguyên test/expectation từ RED; không mở decoder/engine hoặc thay JPEG compositing. Worker format/analyze/targeted rồi freeze, root tiếp review/gates.

- Root tích hợp đúng3file sau worker freeze qua SHA256: core4d7e682fb98e7bedcf1385add0a804686048f2514e8dd2c10048cc12bd4c4135, test88a3c3ff382e49e775368e1f7e4910c7e3949b52f272cb8bb65c179028e1b89b (nguyênRED), ownrecord7930442e79026bbac949dc8f26143613b8a27b0e7299dd1e6e396c018454443b. Source45thêm/8bỏ, helper29dòng; không đổi normalize/cap/identity, source/lock/tool/API khác.
- Root đọc toàn179-case targeted log, analyze0issues và format2/0; không failure. Reviewed test expectations bằng ramp đại số và ma trận tay, PNG đủalpha0/partial/255, JPEG guard chống chuyểnRGBA. Worker không chạy fullgate/AOT/CI; root giữ các cổng đó.
- Giao review implementation mới review_pr52 chỉ đọc frozen worktree; root không dùng design review/55 review thay implementation. No writer overlap; compiler/gates chỉ root sau freeze.

- Review implementation mới review_pr52: findings=[], hash cả3file trước/sau khớp freeze; đọc code/callers/pinnedlibrary/spec/TRAPS. Reviewer không chạy compiler/test/gate và không sửa file. Root tự review: mapping1/3/4 tương đương, helper chỉuint8/2channels từrectify, bijective integerrotation/mod4, oneoutput/views; không secret/debug/deadcode/dep mới hoặc publicAPI thay đổi.
- Main CI sau55 [38993777041](https://github.com/seeker19110/X-Scanner/actions/runs/38993777041) SUCCESS trên9d44fc9, readback mới sau checkpoint pending ở trên. Không dùng CI đó thay CI source XS07b.
- Snapshot cuối gồm spec Approved/PLAN/maps/TRAPS/CHANGELOG/PROGRESS và reconcile55 done trong cùngPR. Root tiếp dispatcher fullgate và normalhook không bypass, AOT smoke từ commit sạch và CI finalhead; execution results/SHA/PR evidence đặt trênPR để tránh commit tự ghi SHA/CI chính nó. Không sửa trackedfile trong lúcgate. PR mới giữOPEN; chưa nghiệm thu UAT/device/iOS/OCR/release/100page hoặc hiệu năng/RAM.
