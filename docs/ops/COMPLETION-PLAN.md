# COMPLETION-PLAN — Kế hoạch hoàn thiện X-Scanner P1

> AI đọc/ghi file này để biết làm tới đâu — resume qua nhiều phiên.
> Trạng thái việc: ⬜ chưa làm · 🔄 đang làm · ✅ xong (kèm bằng chứng) · ➖ hủy (kèm lý do) · ⏳ chờ điều kiện.

- Ngày lập: 2026-10-12 · **Approved for implementation — phiên chính duyệt theo ủy quyền §3d (`/auto-complete`), 2026-10-12.**
- Nguồn phát hiện: `docs/ops/COMPREHENSIVE-AUDIT-STATUS.md` (2026-10-12, `main` @ `6177e29`), 42 phát hiện: 3 Cao · 14 Trung · 25 Thấp; sau hai lượt quét lại Pha 4 tổng 62: 3 Cao · 16 Trung · 43 Thấp (Đợt 4, Đợt 5).
- Work ID: `2026-10-12-p1-completion`. Mỗi W một PR từ nhánh `claude/upbeat-ramanujan-mwmwtt`, tuần tự (một nhánh push được); worker chuẩn bị song song trong worktree khi file không giao nhau.

## Definition of Complete (bản chỉnh cho app mobile offline, không server)

Đối chiếu 2026-10-12 trên `main` @ `0327ab7` (sau W-504): mọi mục có bằng chứng; còn **WAITING** ngoài quyền phiên: W-104b (⏳ 2026-10-18; W-104a hàng rào làm trước), F-014/F-009 (settings chủ repo), AC-9 UAT (chủ repo, D4).

- [x] 0 phát hiện **Cao** còn mở; mọi Trung/Thấp còn lại có kết cục ghi ở bảng dưới (sửa ở W-xxx, hoặc dời kèm lý do). — F-001..F-003 đóng; 62 phát hiện đều có W hoặc mục dời.
- [x] Luồng chính LC-1..LC-3 (`docs/FEATURE-MAP.md`) có widget/integration test đi qua; toàn bộ test xanh trên CI. E2E trên thiết bị = AC-9 UAT (chủ repo, emulator, D4). — `flutter test` 272/272, CI #24 job 114726677983; AC-9 WAITING.
- [x] Mọi lỗi sửa trong kế hoạch có test hồi quy ở lại; khuôn lỗi ghi `TRAPS.md`.
- [x] Nhóm 12 sạch: không còn logic trùng lặp đã biết; `docs/CONVENTIONS.md` được tuân thủ (lệch có ghi nhận). — quét lại lần 2 (F-059 sửa ở #22).
- [x] Cổng tự động chặn thật: pre-commit + CI chạy gate (gồm kiểm quyền manifest release đã gộp và targetSdk ≥ 31). **Branch protection/ruleset cần chủ repo bật** (quyền repo settings, F-014) — WAITING, không tự bật.
- [x] Bảo mật/riêng tư: quét bí mật sạch; OSV sạch; exception cho F-004 có owner/hạn; quyền manifest release chỉ `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. Không có server → không có ACL; kiểm "vượt quyền" thay bằng kiểm manifest/không exported/không mạng. — `maintenance-sweep` 🔴 0, bí mật: không; OSV querybatch 86 package hosted: 0 advisory (2026-10-12); EX-1 tới 2026-10-18; manifest gộp thật PASS.
- [x] Tài liệu khớp code: README, `PROJECT.md`, header `CLAUDE.md`/`AGENTS.md`, `FEATURE-MAP`, `CODEMAP`, ADR, spec §11/§16. — CODEMAP thêm dòng targetSdk (W-504).
- [x] Hiệu năng: số đo trên máy host ghi trong spec §19; trần bộ nhớ có `DEBT:` rõ; p95 trên thiết bị dời P2 theo spec §2 (đã duyệt). — `DEBT:` thiếu "xem lại khi:" 0.
- [x] `PROGRESS.md` phản ánh đúng trạng thái + nợ còn lại có chủ đích.

## Đợt 0 — Tài liệu khai sai trạng thái (✅)

| ID | Từ phát hiện | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Ước lượng | Trạng thái | PR / bằng chứng |
|----|--------------|------|---------------------|-----------|-----------|-----------|-----------------|
| W-201 | F-002, F-003, F-009 (exception), F-014 (tài liệu), F-015, F-016, F-017, F-027 (spec), F-039, F-040, F-041, F-042 | Đồng bộ README, PROJECT, PROGRESS, CHANGELOG, goal/working P1, header CLAUDE/AGENTS, adoption README, spec §11, `TRAPS.md`, ADR-0003, README app, bảng bằng chứng X-Scanner, exception supply-chain | grep không còn "chưa có chức năng chụp"/"Chưa có camera…PDF engine"; `check-adoption.py` PASS; gate PASS | – | S | ✅ | seeker19110/X-Scanner#11 `97deb76`, CI xanh; `check-adoption` PASS |

## Đợt 1 — Dữ liệu & bảo mật

| ID | Từ phát hiện | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Ước lượng | Trạng thái | PR / bằng chứng |
|----|--------------|------|---------------------|-----------|-----------|-----------|-----------------|
| W-101 | F-001, F-019, F-018 | `SessionStore` từ chối `save` khi `session.json` còn trên đĩa mà `load` chưa hoàn tất; `importOriginal` tuần tự với `load`; dấu `DEBT:` cho bản gốc cách ly | Test đỏ trước: load lỗi I/O → save ném lỗi, manifest + bản gốc cũ còn nguyên, lần load sau còn đủ trang; test load ∥ import không mất file | – | S | ✅ | seeker19110/X-Scanner#12 `faf89a0`, CI xanh; đỏ 5 test → xanh; `flutter test` 211/211 |
| W-102 | F-005 | Sau khi lưu trang thành công, xoá bản sao của picker nếu đường dẫn nằm trong thư mục tạm của app (chuẩn hoá, không bao giờ xoá ngoài) | Test đỏ trước: file nguồn trong temp bị xoá sau capture/import thành công; còn nguyên khi lưu lỗi; file ngoài temp không bị đụng | W-101 | S | ✅ | seeker19110/X-Scanner#15 `e7d265c`, CI xanh; đỏ 7 test → xanh; khuôn ghi `TRAPS.md` |
| W-103 | F-006, F-007 | Một cổng giải mã tuần tự cho thumbnail và render khi xuất; tắt kéo-thả khi bận | Test đỏ trước: `maxActive == 1` giữa thumbnail và render khi xuất; kéo khi bận không đổi thứ tự | W-102 | M | ✅ | seeker19110/X-Scanner#16 `43f24d9`, CI xanh; đỏ 4 test (gate 2, controller `maxActive` 2 thay 1, kéo khi bận đổi thứ tự) → xanh |
| W-104a | F-004 | Hàng rào đầu vào (chủ repo duyệt gộp 2026-10-12, kế hoạch M0 §5.1), tách khỏi việc nâng `image` vì không phụ thuộc phiên bản: chỉ nhận JPEG/PNG/WebP tĩnh theo magic bytes (thay `findDecoderForData` 11 định dạng; WebP động lách trần điểm ảnh nên bị từ chối — rà bảo mật); trần 64 MiB đọc từ độ dài file trước khi đọc; ngân sách 60 s mỗi thumbnail/render, quá hạn thì `Isolate.kill`, chỉ báo lỗi khi isolate đã thoát | Mỗi hàng rào test đỏ trước (BMP/GIF/TIFF/TGA bị từ chối; file trên trần bị từ chối; job quá hạn dừng thật: heartbeat không đổi sau khi lỗi); lỗi về notice "không đọc được", không mất trang cũ, giữ file của picker; không thêm dependency; gate PASS | – | S | ✅ | #28 `474fa28` · `test/imaging/isolate_budget_test.dart`, `page_render_test` (W-104), `session_controller_test` (W-104) |
| W-104b | F-004 | Nâng `image` ≥ 4.12.0 khi đủ 7 ngày (từ 2026-10-18) + test hồi quy 2 ảnh tổng hợp (EXIF IFD lặp, PNG bom) | Test hồi quy xanh với bản mới, đỏ với 4.10.1; gate PASS; manifest release sạch; đóng EX-1 | W-104a | S | ⏳ 2026-10-18 | Exception ở `docs/ops/supply-chain-exceptions.md` |

## Đợt 2 — Hàng rào & test

| ID | Từ phát hiện | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Ước lượng | Trạng thái | PR / bằng chứng |
|----|--------------|------|---------------------|-----------|-----------|-----------|-----------------|
| W-301 | F-008, F-034, F-035, F-037 | Gate kiểm quyền + component exported trong manifest release đã gộp; `flutter pub get --enforce-lockfile`; CI chỉ huỷ run cũ trên PR; workflow adopt không giữ token khi chạy gate | Thêm thử `INTERNET` vào manifest → gate đỏ; bỏ ra → xanh; CI xanh | – | S | ✅ | seeker19110/X-Scanner#13 `ba3d5a9`, CI xanh; gate đỏ "uses-permission not allowed: android.permission.INTERNET" → khôi phục byte → PASS; self-test 7/7 |
| W-302 | F-010, F-011, F-028, F-029 | Test: lỗi chép bản gốc ở controller; `meetsGuideline` (vùng chạm Android, nhãn, tương phản) cho 2 màn × Dark/Light; các nhánh lỗi còn thiếu; siết test yếu (48 dp, kích thước trang PDF nén) | Test mới xanh; guideline đỏ thì sửa UI trong cùng PR | W-103 | M | ✅ | seeker19110/X-Scanner#17 `63b7ef0`, CI xanh; 8 test hồi quy mới + 4 test guideline (2 màn × Dark/Light) xanh, không guideline nào đỏ nên không đổi UI; test 48 dp đỏ khi hạ vùng chạm về 44 |

## Đợt 3 — Hiệu năng, trạng thái UI, thống nhất

| ID | Từ phát hiện | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Ước lượng | Trạng thái | PR / bằng chứng |
|----|--------------|------|---------------------|-----------|-----------|-----------|-----------------|
| W-401 | F-012, F-013, F-023 | `buildPdf` chạy ngoài UI isolate; trần điểm ảnh đầu ra nắn (giữ tỷ lệ); `DEBT:` cho trần 50 MP và số trang PDF; số trang đệm theo tổng số trang | Test đỏ trước: đầu ra nắn ≤ trần; 100 trang sắp đúng; PDF vẫn đúng AC-6 | – | S | ✅ | seeker19110/X-Scanner#14 `4efd3d8`, CI xanh; đỏ 4 test (68694 > 10000 px; (1000,1) thay (100,1); 42436 > 40000 px; `trang-01` thay `trang-001`) → xanh; `flutter test` 210/210 |
| W-402 | F-020, F-021, F-022 | Trạng thái "đang mở phiên" khi khôi phục; thumbnail lỗi được thử lại + ô lỗi có nhãn; `cacheWidth` cho thumbnail; nhãn cho thanh tiến trình | Test đỏ trước cho từng hành vi | W-302 | S | ✅ | seeker19110/X-Scanner#18 `4d07a6a`, CI xanh; đỏ: 3 widget (tooltip thử lại, `MemoryImage` thay `ResizeImage`, thiếu "Đang mở phiên…"), controller (`restoring` chưa có; future lỗi bị cache), 2 a11y ô lỗi → xanh; `flutter test` 254/254 |
| W-403 | F-024, F-025, F-027 (test) | Một helper phần mở rộng ở `core/session_manifest.dart`; `imageSizeOf` ở `imaging/`; sửa chuỗi purity test | Refactor không đổi hành vi, test hiện có xanh; grep khuôn `[a-z0-9]{1,5}` chỉ còn 1 nơi | W-402 | S | ✅ | seeker19110/X-Scanner#19 `a7399de`, CI xanh; hàm mới đỏ trước (chưa định nghĩa) → xanh; không assertion cũ nào đổi; grep khuôn 1 dòng; `package:image/` trong `lib/ui` 0 dòng; `flutter test` 261/261 |

## Đợt 4 — Phát hiện của lượt quét lại (Pha 4, bổ sung)

| ID | Từ phát hiện | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Ước lượng | Trạng thái | PR / bằng chứng |
|----|--------------|------|---------------------|-----------|-----------|-----------|-----------------|
| W-501 | F-043, F-044 | Cổng manifest: mọi giá trị `exported` khác vắng/`"false"` là exported; xoá manifest gộp cũ trước Gradle | Self-test đỏ với `True`/`TRUE`/` true`/`@bool/…` rồi xanh; gate PASS | – | S | ✅ | seeker19110/X-Scanner#20 `673ed97`, CI xanh; đỏ "Lists differ: [] != ['exported provider not allowed…']" → xanh 8/8; gate PASS 261 |
| W-502 | F-047, F-048, F-051, F-053, F-056 | Bỏ qua sắp xếp khi bận (cả thao tác ngữ nghĩa); thumbnail lỗi chỉ thử lại khi bấm, có spinner; mọi lỗi giải mã thử → `decodeFailed`; test LC-1 liền mạch; guideline cho trạng thái rỗng và đang mở; thêm test mới vào FEATURE-MAP | Test đỏ trước cho từng hành vi; gate PASS | W-503 (cùng FEATURE-MAP) | M | ✅ | seeker19110/X-Scanner#22 `d219ce7`, CI xanh; đỏ: "(F-048) Bad state: isolate failed", "(F-047) Expected: <1> Actual: <3>", "(F-051) thứ tự đổi khi bận" → xanh; LC-1, 4 ca a11y mới, F-051 lúc rảnh xanh từ đầu (che hành vi sẵn có); test F-020 đổi có chủ đích (thử lại chỉ khi bấm) |
| W-503 | F-050, F-052, F-054, F-055, F-057, F-058 | Đồng bộ FEATURE-MAP/spec AC-8/README/PROJECT/CHANGELOG; `DEBT:` một dòng; ghi phần chép sang isolate vào `DEBT:`; baseline coverage | grep FEATURE-MAP không còn ⚠️ cho phát hiện đã đóng; `maintenance-sweep` không còn cảnh báo giả; gate PASS | W-501 | S | ✅ | seeker19110/X-Scanner#21 `0e45794`, CI xanh;  ⚠️ FEATURE-MAP chỉ còn F-004, F-018, F-026, F-032, F-033, F-047, F-048, F-049, F-051, AC-9 (mở hoặc dời); `DEBT:` thiếu "xem lại khi:" 1 → 0; coverage baseline `flutter test --coverage` 853/902 dòng = 94,6 % (thấp nhất `lib/export/file_sharer.dart` 4/10, `lib/main.dart` 17/35, `lib/ui/page_source.dart` 19/32 — phần nối nền tảng), đo trên nội dung `a7399de`; ngưỡng coverage dời P2 |

## Đợt 5 — Phát hiện của lượt quét lại lần 2

| ID | Từ phát hiện | Việc | Tiêu chí nghiệm thu | Phụ thuộc | Ước lượng | Trạng thái | PR / bằng chứng |
|----|--------------|------|---------------------|-----------|-----------|-----------|-----------------|
| W-504 | F-071 | Cổng manifest FAIL khi `targetSdkVersion` của manifest gộp < 31 hoặc thiếu (khi đó component không khai `exported` mà có intent-filter là exported ngầm) | Self-test đỏ với targetSdk 30 / thiếu `<uses-sdk>` rồi xanh; manifest thật (36) PASS; gate PASS | W-502 | S | ✅ | seeker19110/X-Scanner#24 `0327ab7`, CI xanh; đỏ "Lists differ: [] != ['uses-sdk android:targetSdkVersion must be a number >= 31']" (targetSdk 30) → xanh; self-test 10/10; manifest release gộp thật `targetSdkVersion="36"` PASS; gate PASS 272 |

F-059, F-070, F-072 (tài liệu) đi cùng PR W-502 theo `pr-flow` (0).

## Nhật ký hội tụ (Pha 4)

| Ngày | Phạm vi quét lại | Kết quả (phát hiện mới? đóng được gì?) |
|------|------------------|----------------------------------------|
| 2026-10-12 | Toàn bộ 12 nhóm trên `6ee3362` (sau W-101..W-403) | 0 Cao mở; mọi F-001..F-042 đóng hoặc dời có chủ đích; mới F-043..F-058 (0 Cao, 2 Trung, 14 Thấp) → Đợt 4 (W-501..W-503) hoặc dời có lý do. Chưa hội tụ: cần quét lại nhóm bị ảnh hưởng sau Đợt 4. |
| 2026-10-12 | Nhóm 2/3/4/6/8/9/12 trên `da7cae8` (sau W-501, W-503, W-502) | 0 Cao · 0 Trung; F-043..F-058 (trừ dời) đóng; mới 4 Thấp: F-059, F-070, F-072 sửa trong PR W-502; F-071 → W-504. Chưa hội tụ: còn W-504 (một file, nhóm 2/8). |
| 2026-10-12 | Nhóm 2/8 trên `36861e2` (= `0327ab7`, W-504) | 0 phát hiện mới; F-071 đóng (self-test 10/10, manifest gộp thật `targetSdkVersion="36"` PASS). Không còn nhóm mở: không chạy được exported ngầm (minSdk 24 → provider mặc định không exported; mọi tag component kiểm `exported`). **Hội tụ**; còn W-104 ⏳ 2026-10-18. |
| 2026-10-12 | Nhóm 2/3/5/7 trên `474fa28` (W-104a, #28) | Rà bảo mật diff W-104a (subagent): 1 Trung bình (WebP động lách trần 50 MP) + 2 Thấp (báo lỗi trước khi isolate thoát; lỗi spawn lọt thô) sửa trong #28 với test đỏ trước; 2 Thấp chấp nhận có lý do (timer sau spawn; bản gốc BMP/GIF của bản cũ — P1 chưa phân phối). `maintenance-sweep` 🔴 0 · 🟡 2 (dependabot = F-009 chủ repo; radar 55/100 do script khung, ngoài phạm vi sản phẩm). Không dependency mới. **Hội tụ**; còn W-104b ⏳ 2026-10-18. |

## Phát hiện dời đợt sau (có lý do)

- F-026 xem trước không áp khung: chủ ý P1 (kết quả cắt kiểm ở file xuất); xem lại khi P2 tự nhận mép — phiên chính, 2026-10-12.
- F-030 thumbnail lưu đĩa: cần số đo khởi động trên thiết bị (spec §2 p95 để P2) — phiên chính, 2026-10-12.
- F-031 `flutter_localizations`: thêm dependency ngoài 5 gói đã duyệt (D2) — đề xuất chủ repo ở P2, 2026-10-12.
- F-032, F-033 UX trình chỉnh góc/tiến trình xuất: tính năng UX mới ngoài spec P1 — P2, 2026-10-12.
- F-036 Gradle verification metadata: bắt buộc trước release (release là non-goal P1) — 2026-10-12.
- F-038 chặn ảnh Recents: quyết định sản phẩm (đánh đổi chụp màn hình) — Data Governance P2, 2026-10-12.
- F-018 bản gốc phiên cách ly: giữ để phục hồi tay (spec §12) + `DEBT:` ở W-101; UI xoá/khôi phục ở Data Governance P2.
- F-014, F-009 (bật): cần quyền repo settings của chủ repo — WAITING, không tự bật (CLAUDE.md header).
- F-045 bản sao picker trên iOS: iOS non-goal P1; hướng lỗi là giữ file (an toàn) — backlog P2 iOS, 2026-10-12.
- F-046 nối cổng giải mã ở `main.dart`: quy ước + test F-006 lặp đúng cách nối; xem lại khi thêm nơi giải mã mới — phiên chính, 2026-10-12.
- F-049 thông báo sai sau `load` lỗi I/O: không mất dữ liệu đã lưu, hiếm; cần notice mới + thử load lại — Data Governance P2, 2026-10-12.

## Cập nhật XS-05 — 2026-10-16

F-014 native đã xử lý: ruleset 25250032 active/no-bypass, đúng required check/app 15368/strict,
readback và PUT/GET JSON khớp. [PR #53](https://github.com/seeker19110/X-Scanner/pull/53):
negative control run 38925328599/head bb98b4a cancelled→BLOCKED, không gọi merge API;
CI head cuối xem PR. F-009: alerts GET 204, graph 86/86 Pub khớp lockfile, action step SUCCESS/
compare không warning; EX-2 còn phần workflow chưa merge main. Các dòng WAITING owner settings
ngày 12/10 là lịch sử trước ủy quyền nâng cấp ngày 16/10; hiện chỉ còn chờ merge #53, W-104b
đủ tuổi 18/10 và AC-9 thiết bị. Không đóng EX-1 hoặc tuyên bố P1 Complete.
