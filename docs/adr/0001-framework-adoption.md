# ADR-0001: Áp dụng projects-template

Date: 2026-10-11. Status: Accepted — framework adoption only.
Chủ repo yêu cầu lưu gợi ý rồi áp template lên repo trống.
Nhập nguồn `aab9f887ec4acc4480da852cc300978979087f6b` bằng copy-framework.sh; giữ docs, hooks, agents, scripts và provenance.
Cá nhân hóa brief/tiến độ, gate repository; hoãn workflow phụ thuộc stack/quyền cài đặt.
Không chọn Flutter/native/OCR/depth engine hoặc X-Agents ở ADR này.
Rollback bằng revert commit adoption/config, giữ research; không force-push.
Nâng cấp sau dùng copy-framework.sh --upgrade và review diff/gate; không tự đồng bộ nguồn.
