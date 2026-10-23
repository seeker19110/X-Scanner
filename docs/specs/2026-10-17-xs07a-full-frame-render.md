# XS-07a — full-frame pixel fidelity and render cost

| Thuộc tính | Giá trị |
| --- | --- |
| Work ID | 2026-10-17-xs07a-full-frame-render |
| State | **Approved for implementation** |
| Approver / date | Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07; duyệt thực tế 2026-10-17, theo yêu cầu nâng cấp tiếp sau review/merge #54 |
| Risk | M gọn, một PR; thay đường render hiện có, không API/schema/dependency mới |

## 1. Problem and evidence

PR #54 source935083e có baseline host 12 MP: PDF10trang median82.413s, render82.344s (5sample). Core rectify vẫn dùng homography/bilinear cho fullFrame dù ánh xạ identity. Probe Dart ngày17/10 trên chính lib hiện tại với Random17 RGBA:13×9 đổi16kênh,97×53 đổi1015kênh, giảm1LSB do sai số float/truncation. Đây là sai lệch pixel và chi phí thực, không phải đề xuất thêm engine.

## 2. Outcome and scope

Full-frame không giảm kích thước phải giữ đúng mọi byte pixel sau chuẩn hóa8bit/palette hiện có, trả buffer mới độc lập và giữ chính sách không mang metadata gốc sang export. Giảm thời gian render bằng copy byte chuẩn; không thay mọi homography thành thuật toán khác. Chỉ source `rectify` và regression/integration tests.

## 3. Research và lựa chọn tối giản

Nguồn [Dart List.setRange](https://api.dart.dev/dart-core/List/setRange.html), API của SDK3.13.5, xác nhận copy vào range đích. Đã đọc source dependency ghim image4.10.1: Image.toUint8List là view buffer; ImageDataUint8 có rowStride=width×numChannels; Image.from clone cả metadata/frame. Dùng view + standard byte copy vào Image mới để giữ hành vi metadata hiện tại. Không nhập framework/engine/dependency mới.

| Đối chiếu | Đã có / bằng chứng | Quyết định |
| --- | --- | --- |
| Đã có và sâu hơn | Normalize16bit/palette, cap, isolate budget, geometry/revision, tests/gate | Giữ toàn bộ, không thay lại |
| Đã có nhưng nông hơn | Full-frame đang nội suy dù identity, đã tái hiện mất1LSB | Chỉ thêm guard exact identity và copy byte |
| Chưa có / sự cố thật | Regression exact odd-size pixels và baseline matched cho nhánh này | Thêm test từ lỗi thật và phép đo; không đưa ra claim camera/OCR |

## 5. Scope / non-goals

Chỉ `rectify` và regression/integration tests trong một PR, dùng core/dependency hiện có.
Non-goals: scaled JPEG/image4.12 trước đủ tuổi18/10, đổi decoder/ceilings/budget/isolate, caching, native/PDF writer, concurrency/cancellation, app UI, migration, real document/OCR, device/UAT, 100page acceptance, release.

## 7. Requirements

- FR-1: Sau chuẩn hóa source như hiện tại và tính `rectifiedSize` có cap, chỉ đi fast path khi `quad == PageQuad.fullFrame` theo giá trị và output width/height bằng source width/height. Không dùng epsilon hoặc chỉ object identity.
- FR-2: Tạo output Image8bit mới như hiện tại, cùng numChannels; copy toàn byte bằng Uint8List setRange/setAll vào buffer output. Không trả source/alias hoặc dùng Image.from: clone đó mang EXIF/ICC/text/frame metadata mà đường render hiện tại đã loại bỏ. Không tạo thêm full-size byte copy trung gian.
- FR-3: Quad lệch full-frame dù kích thước làm tròn bằng source, hoặc fullFrame bị cap/downsize, vẫn chạy thuật toán hiện có. Giữ clamp biên, geometry, normalize16bit/palette, RGB/RGBA/grayscale và quarterTurns.
- NFR-1: Không tăng số buffer toàn ảnh so với đường hiện có; không dependency/config/lock change. Không upload/log dữ liệu thật hoặc metadata. Bản gốc chỉ đọc.
- NFR-2: Đo matched host AOT trước/sau dùng cùng corpus/toolchain/lock, input hash và5process mới cho mỗi case/stage/version; xen kẽ before/after. Báo min/median/max, RSS scope, raw/provenance, không p95/device/cold-disk. Nếu không cải thiện render hoặc có regression tài nguyên lớn, điều tra trước bàn giao; không timing threshold CI.

## 9. Acceptance criteria

- AC-1: Full-frame13×9 RGBA tái hiện đỏ trên code cũ bằng assert exact byte, RGB và full-frame tạo lại qua constructor giữ exact pixels. Gồm alpha/1pixel/single-row/single-column, không chỉ ảnh solid hoặc dimensions.
- AC-2: Output là buffer độc lập: sửa output không sửa source và ngược lại; EXIF/text synthetic marker không được copy sang output, source metadata/pixels giữ nguyên.
- AC-3: Full-frame dưới cap vẫn đúng kích thước giới hạn; gần-full-frame cùng kích thước làm tròn vẫn crop đúng (analytical ramp), không identity copy. Test16bit/palette/border/skew cũ giữ xanh.
- AC-4: `renderPageSync` PNG với13×9 input exact ở quarterTurns0, và xoay1..3 đúng mapping; JPEG async/PDF-core/tool tests và fullgate xanh. Không thay golden hoặc so bytes JPEG có mất mát với PNG.
- AC-5: Comparison host ghi đủ dữ liệu/provenance/hash/quy trình/lỗi thực; code và measurements cùng head bàn giao, baseline trước có source935083e và binary hash xác minh. Root fullgate, hook và CI final-head đều xanh. Chưa nghiệm thu device/scan/OCR/release.

## 11. Architecture và code touchpoints

- `apps/mobile/lib/imaging/page_render.dart`: rectify fast path sau normalize/cap, buffer mới, trước homography/per-pixel loop; nhánh generic giữ nguyên.
- `apps/mobile/test/imaging/page_render_test.dart`: exact pixel/regression/ownership/metadata/cap/near-full/PNG rotation tests, giữ toàn bộ test hiện hữu.
- `docs/benchmarks/README.md`: link outcome/PR evidence, giới hạn comparison và source hashes; không thay schema tool/corpus.
- `CODEMAP.md`, `docs/FEATURE-MAP.md`, `TRAPS.md`, `CHANGELOG.md`, `PROGRESS.md`: root cập nhật trong cùng PR.

## 16. Test/eval and evidence

Bảng dưới là mapping test/evidence dự kiến; chỉ nghiệm thu khi test thực và CI final-head đạt. Đỏ trước bằng regression hiện tượng identity thật, không mock khớp implementation, không test chỉ đếm dòng/call hoặc timing threshold. Worker báo checkpoint test đỏ, root đọc/chạy lại trước source logic. Root review, AOT smoke, dispatcher fullgate và normal hook trên snapshot cuối. Comparison thực thi trên PR để không commit tự ghi SHA/CI chính nó.

| AC | Bằng chứng |
| --- | --- |
| AC-1 | `apps/mobile/test/imaging/page_render_test.dart` |
| AC-2 | `apps/mobile/test/imaging/page_render_test.dart` |
| AC-3 | `apps/mobile/test/imaging/page_render_test.dart` |
| AC-4 | `apps/mobile/test/imaging/page_render_test.dart`, `apps/mobile/test/tool/scanner_benchmark_test.dart` |
| AC-5 | `docs/benchmarks/README.md`, `docs/work/2026-10-17-xs07a-full-frame-render/done.md` và execution evidence trên PR của Work ID |

## 17. Delivery and rollback

Một PR sau #54 merge/reconcile. Root tự duyệt theo §3d, worker chỉ source/test/hồ sơ riêng ở worktree tách; root docs/spec/maps/bench evidence. PR mới giữ OPEN để review, quyền merge chỉ đã cấp cho #54. Rollback qua revert PR; không migration/bản gốc đổi, không release.

## Approval

Approved for implementation — phiên chính duyệt theo ủy quyền của chủ repo ngày 2026-10-07; ngày duyệt thực tế 2026-10-17. Phạm vi và điều kiện bằng chứng theo AC-1..5; quyền merge chỉ có cho PR #54, PR XS-07a mới giữ OPEN.
