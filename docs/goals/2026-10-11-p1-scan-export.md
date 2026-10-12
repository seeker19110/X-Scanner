# Goal: P1 — scan nhiều trang, chỉnh góc, lưu gốc, xuất PDF/ảnh

| Thuộc tính | Giá trị |
| --- | --- |
| Goal ID | 2026-10-11-p1-scan-export |
| Owner | Chủ repo; thực thi: phiên chính + worker |
| State | ACTIVE |
| Default-branch SHA đã reconcile | `99027ba` |
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
| S0 | Spec Approved, goal, hồ sơ | — | `docs/specs/2026-10-11-p1-scan-export.md` | #6 | DONE | merge `a1549c5`, CI xanh |
| S1 | `ScanSession` + `SessionStore`, AC-1..3 | S0 | như trên | #7 | DONE | merge `df902de`, CI xanh |
| S2 | Nắn phối cảnh, AC-5 | S1 | như trên | #8 | DONE | merge `1cc15e3`, CI xanh |
| S3 | UI chụp/xem lại/chỉnh góc + Dark/Light, AC-4, AC-7, AC-8 | S2 | như trên | #9 | DONE | merge `99027ba`, CI xanh |
| S4 | Xuất PDF/ảnh + chia sẻ, AC-6 | S3 | như trên | PR-4 | IN PROGRESS | gate cục bộ PASS 205/205 |
| S5 | UAT AC-9 | S4 | như trên | — | WAITING chủ repo | |

## Risk register

| Risk | Trigger | Mitigation/rollback | Owner | State |
| --- | --- | --- | --- | --- |
| Homography thuần Dart chậm trên ảnh 12 MP | Đo PR-2: 2,8–3,5 s/trang (JIT x86) | Isolate không chặn UI; đo trên thiết bị ở P2, vượt → ADR native | Phiên chính | Accepted cho P1 |
| Chỉnh góc chỉ bằng kéo (WCAG 2.2 2.5.7) | Người dùng trình đọc màn hình | Dấu `DEBT:` trong `quad_editor_screen.dart`; P2 | Phiên chính | Accepted cho P1 |
| Không chạy được emulator trong container AI | Không có `/dev/kvm` | AC-9 do chủ repo chạy (D4) | Chủ repo | Accepted |

## Current truth

- Goal gap: S1–S5.
- Blocker/open decision: không.
