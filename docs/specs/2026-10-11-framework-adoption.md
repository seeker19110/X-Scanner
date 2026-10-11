# Framework adoption — X-Scanner

Status: Approved for implementation (framework adoption only).
Approval: chủ repo yêu cầu trực tiếp ngày 2026-10-11: lưu gợi ý và áp dụng projects-template.

## Scope

Advisory, khung ghim commit, cấu hình repo và kiểm chứng. Không app, stack, paid API hoặc release.

## Acceptance criteria

- Research giữ nguyên và đánh dấu ADVISORY.
- Copy chính thức, có commit/manifest và license nguồn.
- PROJECT/PROGRESS/CHANGELOG riêng, không nhận kết quả của template làm kết quả sản phẩm.
- Gate có kiểm tra thật, không báo app build/benchmark PASS.
- Drop-ins chưa phù hợp được giữ inactive, có lý do hoãn; không sửa repo nguồn.

## Verification

`python3 scripts/check-adoption.py --lint`, `python3 scripts/check-adoption.py`,
`bash scripts/test-hooks-gate.sh`, `bash scripts/test-hooks-gate-guard.sh`, doctor và gate.
Evidence ở GitHub Actions; app build/benchmark N/A.

## Rollback

Revert adoption/config commits; giữ research, không force-push.
