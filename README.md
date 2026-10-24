# X-Scanner

Ứng dụng scan tài liệu, hướng tới xuất **PDF hoặc ảnh**.
**Trạng thái (2026-10-23): app Android offline mở vào thư viện nhiều tài liệu (XS-09); mỗi tài liệu: chụp bằng camera hệ thống hoặc nhập ảnh, sắp xếp, xoay, chỉnh 4 góc, giữ bản gốc, xuất PDF/JPG/PNG qua share sheet. Dữ liệu P1 được chuyển một lần sang thư viện. P1 AC-9 đã nghiệm thu trên emulator 18/10; bản có thư viện chưa chạy trên emulator/thiết bị.**

## Bắt đầu

- [Nâng trải nghiệm và hiệu năng](docs/specs/2026-10-23-scanner-experience.md): giao diện thích ứng, nút chỉnh góc, JPEG thumbnail tiết kiệm RAM; giữ camera/ảnh gốc và PDF/JPG/PNG. Bằng chứng từng bước: [hồ sơ 23/10](docs/work/2026-10-23-scanner-experience/done.md).
- [Nghiên cứu nâng cấp ngày 16/10/2026](docs/research/2026-10-16-upgrade-research.md): hiện trạng code/CI, đối chiếu repo sở hữu và nguồn chính thức, ưu tiên và tiêu chí kiểm chứng; ADVISORY.
- [Gợi ý sản phẩm, repo tham khảo và depth](docs/research/2026-10-11-scanner-product-suggestions.md): ADVISORY.
- [Kế hoạch phát triển toàn diện](docs/plans/2026-10-12-comprehensive-development-plan.md): M0–M5, depth và 33 đầu việc XS-01..XS-33; đề xuất, chưa phải phê duyệt triển khai toàn bộ.
- [Corpus và benchmark XS-06a](docs/benchmarks/README.md): fixture tổng hợp có checksum, đo core thumbnail/render/PDF trên host; protocol và giới hạn so với thiết bị.
- [Hàng rào repository XS-05](docs/ops/x-scanner-repository-guards.md): required check đúng nguồn GitHub Actions, dependency review và cách kiểm native settings.
- [Stack: ADR-0002](docs/adr/0002-flutter-android-first-stack.md), [ADR-0003 lựa chọn P1](docs/adr/0003-p1-system-camera-dart-imaging-pdf.md), [spec P0 nền](docs/specs/2026-10-11-p0-foundation.md), [spec P1 scan và xuất](docs/specs/2026-10-11-p1-scan-export.md).
- [Bản đồ tính năng](docs/FEATURE-MAP.md), [sửa ở đâu](CODEMAP.md), [quy ước](docs/CONVENTIONS.md), [kế hoạch hoàn thiện](docs/ops/COMPLETION-PLAN.md).
- [Phạm vi](PROJECT.md), [tiến độ](PROGRESS.md), [hướng dẫn agent](AGENTS.md).
- [Quy trình chuẩn](docs/framework/standard-delivery.md), [quickstart](docs/framework/quickstart.md).
- [Áp dụng template và phần còn hoãn](docs/adoption/README.md).

Nguồn: `seeker19110/projects-template` tại `aab9f887ec4acc4480da852cc300978979087f6b`, nhập bằng script copy chính thức.

## Kiểm tra

Cần Git, Bash >=4, Python 3, jq, coreutils (sha256sum/mkdir), Flutter 3.47.7 và Android SDK (compileSdk 36, Java ≥17); Windows dùng Git Bash.

```bash
git config core.hooksPath scripts/githooks
bash scripts/dev-task.sh doctor
bash scripts/dev-task.sh gate
```

Gate chạy build APK debug, kiểm manifest release đã gộp (`scripts/check-release-manifest.py`), analyze, format, test của app và kiểm tra repository/hooks.
CI xanh cung cấp [APK UAT kèm checksum và commit SHA](docs/ops/android-uat.md), giữ 14 ngày trong Artifacts của run; đây là bản debug để thử nghiệm.
Không chứng minh build iOS, chụp/xuất trên thiết bị thật, depth, chất lượng scan hay OCR. Không commit tài liệu cá nhân hoặc khóa API.
Giấy phép sản phẩm chưa chọn; license nguồn giữ ở `third_party/projects-template.LICENSE`.
