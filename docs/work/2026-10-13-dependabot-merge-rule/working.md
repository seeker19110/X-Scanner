# Công việc: Luật tự merge PR Dependabot nâng nhỏ

- Work ID: 2026-10-13-dependabot-merge-rule
- Yêu cầu / outcome: chủ repo 2026-10-13: "có, tự merge bản nâng nhỏ khi đủ các bước kiểm" — ghi luật vào repo để mọi phiên sau theo cùng một chuẩn.
- Trạng thái: Active — PR mở
- Chủ trì / writer: phiên chính
- Mức rủi ro / số PR: S, 1 PR (tài liệu luật, không đổi code)
- Scope / non-goal: luật trong `docs/ops/dependency-updates.md` + một dòng trỏ ở header CLAUDE.md/AGENTS.md. Non-goal: bật auto-merge của GitHub, workflow tự merge.
- Spec / goal / issue: tiền lệ #48 `f188b14` (kiểm 1–6 rồi merge theo yêu cầu chủ repo) · `docs/work/2026-10-13-dependabot/done.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/admiring-mccarthy-5b360i` @ `763818a` · 2026-10-13T04:55:01Z

## Kế hoạch và phân công

- Một PR tài liệu.

## Quyết định và bằng chứng

- Bảy bước = đúng các bước đã làm với #48 · loại checklist mới · bậc 2 + 3 (đã chạy thật một lần).
- Loại trừ `image` khỏi tự merge · bậc 1 (giải mã ảnh không tin cậy, F-004; W-104b nâng kèm test hồi quy 18/10).
- Danh sách "Hỏi chủ repo" (gói mới, quyền manifest, mạng, license/publisher, permissions của action) · bậc 1 (mỗi mục là thay đổi chủ repo đã giữ quyền: D2 5 dependency, manifest gate, không mạng).
- Security update bỏ bước tuổi khi bản vá lỗ hổng đã công bố · bậc 1 (chờ 7 ngày kéo dài lỗ hổng đã biết); vẫn báo chủ repo.
- Ghi luật ở file dự án mới `docs/ops/dependency-updates.md` + một dòng header CLAUDE.md/AGENTS.md · loại sửa `docs/ops/supply-chain.md` (file khung: gate `check-adoption.py` test_manifest_integrity đỏ khi sửa — đã thử, đỏ đúng 1 test) · bậc 1 (header tự nạp mỗi phiên).
- Ngoại lệ test-trước số 3 (chỉ tài liệu).

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- CI xanh → merge → đổi `done.md`.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
