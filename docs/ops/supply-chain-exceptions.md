# Supply-chain exceptions — X-Scanner

> Theo `docs/ops/supply-chain.md` §Exception: owner, lý do, compensating control, hạn, issue/tracker.
> Exception hết hạn tự trở thành blocker release.

| ID | Thành phần | Lý do | Compensating control | Owner | Hạn | Tracker |
|----|-----------|-------|----------------------|-------|-----|---------|
| EX-1 | `image` 4.10.1 (lỗi giải mã: EXIF IFD lặp treo, PNG bom giải nén — F-004) | Bản vá 4.12.0 phát hành 2026-10-11, chưa đủ 7 ngày theo luật ghim của spec P1 §3 (giảm rủi ro bản phát hành mới bị xâm phạm) | Chưa phân phối app (release là non-goal P1); ảnh chỉ vào khi người dùng tự chọn; giải mã thử trong isolate trước khi nhận trang nên ảnh hỏng không làm mất trang cũ | Chủ repo @seeker19110; thực hiện: phiên AI | 2026-10-18 | `docs/ops/COMPLETION-PLAN.md` W-104 |
| EX-2 | Dependency review workflow trên main (phần còn lại F-009) | Alerts đã bật (GET 204), graph 86/86 Pub khớp lockfile; review step ở PR #53 SUCCESS/compare HTTP200/no-warning nhưng workflow chưa merge main | Native main ruleset bắt buộc app gate/no bypass; Dependabot version updates cooldown 7 ngày; ghim chính xác/lockfile và kiểm CHANGELOG/OSV thủ công như baseline | Chủ repo @seeker19110; triển khai: phiên AI | Khi PR #53 merge, trước release đầu tiên | [PR #53](https://github.com/seeker19110/X-Scanner/pull/53), `docs/ops/x-scanner-repository-guards.md` |
