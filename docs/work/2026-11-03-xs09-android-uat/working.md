# Công việc: XS-09 migration Android UAT trên Windows WHPX

- Work ID: 2026-11-03-xs09-android-uat
- Trạng thái: BLOCKED trước guest boot — thiếu dung lượng ổ Windows; chưa nghiệm thu.
- Yêu cầu / outcome: nối /autopilot hoàn thiện P1/XS-09, xử lý W-602/F-078 bằng kiểm Android thật trên emulator, không thay source app.
- Scope / non-goal: chỉ SDK/AVD đã có của phiên18Oct, copy trạng thái test tổng hợp, kiểm APK debug/thư viện/migration/byte gốc/StatFs/picker và mở lại. Không thay quyền host, không dữ liệu thật, không release/signing/cloud; không xoá/ghi đè AVD/bằng chứng cũ.
- Rủi ro / PR: S test/doc trên dữ liệu tổng hợp, đưa bằng chứng vào PR #73 (cùng yêu cầu completion), không thêm PR tính năng.
- Nhánh/base: codex/xtemplates-completion, f166056, PR https://github.com/seeker19110/X-Scanner/pull/73 .
- Spec/goal: P1, XS-09 Approved; `docs/goals/2026-10-18-upgrade-completion.md`, W-602/F-078. Root tự nghiệm thu kỹ thuật theo §3d, không giả chủ repo đã chạy tay.

## Kế hoạch và bằng chứng

- Đã đọc hồ sơ UAT18Oct và ac9.json; Windows SDK/AVD gốc còn tại `C:\Users\liend\AppData\Local\XScannerUAT`. SDK native37.2.12; `emulator.exe -accel-check` exit0: WHPX(10.0.26300) installed and usable. Linux /dev/kvm thiếu quyền nhưng không cần dùng đường đó.
- ADB Windows private5039 hiện không có guest đang chạy. Chỉ clone AVD cũ sang verification-20261103; giữ original AVD, snapshots/evidence nguyên vẹn. Không đọc nội dung key file; VM/OS giữ opaque images theo cách hoạt động bình thường.
- APK hiện tại có full gate local và Android CI #73 SUCCESS (run41489001004); Guava build-tool finding riêng do worker sửa, không tuyên bố supply-chain xanh.
- Kiểm signer public metadata trước install. Nếu mismatch, không uninstall/clear dữ liệu P1; giữ clone và dùng reconstruction từ frozen synthetic fixture trên AVD mới, ghi đúng giới hạn, không giả in-place upgrade.

## Bàn giao

Giữ working.md đến khi chứng minh DoD và PR đã merge. Evidence mới tách riêng, chỉ fixture tổng hợp; không đính kèm raw userdata images/encryption keys vào Git hoặc dịch vụ.

## Kết quả thật — chưa chạy UAT

- Hai lần boot AVD mới đều dừng trước guest: cần 7372.80 MB, lần đầu có 4596.31 MB, lần hai 2843.23 MB. ADB không có thiết bị; không install/clear/uninstall APK, không chạy migration. Dừng thử sau hai lỗi cùng nguyên nhân, không né kiểm dung lượng.
- AVD P1 cũ giữ nguyên; bản clone phục vụ phiên này được chuyển nguyên trạng sang user-local Linux để giữ lại. Không đưa userdata/key/APK vào Git hay dịch vụ. Chỉ dọn archive toolchain mới tải, đã giải nén và kiểm hash; không compact/shutdown WSL hay xoá dữ liệu cá nhân.
- Artifact Android CI run41489001004/artifact13163652089 đã tải và kiểm SHA256SUMS thật; source f1660564ef7e96b4f66f1bb86c616251c539e3ab, APK SHA256 f0e4376cca2cd0085e5a11b75f80efd89dca75c6ff44c9ce93d5ddc91f213f0e. Receipt: `docs/ops/evidence/xs09-uat-environment-2026-11-03.json`. Đây là provenance, không phải UAT PASS.
- Đối chiếu ba frozen synthetic originals với ac9.json: hash/99780 byte mỗi ảnh khớp. Chưa có kiểm byte sau migration. Local APK signer khác APK P1; CI APK chưa được kiểm signer/install nên không kết luận khả năng cài đè.
- Bước cần operator: giải phóng ít nhất 8 GB trên ổ Windows chạy emulator hoặc nối Android test. WHPX đã dùng được, không cần đổi quyền KVM theo câu hỏi async cũ. W-602/F-078 và Project Complete vẫn mở.
