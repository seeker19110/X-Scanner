# Công việc: XS09 pending picker preservation

- Work ID: 2026-10-18-xs09-picker-preservation
- Outcome: bound camera/gallery/retake recovery to the correct document before library activation; preserve cached/pending originals across normal retry/relaunch.
- Trạng thái: Approved18Oct before source; tests-only/stub phase next.
- Risk: M leaf within owner-approved L PR4b; one preservation PR before app integration if design warrants split.
- Owner: root owns final spec/PLAN/review/gates/PR/merge; worker own designrecord only on separatetree.
- Parent: docs/specs/2026-10-12-document-library-migration.md, explicit18Octowner “Duyệt PR-4b; P1 chưa phân phối”.
- Base: c50670af18b1f11af38d15051b36264e1a051cb3 actualW104merge; branchcodex/xs09-picker-preservation.

## Kế hoạch và phân công
Readactualcallchain/plugin and propose the smallest concrete persistence API/tests for app integration. No source/compiler/gate before approved contract. Root independently verifies actualRED before logic. Worker only docs/work/2026-10-18-xs09-picker-design/working.md.

## Quyết định và bằng chứng
Installed image_picker_android0.8.13+25 retrieveLostImage clears cache before returning; setPendingOptionsAndResult clears cache before a new picker. Per-document globalretrieveLost would attach A's photo to B. Reuse current queues/ID validators/atomicwrite/cache-delete guards; no plugin fork/database/generic task framework.

## Lần thử / blocker
No implementation/tests/gate. Parentcapacityleaf implementing in separatetree. Need settle journal API, legacyP1 lostimage target and residual native→Dart destructive-read handoff window before source.

## Bàn giao
Worker reviews proposedminimaljournal contracts, returns finite test/API design; root chooses and approves before source. Don't claim exactly-once at every instruction or delete unknown/rollback originals.


## Root contract approval — 2026-10-18 before source

Root reviewed full138line design frozen7a670b6 and actualplugin/store behavior. Approved dedicated spec docs/specs/2026-10-18-xs09-picker-preservation.md under explicitownerPR4b/§3d. Chọn6methods/immutableowner+createOwnerbootstrap flag; freshsame-stackemptyprobe maycancel, loadedmarker+null/erroralwayspreserve. Giữ PageSource/controller changes for integration atomically; leaf khôngphá P1currentlyactive. Purestorage→core, callermaxBytes, noAPI/dependencynew. Unknown/orphanambiguityfailclosed; no blanketcleanup. Tests-onlycompilingstub actualRED thenrootGREENLIGHT; finalintegration dependscapacityactualmerge.


### Root correctness refinement before behavior/RED

Root found a reachable P1AC7 regression in the proposed six-method contract: an invalid image would remain active and block every future camera/gallery operation indefinitely. Under §3d choose one specific retained-rejection method, not a force-discard or broad XS10UI. Approved FR8/retainRejected before source behavior: atomic rename of known intent+available staged/cache original to deterministic sibling, no deletion/overwrite; next capture allowed, originals retained. Save/I/O/unknown ownership still active forretry; unaccepted oversized unstaged cache has explicit OSretentionceiling. Tests/stub extend before actualRED; immutable designrecord remains historicalsixmethod proposal.


## Root actual RED verification — 2026-10-18

- Read all stub/test code and synthetic-only IOOverrides harness before execution. Dispatcher format-file reported no formatter; root ran pinned `dart format` on both files (test formatting only, no assertion changes). `flutter pub get --enforce-lockfile` succeeded without lock changes.
- `flutter test --no-pub --reporter expanded test/storage/pending_pick_store_test.dart` compiled and ran: **86 cases, 2 PASS / 84 FAIL**, exit1. Of these, **62 assertion failures** exercise missing persistence/validation/retention behavior; 14 null results, 7 missing paths and one bounded source-read timeout depend on the deliberately absent stub persistence. These 22 are not independent assertion RED proofs and no compilation/setup error is counted as RED.
- Canonical stub SHA256 `080feabd1613c39ae3aaacdaa082787f2560fb3add97487d75c31b302d54b3a7`; formatted test `db9c42c6003873cdd44b7e14162263cdee269088c33f6d82dcae180ea15641be`; raw log `7c72293a68b1a78933b3722fe78c65b0e5da405cfdd901ec1c4a6f3f54952eef`. Outside-repo evidence: `/home/liend/.local/share/x-scanner/downloads/picker-root-red.log`, `picker-root-red-proof.json`, `picker-root-red-status.json`.
- Root GREENLIGHT sent after reading/classifying actual output. Worker owns the two leaf source/test files plus its core record; existing assertions remain fixed, any harness-only compatibility fix requires justification. Root retains spec/global docs/gates/PR/merge. No app activation.


### Root integration-boundary refinement — 2026-10-18 before classification behavior

Independent preflight found that a single undifferentiated sanitized exception cannot tell rejected size from I/O; archiving every stage error would violate active retry. Choose one `PendingPickFailure.sizeRejected` boolean, default false/static message, true only for empty/over-cap source or actual copy total. No broad error hierarchy/string parsing. Root approves this boundary before worker tests/behavior; add default-false scaffolding then actual RED classification assertions, retain original assertions. Save/import/I/O remain active. Reimport after save failure must first load/reconcile the durable document and stable page ID; pending staging remains outside orphan cleanup.


## Fresh capacity main / classification evidence — 2026-10-18

PR59 actualmerge209c808 verified clean/tree by root, then picker branch ff-only c506→209c808 while worker frozen. All13 uncommitted files preserved in stashf2bce45d799ab5ce25d36425cf4ad7ecb718db02; twelve source/test/spec/evidence/records restored byte-identically. One parent-spec approval wording conflict resolved explicitly to currentmain approval/runtime-test-dependency wording plus pending leaf link; no abort/reset-hard. Stash retained until resulting work is safely committed; original four stashes untouched.

Two worker-added finite boundary regressions (journal UTF8 escaped-byte cap and rejected sibling for trailing slash) ran actualRED before minimal fixes. Classification refinement: worker actual8cases3PASS/5assertionFAIL before two typed throws, then96/96GREEN. Root requested freeze after tool had already completed, so defaultfalse reconstruction is sensitivity reproduction after development, not a fabricated earlier RED; historicalGREEN is retained. Root first reproduction filter matched zero tests (exit79), notRED; corrected filter must run before acceptance. Worker source/classification logs/hashes in owncore record.


## Root integrated verification / review freeze — 2026-10-18

On actualmain209c808 root independently ran all96leaf tests:96/96PASS, full expandedoutputread (picker-root-green-209c808.log). Frozen source84997dc8065084bb5b3a0c90b7b25b322f3576ec1ebb48d665d0ded859d1c912/tests34c111806ea21d02e9953cc5f3be05bcabea039518a85fdb363e116f36884254. Root read complete implementation, original86assertions/harness and addedjournal/trailing/classification cases; worker actualedge/classificationREDlogs read, classificationrootreproduction8=3P/5assertionF verified thenexact2throwsrestored. OriginalbehaviorREDbeforeleaflogic retained; nozero-test/compilefailurecalledRED.

Independent reviewer read allsource/tests96definitions/spec/core/rootrecords on separatefrozenreviewtree, hashesbefore/aftermatch, findings=[]. No appactivation. Review also inspected actualSpecCompiler parser/gates: currentCI doesnotruncompiler, and English Attribute|Value silentlyskipsmetadataApprovedchecks. Normalize our three18Octcurrent spec headers to actual Thuộc tính|Giá trị without changing approvals; run manualtrace/contracts as supplementarychecks, notclaim anewCIcontrol. Integration contract/header corrected in separatetree before source. No framework code/suppression/exemption added.

Root fullgate/normalhook/CI/native/exactmerge remain required. Source/test/docs freeze before gate; source/evidence are synthetic only. Capacityactualmerge/Dones and AC9report in samePR maintain currenttruth; currentP1APK still schema1, XS09AC13 remainsopen.


### First integrated fullgate — 2026-10-18

Root dispatcher gate4/4PASS on209c808,754/754Flutter and11freshJVM (XML13:16:16.971UTC inside13:13:54–13:16:18gatewindow;0failure/error/skipped), analyze0,format62files0changes, debugAPK/freshreleasemanifest/repositoryguards. Config2d67f3404dd0329821232ba60af807ced99b190a; snapshotad027ec764cd5f9a39edd4003f53c483fcdf4a48; evidence/log picker-first-gate outside. All checks ran; no CI/device claim from localgate. Supplementary unchangedSpecCompiler C1–C4 generated/in-memory tests ran12/12PASS/0skip for three normalizedspecs, and all ACtraces MAPPED. Beforecommit finalstagedsnapshot will be gated and normalhook will rerun; results remain outsideuntilverified, notinvented here.
