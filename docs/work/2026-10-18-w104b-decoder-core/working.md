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
