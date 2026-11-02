# Công việc: Reject oversized migrations and non-finite corners

- Work ID: 2026-11-03-migration-manifest-cap
- Trạng thái: Targeted RED→GREEN57/57; staged for root review/gate/PR, not committed.
- Scope: AUD-DATA-002 migration output/recovery cap and quad finite-coordinate boundary; S maintenance, no schema/page cap/dependency change.
- Writer: complete_audit_product; root owns shared docs, gate, PR/merge.
- Branch/base: codex/migration-manifest-cap @976c71d; root will reconcile merged main d22e622.
- Approved: root delegated repair under /complete after independent reproduction, 2026-11-03.

## Evidence and plan

- Valid schema1 of25000 synthetic pages encodes4000029 bytes; schema2 grows4325183 bytes beyond4194304 cap. Root/code worker actual migration returned Done then library unreadable; rollback preserves bytes.
- Tests use existing IOOverrides/counting seam with one synthetic original; require typed failure before writes/unchanged source. Production rejects UTF8 schema2>existing cap before journal and uses bounded recovery reader; no bytes/schema/page limits changed.
- Quad regression covers4corners×2axes×NaN/±Infinity; finite clamp test retained. Guard rejects nonfinite x/y before clamp; corrected false NaN comment. Parent independently reproduced old acceptance.
- RED exit1: all3 cases fail (first attempted journal write killed; oversized committed recovery Done; -Infinity accepted). Log /tmp/complete-product-audit/boundaries-red.log. Guards then added; whole targeted suites GREEN exit0,57/57, boundaries-green-suite.log; format4/0 changes. No full gate/commit/push by worker; keep working.md pending PR/merge.

- One first GREEN invocation used repo-root cwd and stopped before tests (no pubspec); not a source/test failure. Correct apps/mobile invocation above passed. Pubget enforce-lockfile exit0, no lock delta.

Root nhập frozen staged patch vào codex/review-migration-boundaries từ maind22e622 (tree-trùng candidate976c71d); reviewer-alt max APPROVE source, không giả runtime model comparison. Cùng PR có CODEMAP/TRAPS F086/F087/PROGRESS. Đang full gate trước commit/CI, chưa merge.

Root final PASS4/4:848 Flutter,11 JVM,38 repository; analyzer0; format70/0; licenses142; coverage96.29% lines/92.26% branches; manifest/16KB/size pass; log complete-boundaries-full-gate.log, native hook sẽ kiểm lại. RED gồm2 matcher failures và1 intentional first-write _Killed tripwire, không phải compile/environment failure. Giữ originals/oversized target, không device/release acceptance.
