# Kiểm thử Android từ APK của CI

CI tạo gói UAT sau khi `scripts/dev-task.sh gate` thành công. Gói này giúp chạy AC-9 của [spec P1](../specs/2026-10-11-p1-scan-export.md) trên đúng bản đã kiểm; build thành công chưa phải bằng chứng AC-9 đạt.

## Lấy đúng bản

1. Mở workflow **Repository checks** của PR hoặc commit cần thử. Chọn run đã xanh và tải artifact `x-scanner-android-debug-<build SHA>-<attempt>` trong Summary/Artifacts. GitHub yêu cầu đăng nhập để tải; artifact được giữ 14 ngày. Hết hạn thì chạy lại workflow trên revision cần thử.
2. Giải nén vào thư mục trống. Gói gồm `X-Scanner-debug.apk`, `BUILD_COMMIT`, `SOURCE_COMMIT`, `FLUTTER.json` và `SHA256SUMS`.
3. Đối chiếu `SOURCE_COMMIT` với commit đầu nhánh PR cần kiểm. Với sự kiện PR, `BUILD_COMMIT` là merge commit thử của GitHub, gồm base và PR head; trên main hai SHA bằng nhau. Không báo APK PR đã kiểm một head khác chỉ vì cùng số PR.
4. Kiểm checksum trước khi cài. Trong Git Bash, Linux hoặc WSL tại thư mục giải nén:

```bash
sha256sum --check SHA256SUMS
```

Cả bốn file phải `OK`. Không cài nếu checksum sai; tải lại từ run đúng. Checksum phát hiện thay đổi/tải lỗi, không thay việc chọn nguồn CI tin cậy. `FLUTTER.json` ghi phiên bản SDK thực tạo gói.

## Cài và chạy

Dùng emulator hoặc máy Android dành cho thử nghiệm, có camera hệ thống và trình xem PDF. Dùng tài liệu tổng hợp, không dùng giấy tờ cá nhân. APK được ký bằng debug key của runner, dành cho kiểm thử; không dùng làm bản phát hành.

Kiểm pin decoder của đúng `SOURCE_COMMIT` trong lockfile: artifact cũ dùng image4.10.1 có lỗi ở [EX-1](supply-chain-exceptions.md); W104b nâng4.12.0 khi đủ7ngày18Oct. Chỉ dùng fixture tổng hợp được kiểm soát. Artifact/UAT không thay hồi quy decoder, gate hoặc actual merge cần để đóng EX1; không nhận artifact cũ đã được vá chỉ vì ngày tải mới.

```bash
adb devices
adb install -r X-Scanner-debug.apk
```

Nếu có nhiều thiết bị, thêm `-s <serial>` vào lệnh adb. Debug key có thể khác giữa các run; nếu cài đè báo `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, dùng thiết bị/profile thử khác hoặc xuất dữ liệu thử cần giữ trước khi gỡ bản cũ. **Gỡ app sẽ mất dữ liệu trong sandbox**, không dùng uninstall làm cách sửa migration/dữ liệu thật.

## Checklist UAT

Ghi Pass/Fail/Not run và bằng chứng cho từng ca; không đánh dấu thay bằng kết quả unit/widget test.

| Ca | Thao tác | Kết quả cần thấy |
| --- | --- | --- |
| AC-9 | Chụp 3 trang tổng hợp, chỉnh góc, xoay, sắp xếp, xuất PDF; chọn app nhận rồi mở file | Đúng số trang/thứ tự/chiều, đủ nội dung sát mép, mở được bằng viewer thật |
| Camera bị huỷ | Từ một phiên có trang, mở camera rồi huỷ | Trang cũ còn nguyên, không có trang rỗng |
| Nhập ảnh | Nhập JPEG/PNG/WebP tĩnh hợp lệ, rồi thử một file không đọc được | Ảnh hợp lệ dùng được; file lỗi báo rõ và không làm mất trang cũ |
| Mở lại | Sửa góc/xoay rồi đóng và mở lại app | Trang và chỉnh sửa được giữ |
| Share | Xuất PDF, JPG và PNG; thử huỷ chọn app nhận | App vẫn dùng tiếp được; với lần chia sẻ thành công, app nhận đọc được toàn bộ file |
| Huỷ xuất | Tạo nhiều trang và huỷ khi đang render | Có thông báo huỷ, bản gốc còn; không chia sẻ kết quả dở |
| Lifecycle camera | Mở camera rồi để Android huỷ tiến trình scanner khi thiếu tài nguyên; hoàn tất ảnh và mở lại | Kiểm đường retrieveLostData, không mất hoặc nhân đôi trang. Ghi rõ nếu môi trường không tái hiện được |
| A11y và theme | Thử Dark/Light, cỡ chữ lớn và TalkBack qua chụp/chỉnh/xuất | Điều khiển đọc được và luồng hoàn tất; ghi riêng hạn chế thao tác góc |
| Offline | Bật chế độ máy bay rồi chụp/nhập/chỉnh/xuất | Luồng cốt lõi hoàn tất; app nhận bên ngoài có thể có yêu cầu mạng riêng |

## Ghi bằng chứng

Lưu kết quả vào hồ sơ P1/việc đang mở, gồm ngày, link run/artifact, `BUILD_COMMIT`, `SOURCE_COMMIT`, phiên bản Flutter, thiết bị/emulator và Android, viewer nhận file, bảng kết quả cùng lỗi tái hiện. Ảnh/video chỉ chứa fixture tổng hợp; không đính kèm scan cá nhân hoặc log nội dung OCR.

AC-9 chỉ đóng sau khi người nghiệm thu ghi bằng chứng chụp → chỉnh → xuất → mở PDF. Checklist mở rộng không chứng minh hiệu năng thiết bị, OCR, depth, iOS hoặc release readiness. PR-4b thư viện/migration và W-104b decoder có phạm vi, cổng và mốc riêng.


## Accepted controlled execution — 2026-10-18

[P1 AC9 proof](evidence/p1-android-uat-2026-10-18/ac9.json): verifiedCI58APK on WindowsWHPX/API36, actual three external-camera captures, crop/rotate/reorder, PDF/share and Librera pages1/3–3/3. Agent executed, root accepted under delegated§3d; [restored review](evidence/p1-android-uat-2026-10-18/review-restored.png), [viewer3/3](evidence/p1-android-uat-2026-10-18/pdf-viewer-page3.png), [synthetic PDF](evidence/p1-android-uat-2026-10-18/three-pages.pdf). Originals preserved byte-for-byte and cancel/restart checked. Dark/Light and offline export/viewer checked; broader checklist items (gallery formats, process-death camera recovery, JPG/PNG recipient, TalkBack/large text, offline capture) are not claimed by this narrow AC9 execution. XS09 migration/nativecapacity need their own later exact-APK evidence.
