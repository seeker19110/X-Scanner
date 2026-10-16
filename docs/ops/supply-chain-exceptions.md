# Supply-chain exceptions — X-Scanner

> Theo `docs/ops/supply-chain.md` §Exception: owner, lý do, compensating control, hạn, issue/tracker.
> Exception hết hạn tự trở thành blocker release.

| ID | Thành phần | Lý do | Compensating control | Owner | Hạn | Tracker |
|----|-----------|-------|----------------------|-------|-----|---------|
| EX-1 | `image` 4.10.1 (lỗi giải mã: EXIF IFD lặp treo, PNG bom giải nén — F-004) | Bản vá 4.12.0 phát hành 2026-10-11, chưa đủ 7 ngày theo luật ghim của spec P1 §3 (giảm rủi ro bản phát hành mới bị xâm phạm) | Chưa phân phối app (release là non-goal P1); ảnh chỉ vào khi người dùng tự chọn; giải mã thử trong isolate trước khi nhận trang nên ảnh hỏng không làm mất trang cũ | Chủ repo @seeker19110; thực hiện: phiên AI | 2026-10-18 | `docs/ops/COMPLETION-PLAN.md` W-104 |


## Ngoại lệ đã đóng

| ID | Đóng ngày | Bằng chứng | Giới hạn còn lại |
| --- | --- | --- | --- |
| EX-2 | 2026-10-16 | [PR #53](https://github.com/seeker19110/X-Scanner/pull/53) merged3f49039; workflow trên main giống reviewedhead51af8e0, [CI38930758793](https://github.com/seeker19110/X-Scanner/actions/runs/38930758793) SUCCESS gồm dependency review; alerts GET204, Pub86/86 khớp, compare HTTP200/no-warning; [readback](evidence/2026-10-16-xs05-native.json) | Dependency review là diff graph, không full audit; snapshot warning upstream vẫn cần review như [runbook](x-scanner-repository-guards.md). EX-1 không thay đổi. |
