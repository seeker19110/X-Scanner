# X-Scanner

Ứng dụng scan tài liệu, hướng tới xuất **PDF hoặc ảnh**.
**Trạng thái: bộ khung phát triển; chưa có ứng dụng chạy được.**

## Bắt đầu

- [Gợi ý sản phẩm, repo tham khảo và depth](docs/research/2026-10-11-scanner-product-suggestions.md): ADVISORY, chưa chốt stack.
- [Phạm vi](PROJECT.md), [tiến độ](PROGRESS.md), [hướng dẫn agent](AGENTS.md).
- [Quy trình chuẩn](docs/framework/standard-delivery.md), [quickstart](docs/framework/quickstart.md).
- [Áp dụng template và phần còn hoãn](docs/adoption/README.md).

Nguồn: `seeker19110/projects-template` tại `aab9f887ec4acc4480da852cc300978979087f6b`, nhập bằng script copy chính thức.

## Kiểm tra

Cần Git, Bash >=4, Python 3 và jq; Windows dùng Git Bash. Chưa chọn SDK mobile.

```bash
git config core.hooksPath scripts/githooks
bash scripts/dev-task.sh doctor
bash scripts/dev-task.sh gate
```

Gate hiện tại chỉ kiểm tra repository, tài liệu, cấu hình và hooks; không phải app build/scan/OCR.
Thêm lệnh build/typecheck thật khi stack được duyệt. Không commit tài liệu cá nhân hoặc khóa API.
Giấy phép sản phẩm chưa chọn; license nguồn giữ ở `third_party/projects-template.LICENSE`.
