# Công việc: XS-05 — hàng rào merge và dependency của X-Scanner

- Work ID: 2026-10-16-xs05-repository-guards
- Yêu cầu / outcome: sau review/sửa/merge PR #52, tiếp tục ưu tiên trong báo cáo 16/10; tự quyết kỹ thuật và chạy đủ gate. Đơn vị này xử lý F-014 và phần F-009 khả thi bằng native controls/CI.
- Trạng thái: Ready — [PR #53](https://github.com/seeker19110/X-Scanner/pull/53) mở sau local gate/native readback; CI final head xác minh trên PR; chưa merge.
- Chủ trì / writer: phiên chính; config worker ở worktree riêng; root review, tích hợp, native settings, gate và PR.
- Mức rủi ro / số PR: S (config/tài liệu thuần), một PR mới; request gồm PR #52 hiện có rồi đơn vị này nên giao worker theo §3c, tuần tự theo dependency.
- Scope / non-goal: ruleset main đúng job thực, dependency review vào cùng gate, bật/kiểm alerts/graph và đọc riêng secret settings; không sửa app/dependency/schema, bật auto-merge/release/scheduler/PR-4b, thêm API trả phí, tạo secret/token mới. Quyền merge trực tiếp đã cấp cho #52; PR đơn vị này để review.
- Spec / goal / issue: nghiên cứu docs/research/2026-10-16-upgrade-research.md §6, XS-05/F-014/F-009; mức S không cần spec sản phẩm. [PLAN.md](PLAN.md) là hợp đồng phân công.
- Nhánh / base SHA / thời điểm reconcile: codex/xs05-repository-guards @ f753933ae9f75c580266d52a585b4af18fc34acb; main ff-only sau #52, 2026-10-16T15:18:22Z.

## Kế hoạch và phân công

1. Review/gate/merge #52; về main ff-only và chốt bằng chứng hai hồ sơ #52 trong PR kế này.
2. T2 worker tạo config/runbook trong worktree riêng; chỉ bốn file của contract, không commit/push/native mutation. Phiên chính giữ writer độc quyền PROGRESS/CODEMAP/CHANGELOG/CLAUDE/AGENTS và hồ sơ tổng.
3. Phiên chính review config, full gate cục bộ, áp native settings sau khi có cấu hình review được; đọc lại trạng thái thật, không dùng Evidence của repo mẫu.
4. Mở PR, CI action thật, negative control huỷ CI của chính PR → đọc BLOCKED rồi rerun success. Không thử merge PR mới; phân biệt cancelled với test code đỏ.

## Quyết định và bằng chứng

- Chọn XS-05 tiếp theo · loại nâng decoder sớm hoặc coi UAT hoàn tất · bậc 1: image 4.12.0 đủ tuổi 18/10; adb hiện không có thiết bị; F-014 còn thiếu qua API thật. Không mở PR-4b từ yêu cầu nâng cấp chung vì spec yêu cầu duyệt rõ dữ liệu thật.
- Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07, áp yêu cầu trực tiếp 2026-10-16 tự quyết kỹ thuật và nâng cấp theo báo cáo; phạm vi S là controls XS-05 phòng thủ, không mở quyền release/migration/deploy. Chọn native controls trên repo công khai sẵn có · loại dịch vụ mới/đổi stack · bậc 1 + 2.
- Chọn native ruleset không bypass, app-bound required check đúng tên, strict, squash và approval 0 vì chỉ có một owner · loại gate/metadata mẫu và một approval không thể tự duyệt · bậc 1 + 2.
- Chọn dependency-review action chính thức v5.0.0/SHA a1d282b36b6f3519aa1f3fc636f609c47dddb294 (08/05/2026, Node24, đã kiểm action.yml/src/release) trong cùng job trước app gate · loại thêm job tổng hợp/permission write/comment API · bậc 2. Ngoại lệ TDD số 3: config thuần/tài liệu.
- Ảnh chụp 16/10 trước triển khai: owner token có admin; main protected=false, rules=[]; Actions app id15368; default GITHUB_TOKEN read, cannot approve; vulnerability-alerts GET404 (disabled); SBOM GET404 (chưa chứng minh graph); secret scanning và push protection enabled. Không in token hay đọc secrets.
- Học nguồn ngoài: đã có và sâu hơn = gate app/manifest/hooks, không nhập lại khung; đã có nhưng nông hơn = Dependabot version updates có cooldown, bổ sung alerts/dependency review cho F-009; chưa có = F-014 được xác minh từ API, bổ sung native policy. Không lấy công nghệ app mới từ khung mẫu.
- PLAN --check-plan: OK, 2 việc, đủ trường/không placeholder/dependency hợp lệ/mỗi việc một PR. Nguồn kỹ thuật: GitHub REST rulesets, troubleshooting required checks, dependency-review-action v5.0.0 và supported package ecosystems (pubspec.lock).

- Review độc lập plan xác nhận schema/action inputs đúng; nhận giới hạn upstream snapshot warnings hết retry có thể tiếp tục. Chọn action chuẩn và nêu giới hạn · loại wrapper/test/config mới · bậc 2; chỉ nhận F-009/đóng EX-2 khi SBOM Pub coverage khớp lockfile và compare của PR không warning. Nếu chưa đủ giữ exception partial.

- Sau khi GitHub ingest xong: SBOM 91 packages, **86/86 hosted Pub khớp chính xác name/version trong pubspec.lock**, không thiếu/thừa. Lần root-only ban đầu là snapshot đang cập nhật; vẫn cần dependency-review chạy thật/compare không warning trên PR mới trước đóng EX-2.

- T2 worker bàn giao Ready, root đã đọc cả 4 file và tích hợp sau freeze. JSON/YAML/exact5rules/1check app 15368/actionlint/12 Bash blocks/link/scope PASS ở worker; root chạy lại kiểm cấu hình và full Android gate trước native ruleset apply. Ngoại lệ TDD3 config/tài liệu, không source app hoặc lockfile.

- Full gate trước apply: PASS 4/4, Flutter 546/546, analyze 0, format 55/0, merged release manifest/adoption/manifest self-test/hook suites PASS. Root review và reviewer độc lập findings=[]; source app/lockfile không đổi.
- Native POST đã tạo ruleset 25250032 active, bypass=[]/current_user_can_bypass=never. So sánh full rule lần đầu dừng vì GitHub thêm required_reviewers=[] và require_extra_approval_for_unattributed_changes=true. Giữ hai mặc định và khai rõ vào JSON · loại bỏ qua mọi unknown field hoặc tắt bảo vệ mặc định · bậc1. Official ruleset docs xác nhận extra approval không ảnh hưởng count 0; author/committer của commit review được liên kết owner. Ghi TRAPS để tránh tái phát drift giả.

- Readback sau canonical defaults: ruleset 25250032 active, protected=true, owner cannot bypass, đúng 5 rule và mọi parameter khớp JSON, duy nhất context/app 15368 strict=true. Lần gọi lại chỉ GET readback, không POST trùng hoặc hạ rule. Evidence docs/ops/evidence/2026-10-16-xs05-native.json; source app/lockfile giữ nguyên.

- Commit bb98b4a qua normal pre-commit PASS 4/4, Flutter 546/546, analyze 0, format 55/0, release manifest/adoption/manifest self-test/hook suites PASS; không bỏ hook. [PR #53](https://github.com/seeker19110/X-Scanner/pull/53) đã mở và gắn chat.
- Negative control thật trên head bb98b4a: [run 38925328599](https://github.com/seeker19110/X-Scanner/actions/runs/38925328599) cố ý bị huỷ, check app 15368 conclusion=cancelled và PR mergeStateStatus=BLOCKED; không gọi API merge. Không artifact được upload (0), vì app gate chưa hoàn tất. Đây không phải test code đỏ hoặc bằng chứng merge API từ chối.
- Bước dependency review trong run bị huỷ đã SUCCESS trước khi app gate bị cancel. API compare f753933...bb98b4a trả200, một thay đổi đúng action/SHA mới, snapshot warning rỗng. Graph86/86 Pub khớp lockfile. EX-2 còn mở vì workflow chưa merge main; không nói full CI run bị huỷ đã pass.
- Tối giản vòng xác minh · chọn commit bàn giao chỉ docs/evidence rồi CI trên head cuối · loại rerun đầy đủ trên head sắp được thay bằng checkpoint tài liệu · bậc2+4, không giảm cổng. Config workflow/ruleset và app giữ nguyên giữa head negative control và head bàn giao; không nhận hai head là một. Kết quả final-head CI/CLEAN đối chiếu trên PR #53 sau push.
- Canonical JSON đã roundtrip PUT cùng ID25250032 và GET/diff toàn rule khớp; không POST trùng hoặc hạ bảo vệ. Reviewer delta findings=[]; official extra approval/count 0 và native defaults đã kiểm.

## Lần thử / blocker

- Lần đọc ngay sau bật alerts chỉ có root package; sau ingest đã khớp 86/86 Pub. Không dùng response rỗng làm coverage. Còn chờ action/compare và phép kiểm CI cancelled→BLOCKED→success; W-104b/AC-9/PR-4b giữ giới hạn riêng.

## Bàn giao / bước tiếp theo

- Đẩy checkpoint tài liệu qua normal pre-commit/full gate; chờ CI head cuối của PR #53 và kiểm app 15368/SUCCESS/CLEAN, compare không warning. Bằng chứng GitHub execution hiện hành nằm trên PR; không tạo commit chỉ để tự ghi SHA/CI của chính commit đó. Giữ PR mở, EX-2 chờ merge workflow, EX-1 từ 18/10/AC-9/PR-4b vẫn giữ giới hạn riêng.

## Nghiệm thu cuối

- Native settings, roundtrip, graph và negative control đạt; local gates/normal pre-commit PASS. PR #53 giữ mở để review; final-head CI đối chiếu trên PR. Chỉ Done sau merge thật của đơn vị này; không đóng AC-9 hoặc EX-1 từ gate.
- Native readback 2026-10-16T15:20Z: alerts 204, SBOM 200 (initial Pub 0/86), dependency compare cda650f...7974fe5 trả HTTP200; kiểm snapshot warning trên PR mới sau khi graph cập nhật. Trước bật compare là403 và alerts404. Chỉ bật alerts/graph, không bật security-update tự tạo PR hoặc auto-merge.
