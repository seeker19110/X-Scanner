# Công việc: Vá Guava trên classpath build, lint và UTP

- Work ID: 2026-11-03-guava-security
- Yêu cầu / outcome: root giao sửa GHSA-xxph-c9ww-hj94/CVE-2026-102554 phát hiện bởi CI PR #73; PR riêng theo docs/ops/VULN-SLA.md.
- Trạng thái: Worker commit 8efc3ce hoàn tất; root review/validation + integration docs, PR/CI/owner L1 merge còn chờ.
- Chủ trì / writer: guava_security; root review/tích hợp và làm mọi thao tác đối ngoại.
- Mức rủi ro / số PR: S, một PR dependency/security config, không tính năng app.
- Scope: settings.gradle.kts, app/build.gradle.kts, hai lockfile Gradle và hồ sơ này. Không thay app source/runtime dependencies, quyền Android, gate/CI, exception OSV, baseline hay secret.
- Nhánh / base SHA: codex/guava-security-fix @ a1959b449d19b4495171c7226d64e2e5f1aeb7bd, worktree /home/liend/.local/share/x-scanner/worktrees/guava-security.

## Kế hoạch và hợp đồng

1. Xác minh advisory, bản vá, release age, license/checksum từ nguồn chính thức.
2. OSV RED trên locks trước sửa; ghi graph releaseRuntimeClasspath trước.
3. Constraint tối thiểu chỉ build classpath/lint/UTP, regenerate locks thật; so toàn bộ delta và release runtime.
4. OSV GREEN, full gate thật, review diff. Root giữ PROGRESS/CODEMAP/CHANGELOG; không ghi chung file.
Approved for implementation — phiên chính giao theo ủy quyền §3d, 2026-11-03. Không thêm business logic/nhánh xử lý lỗi hay quyền sản phẩm. Selector Kotlin có nhánh chọn cấu hình được kiểm bằng OSV RED trước sửa và resolver/GREEN thật; chỉ tài liệu và lock sinh tự động áp ngoại lệ đóng. Persistent regression cũng RED trước regenerate lock.

## Nghiên cứu và quyết định

- Nguồn chính thức: https://github.com/google/guava/security/advisories/GHSA-xxph-c9ww-hj94 ; affected 4.0–33.7.1, fixed 33.7.2. Upstream ghi CVSS3 Moderate 5.9, OSV/GitHub Database dùng CVSS4 High 8.2; không đồng nhất hai điểm số.
- https://github.com/google/guava/releases/tag/v33.7.2 — phát hành 2026-09-29T14:53:52Z, >7 ngày. Changelog xác nhận chặn cấp phát mảng quá lớn khi deserialization các collection; không chạy payload tấn công/OOM trong môi trường build.
- Artifact/POM nguồn Maven Central chính thức: https://repo.maven.apache.org/maven2/com/google/guava/guava/33.7.2-jre/ . SHA256 jar kiểm thật với checksum nguồn: b530942257fb935f8b2cfaa5f8eb5bd59c555fd8e8d01b8ce98912e077ea606c.
- Chọn dependency constraint tối thiểu thay vì suppression hoặc force toàn bộ runtime; đúng/bảo mật trước ít code. Không sửa osv-scanner.toml.
- OSV Scanner v2.7.0 binary kiểm SHA256 khớp CI: 160c6253e2922e9e0a6a9771c5c4c40a4b3c6090b34a3cdd5e80c96cc2e4218b.

## Bằng chứng / lần thử

- `/tmp/guava-osv-red.log`: OSV thật báo 4 mục Guava bị ảnh hưởng: 32.0.1-jre, 33.3.1-jre, 33.4.0-jre ở app lock và 33.4.0-jre ở settings classpath.
- Source env.sh trong mọi shell vì cache Gradle nằm user-local. Worktree mới không có gradlew (file được Flutter sinh, gitignored); dùng Gradle distribution đã checksum-verified để đo graph trước, full Flutter build sau sẽ sinh wrapper.

## Bàn giao

Chưa nghiệm thu. Root sẽ đối chiếu artifacts/gate và tạo PR; L1 giữ owner merge, không bật auto-merge.

- License source: Guava parent POM 33.7.2-jre declares Apache-2.0; artifact checksum verified. Runtime graph before saved at /tmp/guava-runtime-before.txt.
- Attempt 1: direct constraints in dependencies DSL failed because AGP UTP configurations are not created yet (configuration name not found). Layer ④ lifecycle/configuration, not dependency incompatibility. Register scoped declarations after evaluation; no force or runtime constraint.

- Attempt 2: afterEvaluate still cannot address lazy UTP configurations by name. Stopped this approach after two failures, identified layer ④ configuration lifecycle; root approved lazy configureEach matching only androidLintTool and AGP UTP, without force.
- Root extended file contract with apps/mobile/test/build_dependency_security_test.dart. Persistent regression ran RED on real old lockfiles: 2 fail (settings 33.4.0-jre, app 32.0.1-jre below 33.7.2 floor), 1 pass (Guava outside releaseRuntimeClasspath). Assertions retained for GREEN. Log /tmp/guava-regression-red.log.

- Current AGP configuration evidence `/tmp/guava-current-configs.log`: connectedDebugAndroidTest exists and all tasks were realized; 184 configurations registered, no `_internal-unified-test-platform-*`. Old lock references 14 absent configurations (13 UTP plus androidJacocoAnt). `--write-locks` merges stale rows instead of deleting them.
- Root approved a fresh Gradle-generated app lock after external backup. Security regression scope no longer demands obsolete UTP configurations exist; it still requires real Guava build entries, patched floor for every row, lint classpath and no Guava outside build tools/release runtime. Selector remains lazy for future instrumentation configurations; regenerate locks when new ones arise (fail closed).

## Resolution, integrity and regression evidence

- Explicit configuration parameter is used in matching to avoid resolving `name` from the enclosing Kotlin script. Lazy configureEach applies only to current lint/possible late UTP tools, with no force.
- Regenerated app lock from scratch after preserving its bytes at /tmp/guava-app-before-fresh.lock; command: Gradle9.8.1 `-q :app:dependencies buildEnvironment --write-locks`. Settings lock regenerated by the same actual resolver. No fictional UTP versions were inserted.
- `/tmp/guava-lock-delta-audit.json`: 121 deleted module rows belong exclusively to configurations absent from current AGP. Six active lint version/removal changes reflect Guava's changed annotations/transitives; every module+version membership of every current non-tool compile/runtime/test config is unchanged. Old jsr305 only used by lint is removed, checker-qual resolves to existing older Jimfs transitive 2.5.8; neither reaches APK.
- Initial pre-pub-get graph was not comparable because generated Flutter plugin metadata was absent. Re-measured with generated metadata present by backing up patched Gradle files, loading actual HEAD files/locks, resolving the release graph, then restoring patches in finally and resolving again. `/tmp/guava-runtime-before-valid.txt` and after-valid are byte-identical, 24970 bytes.
- Guava33.7.2 and transitive artifact checks from official Maven Central: error_prone_annotations2.50.0 SHA256 4667724877f1d37a689202da191e23efa7657c62eef93ccdac406eccfe5cdd0a (2026-06-10, Apache2); j2objc-annotations3.1 SHA256 84d3a150518485f8140ea99b8a985656749629f6433c92b80c75b36aba3b099b (2025-08-14, Apache2).
- failureaccess1.0.3 computed SHA256 cbfc3906b19b8f55dd7cfd6dfe0aa4532e834250d7f080bd8d211a3e246b59cb, source SHA1 verified aeaffd00d57023a2c947393ed251f0354f0985fc (2025-03-19, Apache2); jspecify1.0.1 computed SHA256 070d75f261fe4c5b8202508366715f7f2d4660f88c8ef7e6d3575e48c9683b66, source SHA1 verified 3d60fd98eb8ade73004f4195c37b6317e02cf3d7 (2026-07-29, Apache2). Their older Maven artifacts lack SHA256 checksum sidecars, so verified published SHA1 and recorded computed SHA256.
- checker-qual2.5.8 computed SHA256 bd655da535df1eeb96fc8874d05d0f7029209de95096e4f84bd07c66688a210d, published SHA1 verified, Maven POM MIT (2018-12-05). All new Guava transitive annotation/failureaccess jars have class major52/53, compatible with pinned Java21. License names are source metadata, not a product legal conclusion.
- `/tmp/guava-osv-green.log`: same scanner/command/config as RED, No issues found (existing unrelated two ignored advisories unchanged). No new ignore or exception.
- `/tmp/guava-regression-green.log`: 3/3 tests pass against actual regenerated locks; floor checks keep their original assertions. Scope assertion corrected before regeneration to avoid requiring absent obsolete UTP configs; still requires lint/build-only Guava and excludes release runtime.

- Identical release graph SHA256: db382ab69009b17cc381437eb0da389fc40ef5a580f6a55a0b6225a6da135994.

## Environment recovery before full gate

- Full gate attempt 1 stopped in :app:mergeDebugNativeLibs with ENOSPC: /tmp is a 2.9GiB tmpfs, full; /home has >800GiB available. No quality/test assertion was measured past build, and this is NOT a gate PASS.
- Git worktree move across filesystems returned EXDEV. Standard mv preserved the entire worktree (source/index-linked state and generated build), then `git worktree repair` updated registration. New path: /home/liend/.local/share/x-scanner/worktrees/guava-security; branch codex/guava-security-fix unchanged. git diff unstaged was empty after move, matching all staged source blobs; no source/build data was deliberately discarded.
- Root approved environment move; all later Gradle/gate work uses the new worktree. Prior /tmp logs are retained outside the moved build tree.

## Checkpoint trước commit — full gate trên cây giữ nguyên

- New worktree full gate attempt2 PASS4/4: debug APK + release manifest/backup/permission checks, uncompressed contents234272422 bytes under245759848 budget, 5 native64-bit libs LOAD >=16KB; analyzer0 issues;69 syntax/config checks; Dart70 files/0 format changes; repository34/34 (main base, framework PR separately adds its tests); Flutter846/846 (843 existing+3 security); JVM11/11 with0failures/errors/skips. Coverage lines96.29%/branches92.24%, existing thresholds unchanged.
- Full output read and deduplicated only repeated progress labels; log /home/liend/.local/share/x-scanner/guava-full-gate.log. Tracked source stayed unchanged during the successful run.
- OSV repeated after the full build at new path: /home/liend/.local/share/x-scanner/guava-osv-final.log, No issues found; no exception changes.
- Self-review diff: only four Gradle files, one regression file, this work record. Existing APK runtime package+versions unaffected; source app, Android permissions, baselines, CI/gates/hooks and suppressions unchanged. Root must add its assigned integration documentation to the same dependency PR before final review/merge.
- Commit hook will rerun full gate, not skipped. Work remains working.md pending actual PR/CI/owner L1 merge; host gates are not device, iOS, OCR, quality or release acceptance.


## Root integration review — 2026-11-03

- Inspected the four Gradle files/lock deltas and the 3-case regression; no source-app, permission, CI/gate, baseline or OSV-exception change. Existing OSV RED predates source constraints; persistent floor regressions also ran RED before lock regeneration.
- Root independently resolved releaseRuntimeClasspath on baseline/framework and patched worktrees, byte-identical SHA256 db382ab69009b17cc381437eb0da389fc40ef5a580f6a55a0b6225a6da135994 (24970 bytes). This is fresh resolver output, not acceptance based only on a worker claim.
- Official release notes read by worker across 33.4.1–33.7.2: 33.4.3 removes JSR-305; 33.4.4 moves Checker Framework nullness to JSpecify; modular-JAR/Unsafe work in 33.4.5–33.4.8 and Java9/10 manifest correction in 33.7.1 are exercised by Java21 gate. Android-flavor minSdk changes do not apply to this JRE-only build classpath. Sources: https://github.com/google/guava/releases/tag/v33.4.3 , https://github.com/google/guava/releases/tag/v33.4.4 , https://github.com/google/guava/releases/tag/v33.7.1 , https://github.com/google/guava/releases/tag/v33.7.2 .
- Root adds CODEMAP/CHANGELOG/TRAPS/PROGRESS in the same security PR; no follow-up cleanup PR. Full gate and pinned OSV will be repeated on these final files before the root docs commit. FIFO/L1 remain owner-controlled; no merge or auto-merge authorized.

- Root final validation on unchanged integration tree: full gate exit0 (846 Flutter, 11 JVM/0 failures/errors/skips, 34 repository checks, analyzer0, format70/0 changes), read complete output. Log: /home/liend/.local/share/x-scanner/guava-root-gate.log. Pinned OSV SHA256 matched CI; root scan exit0 / No issues found, same two existing unrelated ignores; log guava-root-osv.log. Native precommit hook will enforce gate again on the final docs.
