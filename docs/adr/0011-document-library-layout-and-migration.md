# ADR-0011: Thư viện tài liệu lưu mỗi tài liệu một thư mục; migration P1 copy rồi kiểm byte, giữ bản quay lại

- **Trạng thái:** Đã chấp nhận — phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12, cho phạm vi PR-1..PR-3
  của XS-09. Bật migration trên dữ liệu thật (PR-4) chờ chủ repo.
- **Ngày:** 2026-10-12
- **Work ID:** `2026-10-12-xs09-document-library-spec`
- **Spec:** `docs/specs/2026-10-12-document-library-migration.md` (XS-09); tuân ADR-0004 (hợp đồng XS-08)
- **Số hiệu:** bỏ qua 0005–0010 vì luật khung (`CLAUDE.md`, `docs/framework/`) đã dùng ADR-0005..ADR-0010 của repo khung
  (vd ADR-0005 = TDD đỏ-trước); đánh số tiếp từ 0011 để không trùng tham chiếu.

## Bối cảnh

P1 lưu đúng một phiên: `session/session.json` (schema 1) + `session/originals/`, do `SessionStore` ghi nguyên tử, tuần tự
và cách ly manifest hỏng. XS-09 cần nhiều tài liệu có tên và thời điểm, và phải đưa dữ liệu P1 đang có vào bố cục mới mà
không mất trang hay bản gốc (kế hoạch #23 §10, §11: "0 mất trang/gốc").

## Quyết định

1. **Bố cục:** `documents/{docId}/document.json` (schema 2, ADR-0004) + `documents/{docId}/originals/{pageId}.{ext}`. Tên
   thư mục là `docId` (32 hex) và phải bằng `document.id`; không có chỉ mục chung. Tạo tài liệu = ghi vào `{docId}.part/`
   rồi rename.
2. **Migration P1:** nhật ký `migration.json`; kiểm dung lượng trống ≥ tổng bản gốc + 10 %; **copy** từng bản gốc vào
   `documents/{docId}.part/`, kiểm lại bằng codec + cùng kích thước và **cùng byte** (không hash, D-3); rename-commit; rồi
   `session/` → `session.migrated/`. Dừng ở bất kỳ bước nào → phục hồi theo nhật ký, không bao giờ hai tài liệu cho cùng
   dữ liệu, không xoá `session/` trước khi commit.
3. **Bản quay lại `session.migrated/` được giữ** (D-5); không code nào tự xoá. Xoá là quyết định của chủ repo, cùng XS-10.
4. Ba PR đầu (mô hình + codec, lưu trữ, migration) không nối vào app; PR-4 là công tắc duy nhất đổi hành vi.

## Lý do

- Mỗi tài liệu một thư mục: hỏng một tài liệu không lan sang tài liệu khác, không có chỉ mục phải giữ khớp; dùng lại nguyên
  các bảo đảm của `SessionStore` cho từng thư mục, không dependency mới.
- Copy rồi kiểm thay vì rename từng file: dữ liệu P1 còn đọc được tới khi bản mới đã được kiểm đủ; phục hồi chỉ có hai trạng
  thái nhật ký. So byte chặt hơn hash cho mục đích kiểm một bản copy và không cần `package:crypto`.
- Giữ bản quay lại: tự xoá dữ liệu thật của người dùng là việc §3d không cho phiên chính tự quyết; bớt luôn một nhánh code.

## Các phương án đã cân nhắc

- `library.json` chung + thư mục bản gốc chung: một file hỏng làm mất cả thư viện; phải giữ chỉ mục khớp với đĩa.
- SQLite (`sqflite`/`drift`): dependency + native code mới, migration schema riêng; quá mức cho vài trăm tài liệu offline.
- Rename `session/` thành thư mục tài liệu ngay: nhanh, không tốn gấp đôi dung lượng, nhưng dừng giữa chừng để lại trạng
  thái nửa cũ nửa mới khó phục hồi và không còn bản P1 nguyên vẹn để quay lại.
- Xoá `session.migrated/` ở lần mở sau (đề xuất trong bản nháp): tiết kiệm dung lượng nhưng là thao tác xoá dữ liệu thật tự
  động; để chủ repo quyết.

## Hệ quả

- Tích cực: dừng/hỏng ở bất kỳ bước nào không mất trang; từng tài liệu hỏng độc lập; không dependency mới.
- Đánh đổi: lúc migrate cần dung lượng gấp đôi bản gốc (kiểm trước, lỗi `insufficientSpace` có "Thử lại"); sau migrate bản
  quay lại chiếm thêm đúng dung lượng dữ liệu P1 tới khi chủ repo quyết xoá.
- Việc tiếp theo: XS-09 PR-1..PR-3 theo spec §17; PR-4 (nối `main.dart`, chạy migration trên dữ liệu thật) chờ chủ repo;
  chính sách xoá `session.migrated/` đi cùng XS-10.
