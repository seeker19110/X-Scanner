# Biên bản diễn tập ứng phó sự cố — <YYYY-MM-DD>

> Chép file này thành `docs/ops/incidents/drill-<YYYY-MM-DD>.md` rồi thêm một dòng vào bảng "Diễn tập" trong `README.md`.
> Diễn tập dùng dữ liệu/khoá **giả** — không dùng tài liệu thật, không tạo khoá thật để "lộ thử".

- **Kịch bản:** <vd: token GitHub giả bị commit lên nhánh thử / migration P1 báo sai byte trên thiết bị thử / APK UAT checksum sai>
- **Người điều phối:** <tên>
- **Người tham gia:** <tên/vai>
- **Môi trường:** <nhánh thử, emulator, repo fork…>
- **Bắt đầu / kết thúc (UTC):** <> / <>

## Các bước đã chạy (theo `docs/ops/RUNBOOK.md` §5–§6)

| Bước | Lệnh / thao tác | Thời điểm (UTC) | Kết quả | Lệch so với runbook |
|---|---|---|---|---|
| Phát hiện & mở issue `incident` | | | | |
| Phân mức SEV | | | | |
| Bảo toàn chứng cứ | | | | |
| Thu hồi/xoay bí mật (nếu áp dụng) | | | | |
| Đánh giá nghĩa vụ thông báo (giả lập) | | | | |
| Ghi sổ `README.md` | | | | |

## Kết luận

- Thời gian từ phát hiện tới giảm thiệt hại: <phút>
- Điều chạy tốt:
- Điều cần sửa trong runbook (mỗi mục → issue có người phụ trách + hạn):
- Cập nhật `last_drilled` trong `docs/ops/RUNBOOK.md`: <đã/chưa>
