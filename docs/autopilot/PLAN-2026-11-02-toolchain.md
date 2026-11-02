# X-Scanner — khôi phục toolchain và kiểm chứng bản cập nhật khung

> Phiên chính tự duyệt theo §3d ngày 2026-11-02; Work ID: 2026-11-02-xtemplates-completion. Scope P1/XS-09 đã duyệt, không mở roadmap P2+. Blueprint mobile-app/M hiện có là snapshot audit, không tự tick hoặc biến yêu cầu mới của khung thành phạm vi sản phẩm.

## Mục tiêu
Khôi phục Flutter 3.47.7 và JDK/Android SDK ở máy dev; gate thật phải chạy đủ trước commit. Giữ bằng chứng và phần còn chờ, không khai Project Complete từ build/test host.

## Ngân sách
- Tối đa 40 vòng, 4 giờ phiên này; không dịch vụ trả phí.
- Timeout mỗi Gate 1800 giây; mỗi failure tối đa 3 lần, không skip/hạ ngưỡng.
- Một outcome/PR nối nhánh codex/xtemplates-completion; phiên chính làm tuần tự, tooling ngoài repo không có interface sản phẩm cần phân chia.
- Dữ liệu UAT chỉ tổng hợp. Không release/ký/upload tài liệu/auto-merge/ruleset hay đổi cổng để xanh.

## Công việc

- [x] `T-101` Khôi phục toolchain đúng pin từ nguồn chính thức, đối chiếu SHA256 Flutter với CI; Given launcher thiếu SDK, When khôi phục, Then Flutter 3.47.7 và Java 21 chạy thật (local Ubuntu OpenJDK, CI giữ Temurin theo .java-version); thiếu checksum thì dừng. (files: docs/work/2026-11-02-xtemplates-completion/) — Gate: `flutter --version --machine && java -version && adb version`
- [x] `T-102` Chạy toàn bộ gate của repo sau cập nhật, Given toolchain sẵn sàng, When gate chạy, Then build/analyze/format/test/coverage/JVM và repo checks đều đạt; đỏ thì không commit. (sau: T-101; files: .) — Gate: `bash scripts/dev-task.sh gate 2>&1 | tee /tmp/x-scanner-autopilot-gate-full.log`

## Sau đợt
Audit delta bản cập nhật khung, verify --all, tự review diff và báo cáo gate theo CLAUDE §7. Khi xanh mới chuẩn bị commit/PR đúng luật. W-602/F-078 migration UAT, owner/legal/release ở GO-NO-GO tiếp tục giữ trạng thái thật; chỉ đóng khi có bằng chứng thiết bị riêng. Scope của đợt này không phải release readiness.
