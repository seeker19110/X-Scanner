## Summary

<!-- What changed, why, and user/developer impact. -->

-

## Issue / Goal

<!-- Work ID = folder name docs/work/<YYYY-MM-DD-slug>/ holding working.md or done.md (checked by pr-policy). -->

- Work ID:
Closes #

## Research / Spec

<!-- Required for feat: docs/specs/<date>-<slug>.md, Approved, approver/date. -->

- Goal:
- Spec:
- Approval:
- Deviation from spec:

## Change type

- [ ] feat
- [ ] fix
- [ ] refactor
- [ ] docs/spec
- [ ] test
- [ ] chore/ci
- [ ] breaking change

## Validation

<!-- Exact commands and current results; use profile-equivalent gates. -->

- [ ] format/lint/static or type analysis
- [ ] unit/integration tests
- [ ] build/package
- [ ] E2E/a11y/performance/device/eval when applicable
- [ ] security/dependency/secret scan
- [ ] manual/UAT:

### Evidence

<!-- Test counts, screenshots, metric/eval delta, migration query. -->

### Refactor/perf only: before and after

<!-- Required for refactor:/perf: PRs (no behaviour change, no feature mixed in). Same command, same machine. -->

| Metric | Before | After | Command |
| --- | --- | --- | --- |
| Test count (Flutter) | | | `cd apps/mobile && flutter test` |
| Lines in touched files | | | `wc -l <files>` |
| Debug APK contents (uncompressed bytes) | | | `python3 scripts/check-apk-size.py --apk apps/mobile/build/app/outputs/flutter-apk/app-debug.apk --budget apps/mobile/apk-size-budget.json` |
| Runtime dependencies | | | `apps/mobile/pubspec.yaml` |

<!-- Only when the PR changes pubspec.yaml or a Gradle build file (scripts/check-pr-policy.py, BASE-DEP-006):
add a level-2 section titled Dependencies. For each NEW dependency: repo not archived, a release in the last 12 months,
license on docs/ops/license-policy.json, no telemetry/network, and why the existing code or SDK is not enough.
A version bump or a manifest edit with no new dependency: write "None added". -->

## Risk, rollout and rollback

- Risk level and affected critical flows:
- Security/privacy/authorization:
- Data/migration/compatibility:
- Feature flag/canary/health checks:
- Rollback/recovery/reconciliation:
- Residual risks:

## Definition of Done

<!-- Each item needs evidence after "Evidence:" (CI run link, test name, file path, command + result).
     A ticked item without evidence counts as NOT done. Write "n/a: <reason>" when an item does not apply. -->

- [ ] Feature research/spec was approved before source changes. Evidence:
- [ ] Implementation matches spec; deviations are reviewed. Evidence:
- [ ] Acceptance criteria map to tests (AC-xx / S-NNN -> test name). Evidence:
- [ ] Targeted and full profile gates pass (`bash scripts/dev-task.sh gate`, CI run link). Evidence:
- [ ] Inputs/errors/loading/empty states, authorization/privacy/concurrency/idempotency handled. Evidence:
- [ ] No secrets, production or real user data, debug/dead/generated noise. Evidence:
- [ ] Contracts/migrations/docs/ADR/runbook/threat model/data map updated. Evidence:
- [ ] Self-reviewed the diff; review threads resolved and required checks pass. Evidence:
- [ ] Tried on emulator/device (UAT) when behaviour changed, or stated why not. Evidence:

## Reviewer focus
