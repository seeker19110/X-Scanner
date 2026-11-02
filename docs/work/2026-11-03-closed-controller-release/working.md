# Công việc: Release closed document controller after idle

- Work ID: 2026-11-03-closed-controller-release
- Trạng thái: Worker ready for root review — RED then targeted GREEN, full gate/CI/merge pending.
- Scope: main.dart ownership cleanup + app_test.dart behavioral handoff regression. No original bytes/storage/API changes.
- Base: candidate 976c71d9b2a05e56dbfeb65229ca2c2a6242f595; branch codex/closed-controller-release.
- Approval: root /complete audit plan AUD-PERF-001, 2026-11-03; writer complete_audit_code, root owns shared docs/gates/PR.
- Evidence: main._last retains disposed controllers plus thumbnail/cropped-preview Futures; product auditor independently confirmed. No measured peak-RAM/OOM claim.
- Plan: run the retained closed-completed/pending-save/old-successor handoff assertions RED before source; then release only after route dispose and captured idle, identity check before removal.
- Contract: preserve pending durable writes/import sequencing, no production test hooks, no full gate/commit/push/merge by worker.
- DoD: root review, current full gate + CI and merged PR required; keep working.md until actual merge.
- RED: `flutter test test/app_test.dart` exit1; final ownership assertion Expected true / Actual false (closed cache owner retained). Both pending-save/successor assertions ran and passed first; log `/tmp/complete-code-audit/controller-release-red.log`. Source main.dart was unchanged during RED.
- GREEN: same `flutter test test/app_test.dart` exit0, 1/1 smoke covers completed close, in-flight durable save wait and late-old-completion identity. `bash scripts/dev-task.sh format`:70 files/1 formatted (test only). Log `/tmp/complete-code-audit/controller-release-green.log`; no Gradle/full gate/commit/push/merge.
- Implementation: route dispose first disposes controller, then schedules cleanup after captured idle; identity check preserves a live successor. No write cancellation, test-only production hook, cache/storage format or original-byte change. Root transfers this patch onto merged main for full gates and current PR metadata.

Root nhập staged patch vào codex/review-closed-controller-release từ maind22e622 tree-trùng candidate976c71d; cùng PR có CODEMAP/TRAPS(F085)/PROGRESS. Reviewer-alt max APPROVE source; runtime model superiority không được giả nhận. Root đang full gate/CI, chưa merge.

Root final PASS4/4:846 Flutter,11 JVM,38 repository; analyzer0; format70/0; licenses142; coverage96.30% lines/92.26% branches; manifest/16KB/size pass; log complete-controller-full-gate.log. Giữ toàn bộ assertions bàn giao actual save và successor; native commit hook sẽ kiểm lại, chưa device/heap claim.
