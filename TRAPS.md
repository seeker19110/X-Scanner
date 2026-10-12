# TRAPS.md — bẫy đã mắc trong repo này

> Sổ bẫy ĐÃ MẮC THẬT. Mỗi mục có ngày + PR + cách rà + test chốt chặn. Khác `docs/adr/`: ADR ghi quyết định;
> file này ghi lỗi đã xảy ra và khuôn của nó. Gặp triệu chứng lạ → tìm khuôn ở đây trước (`/debug` Pha 1).
> Sửa bug xong → thêm mục mới hoặc thêm ngày/PR vào mục cũ nếu tái phát.

**Dọn "file không được tham chiếu" xoá bản gốc của phiên chưa đọc được.** Bước dọn của `SessionStore.load`
xoá mọi file trong `originals/` không có trong manifest hiện tại. Khi manifest cũ bị cách ly (hỏng) hoặc không
đọc được, "không được tham chiếu" không có nghĩa là "rác": đó là bản gốc duy nhất của phiên trước. Lỗi im lặng
vì app vẫn chạy bình thường, chỉ ảnh biến mất ở lần mở sau. *Cách rà*: mọi chỗ xoá trong `originals/` — hỏi
"manifest nào đang chứng minh file này là rác, và manifest đó đã thật sự được đọc xong chưa?". *Chốt chặn*:
`apps/mobile/test/storage/session_store_test.dart` `a later new session never deletes the quarantined originals`.
(2026-10-11, seeker19110/X-Scanner#7)

_Tái phát 2026-10-12_: `load` lỗi I/O (không phải manifest hỏng) không cách ly gì, `save` sau đó ghi đè manifest,
lần mở sau xoá bản gốc cũ (F-001, W-101). Bài học: "không được tham chiếu" chỉ đúng khi một manifest đã **load
xong** cùng store.

**Lấy mẫu pixel ngoài biên làm viền ảnh tối.** Nắn phối cảnh lấy mẫu song tuyến tại `p − 0,5`; ở mép ảnh
`getPixelLinear` đọc pixel −1 (đen) nên viền trang trắng thành xám (229 thay 255). *Cách rà*: test ảnh trắng
đồng nhất, kiểm pixel ở 4 mép đầu ra. *Chốt chặn*: `apps/mobile/test/imaging/page_render_test.dart`.
(2026-10-11, seeker19110/X-Scanner#8)

**Ảnh 16-bit bị cắt về 0 khi mã hoá.** Ảnh PNG 16-bit/kênh mã hoá thẳng sang JPEG 8-bit cho ảnh đen.
*Cách rà*: mọi đường mã hoá đầu ra phải chuẩn hoá về 8-bit/kênh trước. *Chốt chặn*: test ảnh 16-bit trong
`apps/mobile/test/imaging/page_render_test.dart`. (2026-10-11, seeker19110/X-Scanner#8)

**Plugin nền tảng để lại bản sao tài liệu trong cache của app.** `image_picker_android` ghi ảnh chụp vào cache
và chép ảnh chọn từ thư viện vào `cache/{uuid}/`; app chép sang `originals/` nhưng không xoá bản của plugin, nên
ảnh tài liệu còn trên máy sau khi người dùng xoá trang hoặc xoá tất cả (F-005). *Cách rà*: mỗi plugin trả về một
đường dẫn file — đọc mã nguồn plugin xem file đó nằm đâu và ai xoá nó. *Chốt chặn*:
`apps/mobile/test/ui/page_source_test.dart` và các test "(F-005)" trong `apps/mobile/test/ui/session_controller_test.dart`.
(2026-10-12, W-102)

**Thao tác theo chỉ số vẫn nhận được khi app bận.** Mọi nút tắt khi `busy` nhưng kéo-thả vẫn bật; `move(from, to)`
vào hàng đợi ghi sau các thao tác đang chờ và chạy với chỉ số cũ, nên chuyển nhầm trang (F-007). *Cách rà*: mỗi
cử chỉ/nút tạo một thao tác mang chỉ số hoặc id — nó có bị tắt cùng các nút khi bận không. *Chốt chặn*: test
"(F-007)" trong `apps/mobile/test/ui/review_screen_test.dart`. (2026-10-12, W-103)
