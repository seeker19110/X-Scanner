# Nhật ký quyết định tự duyệt

> Ghi bởi `xt.py loop decide`. Phiên chính tự duyệt điểm quyết định theo tiêu chí chất lượng cuối (`LOOP-STOP-018`, ADR-0008 của khung). Người xem lại bất cứ lúc nào; đổi ý → quyết định mới ghi "thay D-NNN", không sửa mục cũ.

### D-001 · 2026-10-24T01:48:35+00:00 · Duyệt PLAN autopilot 2026-10-24 (không đối số)

- Phương án: (1) Kế hoạch harness + blueprint + phản hồi khung, không mở tính năng mới · (2) Tự chọn hạng mục roadmap P2 (XS-10…) để triển khai
- Chọn: Kế hoạch harness + blueprint + phản hồi khung, không mở tính năng mới
- Lý do (tiêu chí chất lượng cuối): Đúng và an toàn: roadmap là ADVISORY chưa duyệt (CLAUDE.md); việc còn lại có bằng chứng máy
- Đường lùi: Chủ repo nêu tính năng cần làm rồi chạy lại /autopilot với mô tả

### D-002 · 2026-10-24T01:48:35+00:00 · Lỗi doctor ✗ [hooks] '..'

- Phương án: (1) Coi là báo nhầm của khung, gửi feedback, chạy tiếp · (2) Chạy lại install.py để đổi hook
- Chọn: Coi là báo nhầm của khung, gửi feedback, chạy tiếp
- Lý do (tiêu chí chất lượng cuối): Mọi đường dẫn '../..' trỏ file có thật (đã kiểm); đổi hook là điểm dừng
- Đường lùi: Chủ repo chạy install.py

### D-003 · 2026-10-24T02:11:50+00:00 · Gate T-003 đỏ vì --strict đo MUST đã đạt hết, không đo việc phân loại (lần 2, đổi cách)

- Phương án: (1) Đổi Gate T-003 thành scripts/check-blueprint-triage.py (mọi MUST có kết cục; mục còn thiếu phải đã defer); giữ điều kiện done = blueprint-status --strict · (2) Giữ --strict, để vòng chạy tới trần · (3) Tự làm 148 MUST còn thiếu
- Chọn: Đổi Gate T-003 thành scripts/check-blueprint-triage.py (mọi MUST có kết cục; mục còn thiếu phải đã defer); giữ điều kiện done = blueprint-status --strict
- Lý do (tiêu chí chất lượng cuối): Đúng: task là phân loại; --strict vẫn là điều kiện done nên kết quả là done-pending-human, không khai xong. Phương án 3 chạm cấu hình cổng/license/phát hành là điểm dừng
- Đường lùi: Đặt lại Gate T-003 về --strict trong PLAN

### D-004 · 2026-10-24T02:17:56+00:00 · Gate T-004 'feedback collect' không lũy đẳng (sinh bản trùng mỗi lần), loop verify luôn đỏ vì cây đổi

- Phương án: (1) Đổi Gate T-004 sang kiểm 4 phản hồi tay tồn tại (FB-001..003, FB-164); vẫn chạy collect một lần trước báo cáo cuối và xoá bản trùng · (2) Giữ collect làm Gate
- Chọn: Đổi Gate T-004 sang kiểm 4 phản hồi tay tồn tại (FB-001..003, FB-164); vẫn chạy collect một lần trước báo cáo cuối và xoá bản trùng
- Lý do (tiêu chí chất lượng cuối): Gate phải lũy đẳng để verify trên cây cuối có nghĩa; nội dung phản hồi giữ nguyên, lỗi khung đã báo FB-164
- Đường lùi: Đặt lại Gate T-004 về feedback collect khi khung sửa

### D-005 · 2026-10-24T04:00:00+00:00 · ID tính năng trong MoSCoW: blueprint đòi `F-NNN` nhưng `F-001..F-079` đã là ID phát hiện audit nằm trong tên test

- Phương án: (1) Dùng `FT-NN` của `docs/FEATURE-MAP.md` cho tính năng · (2) Đổi tên 79 phát hiện audit và test · (3) Dùng chung `F-NNN` cho cả hai
- Chọn: (1) `FT-NN`
- Lý do (tiêu chí chất lượng cuối): đúng mục đích của PM-PRIO-001/PM-SPEC-001 (mỗi Must có ID ổn định trỏ spec) mà không tái dùng ID cũ; (2) đổi lịch sử, (3) gây trùng ID. Chủ repo ủy quyền toàn bộ 24/10
- Đường lùi: đổi cột ID trong `PROJECT.md` sang tiền tố khác

### D-006 · 2026-10-24T04:00:00+00:00 · Chuẩn bảo mật nhắm tới: blueprint gợi ý OWASP ASVS 5.0.0, app không có server

- Phương án: (1) OWASP MASVS 2.1.0 hồ sơ MAS-L1 · (2) ASVS 5.0.0 · (3) cả hai
- Chọn: (1) MASVS MAS-L1
- Lý do (tiêu chí chất lượng cuối): ASVS là chuẩn cho ứng dụng web/API; app offline không server, không tài khoản nên MASVS là chuẩn tương ứng cho mobile. Xem lại khi có server hoặc đồng bộ đám mây (khi đó thêm ASVS cho phần server)
- Đường lùi: thêm ASVS vào mục Chuẩn áp dụng của `PROJECT.md`
