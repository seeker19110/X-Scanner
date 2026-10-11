# Goal: P1 — scan nhiều trang, chỉnh góc, lưu gốc, xuất PDF/ảnh

| Thuộc tính | Giá trị |
| --- | --- |
| Goal ID | 2026-10-11-p1-scan-export |
| Owner | Chủ repo; thực thi: phiên chính + worker |
| State | ACTIVE |
| Default-branch SHA đã reconcile | `b6c0113` |
| Bắt đầu / review | 2026-10-11 |
| Quyền AI | research / branch / PR / merge khi CI xanh; không deploy/release |
| Budget | Không chi phí mới; CI runner Linux |

## Outcome và Goal DoD

- User/job: người cần số hóa tài liệu tạo tài liệu nhiều trang và xuất PDF/ảnh offline trên Android.
- Baseline → target: không tạo được tài liệu → chụp/nhập, chỉnh góc, xoay, sắp xếp, xuất PDF/JPG/PNG.
- Goal DoD: AC-1..8 có bằng chứng máy trên `main`; AC-9 do chủ repo kiểm trên emulator (D4).
- Guardrails: spec §2 (không mạng/upload/log nội dung, bản gốc không bị ghi đè hay mất).
- Completion approver: chủ repo (AC-9).

## Milestones và slices

| ID | Outcome/AC | Dependency | Spec | PR | State | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| S0 | Spec Approved, goal, hồ sơ | — | `docs/specs/2026-10-11-p1-scan-export.md` | PR-0 | IN PROGRESS | |
| S1 | `ScanSession` + `SessionStore`, AC-1..3 | S0 | như trên | PR-1 | TODO | |
| S2 | Nắn phối cảnh, AC-5 | S1 | như trên | PR-2 | TODO | |
| S3 | UI chụp/xem lại/chỉnh góc + Dark/Light, AC-4, AC-7, AC-8 | S2 | như trên | PR-3 | TODO | |
| S4 | Xuất PDF/ảnh + chia sẻ, AC-6 | S3 | như trên | PR-4 | TODO | |
| S5 | UAT AC-9 | S4 | như trên | — | WAITING chủ repo | |

## Risk register

| Risk | Trigger | Mitigation/rollback | Owner | State |
| --- | --- | --- | --- | --- |
| Homography thuần Dart chậm trên ảnh 12 MP | Đo ở PR-2 vượt vài giây | Giảm kích thước đầu ra hoặc ADR native | Phiên chính | Open |
| Không chạy được emulator trong container AI | Không có `/dev/kvm` | AC-9 do chủ repo chạy (D4) | Chủ repo | Accepted |

## Current truth

- Goal gap: toàn bộ S1–S5.
- Blocker/open decision: không.
