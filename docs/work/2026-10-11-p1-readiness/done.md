# Công việc: X-Scanner: gia cố P0 + spec P1 chờ duyệt

- Work ID: 2026-10-11-p1-readiness
- Yêu cầu / outcome: `/auto-complete` lần 2 (chủ repo chưa trả lời câu hỏi thiết bị/P1). Outcome: gia cố P0 đã duyệt + spec P1 sẵn để duyệt.
- Trạng thái: Done — PR-A (#4) và PR-B (#5) merged; spec P1 được chủ repo duyệt 2026-10-11.
- Chủ trì / writer: phiên chính; PR-A giao `mechanical-worker`.
- Mức rủi ro / số PR: S (PR-A chore) + docs (PR-B spec, không code); 2 PR tuần tự (một nhánh được giao).
- Scope / non-goal: trong scope = gia cố cổng P0 + research/spec P1 (In review). Non-goal: code tính năng P1 (chưa được duyệt), release, chi phí mới.
- Spec / goal / issue: `docs/specs/2026-10-11-p1-scan-export.md` (In review — tạo ở PR-B).
- Nhánh / base SHA / thời điểm reconcile: `claude/upbeat-ramanujan-mwmwtt` @ `794649a` · 2026-10-11T15:38:58Z

## Kế hoạch và phân công

- PR-A `chore` (worker `mechanical-worker`, brief `--check-plan`): `apps/mobile/pubspec.yaml` thêm `flutter: 3.47.7` vào `environment`.
- PR-B `docs` (phiên chính): spec P1 `docs/specs/2026-10-11-p1-scan-export.md` trạng thái In review, kèm research phiên bản/license.
- Sau merge: `/completion` Bước -1 lại (chưa có luồng người dùng) → dừng; BLOCKED chờ chủ repo duyệt spec P1.

## Quyết định và bằng chứng

- Phạm vi lượt này: gia cố P0 + spec P1 In review · loại tự duyệt và code P1 · bậc 1 (`CLAUDE.md` X-Scanner: P0–P4 không tự cho phép triển khai; `/auto-complete` cấm thay đổi ngoài scope đã giao; lần trước bộ phân loại an toàn chặn đúng mâu thuẫn này).
- Gia cố phiên bản SDK bằng `environment: flutter: 3.47.7` trong pubspec · loại script kiểm phiên bản trong doctor · bậc 2 (tính năng nền tảng, 1 dòng). Bằng chứng: bản sao tạm với `flutter: 3.47.8` → `pub get` "requires Flutter SDK version 3.47.8, version solving failed".
- Không thêm cache CI · loại `actions/cache` · bậc 2 (thêm cấu hình/action; lợi ích chỉ là tốc độ — bậc 4).
- Nút Dark/Light không làm lượt này · loại làm ngay · bậc 1 (là UI tính năng P1, chưa được duyệt).
- Research P1 (pub.dev API, 2026-10-11): image_picker 1.2.4 (flutter.dev, BSD-3/Apache-2.0), camera 0.12.1 (flutter.dev, BSD-3), pdf 3.13.1 (Apache-2.0), image 4.12.0 (MIT, có `copyRectify` — đã grep mã nguồn), path_provider 2.1.6 (BSD-3), share_plus 13.3.1 (BSD-3), google_mlkit_document_scanner 0.6.1 (MIT), cunning_document_scanner 3.0.3 (MIT).

- PR-A thực thi bởi `mechanical-worker` (brief `--check-plan` OK). Phiên chính kiểm lại trên repo: diff 1 dòng `flutter: 3.47.7` + `pubspec.lock` (`sdks.flutter: "3.47.7"`, sinh lại bằng `pub get`); đỏ: ghim 3.47.8 → "requires Flutter SDK version 3.47.8, version solving failed"; xanh: "Got dependencies!". Gate worker: PASS 4/4.

- PR-A https://github.com/seeker19110/X-Scanner/pull/4 merged squash `8e1c319` sau CI xanh trên head `dcd467f` (job 114508434013); 0 review thread.
- Spec P1 phương án A (camera hệ thống qua `image_picker` + chỉnh góc tay + `image`/`pdf`) · loại B (`camera` plugin, nhiều code → P2) và C (ML Kit, không trả bản gốc) · bậc 1 với C (mất bản gốc), bậc 2 với B.
- Spec P1 để In review, 4 quyết định mở D1–D4 cho chủ repo · loại tự duyệt · bậc 1 (ngoài scope đã giao).
- `/completion` dừng ở Bước -1 lần nữa · loại audit 12 nhóm · bậc 1 (vẫn chưa có luồng người dùng; chỉ thêm 1 dòng cấu hình).
- Hồ sơ này giữ `working.md` (Blocked) · loại đổi `done.md` · bậc 1 (outcome thật là spec được duyệt; chưa xảy ra).

## Lần thử / blocker

- Từng BLOCKED chờ chủ repo duyệt spec P1; gỡ ngày 2026-10-11 (chủ repo chọn "Duyệt theo đề xuất").

## Nghiệm thu cuối

- PR-A https://github.com/seeker19110/X-Scanner/pull/4 → `8e1c319`; PR-B https://github.com/seeker19110/X-Scanner/pull/5 → `b6c0113` (CI xanh, job 114509830542).
- Outcome đạt: Flutter ghim trong pubspec; spec P1 có trên `main` và đã được duyệt. Việc tiếp theo ở `docs/work/2026-10-11-p1-scan-export/`.
- Nghiệm thu: phiên chính theo ủy quyền §3d, 2026-10-11.
