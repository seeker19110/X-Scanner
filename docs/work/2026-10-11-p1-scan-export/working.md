# Công việc: X-Scanner P1: scan nhiều trang, chỉnh góc, lưu gốc, xuất PDF/ảnh

- Work ID: 2026-10-11-p1-scan-export
- Yêu cầu / outcome: `/auto-complete` lần 3; chủ repo duyệt spec P1 theo đề xuất (D1 A, D2 5 dependency, D3 tắt backup, D4 emulator). Outcome: Goal DoD ở `docs/goals/2026-10-11-p1-scan-export.md`.
- Trạng thái: In progress — PR-0 (#6 `a1549c5`), PR-1 (#7 `df902de`), PR-2 (#8 `1cc15e3`), PR-3 (#9 `99027ba`), PR-4 (#10 `6177e29`) merged; chờ AC-9 (chủ repo). Phát hiện sau P1 xử lý ở `docs/work/2026-10-12-p1-completion/working.md`.
- Chủ trì / writer: phiên chính (PR-0, review/gate/tích hợp); PR-1..4 giao `complex-implementer`.
- Mức rủi ro / số PR: L (dữ liệu tài liệu nhạy cảm, 5 dependency, nhiều màn hình); 5 PR tuần tự vì chung `pubspec.lock`.
- Scope / non-goal: spec §5. Non-goal: tự nhận mép, OCR, depth, iOS, cloud, release.
- Spec / goal / issue: `docs/specs/2026-10-11-p1-scan-export.md` · `docs/goals/2026-10-11-p1-scan-export.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/upbeat-ramanujan-mwmwtt` @ `b6c0113` · 2026-10-11T23:26:23Z

## Kế hoạch và phân công

- PR-0 `docs` (phiên chính): spec Approved + chỉnh §3/FR-5/§12/§17/§19, goal, hồ sơ này, đóng `2026-10-11-p1-readiness`.
- PR-1 `feat` (`complex-implementer`): `lib/core/scan_session.dart`, `lib/core/session_manifest.dart`, `lib/storage/session_store.dart` + test. AC-1..3.
- PR-2 `feat` (`complex-implementer`): `image` 4.10.1, `lib/imaging/` (homography, render, thumbnail trong isolate) + test. AC-5.
- PR-3 `feat` (`complex-implementer`): `image_picker` 1.2.3, `path_provider` 2.1.6, `lib/ui/`, `lib/main.dart`, Android manifest (D3) + widget test. AC-4, AC-7, AC-8.
- PR-4 `feat` (`complex-implementer`): `pdf` 3.13.1, `share_plus` 13.3.1, `lib/export/` + nối UI + test. AC-6.
- Sau PR-4: `/completion` (luồng người dùng đã có) → DoC; AC-9 chờ chủ repo.

## Quyết định và bằng chứng

- Ghim `image_picker` 1.2.3 và `image` 4.10.1 · loại 1.2.4/4.12.0 · bậc 1 (spec §3: bản phát hành ≥ 7 ngày; 1.2.4 mới 5 ngày, 4.10.2–4.12.0 mới 0–1 ngày).
- Nắn bằng homography tự viết · loại `copyRectify` · bậc 1 (đọc mã nguồn 4.10.1: nội suy song tuyến, sai phối cảnh khi trang nghiêng).
- Tọa độ quad tính sau khi áp hướng EXIF · loại tọa độ buffer thô · bậc 1 (thumbnail người dùng kéo góc là ảnh đã xoay EXIF; lệch hệ quy chiếu = cắt sai).
- `SessionStore` nhận thư mục được tiêm, `path_provider` để PR-3 · loại thêm dependency ở PR-1 · bậc 2 (ít dependency hơn) và bậc 3 (test bằng thư mục tạm).
- Manifest hỏng: đổi tên sang `session.corrupt-<thời điểm>.json`, không dọn bản gốc · loại ghi đè khi lưu phiên mới · bậc 1 (giữ ánh xạ bản gốc để phục hồi tay).
- D3: `allowBackup="false"` + `dataExtractionRules` loại mọi miền · loại chỉ `allowBackup` · bậc 1 (Android 12+ vẫn chuyển máy khi chỉ tắt `allowBackup`).
- D4: AC-9 chủ repo chạy trên emulator · loại chạy trong phiên · bậc 1 (container không có `/dev/kvm`).

- PR-0 https://github.com/seeker19110/X-Scanner/pull/6 merged squash `a1549c5` sau CI xanh (job 114603780732); 0 review thread.
- PR-1 do `complex-implementer` viết theo brief `--check-plan` OK. Container khởi động lại nên báo cáo đỏ/xanh của worker bị mất; phiên chính đọc lại toàn bộ diff và chạy lại test.
- Review PR-1 tìm thấy lỗi mất dữ liệu: sau khi manifest bị cách ly, lần `load` thành công kế tiếp xoá bản gốc của phiên hỏng (vì brief cho dọn mọi file không tham chiếu). Đỏ: test `a later new session never deletes the quarantined originals` → PathNotFoundException; sửa: khi còn `session.corrupt-*.json` chỉ dọn `.part`; xanh 22/22 · loại xoá bản gốc mồ côi · bậc 1.
- Gate PR-1 cục bộ: `dev-task.sh gate` PASS 4/4, `flutter test` 99/99.
- PR-1 https://github.com/seeker19110/X-Scanner/pull/7 merged squash `df902de` sau CI xanh (job 114606406106); 0 review thread.
- PR-2 do `complex-implementer` viết (brief `--check-plan` OK; báo cáo đỏ/xanh lưu ở scratchpad `REPORT-p2.md`): T1 đỏ 7/7 → xanh; T2 đỏ 25/25 → xanh; thêm 2 ca biên có đỏ thật (viền tối do lấy mẫu pixel −1 của `getPixelLinear`; ảnh 16-bit bị cắt về 0). Gate worker PASS, 131 test.
- Kẹp tọa độ lấy mẫu vào tâm pixel ngoài cùng · loại lấy mẫu nguyên văn p − 0,5 · bậc 1 (viền trang tối 229 thay 255).
- Bỏ `bakeOrientation` khi không có EXIF orientation · loại luôn gọi · bậc 1 (thư viện luôn sao chép ảnh: ảnh 12 MP chiếm gấp đôi bộ nhớ, rủi ro OOM trên máy).
- PR-2 https://github.com/seeker19110/X-Scanner/pull/8 merged squash `1cc15e3` sau CI xanh (job 114617598572); 0 review thread.
- PR-3 do `complex-implementer` viết (brief `--check-plan` OK; báo cáo `REPORT-p3.md`): T1 đỏ 7 → xanh; T2 đỏ 13 → xanh; T3 đỏ (manifest thiếu `allowBackup`, widget test trên stub) → xanh. Gate phiên chính PASS 4/4, 170/170 test.
- Dùng `onReorderItem` · loại `onReorder` · bậc 1 (`onReorder` deprecated từ Flutter 3.41, `analyze --fatal-infos` đỏ).
- Lỗi đọc file ảnh vừa chọn → `decodeFailed` · loại để exception lọt lên UI · bậc 1 (không crash, cùng ý nghĩa với người dùng).
- Thêm `/build/` vào `android/.gitignore` · loại commit `android/build/reports` · bậc 2 (Gradle 9 ghi problems-report vào thư mục chưa ignore).
- AC-8 kiểm thêm manifest **release** đã gộp (`flutter build apk --release`): chỉ có `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (nội bộ androidx); debug có thêm INTERNET từ `src/debug` cho công cụ dev.
- Chỉnh góc chỉ bằng kéo · ghi `DEBT:` + rủi ro goal, để P2 · bậc 2 (thêm thao tác bàn phím/trình đọc màn hình là luồng mới ngoài spec P1; ghi rõ thay vì im lặng).
- Đo hiệu năng PR-2 (ảnh tổng hợp 4000×3000, `dart run` JIT, x86 4 nhân): nắn 2,8–3,5 s, thumbnail 1,2 s · chấp nhận cho P1 (isolate) · cam kết p95 để P2 trên thiết bị (spec §2).
- PR-3 https://github.com/seeker19110/X-Scanner/pull/9 merged squash `99027ba` sau CI xanh; 0 review thread.
- PR-4 do `complex-implementer` viết (brief `--check-plan` OK; báo cáo `REPORT-p4.md`): T1 đỏ 8 → xanh; T2 đỏ 14 + controller → xanh; T3 đỏ biên dịch rồi đỏ 2 widget test → xanh; nút Xuất khi bận kiểm bằng đột biến.
- PDF nhúng nguyên byte JPEG đã nắn, trang 842 pt theo cạnh dài · loại khổ A4 cố định · bậc 1 (AC-6 đúng tỷ lệ/chiều) và bậc 2 (không resample).
- Dọn `cache/share_plus` khi app khởi động (`clearLeftovers`) · loại chấp nhận bản sao nằm lại tới lần chia sẻ sau, loại xoá ngay sau share · bậc 1 (`share_plus` 13.3.1 chép file vào cache và chỉ xoá ở lần chia sẻ kế tiếp → tài liệu nhạy cảm nằm lại; xoá ngay có thể cắt app nhận đang đọc). Đỏ thật: đổi tạm `clearLeftovers` thành `clear` → "Expected: false Actual: <true>"; khôi phục → xanh.
- Gate PR-4 phiên chính: `dev-task.sh gate` PASS 4/4, 205/205 test. Manifest release đã gộp sau `share_plus`: vẫn chỉ `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; `ShareFileProvider` và receiver `exported="false"`.
- PR-4 https://github.com/seeker19110/X-Scanner/pull/10 merged squash `6177e29` sau CI xanh (job 114631855487); 0 review thread.

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- Code P1 xong. AC-9 (UAT emulator) chờ chủ repo; đóng hồ sơ (`done.md`) sau AC-9. `/completion` tiếp ở `2026-10-12-p1-completion`.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
