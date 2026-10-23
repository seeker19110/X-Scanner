# PLAN.md — Trải nghiệm và thumbnail X-Scanner

## Bối cảnh & mục tiêu
Theo spec `docs/specs/2026-10-23-scanner-experience.md`, giữ toàn bộ quy trình P1 và nâng UI/UX, hiệu năng preview, vòng đời/huỷ. Work ID `2026-10-23-scanner-experience`.

## Đặc tả dùng chung
- Schema/DDL: không đổi.
- API: constructor hiện tại giữ nguyên; decodeOriented có thể thêm optional JPEG scale mặc định 1 nếu cần kiểm hợp đồng raster nhỏ, không thay hành vi gọi hiện tại.
- Quy ước: không dependency mới; source một writer tại một thời điểm. Source env `/workspace/.x-scanner/env.sh`. Flutter test cần quyền loopback của sandbox. Worker chạy targeted imaging suite; root chạy full `bash scripts/dev-task.sh gate` sau tích hợp. Baseline AOT đã compile trước sửa renderer.

## Nhóm PR (đơn vị mở PR)
- **PR-1** (Nâng trải nghiệm scan hiện có): gồm việc T1, T2, T3; source thực thi tuần tự, audit chỉ đọc độc lập.

## Danh sách việc
### T1 — Guard vòng đời và huỷ PDF `route: complex`
- Điểm chạm: `apps/mobile/lib/ui/session_controller.dart`, `apps/mobile/lib/export/page_exporter.dart`, `apps/mobile/test/ui/session_controller_test.dart`, `apps/mobile/test/export/page_exporter_test.dart`
- Đặc tả: không bắt đầu operation sau dispose; giữ operation đã bắt đầu hoàn tất; kiểm huỷ trước PDF packaging.
- Phụ thuộc: none
- Tiêu chí chấp nhận: 3 regression assertion RED trước, toàn bộ hai suite GREEN; root đã thực hiện.

### T2 — JPEG thumbnail scaled decode `route: complex`
- Điểm chạm: `apps/mobile/lib/imaging/page_render.dart`, `apps/mobile/test/imaging/page_render_test.dart`, `apps/mobile/test/imaging/decoder_security_test.dart`
- Đặc tả: chỉ giảm raster decode JPEG cho thumbnail; scale lớn nhất 1/2/4/8 vẫn đủ target và phân biệt trục ảnh không vuông; kiểm original header/pixel limit trước decode, dùng hướng thực tế của decoder; full-resolution export và PNG/WebP giữ nguyên. Optional JPEG scale mặc định 1 được phép để kiểm chứng dimensions. Invalid nonpositive maxSide phải fail sanitize. Không thay pins hoặc cap.
- Phụ thuộc: none
- Tiêu chí chấp nhận: test logic mới assertion RED sau compiling scaffolding nếu cần, rồi GREEN; dimensions/EXIF/odd/skinny/cap và existing imaging/security suites PASS. Worker không fullgate/commit/merge; root benchmark và gate.

### T3 — Giao diện và thao tác chạm `route: complex`
- Điểm chạm: `apps/mobile/lib/app/theme.dart`, `apps/mobile/lib/ui/review_screen.dart`, `apps/mobile/lib/ui/quad_editor_screen.dart`, `apps/mobile/test/ui/review_screen_test.dart`, `apps/mobile/test/ui/quad_editor_screen_test.dart`, `apps/mobile/test/ui/accessibility_test.dart`
- Đặc tả: theo AC2–4; giữ toàn bộ tooltip/semantics và hành vi bận; worker UI thực hiện sau T2, không có source writer song song.
- Phụ thuộc: T2
- Tiêu chí chấp nhận: responsive/visible export/tap-adjust regressions RED trước; GREEN cùng tất cả widget/a11y và fullgate cuối.

## Luật chung cho mọi việc
1. Chỉ sửa file trong Điểm chạm.
2. Logic mới/sửa lỗi có test assertion đỏ trước; nộp output đỏ và xanh, không tính lỗi compile/setup.
3. Chạy cổng targeted đã khai trước báo xong; root fullgate sau tích hợp.
4. Không reset/rebase/push/commit/merge/xoá nhánh.
5. Mơ hồ/mâu thuẫn thì dừng và trả lại.
6. Trả file đã đổi, output RED/GREEN/cổng, chỗ phải dừng.

## Thứ tự tích hợp & migration
T1 → T2 → T3 trên checkout cô lập sẵn có; không migration. Root không sửa source khi worker T2 viết.

## Duyệt cuối (Tầng 1)
Root đọc diff, kiểm actual RED/GREEN, benchmark synthetic AOT có raw mẫu, ảnh widget, a11y và fullgate; không suy quyền merge/deploy từ quyền code.
