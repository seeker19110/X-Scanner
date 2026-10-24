# Công việc: P1 AC9 trên Android Windows tăng tốc

- Work ID: 2026-10-18-p1-android-uat
- Outcome: install the authorized accelerated Android environment and execute P1 AC9 on a verified CI APK, with synthetic originals only.
- Status: **Done** — AC9 accepted 18Oct; report `docs/ops/evidence/p1-android-uat-2026-10-18/ac9.json` merged via [#60](https://github.com/seeker19110/X-Scanner/pull/60) `30b47da`. Scope: P1 APK only; the library build (#62) needs its own run.
- Owner: windows_uat owns isolated Windows/AVD/evidence; independent capacity_review audits readonly; root verifies hashes/screenshots/manifest/authority and owns report/gates/PR.
- Risk S verification, no app source change; part of goal2026-10-18-upgrade-completion S4. D4 keeps emulator choice. User delegated technical acceptance/gates and replied “tự cài đi”; do not claim owner personally ran the scenario.
- Artifact source b227825a3145a2a73e2198320d58d4a08b5f327b / builda810e3fbf8f30acc2db977683aabf5fe79b318d5, CI39088067553/artifact12120799566; same tree as mainc50670a. Root checked exact artifact ancestry separately before PR58 merge.

## Decision and execution evidence

Use an isolated Windows SDK/AVD with native WHPX rather than repeat failed Linux software boots · fewer environment changes and measured usable acceleration; no global PATH/profile/security change. Windows emulator37.2.12, API36 Google APIs x86_64r7,2560MiB/2cores, privateADB5039/emulator5582. accel-check exit0 says WHPX usable; actual boot67.5s. Root read proof; physical host33.95GB RAM, final free~10.16GiB. Static camera backend, SwiftShader graphics; no device performance claim.

Three real com.android.camera2 capture/shutter/Done cycles via image_picker, then actual UI crop,90°/180°rotations, drag reorder[page3,page1,page2], PDF export, Android sharesheet→LibreraFD9.6.39-fdroid. Receiver navigated1/3,2/3,3/3. Same geometric camera source repeated; edits distinguish pages. Backend frames only a subregion of host fixture; comparisons use actual camera JPG originals. No real documents/OCR/cloud.

Root independently recomputed APK/four bundle hashes, three before/after original byte comparisons, unchanged metadata after cancel/force-stop/relaunch, PDF export/share exact equality, three Page objects and rawDCT stream lengths/SHA256. Root inspected receiver3/3 and actual restored3-page UI images. Independent reviewer checked archive digest/ancestry, raw PDF/page objects, timeline and all original copies. Pypdf extraction initially labeled a reencoded JPEG hash as embedded; preserved original attempt, latest report distinguishes extracted JPEG from rawDCT and compares decoded rawDCT pixels. Final per-page orientation180°/0°/90°, image sizes960×1280/885×1280/1280×960; crop/order/aspect correct. MAE0.241/0.205/0.224 reflects JPEG recompression, not byte-identical rendered output.

Committed proof and synthetic preview/PDF: `docs/ops/evidence/p1-android-uat-2026-10-18/ac9.json`. Local full evidence `/home/liend/.local/share/x-scanner/uat-20261018/windows/`, root proof `/home/liend/.local/share/x-scanner/p1-uat-root-proof.json`. Handoff manifest covers67files; checksum validation reported67/67, root checks consolidated evidence and selected originals/artifacts independently. Third-party viewer verified official F-Droid index/APK SHA256/signature/ABI/SEND handler, used only inside owned AVD.

## Attempts and limits

Prior Linux API36/API24 software boots stopped before boot under RAM guard; those are NOTRUN, preserved as historical attempts. First relaunch PNG captured splash while later XML had ready UI; retain it and use fresh matching ready PNG/XML, not a false app failure or stale hierarchy. First drag did not reorder; explicit held drag succeeded and durable order verified. Cold debug launch is slow; no latency/RAM benchmark claim.

Camera cancel left metadata unchanged. Force-stop/relaunch restored three edited pages and originals unchanged. Dark/Light checked and restored Dark. Extra offline test exported/opened PDF with airplane mode and Active default network:none, then airplane mode disabled; no network/privacy guarantee inferred from guest connectivity alone. Scoped logs contain no fatal/unhandled/FlutterError; platform/frame warnings do not establish release performance.

## Root acceptance and handoff

AC9 accepted18Oct: actual camera→edit→PDF→recipient viewer on an emulator, agent executed and root accepted under delegated §3d. This does not validate physical-camera/depth/iOS/OCR/real-document quality or release; current schema1 APK does not activate capacityleaf or XS09PR4b/AC13.

Preserve running owned AVD/appdata and synthetic frozen3-page session backup for later exact-APK migration UAT. Do not uninstall/clear on signer mismatch: CI debug signer may differ per runner; preserve/clone and report reconstructed fixture honestly if update cannot install. Runtime handoff/owned process IDs/privateADB commands in local handoff.json. Next: reconcile this report and P1 AC9 pointers after pending-preservation PR review/gates; app integration remains separate. Keep working until report PR actually merges.
