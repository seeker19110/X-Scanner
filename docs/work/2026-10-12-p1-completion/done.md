# Công việc: X-Scanner P1 /completion — hết lỗi đã biết, Definition of Complete

- Work ID: 2026-10-12-p1-completion
- Yêu cầu / outcome: `/auto-complete` lần 4, bước 2: `/completion` (`docs/framework/project-completion.md` Pha 0–4) sau khi P1 PR-0..4 merged (#6..#10). Outcome: Definition of Complete có bằng chứng hoặc BLOCKED/WAITING đúng §8.
- Trạng thái: **Done** — Pha 0–4 đủ; Pha 4 lần 4 (23/10, `main` `4956064`) 0 Cao, DoC P1 đối chiếu xong trong `docs/ops/COMPLETION-PLAN.md`. AC-9 nghiệm thu 18/10; W-104b/EX-1 đóng #58; F-009/F-014 đóng XS-05. WAITING còn lại (W-602, chạy APK có thư viện trên thiết bị) chuyển sang goal `2026-10-18-upgrade-completion`.
- Chủ trì / writer: phiên chính (kế hoạch, duyệt, tích hợp); audit giao 3 subagent chỉ đọc; sửa giao worker theo số PR.
- Mức rủi ro / số PR: M; PR-A tài liệu Pha 0–2, rồi một PR mỗi việc W-xxx theo kế hoạch.
- Scope / non-goal: app `apps/mobile` P1 + tài liệu dự án. Non-goal: tự nhận mép, OCR, depth, iOS, cloud, release, bật branch protection/auto-merge (cần quyền chủ repo).
- Spec / goal / issue: `docs/specs/2026-10-11-p1-scan-export.md` · `docs/goals/2026-10-11-p1-scan-export.md` · `docs/ops/COMPLETION-PLAN.md` (Pha 2)
- Nhánh / base SHA / thời điểm reconcile: `claude/upbeat-ramanujan-mwmwtt` @ `6177e29` · 2026-10-12T02:03:07Z; lần 5: `claude/admiring-mccarthy-5b360i` @ `ac2c435` (sau #23) · 2026-10-12

## Kế hoạch và phân công

- Pha 0 (phiên chính): `CODEMAP.md`, `docs/FEATURE-MAP.md`, `docs/CONVENTIONS.md`.
- Pha 1 (3 subagent chỉ đọc, song song): A nhóm 1/3/10/12; B nhóm 2/7/11; C nhóm 4/5/6/8/9 → `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`, ID F-xxx.
- Pha 2 (phiên chính): `docs/ops/COMPLETION-PLAN.md` + DoC, tự duyệt theo §3d.
- Pha 3–4: một PR mỗi W-xxx, re-audit nhóm bị ảnh hưởng.

## Quyết định và bằng chứng

- Pha 0 không dừng chờ người dùng xác nhận Hồ sơ/FEATURE-MAP · loại hỏi · ủy quyền `/auto-complete` (§3d): phiên chính tự duyệt cổng và ghi căn cứ.
- Audit chia 3 cụm nhóm cho 3 subagent chỉ đọc · loại 12 subagent hoặc phiên chính tự quét · bậc 2 (≤ 5 subagent, ít ngữ cảnh phiên chính) và bậc 4.
- Pha 1: 3 auditor trả 53 phát hiện thô (A 15, B 9, C 29) → gộp trùng còn 42 (3 Cao, 14 Trung, 25 Thấp), `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md`. Phiên chính lần lại F-001 trên code (`session_store.dart` `_load`/`_save`, `session_controller.dart` `restore`) và grep xác nhận F-002, F-003, F-006, F-007, F-034.
- F-001 sửa ở store (từ chối `save` khi manifest còn mà `load` chưa xong) · loại cách ly manifest khi lỗi I/O (rename cũng có thể lỗi) và chặn ở controller · bậc 1 (chặn ở lớp sở hữu dữ liệu, mọi caller đều an toàn) rồi bậc 2 (controller đã map `StateError` → `saveFailed`).
- F-004 `image` 4.10.1: exception EX-1 tới 2026-10-18 rồi nâng (W-104) · loại nâng ngay 4.12.0 (1 ngày tuổi) và loại tự chặn PNG/EXIF bằng code riêng · bậc 1 (app chưa phân phối nên rủi ro treo/OOM ≈ 0 trong 6 ngày, còn bản phát hành 1 ngày có rủi ro chuỗi cung ứng với quyền đọc mọi tài liệu) rồi bậc 2.
- Không giới hạn định dạng ảnh nhập về JPEG/PNG · loại · bậc 2 (đổi hành vi ngoài spec, không chặn được PNG bom).
- Dời F-026, F-030, F-031, F-032, F-033, F-036, F-038 sang P2/trước release (lý do ở kế hoạch) · loại làm trong P1 · bậc 2 (tính năng/dependency ngoài spec P1 hoặc cần thiết bị/quyết định sản phẩm).
- F-014 branch protection, F-009 bật dependency review: WAITING chủ repo · loại tự bật · CLAUDE.md header (không tự bật auto-merge/dịch vụ; cần quyền repo settings).
- W-201 gộp vào PR kế hoạch · loại PR tài liệu riêng · bậc 4 (cùng loại thay đổi tài liệu, bớt một vòng CI).
- Mỗi W một PR, tích hợp tuần tự trên một nhánh push; worker song song trong worktree khi file không giao nhau (W-101 ∥ W-301 ∥ W-401) · loại song song nhiều nhánh · chỉ được push `claude/upbeat-ramanujan-mwmwtt`.
- Brief `PLAN-c1.md` (scratchpad) `--check-plan` OK: 3 việc, mỗi việc một PR.
- PR kế hoạch + W-201 https://github.com/seeker19110/X-Scanner/pull/11 merged squash `97deb76` sau CI xanh (job 114636563159); 0 review thread.
- W-101 (worker, báo cáo `REPORT-w101.md`): đỏ 5 test (3 store F-001, F-019, controller F-001) → xanh; `flutter test` 211/211. Nhận lệch 1 (save thành công cũng đánh dấu store biết manifest — store vừa tự ghi nó) · bậc 1 (giữ hành vi AC-1). Nhận lệch 2 (load trả Empty/Unrecoverable thì quên danh sách bản gốc cũ) · bậc 1 (cùng khuôn mất bản gốc của phiên bị cách ly, có test đỏ).
- W-301: giữ kiểm thêm `uses-permission-sdk-23` và `activity-alias` (chặt hơn brief) · loại gỡ cho đúng nguyên văn · bậc 1 (cùng là đường cấp quyền/mở component).
- W-401: nhận nhánh phòng vệ khi công thức thu nhỏ vẫn vượt trần (cạnh 1 px) · bậc 1 (không vượt trần bộ nhớ); `buildPdf` qua `Isolate.run` không có test đỏ riêng · ngoại lệ (2) §3.6 (chỉ đổi nơi chạy, hành vi giữ nguyên, test PDF/PdfException cũ bảo vệ).
- Worker không ghi được file báo cáo (harness chặn); phiên chính ghi `REPORT-w101/w301/w401.md` + patch vào scratchpad.
- W-101 https://github.com/seeker19110/X-Scanner/pull/12 merged squash `faf89a0` sau CI xanh (job 114638363016); 0 review thread.
- W-102 (worker): `PageSource.discard` — nguồn tự xoá bản sao của nó, chỉ trong `cacheDir` sau `resolveSymbolicLinks`, chỉ sau khi lưu thành công · loại controller tự xoá theo tiền tố thư mục tạm · bậc 2 (kiến thức "bản sao picker nằm ở cache" ở đúng adapter) và bậc 3 (test bằng fake). Đỏ 7 → xanh; gate PASS 219.

- W-301 https://github.com/seeker19110/X-Scanner/pull/13 merged squash `ba3d5a9` sau CI xanh (job 114640319002); 0 review thread.
- W-401 tích hợp trước W-102/W-103 (bỏ phụ thuộc "W-103" trong kế hoạch) · loại giữ thứ tự cũ · bậc 4 (file không giao nhau: `page_exporter.dart`/`page_render.dart` vs controller/main/review; worker đã xong, không đổi rủi ro).
- W-103 (worker): `DecodeGate` dùng chung cho thumbnail, giải mã thử và render khi xuất; `buildDefaultDragHandles: !busy` · loại khoá toàn cục trong `page_render.dart` · bậc 2 (một lớp nhỏ tiêm qua `main.dart`, test bằng fake) và bậc 3. Đỏ 4 (2 gate, 1 controller `maxActive` 2 thay 1, 1 widget kéo khi bận đổi thứ tự) → xanh; gate PASS 229. Không deadlock: job trong cổng không chờ hàng đợi ghi.

- W-401 https://github.com/seeker19110/X-Scanner/pull/14 merged squash `4efd3d8` sau CI xanh (job 114642488928); 0 review thread.
- W-302 giao worker trước khi W-102/W-103 merge (brief `PLAN-c4.md`, `--check-plan` OK, worker cherry-pick hai commit đó trước) · loại chờ tuần tự · bậc 4 (chung nhánh nền, không chung file với PR đang mở ngoài test đã có).
- W-102 https://github.com/seeker19110/X-Scanner/pull/15 merged squash `e7d265c` sau CI xanh (job 114644429204); 0 review thread.
- W-103 https://github.com/seeker19110/X-Scanner/pull/16 merged squash `43f24d9` sau CI xanh (job 114646372989); 0 review thread.
- W-302 (worker): chỉ thêm/siết test, không guideline nào đỏ nên không đổi `lib/` · loại đổi UI phòng ngừa · bậc 2. Test hồi quy cho code có sẵn xanh ngay (đúng brief); bằng chứng độ nhạy: hạ `_handleSize` về 44 → test 48 dp đỏ. Ghi nhận: `androidTapTargetGuideline` không đo tay nắm chỉ có thao tác kéo, nên test 48 dp không thay được bằng guideline.
- Phiên chính sửa test a11y: chờ đúng future thumbnail đã cache thay vì `delayed(20 ms)` · loại giữ thời gian chờ cố định · bậc 1 (không chập chờn trên CI chậm); chạy 3 lần xanh.
- W-302 https://github.com/seeker19110/X-Scanner/pull/17 merged squash `63b7ef0` sau CI xanh (job 114650363910); 0 review thread.
- W-402 giao worker (brief `PLAN-c5.md`, `--check-plan` OK): `restoring` đặt đồng bộ khi gọi `restore()` · loại cờ "đã khôi phục" mặc định false · bậc 1 (test cũ dựng màn không gọi `restore` không bị kẹt ở trạng thái tải). Thumbnail lỗi bỏ khỏi cache + nút thử lại, không tự thử lại · bậc 2. `ResizeImage` policy `fit` · loại `cacheWidth` (méo khi ảnh xoay/không vuông) · bậc 1.
- W-403 chờ W-402 (chung `session_controller.dart`) · loại song song · CLAUDE.md header (song song cần file rời nhau).
- W-402 (worker): thumbnail lỗi bỏ khỏi cache nên mọi lần dựng lại dòng (notify khác, đổi theme, bấm nút) đều giải mã lại · loại màn tự giữ future để chỉ thử lại khi bấm · bậc 2 (không phải vòng tự động: giải mã lỗi không notify nên không tự kích hoạt; giữ trong controller). `restoring` dùng bộ đếm (hai lần `restore` vẫn đúng), về false trong `finally`.
- W-402 https://github.com/seeker19110/X-Scanner/pull/18 merged squash `4d07a6a` sau CI xanh (job 114657046253); 0 review thread.
- W-403 (worker): phiên chính gỡ `try/catch` toàn bộ trong `imageSizeOf` · loại giữ · bậc 2 (chỉ đọc thumbnail do app tự mã hoá nên nhánh bắt lỗi không với tới; refactor giữ đúng hành vi). Brief sai lệnh grep `package:image` (khớp cả `image_picker`) → kiểm `package:image/` thay thế.
- W-403 https://github.com/seeker19110/X-Scanner/pull/19 merged squash `a7399de` sau CI xanh (job 114658987747); 0 review thread.
- Pha 4: quét lại 12 nhóm bằng 3 auditor chỉ đọc trên `6ee3362` song song CI của #19 · loại chờ merge rồi mới quét · bậc 4 (cùng nội dung, `a7399de` = `6ee3362` cây code). Kết quả 0 Cao; mới F-043..F-058 (2 Trung) → Đợt 4.
- Đợt 4 chia 3 PR: W-501 cổng manifest (phiên chính, nhỏ), W-502 app (worker), W-503 tài liệu sau cùng (FEATURE-MAP cần tên test mới) · loại một PR lớn · bậc 3 (mỗi PR kiểm riêng).
- Dời F-045 (iOS), F-046 (quy ước + test), F-049 (P2, cần notice mới) · loại sửa ngay · bậc 2 (không mất dữ liệu, ngoài phạm vi/hiếm).
- F-037: chấp nhận rủi ro dư (checkout giữ credentials khi không chạy mã bên thứ ba) · loại thêm `persist-credentials: false` + token riêng cho bước push · bậc 2.
- W-501 https://github.com/seeker19110/X-Scanner/pull/20 merged squash `673ed97` sau CI xanh; 0 review thread.
- W-503 làm trước W-502 (đảo phụ thuộc trong kế hoạch) · loại chờ worker W-502 xong · bậc 4 (file rời nhau trừ FEATURE-MAP; W-502 tự thêm test mới của nó vào FEATURE-MAP).
- W-503 https://github.com/seeker19110/X-Scanner/pull/21 merged squash `0e45794` sau CI xanh; 0 review thread.
- W-502: chấp nhận gộp hai catch thành `catch (_)` ở giải mã thử · loại thêm nhánh `on Object` thứ ba · bậc 2 (ít code, cùng hành vi cho người dùng; brief cho phép bắt `Object`).
- W-502: test F-020 cũ đổi sang hành vi mới (giải mã lại chỉ sau `retryThumbnail`) · loại giữ thử lại tự động mỗi lần dựng lại · bậc 1 (không chen giải mã hỏng vào hàng đợi trước render xuất).
- Đĩa phiên đầy chặn gate W-502 → người dùng duyệt xoá 8 worktree worker cũ (đã merge, patch lưu scratchpad), giải phóng ~15 GB · loại tự xoá khi bị chặn quyền · bậc 1.
- Pha 4 lần 2: 2 auditor (X 3/4/6/12, Y 2/8/9) trên `da7cae8` song song CI #22 · loại 3 cụm 12 nhóm · bậc 2 (chỉ nhóm bị Đợt 4 chạm). 0 Cao/Trung; 4 Thấp mới.
- F-059/F-070/F-072 sửa trong PR W-502 (tài liệu đi cùng thay đổi) · loại PR dọn dẹp riêng · bậc 2. F-071 → W-504 riêng (đổi cổng cần test đỏ trước) · loại gộp vào W-502 · bậc 3.
- F-071 sửa bằng FAIL khi targetSdk < 31 hoặc thiếu · loại suy luận exported ngầm theo intent-filter · bậc 2 (một kiểm, chặn cả lớp lỗi).
- Quan sát auditor không tính phát hiện (thao tác Move up/down khi bận im lặng; `_HeldStore` lặp; nút theme bật khi bận) · giữ nguyên · bậc 2.
- F-058 chỉ ghi baseline coverage (94,6 %), không thêm cổng ngưỡng · loại thêm `--coverage` + ngưỡng vào gate · bậc 2 (đã ghi dời P2 trong kế hoạch; vùng thấp là phần nối nền tảng).

- `/auto-complete` lần 5 bước 1: không có phạm vi `/auto` mới — PR P1 #6..#10 đã merge; nối tiếp `/completion` (W-504, W-104, DoC) · loại triển khai kế hoạch M0–M5 (`docs/plans/2026-10-12-comprehensive-development-plan.md`, chủ repo merge seeker19110/X-Scanner#23 `ac2c435`) · CLAUDE.md header (roadmap đề xuất không cho phép triển khai; kế hoạch tự ghi DRAFT) + §3d "ngoài scope đã giao". Việc lượt này trùng M0 của kế hoạch: XS-01 = đóng W-502, XS-02 = W-504, XS-03 = W-104.
- W-504 phiên chính tự làm (1 PR, 1 file) · loại giao worker · bậc 4. FAIL cả khi targetSdk không phải số · bậc 1 (giá trị lạ không chứng minh được ≥ 31).

- Container mới: Maven Central trả 429 qua proxy → init script Gradle cục bộ `~/.gradle/init.d` trỏ mirror Google của Central · loại `--no-verify` hoặc sửa repo Gradle trong repo · bậc 1 (cổng giữ nguyên, repo không đổi). Không đổi cấu hình Git toàn cục (gỡ `safe.directory` lỡ thêm, `chown` SDK thay thế).
- W-504 gate PASS: build + manifest gộp thật (`targetSdkVersion="36"`) PASS, analyze 0, format, `flutter test` 272/272, self-test 10/10.

- W-504 https://github.com/seeker19110/X-Scanner/pull/24 merged squash `0327ab7` sau CI xanh (job 114726677983); 0 review thread. Repo chưa bật auto-merge → phiên chính squash merge sau CI xanh như #11–#22 · loại chờ chủ repo merge tay · bậc 4 (cùng quyền đã dùng ở lượt trước, cổng CI giữ nguyên).
- Pha 4 lần 3: phiên chính tự quét nhóm 2/8 cho W-504 · loại giao auditor · bậc 2 (một file gate). 0 phát hiện mới → hội tụ.
- DoC đối chiếu trên `0327ab7`: `maintenance-sweep` 🔴 0 · 🟡 3 (thiếu "Ngày cập nhật" PROGRESS → sửa ở PR này; thiếu `dependabot.yml` = F-009, WAITING chủ repo; radar 53/100 là chỉ số khung, không phải phát hiện); OSV 86 package hosted 0 advisory; bí mật 0.
- Đóng hồ sơ `2026-10-12-comprehensive-development-plan` (working → done, merge #23 `ac2c435`) trong PR tài liệu này · loại để nguyên "Active" · bậc 1 (hồ sơ khai sai trạng thái sau merge; DoD của chính hồ sơ đó đã đạt).
- Không đổi `docs/work/2026-10-11-p1-scan-export/working.md`: còn chờ AC-9 UAT (chủ repo) · bậc 1.
- `/auto-complete` lần 6: tách W-104 thành W-104a (hàng rào đầu vào, làm ngay) và W-104b (nâng `image`, 2026-10-18) · loại chờ cả gói tới 18/10 · bậc 1 (hàng rào không phụ thuộc phiên bản `image`; giảm rủi ro F-004 sớm 6 ngày). Không mở XS-09: ngoài scope đã giao (câu hỏi cho chủ repo).
- Định dạng nhận: JPEG/PNG/WebP theo magic bytes · loại `findDecoderForData` (11 định dạng, TGA đoán lỏng) và loại chỉ JPEG/PNG · bậc 1 (ít decoder đối mặt input không tin cậy; giữ WebP vì đang nhận được, bỏ thì thoái lui người dùng). BMP/GIF/TIFF/TGA… giờ báo "không đọc được".
- Đuôi file lưu bản gốc vẫn lấy từ tên file · loại suy đuôi từ nội dung · bậc 2 (đuôi không quyết định giải mã; giải mã đã chọn theo nội dung).
- Trần byte 64 MiB, kiểm bằng độ dài file mở sẵn trước khi đọc, chỉ đọc đúng độ dài đó · loại `File.lengthSync` rồi `readAsBytesSync` (file lớn lên giữa chừng vẫn đọc hết) · bậc 1. Dấu `DEBT:` (chưa đo trên máy).
- Ngân sách 60 s mỗi job qua `Isolate.spawn` + `Isolate.kill` (`lib/imaging/isolate_budget.dart`) · loại `Isolate.run(...).timeout` (chỉ thôi chờ, isolate vẫn chạy) · bậc 1; mọi lỗi của job → `ImageDecodeFailure` (không mang nội dung ra khỏi isolate). Dấu `DEBT:` (chưa đo render 50 MP).
- Đỏ-trước: stub (`maxBytes` bị bỏ qua, `Isolate.run(...).timeout`) → 5 test đỏ theo hành vi (BMP/GIF/TIFF/TGA được giải mã; file trên trần vẫn đọc; lỗi khác không map; job quá hạn ném `TimeoutException`; controller không báo `decodeFailed` với BMP) → cài thật → 86/86 xanh ở `test/imaging` + `session_controller_test`.
- Rà bảo mật W-104a (subagent `security-reviewer`, #28 @ `d342ca4`): 1 Trung bình + 4 Thấp. Sửa cả 3 điểm có đường thật · bậc 1. (a) WebP động: VP8X canvas 1×1 che frame lớn → trần 50 MP bị lách, decode cấp phát theo frame (tới 16384² → OOM cả tiến trình). Từ chối mọi WebP động (`hasAnimation`/`format == animated`/`frames`); APNG an toàn vì frame 0 dùng kích thước IHDR. (b) Báo lỗi quá hạn ngay khi kill (isolate còn giữ RAM) → `DecodeGate` mở cho lần giải mã sau → tạm thời hai bản gốc trong RAM. Giờ chỉ báo lỗi khi isolate đã thoát (onExit). (c) Lỗi spawn trước đây lọt ra thô; giờ map về `ImageDecodeFailure`. Mỗi điểm có test đỏ trước: WebP động được giải mã; lỗi báo sau 54 ms dù isolate còn ngủ 600 ms; spawn lỗi ném `ArgumentError`. Sau khi sửa: 115/115. Bỏ qua: timer bắt đầu sau spawn (spawn treo là giả định xa) · bậc 2. Bản gốc BMP/GIF… do bản cũ lưu: P1 chưa phân phối, đã ghi ở PR · không mất dữ liệu.
- `/auto-complete` lần 7: ghi sổ ngay #27/#28 + Pha 4 lần 4 thay vì gộp vào W-104b · loại chờ tới 18/10 · bậc 1 (COMPLETION-PLAN ghi W-104a "PR mở" là sai sự thật). Radar 55/100 không xử lý: kéo điểm toàn bởi script khung (thiếu test, spec adoption) · ngoài phạm vi sản phẩm.
- W-104 mở rộng: thêm trần byte đầu vào, nhận dạng theo nội dung, ngân sách thời gian có dừng thật tác vụ (kế hoạch #23 §5.1) · chủ repo duyệt 2026-10-12 · cùng khuôn lỗi F-004 (ảnh độc hại treo/ngốn RAM), không thêm dependency. Lịch `trig_01UaZ2bXtK9AAmy4NXAKLgzr` (2026-10-18T02:00Z) đã cập nhật prompt.
- `/auto-complete` 2026-10-13: không mở việc mới · loại XS-07 fuzz trên `image` 4.10.1 (W-104b nâng bản 18/10, fuzz sau khi nâng mới có ý nghĩa), XS-11 spike writer (phụ thuộc corpus XS-06, chọn writer khác là dependency mới), F-049 (nằm trong `SessionController` mà PR-4b thay) và XS-10 (xoá/khôi phục dữ liệu người dùng cần quyết định sản phẩm và PR-4b) · bậc 1 + 2. Còn lại đều chờ chủ repo hoặc ngày: PR-4b, XS-20, W-104b, F-014/F-009, AC-9. Đối chiếu trên `b5638d0`: `maintenance-sweep` 🔴 0 · 🟡 3 (dependabot = F-009; radar 57/100 do script khung; `core.hooksPath` của container mới → đặt cục bộ, không đổi cấu hình toàn cục).

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- W-104a merged #28 `474fa28`; Pha 4 lần 4 hội tụ. WAITING (§8): W-104b từ 2026-10-18 (nâng `image` ≥ 4.12.0 + test 2 ảnh tổng hợp, rồi quét lại nhóm 2/7 và đóng EX-1); chủ repo: bật branch protection/ruleset (F-014), dependency review/Dependabot (F-009), chạy UAT AC-9 (D4). Xong W-104b → đổi `working.md` thành `done.md`.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>

## Reconcile XS-05 — 2026-10-16

- PR #52 đã merged f753933 sau review/gate; hồ sơ nghiên cứu/XS-04 được chốt done trong PR kế.
- F-014 native: ruleset 25250032 active/no bypass, check app 15368/strict đúng, PUT/GET readback
  khớp. PR #53 negative control head bb98b4a/run 38925328599 cancelled→BLOCKED.
- F-009: alerts/graph 86/86 Pub đã bật/khớp; review step SUCCESS và compare không warning.
  EX-2 còn chờ workflow merge main trong PR #53; final-head CI xem PR. Các blocker settings
  chủ repo của checkpoint 12/10 là lịch sử trước yêu cầu nâng cấp/ủy quyền 16/10.
- W-104b/EX-1 từ 18/10 và AC-9 thiết bị vẫn mở; không đổi hồ sơ này thành Done hoặc nhận P1 Complete.

## Reconcile sau merge XS-05 — 2026-10-16

PR #53 đã merge `3f49039` (head được review `51af8e0`, CI `38930758793` SUCCESS).
Workflow đã vào main; CI `38931930723` SUCCESS và native rules/readback vẫn khớp.
Alerts trả 204, graph 86/86 Pub và dependency compare cuối không warning; EX-2 đã đóng.
Các dòng chờ owner settings/partial trước đó là lịch sử. EX-1/W-104b (18/10), AC-9
và PR-4b vẫn mở. XS-06a chuẩn bị fixture/tooling host theo Work ID
`2026-10-16-xs06-host-baseline`; chưa nghiệm thu thiết bị, chất lượng, OCR hoặc 100 trang.


## Reconcile sau PR58 — 2026-10-18

W104b đã mergec50670a, headb227825/root639+639/CI39088067553/AOT12/CLI/nativeproof, main clean/treeequal; xem hồ sơ `docs/work/2026-10-18-w104b-decoder-upgrade/done.md`. F004/EX1 đã đóng. F009/F014/EX2 đã đóng ở XS05. Hồ sơ P1 vẫn working vì AC9 chưa có camera→edit/reorder→recipientPDF thật; không rename Done từ dòng bàn giao12Oct chỉ nói sauW104b. Linuxemulator36/24 thiếuRAM; owner giao tự cài môi trường có tăng tốc18Oct, thực hiện Windowssetup riêng. PR4b đã ownerApproved/P1notdistributed; không còn chờ lại quyền đó.


## AC9 execution accepted — 2026-10-18

Root accepts agent-run emulator AC9 under delegated§3d after actual3system-camera captures→crop/rotate/reorder→PDF→Androidsharesheet→Librera1/3,2/3,3/3 on verifiedCI58APK. Bundle/APK/PDF/rawDCT/originalbefore-after hashes and cancel/restart manifest/UI independently verified; proof `docs/ops/evidence/p1-android-uat-2026-10-18/ac9.json`, work2026-10-18-p1-android-uat. Not owner-personally-run, not release/physicalcamera/OCR/depth/XS09AC13. Earlier owner/device waiting entries are historical; report reconciliation still awaits merge, so keep working until that actualmerge and final convergence audit.
