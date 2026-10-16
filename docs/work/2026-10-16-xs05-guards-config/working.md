# Công việc: XS-05 — cấu hình ruleset và dependency review

- Work ID: 2026-10-16-xs05-guards-config
- Yêu cầu / outcome: triển khai T2 từ PLAN.md của hồ sơ tổng XS-05: ruleset native riêng X-Scanner và dependency review trong cùng job CI, kèm runbook apply/readback.
- Trạng thái: Ready for root gate — kiểm cấu hình xanh; chưa full gate/root nghiệm thu/native apply/merge.
- Chủ trì / writer: worker xs05_config; phiên chính giữ hồ sơ tổng và nghiệm thu.
- Mức rủi ro / số PR: S; phần cấu hình của PR-2 XS-05, phụ thuộc PR-1 #52 đã merge. Ngoại lệ TDD số 3: config thuần và tài liệu, không thêm logic ứng dụng.
- Scope / non-goal: chỉ .github/rulesets/main.json, .github/workflows/ci.yml, docs/ops/x-scanner-repository-guards.md và hồ sơ đơn vị này. Không source app/dependency/lockfile, native mutation, commit/push/merge hoặc đổi hồ sơ tổng.
- Spec / goal / issue: hợp đồng T2 ở docs/work/2026-10-16-xs05-repository-guards/PLAN.md (worktree phiên chính); F-014/F-009; research 16/10. Mức S không cần feature spec mới.
- Nhánh / base SHA / thời điểm reconcile: `codex/xs05-guards-config` @ `f753933` · 2026-10-16T15:20:15Z

## Kế hoạch và phân công

- Root giao worker T2 trong worktree riêng `/home/liend/.local/share/x-scanner/xs05-guards-config`, nhánh `codex/xs05-guards-config` từ main sau #52 squash merge `f753933ae9f75c580266d52a585b4af18fc34acb`.
- Chỉ thêm ruleset đúng schema/giá trị và bước action đúng SHA/inputs trong contract; giữ job/check/quyền/gate/upload.
- Kiểm JSON/YAML/actionlint, schema/contract và diff; bàn giao Ready for root gate. Root tích hợp, chạy full Android gate, áp settings và ghi evidence thật, không dùng lời worker thay nghiệm thu.

## Quyết định và bằng chứng

- Reconcile base thực `f753933ae9f75c580266d52a585b4af18fc34acb`, nhánh đúng và working tree sạch trước tạo hồ sơ; hook cục bộ đặt `scripts/githooks`. PROGRESS ở base còn nói #52 mở; trạng thái merge do root reconcile ở hồ sơ tổng, worker không sửa file ngoài scope.
- Chọn ruleset native tối thiểu + một step trong job hiện hữu theo hợp đồng đã duyệt · loại workflow/gate mẫu và app source thay đổi · bậc 1, 2.
- Chọn dependency review ghim v5.0.0/SHA có input xác minh tại upstream, chỉ contents read và không comment PR · loại tag nổi hoặc quyền ghi · bậc 1.
- Ghi rõ snapshot retry timeout vẫn có thể trả dữ liệu thiếu; HTTP 200/CI xanh không thay readback Pub · loại đóng EX-2 từ kết quả rỗng · bậc 1. Root giữ quyền kết luận F-009/EX-2.
- Đã đọc official REST ruleset schema, alerts PUT/GET, graph SBOM/compare và action.yml/src tại SHA; PUT vulnerability-alerts bật cả graph và alerts, không bịa field API riêng.
- Kiểm cấu hình trên thay đổi ở base `f753933`, ngày 16/10: `python3 -m json.tool` PASS; actionlint 1.7.12 PASS (exit 0, không diagnostics); `git diff --check` PASS.
- Kiểm exact contract bằng Python/PyYAML PASS: đủ 5 rule, bypass rỗng, đúng một required check/app ID/strict; action đúng SHA và 9 input; remove duy nhất step mới thì YAML bằng base, nên checkout/quyền/job/gate/upload cũ giữ nguyên. Đúng 4 file được giao thay đổi; không file nguồn/dependency đổi.
- Bash syntax PASS cho 12 block shell của workflow/runbook; link tương đối mới tồn tại. Chỉ parse các lệnh runbook, không chạy mutation GitHub. Tự đọc toàn bộ diff và file mới; không phát hiện thay đổi ngoài contract hoặc dữ liệu nhạy cảm.
- `dev-task.sh format-file` đã gọi cho cả 4 file; dispatcher skip vì không khai formatter per-file cho JSON/YAML/Markdown. JSON/YAML được parse riêng, không nhận skip là bằng chứng format tự động.

## Lần thử / blocker

- Không failure của kiểm cấu hình; full Android gate chưa chạy tại worktree worker, cố ý dành cho root sau tích hợp theo contract. Không suy PASS app/CI từ actionlint.
- Helper kiểm link cuối có hai false positive: chuỗi printf trong YAML và ví dụ inline code trong checkpoint. Lỗi ở tầng ④ vì regex tạm đọc nội dung ngoài Markdown hoặc code như link thật; không phải link tài liệu hỏng. Giới hạn vào Markdown và bỏ inline code khỏi phép kiểm; JSON/YAML vẫn parse và actionlint riêng.
- Live settings/coverage/check-blocking không thuộc quyền worker; runbook không ghi control verified khi chưa có readback của root. AC-9, EX-1 và phần thiếu coverage EX-2 giữ mở.

## Bàn giao / bước tiếp theo

- Bàn giao Ready for root gate: giữ đúng 4 file chưa commit trong worktree `/home/liend/.local/share/x-scanner/xs05-guards-config`. Root đọc/tích hợp patch, cập nhật hồ sơ tổng, chạy đủ gate trước commit và CI; chỉ root áp/readback settings và ghi evidence. Chưa commit/push/merge hoặc native mutation bởi worker.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Chưa nghiệm thu cuối; giữ working.md. Chỉ root đổi Done sau đủ DoD và merge thật.
