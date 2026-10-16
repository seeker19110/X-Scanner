# PLAN.md — PR #52 review và XS-05 hàng rào repository

## Bối cảnh & mục tiêu
Chủ repo yêu cầu review/sửa/merge PR #52 rồi nâng cấp tiếp theo ưu tiên báo cáo ngày 16/10. W-104b còn chờ 18/10, AC-9 thiếu thiết bị. XS-05 đóng khoảng trống F-014 và phần khả thi F-009 bằng controls của GitHub cho repo công khai. Hồ sơ chính: docs/work/2026-10-16-xs05-repository-guards/working.md.

## Đặc tả dùng chung
- Schema/DDL: không đổi dữ liệu app, pubspec hoặc lockfile.
- API: dùng GitHub REST rulesets/alerts/dependency-graph hiện có; không thêm API ứng dụng, dịch vụ trả phí hoặc token.
- Quy ước: cấu hình/tài liệu mức S; ngoại lệ TDD số 3. Chạy actionlint, kiểm JSON/YAML trên file đổi; root chạy đầy đủ scripts/dev-task.sh gate trước commit và CI. Worker nộp trạng thái Ready for root gate, không báo Done trước gate/merge.
- Phạm vi quyền: user cấp merge PR #52 và tự quyết kỹ thuật trong việc nâng cấp; native controls XS-05 là cấu hình bảo vệ trong scope. Không bật auto-merge, release, scheduler, migration PR-4b hoặc dịch vụ ngoài. Root là người duy nhất áp native settings sau chuẩn bị/review; worker chỉ tạo file trong worktree riêng.

## Nhóm PR (đơn vị mở PR)
- **PR-1** (review PR #52 hiện có): gồm việc T1 — không mở PR mới, hoàn tất trước PR-2.
- **PR-2** (XS-05 repository guards): gồm việc T2 — phụ thuộc PR-1; reconcile từ main sau squash merge #52, chạy tuần tự.

## Danh sách việc
### T1 — Review PR #52   `route: standard`
- Điểm chạm: `docs/work/2026-10-16-android-uat-artifacts/done.md`
- Đặc tả: reviewer chỉ đọc worktree riêng tại head 9b5572b, đã trả findings rỗng; root review toàn bộ diff, kiểm gói thực, chạy gate/CI và squash merge theo head được kiểm. Bằng chứng merge thật reconcile vào PR-2.
- Phụ thuộc: none
- Tiêu chí chấp nhận: không finding chưa xử lý; full gate và CI xanh; PR #52 MERGED với SHA thật; không đóng AC-9 từ artifact.

### T2 — Cấu hình native ruleset và dependency review   `route: standard`
- Điểm chạm: `.github/rulesets/main.json`, `.github/workflows/ci.yml`, `docs/ops/x-scanner-repository-guards.md`, `docs/work/2026-10-16-xs05-guards-config/working.md`
- Đặc tả: thêm ruleset riêng X-Scanner tên X-Scanner main, branch target refs/heads/main, enforcement active, bypass_actors rỗng. Rules deletion/non_fast_forward/required_linear_history; pull_request approval count 0 (single owner), dismiss stale reviews true, code owner false, last push approval false, review thread resolution true, allowed merge methods chỉ squash; required_status_checks duy nhất Framework and Android app gate có integration_id 15368 (GitHub Actions đã xác minh qua check-runs), strict_required_status_checks_policy true, do_not_enforce_on_create false. Không dùng gate/metadata mẫu. Trong CI thêm step Review dependency changes ở cùng job trước app gate, chỉ khi github.event_name == 'pull_request', action actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294 (v5.0.0, published 2026-05-08 đã kiểm source). with fail-on-severity low, fail-on-scopes runtime,development,unknown; vulnerability-check true; license-check false (chưa chốt license policy); warn-only false; comment-summary-in-pr never; show-openssf-scorecard false; retry-on-snapshot-warnings true với timeout 120. Giữ quyền contents read và mọi bước hiện có; không dùng pull_request_target, không skip khi lỗi API. Runbook ghi đúng lệnh apply/readback ruleset/alerts/graph, không nhận evidence cũ của repo mẫu. Phân biệt policy dự kiến với trạng thái live do root ghi sau; EX-1 và AC-9 giữ mở. Nêu rõ upstream retry snapshot warnings có thể tiếp tục sau timeout; không tuyên bố snapshot thiếu luôn fail-closed. Root chỉ nhận F-009/đóng EX-2 sau readback Pub coverage khớp lockfile và compare không snapshot warning; nếu chưa đủ thì giữ partial. Không sửa source SDK, dependency app, file khung đã ghim. Cập nhật checkpoint config unit, không commit/push/merge/native mutation.
- Phụ thuộc: T1
- Tiêu chí chấp nhận: JSON khớp rule/check/name/id/strict/bypass; YAML/actionlint PASS, checkout vẫn persist-credentials false, gate/upload giữ thứ tự và mọi lỗi dep review chặn job. Root review diff, full gate xanh và CI action thực chạy thành công; live controls chỉ được ghi verified sau readback. Nộp danh sách file, kiểm config, điểm chưa đo và Ready for root gate.

## Luật chung cho mọi việc
1. Chỉ sửa file trong Điểm chạm; chạm file khác → kết quả bị loại.
2. Code mới có nhánh/tính toán/xử lý lỗi và mọi fix → test đỏ trước; nộp output đỏ và xanh. T2 chỉ config thuần/tài liệu là ngoại lệ số 3, ghi rõ.
3. Chạy cổng đã khai ở Đặc tả dùng chung trước khi báo xong; nộp kết quả thật, không nhận Done trước full gate/root merge.
4. Không git reset --hard/rebase/push --force/xoá nhánh; không commit/merge — root tích hợp.
5. Mơ hồ/mâu thuẫn trong brief → dừng và báo chỗ lệch; không đoán.
6. Trả file đã đổi · test đỏ trước/ngoại lệ · kiểm cấu hình xanh · gate chưa chạy hoặc kết quả · chỗ phải dừng.

## Thứ tự tích hợp & migration
PR-1 merge → git fetch/main ff-only → branch codex/xs05-repository-guards → T2 worktree riêng. Root tích hợp patch, cập nhật CODEMAP/PROGRESS/CHANGELOG và work records; chạy full gate, áp settings đã review, mở PR-2, kiểm CI/negative control với evidence thật. Không migration app.

## Reconcile native defaults sau T2 — 2026-10-16
Root thêm hai tham số do GitHub tự trả về: required_reviewers=[] và require_extra_approval_for_unattributed_changes=true. Không đổi số approval0 hay rule/check; official docs xác nhận extra approval không có tác dụng khi count0. Giữ bảo vệ mặc định, làm JSON/readback khớp chính xác; root review delta này và ghi bằng chứng.

## Duyệt cuối (Tầng 1)
Đọc diff và source action, kiểm active ruleset không bypass và app-bound check đúng tên; alerts/secret settings đọc riêng; không suy graph có đủ pub packages từ response rỗng. Negative control trên chính PR-2: sau full gate cục bộ xanh, cố ý huỷ một run CI của PR-2, đọc conclusion cancelled và mergeStateStatus BLOCKED với required check ràng buộc app 15368; không gửi merge request cho PR-2. Rerun CI, chờ success/CLEAN. Ghi chính xác đây là phép kiểm CI không đạt (cancelled), không phải test code cố tình đỏ hay API merge bị từ chối. Không cố merge code không xanh hoặc bật auto-merge. PR-2 để review trừ khi được cấp quyền merge riêng.
