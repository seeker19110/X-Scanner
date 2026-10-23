# Công việc: W104b — bounded decoder core T1

- Work ID: 2026-10-18-w104b-decoder-core
- Yêu cầu / outcome: Approvedspec/PLAN W104b18Oct, stagedRED trước dependency/core changes, giữ caps/originals và regressionexisting.
- Trạng thái: Planned tests-only; chưa production/pubspec/lock/test execution.
- Chủ trì / writer: root tiếp quản unit sau worker tự động bị safetyfilter từ chối; worker chỉ tạo ownrecordtemplate01:29Z, chưa tạo/sửa appfiles. Không nhận output lượt hỏng làm evidence.
- Rủi ro / PR: Msecuritymaintenance, cùng mộtPRW104b, rootrecord tổng là docs/work/2026-10-18-w104b-decoder-upgrade/working.md.
- Scope: tests hữu hạn cục bộ và callsite/packageupgrade trong Approvedspec; không công cụ tấn công, OOM, dữ liệu thật, outboundupload hoặc skipqualitygate.
- Base: codex/w104b-decoder314a296/image4.10.1; production/pin đợi actual56merge, oldsource/lock phải giữ nguyên khiREDA.

## Kế hoạch và phân công

Root viết/đọc/rerun tests-onlyREDA, lưufulloutput/hash trướcpin. PhaseB newlibraryAPI tests chạyRED trướccorewire. Root hoặc worker bảo trì giới hạn chỉ triển khai sauGREENLIGHT; preserveexistingtestexpectations. Gate/CI/review độc lập vẫn đầyđủ, không bypasssafeguards.

## Quyết định và bằng chứng

Worker execution bịautomaticcontentfilter từ chối trước bất kỳsource/test/packageedit; root không retry payload vào worker. Unit chỉ là localdefensiveregression trên hữu hạn ảnh tổng hợp, không test mục tiêubênngoài. Staticpackageaudit riêng đã xong; không dùng staticreview làmruntimePASS.

## Lần thử / blocker

ChưaRED. CPU/compiler window đợi56hook xong; metadata/sourceprep không chạycompiler song song. Nếu ca testkhôngtáihiện phải ghi đúngactualfailure, không bịa hoặc nớiACđểxanh.

## Bàn giao / bước tiếp theo

Root tạo finite tests theoApprovedspec, chạy baseline vàđọcactualassertions trướcdependency/core. ChưaDone/merge; actualexecutiontrênPR/working tổng.


## Actual merge reconciliation — 2026-10-18

PR [#58](https://github.com/seeker19110/X-Scanner/pull/58) squash merged `c50670af18b1f11af38d15051b36264e1a051cb3` at02:01:14Z after exact reviewed head `b227825a3145a2a73e2198320d58d4a08b5f327b`, base561a5cf. Root main ff-only/clean and merge tree1368c79fa742dd4432269d31526292e4db349cb0 equals reviewedhead. Final fresh review23files findings=[], source/test/lock hashes unchanged.

Root dispatcher gate + normal hook each4/4 and639/639 Flutter tests, analyze0/format0, realAPKdebug and freshmerged release manifest check pass; gate contexts same precommit snapshot a6fe9d98066359bd41d539492641dd135c60a24f/config0d929cd106ce22d7d05a5d2a5e80e89a70866ae3. Postcommit evidence-check correctly reports old HEAD/snapshot stale; it is not represented as a postcommit PASS. Final-head [CI39088067553](https://github.com/seeker19110/X-Scanner/actions/runs/39088067553) SUCCESS runs639 unique successful Flutter tests/allgate stages. Fresh cleanhead hostAOT12grayalpha cases and compiledCLI generate64×48×3→thumbnail→render-pdf PASS, original3SHA256s unchanged; not device/performance acceptance.

Fresh nativeproof02:00:59Z: ruleset25250032 exact5rules/app15368/strict/protected/no bypass/ownernever;0 unresolvedthreads; exactopen/clean head/base; auto-mergeoff. Dependencycompare HTTP200 only image4.10.1→4.12.0, MIT/no vulnerabilities, empty snapshot warning. Artifact12120799566 builda810e3fbf8f30acc2db977683aabf5fe79b318d5 parents[561a5cf,b227825], same tree; metadata/ancestry only, no APKinstall. OfficialPub/Maven/OSV/package audit retained outside repo with rawlogs under /home/liend/.local/share/x-scanner.

W104b AC1..6 satisfied for this maintenance outcome, F004 fixed on actualmain; EX1 closes in this reconciliation. Lazyinflater read-ahead/cap is not RAMquota, and all21grayalpha regressions remain. AC9/UAT and XS09 integration remain separate and incomplete. Root nghiệm thu theo existingowner §3d/merge delegation18Oct after actualproof; this record may now be Done.
