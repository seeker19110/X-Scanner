# X-Scanner app (Flutter, Android trước)

Scan tài liệu offline: chụp bằng camera hệ thống hoặc nhập ảnh, chỉnh 4 góc, lưu từng tài liệu trong thư viện giữ bản gốc,
xuất PDF/JPG/PNG qua share sheet. Spec: `docs/specs/2026-10-11-p1-scan-export.md`.

```bash
flutter run                      # chạy trên emulator/thiết bị Android
flutter test                     # test của app
bash ../../scripts/dev-task.sh gate   # cổng đầy đủ (chạy từ bất kỳ đâu trong repo)
```

- Cấu trúc `lib/`: `core/` (kiểu thuần Dart), `imaging/`, `storage/`, `export/`, `ui/`, `app/` — sửa ở đâu: `CODEMAP.md` ở gốc repo.
- Tính năng: `docs/FEATURE-MAP.md`; quy ước: `docs/CONVENTIONS.md`.
