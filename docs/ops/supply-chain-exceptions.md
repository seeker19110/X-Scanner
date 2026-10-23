# Supply-chain exceptions — X-Scanner

> Theo `docs/ops/supply-chain.md` §Exception: owner, lý do, compensating control, hạn, issue/tracker.
> Exception hết hạn tự trở thành blocker release.

| ID | Thành phần | Lý do | Compensating control | Owner | Hạn | Tracker |
|----|-----------|-------|----------------------|-------|-----|---------|


Không còn exception mở. Lịch sử EX1 trước khi đủ tuổi và trước merge được giữ trong hồ sơ W104b.

## Ngoại lệ đã đóng

| ID | Đóng ngày | Bằng chứng | Giới hạn còn lại |
| --- | --- | --- | --- |
| EX-1 | 2026-10-18 | [PR58](https://github.com/seeker19110/X-Scanner/pull/58) mergedc50670a, reviewedheadb227825/tree khớp; [CI39088067553](https://github.com/seeker19110/X-Scanner/actions/runs/39088067553)639/639, rootgate/hook639+639, stagedactualRED/instancecaps/AOT12; hồ sơ `docs/work/2026-10-18-w104b-decoder-upgrade/done.md` | Pin4.12.0/byte-pixel-time-format guards; lazyinflater có read-ahead, không RAMquota/security certification. AC9/release chưa nghiệm thu. |
| EX-2 | 2026-10-16 | [PR #53](https://github.com/seeker19110/X-Scanner/pull/53) merged3f49039; workflow trên main giống reviewedhead51af8e0, [CI38930758793](https://github.com/seeker19110/X-Scanner/actions/runs/38930758793) SUCCESS gồm dependency review; alerts GET204, Pub86/86 khớp, compare HTTP200/no-warning; [readback](evidence/2026-10-16-xs05-native.json) | Dependency review là diff graph, không full audit; snapshot warning upstream vẫn cần review như [runbook](x-scanner-repository-guards.md). EX-1 không thay đổi. |

### EX1 đóng sau actualmerge18Oct

Không gia hạn ngầm: bản vá đủ7ngày, verifiedarchive/tag/lock và các gate đã vào actualmain trước khi đóng. Revert decoder qua PR phải mở lại EX1; không nhận unit-only hoặc PR-open làm vá trên main.
