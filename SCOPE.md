# SCOPE.md — thay đổi phạm vi X-Scanner

> PM-PRIO-004. Phạm vi MVP = bảng "Tính năng MVP (MoSCoW)" trong `PROJECT.md` cộng các spec có `Approved for implementation`
> trong `docs/specs/`. File này giữ **điều kiện xét** và **nhật ký thay đổi**; nội dung phạm vi vẫn sống ở `PROJECT.md`.

## Mốc đóng băng

Phạm vi được duyệt theo từng spec (P0, P1 ngày 2026-10-11; XS-09 ngày 2026-10-12, PR-4 do chủ repo duyệt). Bảng MoSCoW
lập lại ngày 2026-10-24 từ các spec đó (không thêm tính năng mới); đây là mốc tham chiếu cho mọi thay đổi sau.

## Điều kiện xét một thay đổi phạm vi

1. Có lý do kiểm được (lỗi người dùng, rủi ro trong `docs/RISKS.md`, ràng buộc pháp lý) — không phải "tiện thì làm".
2. Ghi rõ mục bị đẩy ra hoặc hạ mức để bù (Must → Should/Could/Won't), trừ khi chủ repo nói rõ chấp nhận tăng phạm vi.
3. Tính năng mới mức M/L vẫn cần spec `Approved for implementation` trước khi sửa source (`AGENTS.md` "Feature gate").
4. Người quyết: chủ repo. Phiên AI chỉ đề xuất; tài liệu ADVISORY (`docs/research/`, `docs/plans/`) không tự thành phạm vi.

## Cách ghi

- Sửa bảng MoSCoW trong `PROJECT.md` **và** thêm một dòng vào bảng dưới, trong **cùng một commit** có tiêu đề
  `docs(scope): <tóm tắt thay đổi>`; thân commit nêu mục thêm/bớt và mục bù.
- Kiểm: `git log --oneline --grep '^docs(scope)'` liệt kê đủ các dòng trong bảng.

## Nhật ký

| Ngày | Thay đổi | Mục bị đẩy ra / hạ mức để bù | Người quyết | Commit |
|---|---|---|---|---|
| 2026-10-24 | Lập mốc tham chiếu từ spec đã duyệt (không đổi phạm vi) | — | phiên AI ghi nhận; chủ repo chưa xác nhận | commit thêm file này |
