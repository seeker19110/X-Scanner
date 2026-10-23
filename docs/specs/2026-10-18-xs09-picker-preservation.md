# XS09 — pending picker original and document ownership

| Thuộc tính | Giá trị |
| --- | --- |
| Work ID | 2026-10-18-xs09-picker-preservation |
| State | **Approved for implementation** |
| Approver/date | Root18Oct under explicit owner PR4b approval/P1notdistributed and §3d; BEFORE source |
| Risk | M persistence leaf in L library integration; no app activation in this PR |

## 1. Evidence and research

Design `docs/work/2026-10-18-xs09-picker-design/done.md`, frozen7a670b6f712c791604ac71c23d51e38cebb866bd7267592006f91a8c30a8857b, reviewed by root before approval. Actual installed image_picker_android0.8.13+25 read-clears lost-result preferences BEFORE Dart return and clears again on new launch. Current SessionController.restore globally retrieves a lost photo; multi-document B would consume A's result. A stable pageId is not reserved until after decode, so replay after manifest commit can duplicate pages. DocumentStore.load cleans orphan originals, so preserve pending outside documents.

| Already deeper | Present but shallower | Missing and real need |
| --- | --- | --- |
| Core validators, atomic manifest, queue, .part/flush/rename, source retained before save | P1 caches only, no durable owner or operation id | Minimal pending journal/copy before library activation prevents cross-document attachment and loss after retry |

Reuse stdlib/core validators/IOOverrides; no plugin fork, database/dependency, generic task framework or XS10 deletion UI. [Official picker documentation](https://pub.dev/packages/image_picker) describes startup lost-data retrieval and cache retention; installed source supplies actual behavior. Root chooses one immutable owner + createOwner bootstrap flag over nullableowner/assign API.

## 7. Leaf requirements and exact API

A `PendingPick` immutable value, private constructor, fields docId/pageId/replacePageId/createOwner/cacheRelativePath/extension, and `PendingPickStore(dir,cacheDir,maxBytes)` with seven queued methods:

```dart
Future<PendingPick?> load();
Future<PendingPick> begin({required String docId, required String pageId, String? replacePageId, bool createOwner = false});
Future<PendingPick> remember(PendingPick pick, String resultPath);
Future<File> stage(PendingPick pick);
Future<void> cancel(PendingPick pick);
Future<void> complete(PendingPick pick);
Future<void> retainRejected(PendingPick pick);
```

- FR-1 Identity: one queue per app-owned instance. begin validates 32lowerhex IDs via existing helpers, new!=replace, createOwner cannotretake; maxBytes positive. Refuse existing intent/unknown orphan state, never overwrite. Every mutation rereads current durable journal and compares immutable tuple(docId,pageId,replacePageId,createOwner); stale handles cannot affect a newer operation. Same remembered canonicalpath idempotent; different source rejected.
- FR-2 Journal: version1 `intent.json`, atomic `.tmp`+flush+rename. Read at most8193bytes, accept<=8192; strict field types/IDs/bool/version, paired cacheRelativePath/extension, pathlength<=2048. Relative path no absolute/empty segment/dot/dotdot/backslash/NUL; extension uses P1 lowercasedvalidator/fallbackjpg. Root/files regular directory/file without symlink. Invalid/future/UTF8/oversize/orphan unknown state untouched + sanitized closed exception, never silently repaired by deletion. load null only when truly no state. A valid journal may coexist with its known original/partial; unknown temp without unambiguous durable metadata fails closed.
- FR-3 Source: remember canonicalizes actual cache root/result, verifies strictly inside canonicalcache (not root/siblingprefix/outside/link escape), regular file before source reads. Persist canonical cache-relative path + extension BEFORE stage/decode, never absolute untrusted path in journal. On retry validate containment/type again. Public errors use a closed sanitized exception/static message, no path/content/marker/OS details.
- FR-4 Copy: caller supplies maxBytes (integration64MiB; leaf imports no imaging). Bounded streaming/random-access chunks,0<size<=cap before read and actualtotal<=cap during read; never whole-file readAsBytes/unboundedcopy. Target only `original.{extension}.part`, flush, rename `original.{extension}`; no symlink writes, no overwrites. Source bytes unchanged. Known partial can only be restaged after valid cached source still exists, keep if sole remaining copy. Existing complete stagedoriginal reused after type/cap/identity checks, including when OS cache no longer exists; never native-retrieve in leaf. Queue/cleanup must retain recoverable state on I/O failure. `PendingPickFailure` has a closed `sizeRejected` boolean (default false): true only for an empty or over-cap original/actual copied byte total, false for I/O, identity, journal/path/unknown state. The public message stays static. Integration may retain a size rejection and allow another capture, but must keep ordinary storage failures active for Retry; never parse exception strings or treat every stage failure as an invalid image.
- FR-5 cancel: removes empty intent only; no rememberedsource/staged/partial, exact immutabletoken. App may invoke only for fresh same-stack picker/probe null with no error. Loaded pending+recovernull/error always retained and globalnewpickerblocked. Leaf cannot prove freshcall; caller protocol gets integration tests. No force/discard API.
- FR-6 complete: caller acknowledgement ONLY after durable manifest references correct stablepageId/path and replay byte-check when staged exists. Leaf does not depend on DocumentStore. Known staging/part cleanup before journal last; no document/rollback/cache/unknownfile deletion. Cleanup failure preserves context for retry. App discards rawcache only after durablemanifest while ownedpendingcopy remains.
- FR-7 No main.dart/PageSource/controller/UI activation in leaf. Stage methods do not launch/retrieve/discard picker. Preserve current P1 error behavior until app integration changes source exceptions atomically with controllercatch. Minimal IOOverrides fault harness in tests, no public production fault hooks.

- FR-8 Rejected input must not permanently block P1AC7: add `retainRejected(pick)`, queued and exact immutabletoken. Only a known remembered result with a complete staged original OR still-valid cached source may be retained; never an empty/ambiguous intent. Atomically rename the whole active pending directory to the deterministic sibling `{dir}.rejected-{pageId}` after checking target is absent/no symlink; never overwrite/delete archived data. New active load then returns null and new picker may begin. This preserves all known journal/staged/partial bytes and cached source unchanged; leaf does not discard cache. Complete stagedcopy survives OS cache eviction; an unaccepted oversized source that was never staged retains only cache/path, same cache-eviction ceiling as P1 input rejection. Missing bothsource/staged stays failclosed. Unknown files/state or failure before rename leaves activecontext; afterrename replay detects no activeintent and keeps archive. No user-facing archive/recovery/deletion UI in this leaf. `DEBT: rejected picker inputs are retained outside the active intent without recovery UI | trần: private retained data until XS10/manualreview; unstaged oversized source still relies on OS cache | xem lại khi: XS10 defines retention/recovery or before distributed release.`

## 9. Acceptance

- AC-1: Compiling stub yields actualbehavior RED for identity/roundtrip/reservation/CAS/invalidjournal; same assertions GREEN. Bounded read handles malformed UTF8/oversize/future fields and links without modifying private testtrees.
- AC-2: Synthetic small cache root + gallerysubdir remembered/copy byte-exact, source unchanged. Reject outside/root/sibling/pathinjection/symlink/output link. Constructor/cap4bytes exact accepted/5bytes/empty/growingfile refused without over-cap writes.
- AC-3: Rejectedresult retention keeps exact bytes/owner/token in a new sibling, never overwrites collision, wrongtoken/empty/unknown state rejected; valid fresh begin succeeds after retention, failedrename preserves activecontext. Freshinstances replay stableintent/staged/partial, no orphan auto-deletion. IOOverrides finitefaults before/after durable journal/copy/rename/cleanup retain rawsource orownedpending until callercommit; stale/cancel/complete constraints protect newintent andknownbytes. Tests distinguish setup/compile error from RED.
- AC-4: Root verifies actualRED before logic, source/hash review, targeted+fullgate/normalhook/finalCI/native and exactmerge proof; samePRmaps/spec/records. No UAT or native exactly-once claim.

## 11. Architecture và code touchpoints

- `apps/mobile/lib/storage/pending_pick_store.dart` — newpureDartstorageleaf, core validators only.
- `apps/mobile/test/storage/pending_pick_store_test.dart` — bounded filesystem+fault tests.
- `docs/work/2026-10-18-xs09-picker-preservation/done.md` — rootapproval/decision/proof.

New paths must exist before contract acceptance; no fakeexemptions. One leaf PR after capacitymainreconcile, then integration.

## 12. Required integration protocol (next PR, not accepted from leaf tests)

One PageSource/PendingPickStore/LibraryStore/DecodeGate app-lifetime. Reserve before camera/gallery/retake; remember+stage even if route disposed while OSresult returns, stop UI/save afterwards. Matching readable owner alone retrieves; unresolved intent blocks allpickers and mutations of owner (retake target fixed). Decode failure or over-cap rejection retains original/context via retainRejected and lets a subsequent P1capture proceed; save/import/I/O failures remain active for retry. No invalidfile may silently lock all future captures. Unknown/missingresult ownership stays blocked. Restore owner manifest before reimport; committed stablepageId/path/bytes→cleanup only; missing retake target/conflict/newer/corruptowner→preserve+Retry, never attach toB.

Bootstrap after migration: Failed blocks; existingmarker takesprecedence. No marker→reserve BEFORE single startup retrieveLost. MigrationDone uses known docId/createOwnerfalse, append oldP1recovery behavior. NotNeeded/SourceUnreadable uses reserved freshdocId/createOwnertrue; freshnil-without-error cancels emptyprobe and nevercreatesemptydoc. A loadedmarker+nil/error staysambiguous/retained. Result remembered+staged BEFORE creatingexactreservedowner via LibraryStore; missingfolder onlycreatableforcreateOwnertrue, existingusableempty/alreadycommittedstablepage canresume, corrupt/newer/unexpectedpages failclosed. No assignment to arbitraryexistingdoc, keeplegacyP1/rollbackbytes. PageSource must distinguish error from cancel only when controllerupdated tocatch; no standalonebehaviorregression in leaf.

## 16. Test/evidence

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `apps/mobile/test/storage/pending_pick_store_test.dart` |
| AC-2 | `apps/mobile/test/storage/pending_pick_store_test.dart` |
| AC-3 | `apps/mobile/test/storage/pending_pick_store_test.dart` |
| AC-4 | `docs/work/2026-10-18-xs09-picker-preservation/done.md` |

## 19. Limits and rollback

Put this debt at actualhandoff code during integration: `DEBT: plugin clears lost-result preferences before Dart can journal the returned path | trần: a crash between native clear and durable remember can leave an unassigned cache original | xem lại khi: a device test reproduces this handoff loss or before distributed release requires transactional picker recovery.` No promise of fullpowerloss/fs-corruption resistance or process exactly-once. Unknown journal/owner states stay preserved and blocked until XS10/manualreview; do not inventmissingtext or droporiginal. Leafrollback via PR preserves pendingfiles; app has not activated them.
