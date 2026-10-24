# Đóng góp

Đọc PROJECT.md, AGENTS.md và docs/framework/standard-delivery.md.
Mỗi thay đổi theo spec/Work ID; advisory không tự cấp phép triển khai.
Chạy doctor/gate, dùng worktree riêng và chỉ chia việc khi file/contract độc lập.
Không commit dữ liệu người dùng/secrets; báo đúng kiểm tra đã chạy và còn thiếu.
Dữ liệu test chỉ dùng dữ liệu tổng hợp: `docs/compliance/test-data-policy.md`. Lỗ hổng bảo mật: `SECURITY.md`.

## Nhánh dùng chung và lịch sử Git

**Nhánh dùng chung** là: `main`; mọi nhánh đã mở PR (kể cả draft) hoặc đã có review; mọi nhánh mà người khác hay agent khác
đang làm hoặc đã kéo về (worktree khác, phiên AI khác, Dependabot).

- Trên nhánh dùng chung: **không** `git push --force`/`--force-with-lease`, **không** `rebase`, `commit --amend`, `reset` làm đổi
  commit đã đẩy. Sửa bằng commit mới; cập nhật từ `main` bằng `git merge main` (hoặc nút "Update branch" của PR).
- Chỉ được viết lại lịch sử trên **nhánh cá nhân chưa chia sẻ** (chưa push, hoặc đã push nhưng chưa mở PR và chắc chắn không ai
  khác dùng). Mở PR rồi thì nhánh thành dùng chung.
- `main` được ruleset chặn force-push và bắt buộc PR + check `Framework and Android app gate`, không bypass
  (`docs/ops/x-scanner-repository-guards.md`). Merge PR bằng squash.
- Nhánh Dependabot do bot quản lý: không push commit tay lên đó trừ khi `docs/ops/dependency-updates.md` cho phép.
- Lỡ viết lại nhánh dùng chung: dừng, báo người cùng làm trên PR, không force-push thêm để "sửa"; khôi phục từ `git reflog`
  bằng commit mới.
