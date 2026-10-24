<!-- Major dependency/toolchain upgrade (OPS-MAINT-005). Open with ?template=major-upgrade.md, add the label
     `major`, and keep the upgrade alone: no feature or unrelated fix in the same PR. Dependabot ignores majors;
     they go through /deps-upgrade. Title example: `build(deps)!: upgrade <package> 3.x to 4.0`. -->

## Summary

- Package/toolchain and versions (from → to):
- Why now:

## Issue / Goal

- Work ID:

## Upgrade notes

- Changelog / migration guide read (links) and summary of breaking changes that touch this repo:
- Official codemod or `dart fix` run (command + result), or "none available":
- Code touchpoints changed:
- Lockfiles regenerated (`pubspec.lock`, `gradle.lockfile`, `settings-gradle.lockfile`) and diff reviewed:
- Release age ≥ 7 days and integrity (`docs/ops/dependency-updates.md` steps 1–2):

## Validation

- [ ] `bash scripts/dev-task.sh gate` PASS (paste the final line)
- [ ] Coverage ratchet, license check, OSV scan green
- [ ] Android UAT on a device with the CI debug APK (`docs/ops/android-uat.md`) when runtime code changed

## Risk, rollout and rollback

- Risk and affected flows:
- Rollback: revert this PR (single squash commit); data/format compatibility of files written by the new version:
- Residual risks:
