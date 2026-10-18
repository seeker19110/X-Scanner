# Công việc: W-104b — vá decoder ảnh và đóng EX-1

- Work ID: 2026-10-18-w104b-decoder-upgrade
- Yêu cầu / outcome: “tiếp cho đến khi hoàn thiện”; nối ưu tiên1 báo cáo16Oct, W104b/F004 đã có trong COMPLETION-PLAN. Đủ tuổi mới nâng image4.10.1→4.12.0, nối instancecaps và bằng chứng EXIF/PNG trước đóng EX1.
- Trạng thái: Research — chưa sửa production/tests/dependency; PR56 đang review/gate trước merge/reconcile làm base.
- Chủ trì / writer: root giữ research approval/spec/PLAN/maps/reconciliation/fullgate/PR/merge; worker nghiên cứu chỉ ghi ownrecord, implementation chờ contract/RED/rootGREENLIGHT.
- Mức rủi ro / số PR: M thận trọng vì decoder ảnh không tin cậy, một outcome/PR sau56. Yêu cầu nhiều PR dùng subagents theo§3c, worktree/file writer rời nhau.
- Scope / non-goal: pin decoder, pub-generated lock, per-instancecaps trước header parsing, regressions và sửa callsite bắt buộc do upstream. Không scaledJPEG, SDK/PDF/UI/migration/filters/OCR/release/auto-merge/cloud/real document hoặc quota RAM/device claims.
- Spec / goal / issue: docs/ops/COMPLETION-PLAN.md W104b, docs/goals/2026-10-11-p1-scan-export.md (quyền merge khi CI xanh); spec nhỏ đang soạn trước logic.
- Nhánh / base: research checkout codex/w104b-decoder tại314a296; execution base phải là actual56merge trên main, sẽ đo lại. Root checkout56 giữ snapshot gate riêng.

## Kế hoạch và phân công

1. Root review56 và dispatcher/hook/CI/native exacthead; guarded squash rồi mainff-only/tree match và chốt ownrecords56 thật.
2. w104b_research trên /home/liend/.local/share/x-scanner/w104b-decoder chỉ ownrecord docs/work/2026-10-18-w104b-decoder-research/working.md, officialPub/version/archive/hash/license/SDK và packagedlibdiff, API/caps/EXIF/PNG. Chưa compiler/test/production.
3. review56 tiếp vai chỉ đọc design/PNG/lazyinflate ở checkout riêng, không writer/compiler. Root tự kiểm chứng dữ liệu, duyệt spec/PLAN trước worker source.
4. Worker tests-only baseline4.10.1 actualRED, pause để root đọc/rerun; chỉ sauGREENLIGHT mới pin4.12.0/pubget và core cần thiết. Targeted/fullgate/hook/CI/head/native/smoke trước merge.
5. Re-audit impactedsecurity/dependency/core groups, reconcile EX1 chỉ sau bằng chứng và actualmerge. AC9 riêng; không nhận P1Complete từ unit/host gates.

## Quyết định và bằng chứng

- Chọn nối W104b đã Approved thay vì mở roadmap mới · loại tự kích hoạt XS09PR4b/OCR/release · bậc1+2: sửa đầu vào không tin cậy trong scope đã giao và vẫn giữ quyền dữ liệu riêng.
- Quyền merge: goalP1 đã ghi “research / branch / PR / merge khi CI xanh”; yêu cầu18Oct nối chuỗi review/repair/gate/merge đang có. Không suy deploy/auto-merge hoặc bật migration thật.
- Chọn instancecap trước startDecode, giữ bytecap/headercap/outputcap/timebudget/staticWebP gate · loại sửa global decoderlimit, bỏ timeout hoặc tăng quota · bậc1+2; API và test phải xác minh archive thật trước source.
- Fresh UTCclock18Oct01:18 > published11Oct00:28 +7days; metadata/archive còn được research kiểm. Không dùng dòng “Published6daysago” của trang cache làm tuổi chính xác.
- Existing lock archive4.5.1 thoả image4.12 constraint^4.5.0; giữ mọi dependency khác nếu solver cho phép, không ép upgrade toàn graph. Root sẽ tự so wholelock và archive SHA; chưa có kết quả solver.
- Bản image mới sửa setter/copyRotate hai kênh: chỉ bỏ workaround56 nếu regression hiện có vẫn bảo vệ chính xác PNG/JPEG/crop/cap/ownership; không chuyểnRGBA hoặc đổi JPEGpolicy.

## Lần thử / blocker

- Chưa RED/production hoặc gateW104b. Hai ảnh synthetic phải an toàn, không OOM và không đưa thời gian/RSS tuỳ ý thành cổng chất lượng; không bịa yêu cầu reject trailingPNG nếu upstream chủ ý đọc lazy.
- AC9: adb18Oct không có thiết bị. Agent uat_readiness chuẩn bị SDK/AVD riêng ngoài repo, KVM EACCES; softwareboot chỉ thử có thời hạn và không chạy đồng thời compiler/gate. Chưa UAT PASS.
- PR57 là harness do phiên khác tạo; không tích hợp trong outcome này.

## Bàn giao / bước tiếp theo

Đợi review56/rootgate, chốt source nghiên cứu và phương án PNG regression có quan sát thật; root duyệt spec/PLAN rồi giao implementation sau actual56merge. Ownrecords/source hiện còn chưa commit ở checkout riêng, không discard.

## Nghiệm thu cuối

Chưa Done. Chỉ rename sau actualPRmerge và defaultbranch readback; EX1/AC9/PR4b không tự đóng theo lời khai worker.

- check-plan ban đầu thiếu cú pháp nhómPR chuẩn, exit1 trước dispatch; root sửa đúng **PR-1**/“gồm việcT1”, check-plan lạiPASS1task. Không logic/test được giao khi brief đỏ.
- Research staticunit froze3491b1211e91d6d8e43f161b18baa20a99c601f34126825582362e95014d97d5;151changedlibfiles inventoried/reviewed,396/396 libblobs tagverified; root đọc primaryEXIF/PNG/decoder/WebP/limits và metadata. Một lượt nghiên cứu trước bị automatic safetyerror; không nhận finalaudit từ lượt hỏng. Unit thu hẹp chỉ staticmaintenance, hoàn tất không compiler/payload/sourcechange.
- Root Approved smallspec/PLAN18Oct beforetests/source. Chọn PNG finiteunused-tail consumptioncanary thay decompressionOOM/RSS/timeproof; có primarysourcechunk/lazyread/close support, vẫn phải actualRED/GREEN. StagedREDB saupin dùng mớiAPIdefaultlimit và trướccorewiring, không tính compilefailure làRED.
- Chọn cho worker viết tests-onlyREDA trên reviewed314a296/oldlock trong lúc56pending (decoder sections unchanged; noappdependency on56), nhưng không chạy compiler cùngroothook và không pin/source trướcactualmerge/rootGREENLIGHT · bậc1+3: kiểmchứngđộc lập mà giữsourcefreeze vàresourcebudget.
- Chủ repo18Oct xác nhận “Duyệt PR-4b; P1 chưa phân phối”; goalupgrade-completion ghi scope/phụthuộc, ownworkPR4b riêng; không hỏi lại quyền và không trộn migration vào decoderPR.

## Actual REDA — 18Oct before dependency/core changes

- Root tiếp quản T1 sau worker safetyfilter dừng trước source/testedit. Starter ownrecord giữ lịch sử; production/pubspec/lock diff rỗng tại314a296 khi chạy actualRED. Firstsetupattempt dùng constZLibEncoder không hợp lệ, compileerrors3; sửa testhelperconstructor, KHÔNG tính lần compilehỏng là RED.
- Root tests5ca với fixturehữu hạn (~64KiBmax), không OOM/RSStimingthreshold. Actualrun w104b-root-red-a.log và independentconfirm w104b-root-red-a-confirm.log đều exit1,2PASS/3FAIL: cycleEXIF ImageDecodeFailure sauboundedkill; PNGunusedtail ImageDecodeFailure do eagerinflate; imageSizeOf8000×8000 trả64MP thaynull. Completezlibfiniteunuseddata và truncatedrowerrorguards PASS. Childđãthoát, không decoderjobtreo sau test.
- Chỉ đổi tên ca “validsurplusPNG” để không nhận PNGconformance khi chỉzlibstreamcomplete; expected/raster/payload giữ nguyên; cuối formatcơ học mộtfile. Actualrenamed RED w104b-root-red-a-final.log vẫn2PASS/3FAIL. CanonicaltestSHA986596fb45887345147855373e178f9e8a6d48abfe8a4581c19e25f0925820ad;5expectations giữqua pin/core. Không dùng code production làm expectedtransform.
- Gate56/hook18Oct4/4 each628/628 và12cleanheadAOTPASS; docsheadcc5bb44 đãpush, CI39086812105pending. W104bproduction/pinvẫnđợiactual56merge, không giảCIpendingPASS.
- CPUwindowhiện nhườngisolatedsoftwareemulator480s; rootkhôngcompiler/Flutter/test trongwindow. Root tiếp tụcsource/docs/read-onlyAPI.

- Actual56merged561a5cf05f12ccba03d536f5b522ad0e046f6255 guardedheadcc5bb44. Rootmainff-only/treeequalreviewed/clean; executioncheckout switchedto codex/w104b-decoder-core@561a5cf withuntrackedtests/docs preserved. Production/pubspec/lockstillunchanged beforepin. RootGREENLIGHT dependencyphase afteractual REDA/metadata/integrity/sourceaudit; corewiringstillwaitsseparateREDB.

- Afterpin generatedlock onlyimage version/hash changes (90total/86hosted); archive4.5.1 unchanged and API/archivehashmatches target. FiveREDAcases on4.12/beforecore =4PASS/1FAIL (headernullable); EXIFcycle and PNGboundedconsumption GREEN fromdependencyonly.
- StagedREDB uses newlibraryAPI (unavailableoldversion, no compilefailurecounted):11tests=6PASS/5FAIL: originaloversizedheader + explicitcaller6px vs librarydefault1 JPEG/PNG/WebP + imageSizeOfdefaultcapthrow. Rootconfirmcombinedoldpage_render78+new11=89cases=84PASS/5FAIL; all21XS07bnewcasesGREENwithpatchedlibbeforehelperremoval. Corehash4d7unchangeduntilthisRED/rootGREENLIGHT. TestSHA db202605f4541f54030ca9fc6572900bce4051bab6b5da63d8fe1fbf78c95c54 unchangedthroughGREEN.
- RootGREENLIGHT corewire afteractualREDB/rootconfirm. Sharedstartvalidatesnonpositive/header/productcap; eachinstancegetsmaxbeforeparse, decodedresultcapvalidated, imageSizeOfcatchonlyImageException→null. Removedupstreamfixedtwochannelworkaround, reusesetPixel/copyRotate; noRGBApromotion/JPEGpolicychange. Firstapplypatchtypohelpercontextfailedatomicallybeforeedit, correctedcontextthenapplied; no testfailurehidden.
- Targeted imaging/export/controller/tool GREEN240/240, format2/0. Fullgates/analyze/CI/AOTstillpending. Sourcecommentsclarifyheadercap; freeze4runtimefiles inoutsidew104b-source-freeze.json forfreshread-onlyreview. No existingtestexpectedvaluechanged; rawREDA/B retainedoutside.

- Fresh independent implementation review found no actionable issue in the four frozen runtime files; all SHA256 values matched before/after, and existing page_render_test stayed88a3c3. Reviewer read APIs/callers/cache/guard semantics only, no compiler or fixture generation. Root independently reviewed diff/source/tests/lock and remaining trust boundaries.
- Root analyze0issues; doctor READY4; spec trace6/6 MAPPED after fixing evidence-table backtick syntax (mapping is not acceptance). Live OSV query on all86 hosted packages returned0advisory, saved outside w104b-osv.json; this is not proof all decoder bugs are absent. New explicitlimit tests reset the global default in finally.
- Docs/maps/TRAPS/changelog/PROGRESS and actual56 root/worker Done reconciliation are in the same pendingPR. EX1 and F004 remain open until final checks and actual main merge; UAT/PR4b are separate. Runtime files frozen for fullgate; no tracked edits during gate/hook. Execution evidence, finalhead/CI and actualmerge readback will be recorded on the PR to avoid self-referential commits.
