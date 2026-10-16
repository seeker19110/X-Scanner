# Changelog — X-Scanner

## Unreleased — 2026-10-16

- XS-05: ruleset `main` bắt buộc PR/squash và check `Framework and Android app gate` từ GitHub Actions,
  không bypass; kiểm dependency theo advisory trong cùng gate. Runbook tách policy, live evidence và giới hạn snapshot.

- XS-04: CI cung cấp APK debug cho UAT sau full gate, kèm checksum, SHA checkout/PR head và phiên bản Flutter;
  artifact giữ 14 ngày, hướng dẫn tải/kiểm/cài và ghi bằng chứng AC-9 tại `docs/ops/android-uat.md`.

- Dependabot (chủ repo duyệt 2026-10-13): nâng bản hằng tuần cho `pub` (`apps/mobile`) và GitHub Actions, chờ
  bản phát hành đủ 7 ngày, bỏ qua bản major, mỗi hệ sinh thái một PR.

- P1 scan và xuất (#6–#10): phiên nhiều trang lưu bền giữ bản gốc, chụp bằng camera hệ thống hoặc nhập ảnh,
  sắp xếp/xoá/chụp lại/xoay, chỉnh 4 góc và nắn phối cảnh, Dark/Light, tắt sao lưu Android,
  xuất PDF/JPG/PNG qua share sheet.
- Hoàn thiện P1 (#11–#20, /completion): khôi phục phiên lỗi I/O không ghi đè phiên cũ, xoá bản sao ảnh
  của picker sau khi lưu, một cổng giải mã cho thumbnail và render xuất, tắt kéo-thả khi bận, PDF dựng trong
  isolate có trần điểm ảnh, trạng thái "Đang mở phiên…" và thử lại thumbnail lỗi, kiểm a11y Dark/Light,
  gate tự kiểm manifest release đã gộp, tài liệu trạng thái, ADR-0003, `TRAPS.md`.
- Sửa sau quét lại (#21, #22): khi app bận, thao tác TalkBack Move up/down không đổi thứ tự trang; ảnh xem
  trước lỗi chỉ giải mã lại khi bấm "Tải lại" (có vòng quay); mọi lỗi khi kiểm ảnh mới đều báo "không đọc được".
- Gate manifest release (W-504): chặn khi `targetSdkVersion` < 31, thiếu hoặc không phải số — dưới 31 component có
  intent-filter mà không khai `exported` vẫn bị exported ngầm.
- Hàng rào ảnh đầu vào (W-104a): chỉ nhận JPEG/PNG/WebP tĩnh nhận dạng theo nội dung, từ chối bản gốc trên 64 MiB
  trước khi đọc, và dừng hẳn thumbnail/render quá 60 giây; các trường hợp này báo "không đọc được", không mất trang.
- XS-09 PR-1 (#31, chưa nối vào app): mô hình tài liệu `ScanDocument` (tên 1–120 ký tự, thời điểm UTC), `revision` mỗi trang
  tăng ở mọi lần chỉnh, codec `document.json` schema 2 đọc được schema 1 và báo "cần cập nhật app" với schema mới hơn.
- XS-09 PR-2 (#32, chưa nối vào app): lưu mỗi tài liệu một thư mục với cùng bảo đảm như phiên P1, thư viện liệt kê không
  đổi gì trên đĩa (tài liệu hỏng chỉ hiện "không mở được", schema mới hơn hiện "cần cập nhật app"), tạo tài liệu nguyên tử.
- XS-09 PR-3 (#33, chưa nối vào app): migration phiên P1 thành một tài liệu — copy rồi so từng byte bản gốc, commit bằng
  rename, giữ phiên cũ làm bản quay lại không tự xoá, nhật ký để dừng ở bất kỳ bước nào cũng làm tiếp được; tên mặc định
  "Tài liệu dd/MM/yyyy HH:mm".
- XS-13 PR-1 (#36): ô trang trong danh sách hiện ảnh đã cắt và xoay đúng như file xuất (F-026), dựng từ thumbnail; kết quả
  của lần chỉnh cũ không bao giờ hiện thay cho lần chỉnh mới.
- XS-13 PR-2 (#37): trình chỉnh góc hiện trang đúng hướng đã xoay, có Hoàn tác/Làm lại, hỏi "Bỏ thay đổi?" trước khi rời màn khi
  còn thay đổi, kính lúp khi kéo góc, và trình đọc màn hình dịch được từng góc ("Dịch lên/xuống/sang trái/sang phải") (F-032).
- XS-12a PR-1 (#40): khi xuất hiện "Đang xuất trang i/N" với thanh tiến độ và nút "Huỷ"; huỷ dừng ở trang kế tiếp, không để lại
  file dở và báo "Đã huỷ xuất." (F-033). File xuất luôn là các trang lúc bắt đầu xuất.
- XS-09 PR-4a (#43, chưa nối vào app): màn "Thư viện" — danh sách tài liệu mới sửa trước (tên, số trang, ngày), "Tài liệu mới",
  "Đổi tên" báo lỗi tại chỗ, thông báo khi nâng cấp dữ liệu thiếu bộ nhớ hoặc không chuyển được phiên cũ, kèm "Thử lại".
- P0 nền (#1, #2): app Flutter `apps/mobile`, lõi `PageQuad`/`ScanPage`, gate APK debug/analyze/format/test.

## 2026-10-11

- Lưu nghiên cứu scan/PDF/ảnh/OCR/depth làm gợi ý.
- Áp dụng projects-template, provenance, project brief và gate repository.

Chưa có app release.
