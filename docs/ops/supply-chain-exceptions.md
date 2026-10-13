# Supply-chain exceptions — X-Scanner

> Theo `docs/ops/supply-chain.md` §Exception: owner, lý do, compensating control, hạn, issue/tracker.
> Exception hết hạn tự trở thành blocker release.

| ID | Thành phần | Lý do | Compensating control | Owner | Hạn | Tracker |
|----|-----------|-------|----------------------|-------|-----|---------|
| EX-1 | `image` 4.10.1 (lỗi giải mã: EXIF IFD lặp treo, PNG bom giải nén — F-004) | Bản vá 4.12.0 phát hành 2026-10-11, chưa đủ 7 ngày theo luật ghim của spec P1 §3 (giảm rủi ro bản phát hành mới bị xâm phạm) | Chưa phân phối app (release là non-goal P1); ảnh chỉ vào khi người dùng tự chọn; giải mã thử trong isolate trước khi nhận trang nên ảnh hỏng không làm mất trang cũ | Chủ repo @seeker19110; thực hiện: phiên AI | 2026-10-18 | `docs/ops/COMPLETION-PLAN.md` W-104 |
| EX-2 | Không có dependency review / cảnh báo lỗ hổng tự động (F-009) | Cần chủ repo bật Dependency graph/alerts trong repository settings rồi mới nhập `dependency-review.yml` | Dependabot version updates (`.github/dependabot.yml`, chủ repo duyệt 2026-10-13: pub + github-actions, cooldown 7 ngày); ghim chính xác + lockfile; đọc CHANGELOG các gói giải mã dữ liệu ngoài (`image`, `pdf`) khi bảo trì; OSV query thủ công (2026-10-12: 0 advisory/86 package) | Chủ repo @seeker19110 | Trước release đầu tiên | `docs/ops/COMPLETION-PLAN.md` (dời) |
