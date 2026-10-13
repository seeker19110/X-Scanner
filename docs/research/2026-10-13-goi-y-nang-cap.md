# Gợi ý nâng cấp — rà soát 2026-10-13

> Lấy từ đợt rà soát chéo 19 repo của chủ sở hữu (ma trận vệ sinh ở [seeker19110/stored, mục 23 §8.1](https://github.com/seeker19110/stored/blob/main/23-own-repos-lessons/README.md); gợi ý tích hợp ở §7b của cùng file). Số liệu đo bằng lệnh trên HEAD (đếm `uses:` ghim SHA 40 ký tự, khối `permissions:`, `dependabot.yml`, `.claude/settings.json`), không suy ra từ văn xuôi. Đây là **đề xuất**, chưa sửa code. Mỗi mục kèm bằng chứng để kiểm lại trước khi làm; mục nào đã xử lý thì đánh dấu hoặc xoá.

## Hiện trạng đo được

| HEAD đọc | Action ghim SHA | Workflow thiếu `permissions:` cấp đầu | Dependabot | LICENSE · SECURITY | File test |
|---|---|---|---|---|---|
| `b5638d0` (2026-10-13) | 2/2 | – | **không có** | không · có | 32 |

## Đề xuất (🔴 cao · 🟠 trung bình · 🟢 nhẹ)

| # | Mức | Đề xuất | Bằng chứng | Kiểm xong khi |
|---|---|---|---|---|
| 1 | 🟠 | Thêm `auto-complete-guard.sh` từ khung và đăng ký vào Stop | `.claude/hooks/` không có file này; Stop chỉ gọi `usage-guard.sh` và `telemetry-record.sh` (khung có thêm guard). Lỗi đã ghi từ ngày 12/10 và vẫn còn sau 39 commit | File có mặt và workflow `adopt-projects-template.yml` không báo lệch |
| 2 | 🟠 | Thêm `.github/dependabot.yml` (ecosystem `pub` cho Flutter và `github-actions`) | Không có Dependabot; 2/2 action đã ghim SHA, nhưng không có bot thì SHA sẽ cũ dần | Dependabot mở PR đầu tiên |
| 3 | 🟢 | Chọn LICENSE, hoặc ghi rõ "giữ mọi quyền" | Không có file LICENSE | Có `LICENSE` hoặc dòng tương ứng trong README |

## Giữ nguyên (điểm mạnh)

- Áp khung bằng GitHub Action ghim SHA; 54 mục deny và 77 mục allow giống khung; TRAPS.md.

## Gợi ý tích hợp từ catalog `stored`

- Chọn model VLM / multimodal cho OCR và hiểu tài liệu (stored mục 14).

## Ghi chú chung

- Ghim action theo SHA bằng [pinact](https://github.com/suzuki-shunsuke/pinact) hoặc [ratchet](https://github.com/sethvargo/ratchet), giữ comment tag (`# v7.0.1`), rồi để Dependabot `github-actions` tự nâng SHA. Đây là cách projects-template, xboss và Sales-Hunter đang làm.
- Chuẩn tham chiếu là `seeker19110/projects-template`: 25/25 action ghim SHA, mọi workflow có `permissions:` cấp đầu, Dependabot cho npm, github-actions và pip.
