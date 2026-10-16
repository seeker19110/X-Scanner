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
cử chỉ/nút tạo một thao tác mang chỉ số hoặc id — nó có bị tắt cùng các nút khi bận không. **Tái phát (F-051):**
tắt tay kéo không tắt thao tác ngữ nghĩa Move up/down mà `ReorderableListView` gắn cho mỗi dòng; chúng gọi thẳng
`onReorderItem`. Chặn ở callback (`if (busy) return`), không chỉ ở widget nhập liệu. *Chốt chặn*: test "(F-007)" và
"(F-051)" trong `apps/mobile/test/ui/review_screen_test.dart`. (2026-10-12, W-103; W-502)

**Cache một `Future` lỗi.** `thumbnailFor` cache future theo id trang; một lần giải mã lỗi (file tạm thời không đọc
được) bị giữ mãi nên trang không chỉnh góc được tới khi mở lại app (F-020). *Cách rà*: mọi map cache `Future` —
nhánh lỗi có cho thử lại không. **Đính chính (F-047):** gỡ future lỗi khỏi map ngay khi lỗi làm MỌI lần dựng lại
widget giải mã lại bản gốc hỏng; giữ future lỗi trong cache, đánh dấu id lỗi (so `identical`) và chỉ gỡ khi người dùng
bấm thử lại (`retryThumbnail`). *Chốt chặn*: test "(F-020)"/"(F-047)" trong
`apps/mobile/test/ui/session_controller_test.dart` và `review_screen_test.dart`. (2026-10-12, W-402; W-502)

**So sánh ruleset thiếu mặc định phía GitHub báo drift giả.** Sau POST cấu hình XS-05, GitHub
trả thêm `required_reviewers: []` và `require_extra_approval_for_unattributed_changes: true`,
làm so sánh nguyên rule đỏ dù các giá trị đã yêu cầu khớp. *Cách rà*: đọc nguyên readback,
đối chiếu tài liệu chính thức trước khi bỏ qua field hoặc hạ rule; extra approval không tăng
count khi required approvals=0. *Chốt*: khai rõ mặc định đã kiểm trong `.github/rulesets/main.json`,
so JSON với readback thật và kiểm CI không đạt bị BLOCKED; không nuốt mọi field lạ.
(2026-10-16, Work ID `2026-10-16-xs05-repository-guards`; evidence trong hồ sơ)
