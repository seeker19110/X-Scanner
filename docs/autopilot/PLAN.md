# docs/autopilot/PLAN.md — X-Scanner · đưa repo về trạng thái autopilot sạch sau XS-09

> Duyệt: D-001 (phiên chính tự duyệt, 2026-10-24) · Stack/ADR: `docs/adr/0002-flutter-android-first-stack.md` (Flutter 3.47.7, Android trước) · Spec đang hiệu lực: P1, XS-09 (Approved) · Blueprint: `BLUEPRINT.md` (`mobile-app`, M)

Tóm tắt duyệt (≤ 30 dòng):
- Không có yêu cầu sản phẩm mới: `/autopilot` gọi không đối số sau khi XS-09 PR-4b đã merge (#62) và kế hoạch hoàn thiện P1 đã đóng (#63). Roadmap P2+ trong `docs/plans/` là ADVISORY, chưa được duyệt nên **không** nằm trong kế hoạch này (CLAUDE.md: advisory không cho phép triển khai).
- Mục tiêu: repo đạt điều kiện vòng autopilot của khung #57 — `PROGRESS.md` đúng luật, lệnh `xt.yaml` khớp cổng thật, `BLUEPRINT.md` được phân loại có bằng chứng; việc cần người được gom rõ.
- Blueprint `mobile-app`/M: 402 MUST · 1069 SHOULD, phần lớn cho web/server/CSDL; app là Flutter offline, không server, không tài khoản, không mạng.
- Rủi ro: (1) tick blueprint không bằng chứng → chỉ `[x]` khi có file/test/CI dẫn được, không áp dụng ghi `[~]` kèm điều kiện; (2) va chạm hai gate song song ở hook commit (F-077) → đọc log trước khi coi là lỗi code.
- Merge: `xt.yaml` `merge_autonomy: L1` → làm theo `xt.py merge-check`; `human` thì để người merge.

## Mục tiêu của kế hoạch này
`xt.py doctor` không còn lỗi do repo (lỗi ✗ hook còn lại là báo nhầm của khung, gửi `feedback`); `progress-check` xanh; mọi MUST của blueprint có kết cục (đạt có bằng chứng / không áp dụng có điều kiện / chờ người).

## Ngân sách (4 con số)
- Số vòng tối đa: mặc định `--single-session` (max(20, 4 × task chưa làm))
- Ngân sách: phiên hiện tại, không API trả phí; subagent tối đa 5 đang chạy (CLAUDE.md §2)
- Timeout mỗi lệnh Gate: 1800 s (`XT_RECORD_TIMEOUT` mặc định)
- Ngày hết hạn: 12 giờ từ `loop init` (`--hours 12`)

## Hạn
| Loại | Ngày | Hậu quả nếu trễ | Cách xử lý khi trễ |
|---|---|---|---|
| Hạn mong muốn | 2026-10-24 | nội bộ | bàn giao qua PROGRESS |

## Điểm dừng bắt buộc về hành động
- Xoá/đổi dữ liệu thật, migration phá vỡ
- Deploy/release, gửi thông báo ra ngoài, dịch vụ trả phí
- Secret, quyền, ruleset, cấu hình cổng/CI/hook — gồm F-077 (hai gate song song ở hook commit): **defer cho chủ repo**
- Chạy APK có thư viện trên thiết bị/emulator (W-602): container không có KVM — **defer**

## Thứ tự & lý do
1. Harness trước (T-001, T-002): `loop` đọc `PROGRESS.md`/`xt.yaml`; sai thì mọi vòng sau đọc sai.
2. Blueprint (T-003): cần harness đúng để ghi bằng chứng.
3. Phản hồi khung (T-004) cuối, gom lỗi khung gặp trong phiên.

## Task

### Lát 1 — Harness đúng luật
- [x] `T-001` `PROGRESS.md` về đúng 4 mục, ≤ 8 KB; lịch sử chuyển sang `docs/changelog/2026-10-progress-history.md` (giữ nguyên văn) — Gate: `python3 .xtemplates/scripts/xt.py progress-check PROGRESS.md`
- [x] `T-002` `xt.yaml` khớp `.claude/project-commands.sh` (test thiếu JVM `:app:testDebugUnitTest`); thêm script kiểm khớp — Gate: `bash scripts/check-xt-yaml-sync.sh`

### Lát 2 — Blueprint có bằng chứng
- [x] `T-003` Phân loại mọi MUST của `BLUEPRINT.md`: `[x]` + bằng chứng, `[~] — Không áp dụng: <điều kiện>`, còn lại `loop defer` cho người (D-003: Gate đo phân loại; điều kiện `done` vẫn là `blueprint-status --strict`) — Gate: `python3 scripts/check-blueprint-triage.py`

### Lát 3 — Khung
- [x] `T-004` Ghi phản hồi khung (doctor báo nhầm `..`, F-077 hai gate song song, guard thiếu `flutter pub add`) — Gate: `python3 .xtemplates/scripts/xt.py feedback collect`

## Phụ thuộc ngoài
| Việc | Bên ngoài | Ngày cam kết | Kế hoạch B |
|---|---|---|---|
| W-602 chạy APK thư viện | máy Android tăng tốc (chủ repo) | — | giữ WAITING trong goal |
| F-077 sửa hook | chủ repo quyết cấu hình cổng | — | đọc log hook trước khi coi build đỏ là lỗi code |
