# Công việc: XS-09 PR-4b — nối thư viện và migration

- Work ID: 2026-10-18-xs09-pr4b-integration
- Yêu cầu / outcome: chủ repo18Oct trả lời trực tiếp “Duyệt PR-4b; P1 chưa phân phối” sau câu hỏi cụ thể về copy/kiểm từngbản gốc, giữ session.migrated và phục hồi khi bịngắt. Tích hợp thư viện/documentstore với app, hoàn tất XS09AC13 và capacityadapter; không hỏi lại quyền này.
- Trạng thái: Research/design — chưa production/tests; pinW104b cần merge trước executionbase.
- Chủ trì / writer: root giữ spec/approval/PLAN/docs/gates/PR/merge; worker riêng sau contract. Chỉđọc thiết kế trước sourceapproval.
- Mức rủi ro / số PR: L (migration dữ liệu thật), satu outcome/PR cuối của XS09 sauPR1..3/4a đãmerge; goal18Oct và XS09spec/ADR0011.
- Scope / non-goal: reuseLibraryStore/DocumentStore/P1Migration/LibraryScreen/Controller, nối main/sessioncontroller/review, free-spaceAndroidadapter; giữ toàn P1flow và rollback. Không xoá document/quarantine/rollback, không cloud/OCR/paidAPI/release/deploy/auto-merge.
- Spec / goal: docs/specs/2026-10-12-document-library-migration.md (PR4bapproval update bởiroottrướclogic), docs/goals/2026-10-18-upgrade-completion.md.
- Nhánh/base: readonlydesign codex/xs09-pr4b314a296; actualexecution cần freshmain sauW104b.

## Kế hoạch và phân công

1. Read priorXS09PR1..3/4adone, fullspec/currentmain callchain andstorage seams. Rootdesignonly untilspec/PLANcomplete.
2. Delegate worker separateworktree/disjointfiles aftercontract. Root independentlyreruns tests-onlyRED beforelogic; keeperror/recovery/originalguards.
3. Androidcapacity reuse platformStatFs ratherthan dependency/Process/permission; exactAPI/staticruntime verification beforecode. Platformerrors map only sanitizedFileSystemException; don't inventfreebytes0 or assume infinitecapacity.
4. Rootreview/integrate/fullgate/hook/CI/native; exactAPKsyntheticUAT ifenvironment works. Guardedsquash onlyafterconditions; postmerge re-audit/docs/reconciliation.

## Quyết định và bằng chứng

- Explicitownerapproval18Oct includesP1notdistributed, authorizesPR4bdata-layoutswitch andcopy/check/retainrollback. No automaticdowngrade selected; fallback perexisting§18 remainsmanualrename andneverdelete.
- Reuse existinglibrary/migration instead ofnewdatabase/transactionframework · bậc1+2: originalpreservation alreadytested, leastnewlogic.
- Oldroot/workerhistoryDone describes12Octapprovallimit; do notrewritehistoricalclaims. Appendfreshapprovalto currentspec beforelogic, recordactualdate/ownerresponse ratherthan self-approvalfiction.

## Lần thử / blocker

Chưa tests/code/gates. W104bbasepending; UATdevice/KVMavailability separate. No releaseornewdependencyapproval needed forplatformadapter ifstandardAPIadequate.

## Bàn giao / bước tiếp theo

Rootapproveconcretecontract afterreadonlydesign thenworkerREDonfreshbase. Preserveoriginals/session.migrated andall unfinishedrecords. NoDonebeforeactualmerge andACevidence.
