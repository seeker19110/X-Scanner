# Hàng rào repository — X-Scanner

Chính sách XS-05 xử lý F-014 và phần khả thi của F-009. File này mô tả cấu hình và cách
kiểm; **có file cấu hình trong Git chưa chứng minh control đã chạy trên GitHub**.
Bằng chứng live do phiên chính ghi ở [bảng riêng của X-Scanner](../adoption/README.md)
và hồ sơ `docs/work/2026-10-16-xs05-repository-guards/done.md`, kèm ngày/SHA/run thật.
Không dùng Evidence của repo mẫu trong `repository-settings.md`.

## Chính sách đích

| Control | Cấu hình được review |
| --- | --- |
| Ruleset | [main.json](../../.github/rulesets/main.json), tên `X-Scanner main`, target branch `refs/heads/main`, enforcement `active`, không bypass actor |
| Bảo vệ lịch sử | Chặn xóa và force push, yêu cầu lịch sử tuyến tính |
| Pull request | Bắt buộc PR và giải quyết review thread; chỉ squash merge; 0 approval bắt buộc vì repo một owner; dismiss stale reviews bật; không bắt code owner/last-push approval |
| Required check | Chỉ `Framework and Android app gate`, ràng buộc GitHub Actions app ID `15368`; strict bật, `do_not_enforce_on_create: false` |
| Dependency review | Trong cùng job, trước app gate, chỉ chạy sự kiện `pull_request`; mọi lỗi API/action và vulnerability từ mức `low` chặn job; xét cả runtime/development/unknown |
| Quyền CI | `contents: read`, checkout không lưu credentials; không đăng comment PR, không thêm secret hoặc dịch vụ |

Action dependency review ghim v5.0.0 tại SHA
`a1d282b36b6f3519aa1f3fc636f609c47dddb294` (08/05/2026). License check tắt vì
chưa có license policy sản phẩm; Scorecard tắt. Các bước build/analyze/format/test và
upload APK UAT giữ nguyên; không bật auto-merge, release hoặc workflow mẫu.

GitHub readback thêm hai mặc định được khai rõ trong JSON: `required_reviewers: []` và
`require_extra_approval_for_unattributed_changes: true`. Giữ mặc định bảo vệ của GitHub;
[quy tắc này không tăng số approval khi required approvals bằng 0](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets#additional-approval-for-unattributed-copilot-pull-requests).
Không bỏ qua field lạ trong so sánh chỉ để báo khớp.

## Áp ruleset và đọc lại

Phiên chính thực hiện sau review cấu hình và full gate xanh, bằng tài khoản đã có quyền
Administration của repo. Không cần tạo token mới. Chạy từ root repo; lưu evidence ngoài
working tree để không làm đổi snapshot trong lúc gate chạy.

```bash
set -euo pipefail
repo='seeker19110/X-Scanner'
evidence_dir="$(mktemp -d /tmp/x-scanner-guards.XXXXXX)"
gh api --paginate --slurp "repos/$repo/rulesets?includes_parents=false&per_page=100" \
  > "$evidence_dir/rulesets-before.json"
jq '.[][] | {id, name, enforcement}' "$evidence_dir/rulesets-before.json"
```

Đọc danh sách trước. **Chỉ khi chưa có `X-Scanner main`**, tạo từ JSON đã review:

```bash
gh api --method POST "repos/$repo/rulesets" --input .github/rulesets/main.json \
  > "$evidence_dir/ruleset-applied.json"
ruleset_id="$(jq -er '.id | numbers' "$evidence_dir/ruleset-applied.json")"
```

Nếu đã có ruleset đó, đọc đúng ID trước; đối chiếu thay đổi, rồi cập nhật cùng ID thay
vì tạo bản trùng. Lệnh thay cho POST ở trên, không chạy cả hai:

```bash
: "${ruleset_id:?Điền ID đã đọc và review}"
gh api "repos/$repo/rulesets/$ruleset_id" > "$evidence_dir/ruleset-before.json"
gh api --method PUT "repos/$repo/rulesets/$ruleset_id" --input .github/rulesets/main.json \
  > "$evidence_dir/ruleset-applied.json"
```

Đọc lại với quyền đủ để nhận trường `bypass_actors`, so toàn bộ cấu hình và các rule
thực sự áp dụng lên main. Thiếu trường không được suy thành mảng rỗng.

```bash
gh api "repos/$repo/rulesets/$ruleset_id" > "$evidence_dir/ruleset-readback.json"
projection='{name,target,enforcement,bypass_actors,conditions,rules:(.rules|sort_by(.type))}'
diff -u <(jq -S "$projection" .github/rulesets/main.json) \
  <(jq -S "$projection" "$evidence_dir/ruleset-readback.json")
gh api --paginate --slurp "repos/$repo/rules/branches/main?per_page=100" \
  > "$evidence_dir/main-active-rules.json"
gh api "repos/$repo/branches/main" --jq '{name, protected}'
```

Xác minh tên check và `.app.id` trên head PR hiện tại bằng API check-runs; ID `15368`
phải là app phát check đó, không chỉ một context cùng tên. Required check không tự bảo
vệ nội dung workflow khỏi người có quyền sửa repo; review diff CI vẫn bắt buộc.

```bash
: "${head_sha:?Điền head SHA thực của PR}"
gh api --paginate --slurp "repos/$repo/commits/$head_sha/check-runs?per_page=100" \
  > "$evidence_dir/check-runs.json"
jq '[.[].check_runs[] | select(.name == "Framework and Android app gate") | {name, head_sha, app_id:.app.id, status, conclusion, html_url}]' \
  "$evidence_dir/check-runs.json"
```

## Bật alerts/graph và kiểm dữ liệu

REST `PUT vulnerability-alerts` bật cả dependency alerts và dependency graph. GET trả
204 mới xác nhận alerts bật; 404 hoặc lỗi quyền phải điều tra, không ghi verified.

```bash
gh api --method PUT "repos/$repo/vulnerability-alerts"
gh api --include "repos/$repo/vulnerability-alerts" \
  > "$evidence_dir/alerts-readback.http"
gh api "repos/$repo/dependency-graph/sbom" > "$evidence_dir/sbom.json"
jq -r '.sbom.packages[]?.externalRefs[]? | select(.referenceType == "purl") | .referenceLocator' \
  "$evidence_dir/sbom.json" | sort -u > "$evidence_dir/graph-purls.txt"
```

Đối chiếu từng cặp tên/phiên bản của **mọi gói hosted trong `apps/mobile/pubspec.lock`**
với Pub purl thực nhận, ghi SHA default branch đang xuất SBOM. HTTP 200, chỉ có root
package, hoặc danh sách rỗng chưa chứng minh coverage Pub; count bằng nhau cũng chưa
đủ nếu tên/phiên bản lệch. Việc parse graph có thể trễ sau khi bật hoặc push.

Đọc dependency compare trên đúng base/head PR, lưu cả header của mọi trang:

```bash
: "${base_sha:?Điền base SHA thực của PR}"
: "${head_sha:?Điền head SHA thực của PR}"
gh api --include --paginate \
  "repos/$repo/dependency-graph/compare/$base_sha...$head_sha?per_page=100" \
  > "$evidence_dir/dependency-compare.http"
```

Kiểm HTTP status, dữ liệu và header `x-github-dependency-graph-snapshot-warnings`
(giá trị có cảnh báo được mã hóa base64), cùng log bước dependency review thực trong CI.
Một diff rỗng trên PR chỉ đổi cấu hình là hợp lệ nhưng không chứng minh toàn bộ lockfile
được quét. Không dùng kết quả này như một full audit của các gói đã tồn tại.

**Giới hạn upstream:** `retry-on-snapshot-warnings: true` cấu hình timeout retry 120 giây, nhưng
[source v5.0.0](https://github.com/actions/dependency-review-action/blob/a1d282b36b6f3519aa1f3fc636f609c47dddb294/src/main.ts#L33)
trả comparison còn cảnh báo sau timeout. `warn-only: false` chặn vulnerability/lỗi
action; nó không biến snapshot warning thành lỗi. Do đó CI xanh chưa chứng minh dữ
liệu đầy đủ. DEBT: chưa có cổng fail trên snapshot thiếu sau timeout | trần: dùng hành vi upstream v5.0.0 | xem lại khi: snapshot warning xuất hiện trong CI hoặc trước release đầu tiên.

Chỉ nhận F-009 hoàn tất và đóng EX-2 khi có readback Pub khớp lockfile **và** compare
không snapshot warning, cùng bước action thực chạy thành công trên head CI cuối và
workflow đã merge vào main. Trong khi PR còn mở, ghi controls sẵn sàng trên PR, giữ
EX-2 cho phần workflow chưa có trên main.
Chưa đủ thì ghi partial, giữ [EX-2](supply-chain-exceptions.md)
mở cùng compensating controls. [EX-1](supply-chain-exceptions.md) (`image` chờ 18/10)
và AC-9 UAT thiết bị vẫn mở độc lập.

## Kiểm chứng chặn merge và rollback

Trên PR cấu hình, sau full gate cục bộ xanh: phiên chính có thể hủy một run CI, đọc
conclusion `cancelled` và merge state `BLOCKED` khi required check ràng buộc app đang
active. Sau đó rerun, đợi `success`/`CLEAN`. Ghi rõ đây là run bị hủy, không phải test
code cố tình đỏ hay bằng chứng API merge bị từ chối. Không thử merge khi check thiếu/đỏ.

Nếu cấu hình sai: sửa tên check/app ID hoặc rule bằng PR, giữ cổng hiện có. Revert commit
CI không tự hoàn tác settings native; root phải review JSON/readback trước khi cập
nhật cùng ruleset ID. Không tắt ruleset, thêm bypass hoặc bỏ qua gate để merge.

## Nguồn đã đối chiếu ngày 16/10/2026

- [GitHub REST rulesets: schema, create/update và readback](https://docs.github.com/en/rest/repos/rules).
- [GitHub REST: bật và kiểm vulnerability alerts](https://docs.github.com/en/rest/repos/repos#enable-vulnerability-alerts).
- [GitHub REST SBOM](https://docs.github.com/en/rest/dependency-graph/sboms) và [dependency compare](https://docs.github.com/en/rest/dependency-graph/dependency-review).
- [Inputs action tại SHA ghim](https://github.com/actions/dependency-review-action/blob/a1d282b36b6f3519aa1f3fc636f609c47dddb294/action.yml).

## Bằng chứng đợt XS-05

[PR #53](https://github.com/seeker19110/X-Scanner/pull/53) giữ bằng chứng head CI cuối.
[Run38925328599](https://github.com/seeker19110/X-Scanner/actions/runs/38925328599)
ở head bb98b4a được cố ý huỷ: action review SUCCESS trước app gate, required check
15368 cancelled và PR BLOCKED, không artifact. Checkpoint sau chỉ tài liệu/evidence;
CI final-head được đối chiếu riêng, không nhận hai head là một hay nhận API merge bị từ chối.


## Reconcile sau review/merge53 — 2026-10-16

PR53 đã merge3f49039 sau CI38930758793 trên head51af8e0 SUCCESS; workflow trên main
khớp reviewedhead. Readback đủ86/86Pub, alerts204, final compare HTTP200/no snapshot
warning và action thực success, nên EX-2 đóng theo tiêu chí trên. Đã xem lại debt
snapshot trước đóng: giữ hành vi action chuẩn cùng evidence đầy đủ hiện tại, xem lại
khi warning xuất hiện hoặc trước release; không nhận graph diff là full security audit.
[Bằng chứng](evidence/2026-10-16-xs05-native.json) giữ cả cancelled head ban đầu và
final head riêng biệt. EX-1 và AC-9 vẫn mở.
