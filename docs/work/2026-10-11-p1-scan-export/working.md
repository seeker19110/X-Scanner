# Công việc: X-Scanner P1: scan nhiều trang, chỉnh góc, lưu gốc, xuất PDF/ảnh

- Work ID: 2026-10-11-p1-scan-export
- Yêu cầu / outcome: `/auto-complete` lần 3; chủ repo duyệt spec P1 theo đề xuất (D1 A, D2 5 dependency, D3 tắt backup, D4 emulator). Outcome: Goal DoD ở `docs/goals/2026-10-11-p1-scan-export.md`.
- Trạng thái: In progress — PR-0 (docs duyệt spec).
- Chủ trì / writer: phiên chính (PR-0, review/gate/tích hợp); PR-1..4 giao `complex-implementer`.
- Mức rủi ro / số PR: L (dữ liệu tài liệu nhạy cảm, 5 dependency, nhiều màn hình); 5 PR tuần tự vì chung `pubspec.lock`.
- Scope / non-goal: spec §5. Non-goal: tự nhận mép, OCR, depth, iOS, cloud, release.
- Spec / goal / issue: `docs/specs/2026-10-11-p1-scan-export.md` · `docs/goals/2026-10-11-p1-scan-export.md`
- Nhánh / base SHA / thời điểm reconcile: `claude/upbeat-ramanujan-mwmwtt` @ `b6c0113` · 2026-10-11T23:26:23Z

## Kế hoạch và phân công

- PR-0 `docs` (phiên chính): spec Approved + chỉnh §3/FR-5/§12/§17/§19, goal, hồ sơ này, đóng `2026-10-11-p1-readiness`.
- PR-1 `feat` (`complex-implementer`): `lib/core/scan_session.dart`, `lib/core/session_manifest.dart`, `lib/storage/session_store.dart` + test. AC-1..3.
- PR-2 `feat` (`complex-implementer`): `image` 4.10.1, `lib/imaging/` (homography, render, thumbnail trong isolate) + test. AC-5.
- PR-3 `feat` (`complex-implementer`): `image_picker` 1.2.3, `path_provider` 2.1.6, `lib/ui/`, `lib/main.dart`, Android manifest (D3) + widget test. AC-4, AC-7, AC-8.
- PR-4 `feat` (`complex-implementer`): `pdf` 3.13.1, `share_plus` 13.3.1, `lib/export/` + nối UI + test. AC-6.
- Sau PR-4: `/completion` (luồng người dùng đã có) → DoC; AC-9 chờ chủ repo.

## Quyết định và bằng chứng

- Ghim `image_picker` 1.2.3 và `image` 4.10.1 · loại 1.2.4/4.12.0 · bậc 1 (spec §3: bản phát hành ≥ 7 ngày; 1.2.4 mới 5 ngày, 4.10.2–4.12.0 mới 0–1 ngày).
- Nắn bằng homography tự viết · loại `copyRectify` · bậc 1 (đọc mã nguồn 4.10.1: nội suy song tuyến, sai phối cảnh khi trang nghiêng).
- Tọa độ quad tính sau khi áp hướng EXIF · loại tọa độ buffer thô · bậc 1 (thumbnail người dùng kéo góc là ảnh đã xoay EXIF; lệch hệ quy chiếu = cắt sai).
- `SessionStore` nhận thư mục được tiêm, `path_provider` để PR-3 · loại thêm dependency ở PR-1 · bậc 2 (ít dependency hơn) và bậc 3 (test bằng thư mục tạm).
- Manifest hỏng: đổi tên sang `session.corrupt-<thời điểm>.json`, không dọn bản gốc · loại ghi đè khi lưu phiên mới · bậc 1 (giữ ánh xạ bản gốc để phục hồi tay).
- D3: `allowBackup="false"` + `dataExtractionRules` loại mọi miền · loại chỉ `allowBackup` · bậc 1 (Android 12+ vẫn chuyển máy khi chỉ tắt `allowBackup`).
- D4: AC-9 chủ repo chạy trên emulator · loại chạy trong phiên · bậc 1 (container không có `/dev/kvm`).

## Lần thử / blocker

- Không.

## Bàn giao / bước tiếp theo

- Merge PR-0, rồi giao PR-1 theo brief trong scratchpad của phiên (`PLAN-p1.md`).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

<DoD, mọi PR MERGED + merge SHA và main đã đối chiếu, giới hạn/rủi ro còn lại,
ngày và người nghiệm thu theo ủy quyền. Khi đủ điều kiện rename working.md → done.md
trong cùng thư mục; không overwrite lịch sử. Chưa có PR/merge thì giữ working.md.>
