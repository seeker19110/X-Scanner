# Chính sách giữ dữ liệu tạm và artefact — X-Scanner

> XC-GREEN-007. Lập 2026-10-24 từ code tại `edbdc50`. Bảng đầy đủ mọi dữ liệu (kể cả dữ liệu người dùng giữ lâu dài):
> `docs/privacy/data-map.yaml`. Đổi cách dọn file tạm → sửa file này và test tương ứng trong cùng PR.

## File tạm trong app

| Dữ liệu tạm | Nơi | Khi nào bị xoá | Code | Test |
|---|---|---|---|---|
| File xuất PDF/JPG/PNG | `getTemporaryDirectory()/exports` | Đầu mỗi lần xuất (xoá kết quả lần trước), sau khi chia sẻ xong/huỷ/lỗi (`finally` → `clear()`), và khi mở một tài liệu (`clearLeftovers()`) | `apps/mobile/lib/export/page_exporter.dart` (`clear`, `clearLeftovers`); gọi ở `apps/mobile/lib/ui/session_controller.dart` (`_restoreDocument`, `finally` của xuất) | `apps/mobile/test/export/page_exporter_test.dart` ("a new export removes the files of the previous one", "clear removes the directory and tolerates a missing one") |
| Bản sao share_plus giữ lại | `getTemporaryDirectory()/share_plus` | Khi mở một tài liệu (`clearLeftovers()`), lúc chắc chắn không còn chia sẻ nào đang đọc | `apps/mobile/lib/main.dart` (`leftoverDirs`), `page_exporter.dart` | `page_exporter_test.dart` ("clearLeftovers also removes copies kept by the share sheet") |
| Bản sao ảnh của image_picker | cache (thư mục tạm của app; photo picker chép vào `cache/{uuid}/`) | Ngay sau khi app lưu bản gốc riêng (`discard`); thư mục `{uuid}` rỗng cũng xoá. Xoá lỗi thì để hệ điều hành thu hồi cache | `apps/mobile/lib/ui/page_source.dart` (`ImagePickerPageSource.discard`) | `apps/mobile/test/ui/page_source_test.dart` (F-005) |
| `*.part`, `*.tmp` khi ghi | trong `documents/{id}/`, `pending-pick/`, `migration.json.tmp` | Xoá ở lần `load`/chạy lại kế tiếp | `apps/mobile/lib/storage/document_store.dart`, `pending_pick_store.dart`, `p1_migration.dart` | `apps/mobile/test/storage/document_store_test.dart` ("load cleans orphan originals and .part files"); `p1_migration_test.dart` ("copying with a partial .part reruns with the same id") |
| Nhật ký migration `migration.json` | app support | Xoá khi migration hoàn tất | `p1_migration.dart` | `apps/mobile/test/storage/p1_migration_test.dart` |

Mọi bước dọn là "best effort": lỗi xoá không báo người dùng, không log, và được thử lại ở lần dọn sau.

## Dữ liệu giữ có chủ đích (không phải "phòng khi")

| Dữ liệu | Vì sao giữ | Tới khi | Dấu nợ |
|---|---|---|---|
| `session.migrated*` | bản quay lại sau migration P1 (ADR-0011) | xoá dữ liệu app | chờ XS-10 có UI xoá |
| `pending-pick.rejected-*` | không mất ảnh người dùng chọn nhưng app không đọc được | xoá dữ liệu app | `DEBT:` trong `pending_pick_store.dart` |
| Tài liệu hỏng bị cách ly | không xoá dữ liệu không đọc được | xoá dữ liệu app | `DEBT:` trong `document_store.dart` |

Các mục này **chưa có hạn tự động**; trước khi phân phối cần spec XS-10 (xoá/thùng rác, thời hạn) — `docs/RISKS.md` RK-010.

## Artefact CI

| Artefact | Giữ | Cấu hình |
|---|---|---|
| Gói APK debug UAT | 14 ngày | `.github/workflows/ci.yml` (`retention-days: 14`) |
| Log run Actions | theo mặc định của repo GitHub (chưa đặt riêng) | Settings → Actions → General (chủ repo) |
