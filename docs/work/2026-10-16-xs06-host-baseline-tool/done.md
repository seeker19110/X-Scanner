# Công việc: XS-06a — corpus và harness host (T1)

- Work ID: 2026-10-16-xs06-host-baseline-tool
- Yêu cầu / outcome: T1 XS-06a theo PLAN của phiên chính, corpus tổng hợp tái lập và CLI đo host bằng production core.
- Trạng thái: Done — root nghiệm thu/tích hợp và PR #54 merged17/10.
- Chủ trì / writer: worker XS-06a tool, chỉ hồ sơ đơn vị; root giữ hồ sơ tổng/tích hợp/gate/PR.
- Mức rủi ro / số PR: S, tooling nội bộ trong một PR tổng XS-06a do root mở.
- Scope / non-goal: bốn điểm chạm T1; không app lib, SDK/dependency/lockfile/framework/CI/settings; không commit/push/merge/subagent/full gate.
- Spec / goal / issue: `docs/work/2026-10-16-xs06-host-baseline/PLAN.md` ở checkout root; contract approved trước giao việc, không feature app mới.
- Nhánh / base SHA / thời điểm reconcile: `codex/xs06-baseline-tool` @ `3f49039` · 2026-10-16T16:28:20Z

## Kế hoạch và phân công

1. Đọc luật/context, production core và PLAN đầy đủ; tạo hồ sơ bằng new-work.sh.
2. Tạo test với API stub chạy được; báo log đỏ rồi giữ nguyên source để root xác minh.
3. Chỉ sau root greenlight: triển khai CLI/manifest/record/guardrails, README và chạy targeted format/analyze/test.
4. Root review/tích hợp, compile AOT/baseline/full gate/CI; worker báo Ready for root gate, giữ working.md.

Điểm chạm độc quyền: `apps/mobile/tool/scanner_benchmark.dart`, `apps/mobile/test/tool/scanner_benchmark_test.dart`, `docs/benchmarks/README.md`, hồ sơ này. Worktree riêng `/home/liend/.local/share/x-scanner/xs06-baseline-tool`, base `3f49039c216b15a3827a06afb92ee25027cbf571`.

## Quyết định và bằng chứng

- Chọn một API `runBenchmark(args, output, errors)` và CLI wrapper, không abstraction/injection framework · loại chia nhiều lớp · bậc 2; API stub hiện trả 0 và chưa triển khai logic.
- Test dùng corpus tiny độc lập để kiểm manifest, giới hạn byte/symlink/checksum và production-core output; không dùng fixture generator của tool cho preflight/integration · loại chỉ test roundtrip tự xác nhận · bậc 3.
- `bash scripts/dev-task.sh doctor`: READY 4 kiểm tra, chưa PASS gate. `core.hooksPath` đọc lại là `scripts/githooks`.
- Red 2026-10-16 trên base `3f49039` + hai file mới: `flutter test --reporter expanded test/tool/scanner_benchmark_test.dart`, exit 1, 44 ca chạy/44 fail. Assertion đầu: Expected 2 / Actual 0; kiểm overwrite và corpus validation Expected 1 / Actual 0. Không compile/import error, không throwsAnything. Log ngoài repo: `/home/liend/.local/share/x-scanner/xs06-tool-red.log`.
- Script per-file formatter không nhận Dart (skip); dùng `dart format` trực tiếp đúng hai file, 2 file/1 đổi. Không sửa script/framework.
- Root đọc/rerun đỏ ban đầu, yêu cầu test checksum dùng JPEG hợp lệ khác pixel, actual dimensions lệch manifest dù hash đúng, SHA có newline. Đã chỉ sửa tests rồi chạy đỏ 46/46, exit 1; log `/home/liend/.local/share/x-scanner/xs06-tool-red-review.log`. Root đọc/rerun cùng 46/46 trước GREENLIGHT implementation; log riêng root `/home/liend/.local/share/x-scanner/xs06-root-red-review.log`.
- Chọn `mkdir` argv/coreutils để chiếm NEW_DIR atomically theo quyết định root · loại Directory.create vốn nhận directory đã tồn tại · bậc 1. Từng file exclusive, manifest ghi cuối; không dọn partial corpus hoặc overwrite input.
- Chọn băm buffer đọc đúng length có trần qua stdin `sha256sum --zero`, không shell · loại hash trực tiếp file có thể tăng sau stat · bậc 1, root đồng ý refinement. JPEG type/header/dimensions probe bằng production `imageSizeOf` trong `runWithinBudget(decodeBudget)`. Corpus phải bất biến suốt run; không tuyên bố chống concurrent mutation/TOCTOU.
- Production `thumbnail`/`renderPage` tuần tự, PDF fullres JPEG buffers độc lập + `buildPdf` qua Isolate.run, file ghi `flush: true`; chỉ xóa unique tempdir do invocation tạo. Original/manifest test giữ byte hash, không real documents/OCR.
- Metadata ghi core/function + appSha và SHA256 lock, engine version không hardcode (null); host chỉ OS/ABI/Dart version. Render timer PDF bắt đầu sau createTemp; duration total gồm tạo tempdir nhưng không gồm preflight/cleanup/JSON, README ghi đúng phạm vi.
- Final targeted format: `dart format --output=none --set-exit-if-changed tool/scanner_benchmark.dart test/tool/scanner_benchmark_test.dart`, exit 0, 2 file/0 đổi; log `/home/liend/.local/share/x-scanner/xs06-tool-format.log`.
- Final analyze: `flutter analyze --no-pub --fatal-infos`, exit 0, No issues found (0 errors/warnings/info); log `/home/liend/.local/share/x-scanner/xs06-tool-analyze.log`.
- Final targeted test sau timer/import/braces refinements: `flutter test --no-pub --reporter expanded test/tool/scanner_benchmark_test.dart`, exit 0, 46/46; log `/home/liend/.local/share/x-scanner/xs06-tool-green.log`. Không dùng timing/RSS threshold, không dùng test process làm baseline.
- Self-review bốn điểm chạm: core sẵn có, stdlib/coreutils, không dependency/engine abstraction mới; scope guard/data preservation và docs/protocol khớp. README có AOT/process/checksum, 12/24/48 MP × 1/10/30/100 trang, p95 ≥30 mẫu/case, physical holdout/NFC/unknown=null và giới hạn device/UAT/corpus120.

## Lần thử / blocker

- Hai mốc đỏ là chủ đích TDD, root xác minh độc lập trước source logic. Chưa chạy full gate hoặc AOT/baseline trên worker.
- Đã thử gọi formatter từ app directory nên sai đường dẫn; sửa workdir về repo root trước lần format thật. Không dùng lần gọi lỗi làm bằng chứng.
- Analyze lần đầu có 5 info (4 relative-lib imports, 1 thiếu braces); sửa cơ học sang package imports/braces rồi rerun targeted checks sạch. Không đổi cổng hoặc tắt lint.

## Bàn giao / bước tiếp theo

- Root review diff/source/test/README hiện tại, tích hợp bốn file, compile AOT/smoke/baseline rồi full gate/CI. Các file vẫn untracked trong worktree worker; không commit/push/merge hoặc discard. Worker source freeze, chỉ sửa tiếp khi root yêu cầu finding cụ thể.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Ready for root gate; chưa Done, chưa full Android gate/AOT/baseline/PR/merge. XS-06 đầy đủ, device/UAT/OCR/quality không được suy ra từ tiny host tests. Root giữ final review/integration/PR và các số đo trên head cuối.

## Nghiệm thu sau merge — 2026-10-17

- [PR #54](https://github.com/seeker19110/X-Scanner/pull/54) MERGED `8b99c511e1134534a05b3c93667239c50abf84c9` lúc2026-10-16T23:20:17Z, reviewedhead `95dad0d6688ced6be427ff1d49e9a96bab88abc8`. Main ff-only và tree exact reviewedhead; guarded squash, không bypass/auto-merge.
- Root review sửa F1/POSIX filename testcase; Linux46/46, fullgate4/4 và normal hook4/4, Flutter592/592, analyze0/format57/0, fresh AOT+5smoke PASS, input hashes unchanged. [CI cuối38980161272](https://github.com/seeker19110/X-Scanner/actions/runs/38980161272) SUCCESS trên95dad0d; log đếm592testpass/0failure. Native5rules exact/no bypass, requiredapp15368, threads0, dependencycompareHTTP200/0change/emptywarnings.
- Root kiểm20raw/provenance lịch sử935083e, hash tool/lock/bin/corpus/median đều khớp; không relabel source. Artifact12080842859 build6fe17bd parents đúng base/head, API metadata/ancestry only, chưa cài thiết bị.
- DoD đơn vị XS06a tooling/host baseline đạt theo ủy quyền; rename done sau mergeproof và đưa vào PR kế. XS06 corpus/device đầy đủ, AC9/UAT, EX1/decoder, OCR/iOS/release và PR4b vẫn mở.
