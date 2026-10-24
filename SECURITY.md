# Chính sách bảo mật

## Phiên bản được hỗ trợ

X-Scanner **chưa có bản phát hành**. Chỉ nhánh `main` mới nhất được nhận bản sửa bảo mật. APK debug do CI tạo
(`docs/ops/android-uat.md`) chỉ để thử nghiệm và không được hỗ trợ như bản phát hành.

| Phiên bản | Hỗ trợ |
|---|---|
| `main` (mới nhất) | Có |
| Commit cũ hơn, APK debug từ CI cũ | Không — cập nhật lên `main` |

## Báo lỗ hổng (kênh riêng)

1. Dùng **GitHub Security Advisories**: tab **Security** của repo → **Report a vulnerability**
   (https://github.com/seeker19110/X-Scanner/security/advisories/new). Báo cáo chỉ chủ repo và người được mời thấy.
2. **Không** mở issue/PR công khai mô tả chi tiết lỗ hổng, và **không** đính kèm ảnh giấy tờ thật, nội dung OCR, khoá truy cập
   hay dữ liệu cá nhân. Dùng ảnh/tài liệu tổng hợp để tái hiện.
3. Nếu nút **Report a vulnerability** chưa hiện (tính năng private vulnerability reporting đang **tắt** khi kiểm ngày
   2026-10-24 — chủ repo cần bật ở Settings → Code security), mở một issue công khai **chỉ** với tiêu đề
   "Yêu cầu kênh báo bảo mật riêng", không kèm chi tiết; chủ repo sẽ mở kênh riêng.

Nên gửi: mô tả, phiên bản/commit, thiết bị và Android, bước tái hiện, ảnh hưởng dự kiến.

## Thời hạn phản hồi

- Phản hồi ban đầu (xác nhận đã nhận): **trong vòng 14 ngày**.
- Sau khi xác nhận lỗ hổng: đánh giá mức theo `docs/ops/RUNBOOK.md` §5 và báo kế hoạch xử lý cho người báo.

## Công bố phối hợp

Chúng tôi đề nghị người báo không công bố cho tới khi có bản sửa trên `main` hoặc sau 90 ngày kể từ khi xác nhận, tuỳ điều nào
đến trước; hai bên có thể thống nhất thời hạn khác. Bản sửa được ghi trong `CHANGELOG.md` (nhóm Security) và GitHub Security
Advisory, ghi công người báo nếu họ đồng ý.

## Phạm vi

Trong phạm vi: app `apps/mobile` (lưu trữ trên máy, giải mã ảnh, xuất/chia sẻ, migration), workflow CI và script trong repo.
Mô hình đe doạ: `docs/THREAT-MODEL.md`. Ngoài phạm vi: lỗ hổng của Android, app camera/trình xem PDF bên thứ ba, hay thiết bị
đã root.
