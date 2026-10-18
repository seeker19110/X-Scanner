# Goal: hoàn thiện nâng cấp P1 và tích hợp thư viện đã duyệt

| Thuộc tính | Giá trị |
| --- | --- |
| Goal ID | 2026-10-18-upgrade-completion |
| Owner | Chủ repo; root tích hợp/nghiệm thu, worker riêng theo contract |
| State | ACTIVE |
| Default-branch SHA đã reconcile | 209c808ec20b4df9ca75e64c0c8d037e150aae7c; actual59merge/tree verified18Oct |
| Bắt đầu / review | 2026-10-18 |
| Quyền AI | research/spec/branch/PR/review/merge sau gates theo goalP1 + yêu cầu tiếp; không deploy/auto-merge/release |
| Budget | Không paidAPI/dịch vụ mới; chỉ công cụ/dev/CI hiện có, checkpoint trước ngưỡng ngữ cảnh |

## Outcome và Goal DoD

Tiếp từng outcome theo báo cáo16Oct cho scope P1 đang có và XS09PR4b chủ repo duyệt rõ18Oct (“Duyệt PR-4b; P1 chưa phân phối”). Đóng F004/EX1 bằng decoder đủ tuổi, tích hợp thư viện bảo toàn dữ liệu và chạy/ghi đúng bằng chứng UAT; không tự coi toàn roadmap advisory là Approved.

DoD:56 và W104b được review/gate/merge đúnghead; image4.12 pin/hash/instancecaps/regressions đạt và EX1reconciled; XS09PR4b Approved/source/AC13 + migration/lifecycle/rollback tests đạt; CI/native/gates xanh; affected re-audit không còn finding Cao/Trung chưa xử lý; mọi limitation có owner/evidence/điều kiện xem lại. AC9 chỉ đạt từ camera→edit→export→recipientPDF thật, không thay bằng host/widget test. Nếu thiếu thiết bị/quyền môi trường, giữ WAITING có bằng chứng, không báo ProjectComplete.

## Scope / non-goals

Dùng lại P1, XS08/XS09PR1..3/4a đã merge. Không cloud/OCR/depth/newcameraengine/filter/release/signing/automation hoặc tự xoá scan/quarantine/session.migrated. Nghiên cứu/performance đề xuất chưa đủ evidence không thành mandatory feature. PR57harness độc lập ngoài goal.

## Milestones và slices

| ID | Outcome/AC | Dependency | Spec | PR | State | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | Fresh review/gate/merge56 grayalpha | 55merged | specXS07b17Oct | 56 | DONE | work2026-10-17-xs07b-gray-alpha-render |
| S2 | W104b decoder/F004/EX1 | S1actualmerge | specW104b18Oct | 58 | DONE | work2026-10-18-w104b-decoder-upgrade |
| S3 | Library/app/migration/capacityadapter, XS09AC13 | S2merged; explicit18Octownerapproval | specXS09 ownerApproved18Oct; capacityleafApproved before source | pending | IMPLEMENT | work2026-10-18-xs09-pr4b-integration |
| S4 | Synthetic OS UAT/AC9 evidence | usableemulator/device; exactartifact | P1AC9/D4 andandroid-uat | report nextPR | ACCEPTED/report merge pending | work2026-10-18-p1-android-uat; ac9.json |
| S5 | Re-audit/reconcile currentmain/docs/exceptions/records | S1..3; actualS4outcome | completionplaybook/P1 | pending | BACKLOG | actualmergeproofs required |

## Risk register

| Risk | Trigger | Mitigation/rollback | Owner | State |
| --- | --- | --- | --- | --- |
| Upstreamdecoder regression | image broad4.11/4.12 changes | verifyfullpackageddiff/hash, stagedRED, core/realCLI/gates; revertPR and reopenEX1 ifneeded | root | Active |
| Data migration | appfirstopen switcheslayout | copy/check/journal/relaunch, diskspace adapter, retainrollback; P1notdistributed confirmed18Oct | root | Active |
| Emulator infeasible | KVM EACCES, softwarebootlimited | isolatedSDK/AVD, boundedattempt; no OS privilege changes or fakeAC9 | root/operator | Active |
| Concurrent external PR/main change | PR57/otheragent | freshfetch andstrictcheck before merge; no overriding others'files | root | Active |

## Current truth

- Current:56/58 merged, W104b/F004 fixed on c50670a and EX1 reconciled; PR4b authorized, capacityleaf verification active, pending-picker designApproved before source; AC9 awaits actual Windows accelerated UAT.
- Decision: technical/specselfapprovalunder§3d; actualdataactivationPR4bownerconsent18Oct recorded, noquestionrepeat.
- Next slice: merge capacity only after fullgate/hook/finalCI/native proof, then pending-picker preservation and appintegration from freshmain; finish actual UAT on verified artifacts.

## Iteration log

### Iteration1 — 2026-10-18
Ownercontinuesuntilcomplete; current56runtime reviewedindependently findings[], rootfreshgate628/628 beforedoccommit/hook, newCIpending. W104bresearch officialAPI/hash/age verified; scopedplanApprovedbeforelogic. PR4bexplicitownerreply received; implementationstillpending. No completionclaimsfromhistoricalpasses.

## Final audit

NOT COMPLETE. Executionandactualmain evidence pending; no device/iOS/OCR/release acceptance.

18Octiteration:56actualmerge561a5cf at01:40:12Z, CI39086812105/root628+628/AOT12/nativeproof. W104bstagedREDA/B→GREEN240; EX1stillopenuntilmerged. API36softwarebootmemoryguardstopped safely, nodeviceclaim; isolatedAPI24preparedforfuturewindow. OwnerPR4bapprovalretained; no technicaldecisionreconfirmation.


### Iteration2 — actual58merge and PR4b foundation

S2done: PR58/c50670a, exactmain/tree/headCI proof; EX1 reconciled. S3 capacityleaf has actual Dart1P/18F and JVM2P/9F RED, sameassertion implementation then targeted19Dart/11JVM, rootfreshmain/fullgate/PRpending. Additional pending-picker persistence contract is being designed before app switch; no arbitrary document receives global lostresult. Root reuses existing controllers/stores/IDs and no runtime dependency. S4 remainsWAITING: both Linuxsoftware boots hit guard, owner now explicitly authorizes self-install accelerated Android environment; Windowssetup separate. Goal remainsACTIVE, notProjectComplete.


### Iteration3 — capacity actualmerge and AC9 accepted

PR59/209c808 merged11:06UTC, finalCI39121270944/rootgate+hook658Flutter+11freshJVM/nativeexacthead/tree; capacityleaf Done. Pendingoriginal7methods + static sizeRejectedclassification contract Approved before behavior, source/targeted review underway on freshmain209c808. AC9 actualWindowsWHPX/API36+exactCI58APK camera3→edit/reorder→PDF→Librera all3pages, originals/cancel/restart verified; root accepts under§3d, reportmergepending. App/library/XS09AC13 stillACTIVE, nativecapacity not yet called by P1APK. Continue leaf→app integration→exactAPK migrationUAT→finalaudit; no release.
