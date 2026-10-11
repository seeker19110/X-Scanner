# Goal: P0 foundation — app Flutter có cổng thật

| Thuộc tính | Giá trị |
| --- | --- |
| Goal ID | 2026-10-11-p0-foundation |
| Owner | Chủ repo; thực thi: phiên chính |
| State | COMPLETE |
| Default-branch SHA đã reconcile | `37658f9` |
| Bắt đầu / review | 2026-10-11 |
| Quyền AI | research / branch / PR / merge khi CI xanh (chủ repo xác nhận 2026-10-11); không deploy/release |
| Budget | Không chi phí mới; CI runner Linux |

## Outcome và Goal DoD

- User/job: người phát triển cần cổng build/type/lint/test thật để bắt đầu P0/P1.
- Baseline → target: build/typecheck N/A → APK debug, analyze, test chạy trong gate và CI.
- Guardrails: theo spec §2; không tuyên bố camera/depth/iOS đã kiểm chứng.
- Completion approver: chủ repo.

## Milestones và slices

| ID | Outcome/AC | Dependency | Spec | PR | State | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | ADR-0002, spec, guard AC-6 | — | `docs/specs/2026-10-11-p0-foundation.md` | #1 | DONE | merge `cf620cf`, CI xanh |
| S2 | App nền + lõi + gate/CI, AC-1..5, AC-7 | S1 merged | như trên | #2 | DONE | merge `37658f9`; CI job 114502711383: gate PASS 4/4, 20/20 test |

## Risk register

| Risk | Trigger | Mitigation/rollback | Owner | State |
| --- | --- | --- | --- | --- |
| Camera/depth không khả thi | Spike thiết bị thất bại | ADR mới cho đường capture; giữ lõi Dart | Chủ repo | Open — cần thiết bị |

## Current truth

- Goal gap: không còn — Goal DoD đạt 2026-10-11.
- Blocker/open decision: spike thiết bị nằm ngoài goal này.
