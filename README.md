# X-Scanner

Ứng dụng scan tài liệu, hướng tới xuất **PDF hoặc ảnh**.
**Trạng thái: P0 nền — app Flutter `apps/mobile` build được APK debug; chưa có chức năng chụp.**

## Bắt đầu

- [Gợi ý sản phẩm, repo tham khảo và depth](docs/research/2026-10-11-scanner-product-suggestions.md): ADVISORY.
- [Stack: ADR-0002](docs/adr/0002-flutter-android-first-stack.md), [spec P0 nền](docs/specs/2026-10-11-p0-foundation.md).
- [Phạm vi](PROJECT.md), [tiến độ](PROGRESS.md), [hướng dẫn agent](AGENTS.md).
- [Quy trình chuẩn](docs/framework/standard-delivery.md), [quickstart](docs/framework/quickstart.md).
- [Áp dụng template và phần còn hoãn](docs/adoption/README.md).

Nguồn: `seeker19110/projects-template` tại `aab9f887ec4acc4480da852cc300978979087f6b`, nhập bằng script copy chính thức.

## Kiểm tra

Cần Git, Bash >=4, Python 3, jq, Flutter 3.47.7 và Android SDK (compileSdk 36, Java ≥17); Windows dùng Git Bash.

```bash
git config core.hooksPath scripts/githooks
bash scripts/dev-task.sh doctor
bash scripts/dev-task.sh gate
```

Gate chạy build APK debug, analyze, format, test của app và kiểm tra repository/hooks.
Không chứng minh build iOS, camera/depth trên thiết bị, chất lượng scan hay OCR. Không commit tài liệu cá nhân hoặc khóa API.
Giấy phép sản phẩm chưa chọn; license nguồn giữ ở `third_party/projects-template.LICENSE`.
