# Feature spec: P1 — scan nhiều trang, chỉnh góc, lưu gốc, xuất PDF/ảnh

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | `docs/goals/2026-10-11-p1-scan-export.md` · Work ID `2026-10-11-p1-scan-export` (spec soạn ở `2026-10-11-p1-readiness`) |
| Spec owner | Phiên chính (Claude Code) |
| State | **Approved for implementation** |
| Approver / date | Chủ repo, chọn "Duyệt theo đề xuất" trực tiếp trong phiên — 2026-10-11 |
| Last updated | 2026-10-11 |

> `CLAUDE.md` (ngữ cảnh X-Scanner): lộ trình P0–P4 không tự cho phép triển khai sản phẩm. Chủ repo đã duyệt spec
> này và chốt D1–D4 theo đề xuất (§19) ngày 2026-10-11; chỉ phạm vi P1 ở đây được code.

## 1. Problem, user và evidence

App hiện chỉ có màn hình nền và lõi `PageQuad`/`ScanPage` (P0). Người cần số hóa tài liệu chưa làm được gì.
Nghiên cứu §6 đề xuất MVP: chụp/nhập → xem lại (sắp xếp, chụp lại, chỉnh góc, xoay) → xuất PDF/JPG/PNG, offline,
giữ bản gốc. Chưa có dữ liệu người dùng; mọi số liệu ở §2 là mục tiêu đề xuất, chưa đo.

## 2. Outcome, baseline, target và guardrails

- Baseline: không tạo được tài liệu nào.
- Target: tạo tài liệu nhiều trang và xuất PDF/ảnh hoàn toàn offline, trên Android (máy thật hoặc emulator).
- Guardrails: không mạng/upload/log nội dung; bản gốc không bị ghi đè; không mất phiên khi app bị đóng giữa chừng;
  không nạp đồng thời nhiều ảnh gốc 12 MP vào bộ nhớ; không bịa nội dung trang.
- Chưa cam kết: p95 xử lý ≤ 2 giây, 100 trang (đo ở P2 trên thiết bị được chọn).

## 3. Research current state (nguồn sống, truy cập 2026-10-11)

| Package | Phiên bản | Publisher | License | Vai trò đề xuất |
| --- | --- | --- | --- | --- |
| `image_picker` | 1.2.4 | flutter.dev | BSD-3-Clause/Apache-2.0 | Chụp bằng app camera hệ thống + nhập từ thư viện |
| `path_provider` | 2.1.6 | flutter.dev | BSD-3-Clause | Thư mục riêng của app cho bản gốc/phiên |
| `image` | 4.12.0 | loki3d.com | MIT | Giải mã, `copyRectify` (đã kiểm mã nguồn), xoay, mã hoá JPG/PNG |
| `pdf` | 3.13.1 | nfet.net | Apache-2.0 | Tạo PDF nhiều trang từ ảnh |
| `share_plus` | 13.3.1 | fluttercommunity.dev | BSD-3-Clause | Chia sẻ/lưu file xuất qua share sheet hệ thống |
| `camera` | 0.12.1 | flutter.dev | BSD-3-Clause | Phương án thay cho capture (preview tự dựng) |
| `google_mlkit_document_scanner` | 0.6.1 | flutter-ml.dev | MIT | Phương án thay (scanner hệ thống) |

Ràng buộc tối thiểu của mọi package (Flutter ≥ 3.24–3.44, Dart ≥ 3.0–3.12) đều thoả với Flutter 3.47.7 / Dart 3.13.5 đang ghim. Ghim khi code (bản ổn định mới nhất đã phát hành ≥ 7 ngày, kiểm 2026-10-11): `image_picker` 1.2.3 (1.2.4 mới 5 ngày),
`path_provider` 2.1.6, `image` 4.10.1 (4.10.2–4.12.0 phát hành 2026-10-10/11), `pdf` 3.13.1 (`image` >=4.1.0 <=5.0.0),
`share_plus` 13.3.1.

Kiểm mã nguồn `image` 4.10.1: `copyRectify` nội suy **song tuyến** 4 góc, không phải phép chiếu phối cảnh, nên làm
méo tỷ lệ chữ khi trang chụp nghiêng mạnh. FR-5 vì vậy dùng homography (ánh xạ hình vuông → tứ giác, dạng đóng)
tự viết, lấy mẫu bằng `getPixelInterpolate` của `image`.

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | Không chi phí | App không dùng được | Loại |
| A. `image_picker` (camera hệ thống) + chỉnh góc tay + `image`/`pdf` | Ít code nhất; ảnh độ phân giải đầy đủ của app camera; không cần quyền CAMERA riêng | Không có hướng dẫn chụp/tự chụp (để P2) | **Đề xuất** |
| B. `camera` plugin, preview tự dựng | Kiểm soát preview, nền cho hướng dẫn/depth (P2–P3) | Nhiều code, quyền CAMERA, vòng đời camera | Hoãn sang P2 |
| C. ML Kit Document Scanner | Gần như không code | Phụ thuộc Play services, chỉ trả ảnh đã xử lý → không giữ bản gốc, khó tích hợp depth | Loại (vi phạm guardrail bản gốc) |

## 5. Scope / non-goals

Scope: phiên scan nhiều trang; chụp (camera hệ thống) hoặc nhập ảnh; danh sách trang (sắp xếp, xoá có xác nhận,
chụp lại); chỉnh 4 góc thủ công + xoay 90°; lưu bản gốc bất biến + tham số chỉnh sửa; phục hồi phiên sau khi app bị
đóng; xuất PDF nhiều trang, JPG, PNG; chia sẻ qua share sheet.
Non-goals: tự nhận diện mép trang, hướng dẫn chụp, mờ/chói, tự chụp, bộ lọc ảnh, OCR, depth, iOS, đồng bộ/cloud,
tài khoản, nhiều tài liệu song song (P1 chỉ một phiên đang mở).

## 6. User journeys và mọi state

Chụp → Xem lại → Xuất.
- Rỗng: chưa có trang → nút "Chụp" và "Nhập ảnh".
- Đang xử lý: tạo thumbnail/nắn ảnh/xuất → chỉ báo tiến trình, không chặn UI.
- Lỗi: người dùng huỷ camera (không phải lỗi, không thêm trang); ảnh không giải mã được → thông báo, không thêm trang;
  hết dung lượng khi sao chép → thông báo, phiên giữ nguyên trạng thái trước.
- Phục hồi: mở lại app khi có phiên dở → hiện lại đúng các trang và chỉnh sửa.
- Quyền: không yêu cầu quyền CAMERA/STORAGE của app (camera hệ thống và photo picker tự xử lý).

## 7. Functional requirements

- FR-1 `ScanSession` (lõi Dart thuần): danh sách `ScanPage` có thứ tự; thêm, xoá, di chuyển, thay trang (chụp lại); id duy nhất.
- FR-2 Lưu trữ: bản gốc được sao chép vào thư mục riêng của app, tên theo id, không bao giờ ghi đè; manifest JSON có
  `schemaVersion`, ghi nguyên tử (ghi file tạm rồi đổi tên); đọc manifest được validate tại biên, manifest hỏng → không
  crash, giữ bản gốc, báo phiên không phục hồi được.
- FR-3 Xoá trang/chụp lại: chỉ khi người dùng xác nhận; file gốc của trang bị thay/xoá chỉ bị dọn khi phiên được lưu xong.
- FR-4 Chỉnh góc: 4 điểm kéo được, ràng buộc bởi `PageQuad` (không cho tạo tứ giác không hợp lệ); xoay 90°.
- FR-5 Render: nắn phối cảnh từ bản gốc bằng homography (§3) trong isolate, sau khi áp hướng EXIF; giải mã từ chối ảnh
  quá `maxPixels`; preview dùng thumbnail giới hạn cạnh dài.
- FR-6 Xuất PDF: mỗi trang một trang PDF, giữ tỷ lệ ảnh (không kéo giãn), chiều theo ảnh; xuất JPG/PNG từng trang.
- FR-7 Chia sẻ file xuất qua share sheet; file tạm xuất được dọn sau khi chia sẻ xong hoặc khi mở lại app.

## 8. Non-functional requirements

Privacy: không mạng, không log đường dẫn/nội dung ảnh. Bộ nhớ: xử lý tuần tự từng trang, không giữ quá 1 ảnh gốc đã
giải mã cùng lúc. A11y: nhãn cho mọi nút, vùng chạm ≥ 44×44 dp, AA cả Dark/Light (thêm chuyển chế độ Dark/Light ở P1).
Độ tin cậy: mọi I/O có nhánh lỗi; ghi manifest nguyên tử.

## 9. Acceptance criteria

- AC-1 Given phiên có 3 trang, When di chuyển trang 3 lên đầu và xoá trang 2, Then thứ tự và id đúng; bản gốc trên đĩa không đổi byte.
- AC-2 Given app bị đóng sau khi thêm trang, When mở lại, Then phiên phục hồi đủ trang và chỉnh sửa.
- AC-3 Given manifest hỏng hoặc sai `schemaVersion`, When mở app, Then không crash, bản gốc còn nguyên, hiện thông báo.
- AC-4 Given người dùng kéo góc tạo tứ giác không hợp lệ, Then thay đổi bị từ chối, quad trước đó giữ nguyên.
- AC-5 Given ảnh gốc và quad, When nắn, Then ảnh đầu ra đúng kích thước dự kiến và bản gốc không đổi.
- AC-6 Given 3 trang khác tỷ lệ, When xuất PDF, Then PDF có 3 trang, mỗi trang đúng tỷ lệ/chiều ảnh.
- AC-7 Given người dùng huỷ camera hoặc ảnh không giải mã được, Then không thêm trang và không mất trang cũ.
- AC-8 Given app khởi động, Then không có request mạng nào và không xin quyền CAMERA/STORAGE.
- AC-9 Given máy Android/emulator thật, When chụp → chỉnh → xuất PDF, Then file mở được trong trình xem PDF (UAT thủ công).

## 11. Architecture và code touchpoints

Đường dẫn thật sau khi triển khai (cập nhật 2026-10-12, F-027; bản đồ đầy đủ ở `CODEMAP.md`):
`apps/mobile/lib/core/scan_session.dart`, `apps/mobile/lib/core/session_manifest.dart`, `apps/mobile/lib/core/quad_editing.dart` (thuần Dart) ·
`apps/mobile/lib/storage/session_store.dart` (đĩa, manifest) · `apps/mobile/lib/imaging/homography.dart`, `apps/mobile/lib/imaging/page_render.dart`
(isolate, `image`) · `apps/mobile/lib/export/pdf_export.dart`, `apps/mobile/lib/export/page_exporter.dart`, `apps/mobile/lib/export/file_sharer.dart` ·
`apps/mobile/lib/ui/` (`page_source.dart`, `session_controller.dart`, `review_screen.dart`, `quad_editor_screen.dart`) · `apps/mobile/lib/main.dart` ·
test tương ứng dưới `apps/mobile/test/` · `apps/mobile/pubspec.yaml`/`pubspec.lock` (5 dependency ở §3, phương án A).

## 12–13. Contract và dữ liệu

Manifest `session.json`: `{schemaVersion: 1, pages: [{id, original, quad: [8 số], quarterTurns}]}`; `original` là
đường dẫn tương đối thư mục phiên, đúng khuôn `originals/<id>.<ext>` (từ chối đường dẫn tuyệt đối, `..`, id lạ).
Tọa độ `quad` tính trên ảnh gốc **sau khi áp hướng EXIF**, trước `quarterTurns`. Manifest hỏng được đổi tên sang
`session.corrupt-<thời điểm>.json` (giữ để phục hồi tay), bản gốc không bị dọn khi manifest không đọc được. Dữ liệu là tài liệu người dùng (có thể nhạy cảm): chỉ ở thư mục riêng của app, xoá khi người dùng xoá
phiên; không backup ra cloud và không chuyển máy (`android:allowBackup="false"` + `dataExtractionRules` loại trừ mọi
miền — D3).

## 14. Security/privacy/abuse cases

Ảnh nhập từ thư viện là dữ liệu ngoài: giải mã có giới hạn kích thước, lỗi giải mã không crash. Không lưu ngoài thư mục
app trừ khi người dùng chủ động chia sẻ. Cần Data Governance ngắn (retention/xoá) trước khi phát hành — không thuộc P1 code.

## 16. Test/eval plan

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | `apps/mobile/test/storage/session_store_test.dart::keeps original bytes and cleans the deleted page after save` | + `test/core/scan_session_test.dart` |
| AC-2 | `apps/mobile/test/storage/session_store_test.dart::a new store on the same root restores pages and edits` | |
| AC-3 | `apps/mobile/test/storage/session_store_test.dart::garbage manifest` | + schemaVersion 2, bản gốc thiếu, UTF-8 sai, bản gốc của phiên bị cách ly |
| AC-4 | `apps/mobile/test/ui/quad_editor_screen_test.dart::rejects an invalid drag and keeps the previous quad (AC-4)` | + `test/core/quad_editing_test.dart` |
| AC-5 | `apps/mobile/test/imaging/page_render_test.dart::re-decodes to the rectified size (AC-5)` | + `renderPage renders from a file and keeps the original intact` |
| AC-6 | `apps/mobile/test/export/pdf_export_test.dart::3 pages keep their aspect and orientation (AC-6)` | + `test/export/page_exporter_test.dart::pdf: 3 pages become one X-Scanner.pdf with 3 pages` |
| AC-7 | `apps/mobile/test/ui/review_screen_test.dart::undecodable image shows a message and keeps pages (AC-7)` | + `cancelled capture adds no page (AC-7)` |
| AC-8 | `apps/mobile/test/android_manifest_test.dart::declares no network, camera or storage permission and disables backup` | manifest release đã gộp: gate chạy `processReleaseMainManifest` rồi `scripts/check-release-manifest.py` (W-301, W-501; trước đó kiểm tay ở PR-3, PR-4) |
| AC-9 | `docs/ops/evidence/p1-android-uat-2026-10-18/ac9.json` | Agent-run Windows/WHPX/API36, three camera/edit/PDF/viewer pages; root accepted18Oct under delegated §3d; report record2026-10-18-p1-android-uat |

## 17. Slice/PR plan

PR-0 `docs` duyệt spec/goal → PR-1 `ScanSession` + `SessionStore` (AC-1..3, không dependency mới: thư mục được tiêm
vào) → PR-2 nắn ảnh + `image` (AC-5) → PR-3 UI chụp/xem lại/chỉnh góc + Dark/Light + `image_picker`/`path_provider`
+ D3 (AC-4, AC-7, AC-8) → PR-4 xuất PDF/ảnh + `pdf`/`share_plus` (AC-6) → UAT AC-9. Tuần tự vì chung `pubspec.lock`.

## 18. Rollout/rollback

Chưa phát hành. Mỗi PR revert được độc lập theo thứ tự ngược. Không migration (manifest `schemaVersion` 1 đầu tiên).

## 19. Risk, assumptions và open decisions

| Item | Verification/mitigation | Owner | Due | Decision |
| --- | --- | --- | --- | --- |
| D1 Capture: phương án A (camera hệ thống) hay B (`camera` plugin) | A cho P1, B ở P2 | Chủ repo | Trước code | **A** (2026-10-11) |
| D2 Thêm 5 dependency ở §3 | License đã ghi; ghim phiên bản ở §3 | Chủ repo | Trước code | **Đồng ý** (2026-10-11) |
| D3 `android:allowBackup` cho dữ liệu tài liệu | Tắt backup + chuyển máy | Chủ repo | PR-3 | **Tắt** (2026-10-11) |
| D4 Cách kiểm AC-9 (máy thật hay emulator) | Container AI không có `/dev/kvm` nên không chạy được emulator | Chủ repo | Sau PR-4 | **Emulator**, chủ repo chạy; máy thật sau |
| Hiệu năng nắn thuần Dart trên ảnh 12 MP | Đo PR-2 (ảnh tổng hợp 4000×3000, Dart JIT, x86): nắn 2,8–3,5 s, thumbnail 1,2 s, chạy trong isolate nên không chặn UI | Phiên chính | P2 | Chấp nhận cho P1; đo lại trên thiết bị ở P2, vượt ngân sách → ADR native/OpenCV |

Mọi quyết định chặn đã đóng.

## Approval

- [x] Product/scope — §5, phương án A
- [x] UX/a11y — §6, §8
- [x] Architecture/API/data — §11–13
- [x] Security/privacy/cost — §14, D3; không chi phí
- [x] Test/telemetry/rollout/rollback — §16, §18
- [x] Blocking decisions closed — D1–D4

**Conclusion:** **Approved for implementation**
**Approver/date:** chủ repo chọn "Duyệt theo đề xuất" (D1 A, D2 5 dependency, D3 tắt backup, D4 emulator) — 2026-10-11.


### D4 execution and acceptance — 2026-10-18

Emulator remains the approved D4 environment. Owner subsequently delegated technical decisions/all gates/continuation and self-installation (“tự cài đi”); root accepted the agent-run controlled-emulator AC9 evidence under §3d, without claiming owner personally ran it. ExactCI58 source/build/APK identity, actual system camera3times→crop/rotate/reorder→PDF→Librera pages1/3,2/3,3/3, original byte preservation and restart evidence are in `docs/ops/evidence/p1-android-uat-2026-10-18/ac9.json` and `docs/work/2026-10-18-p1-android-uat/working.md`. This is P1 schema1 UAT, not unmerged XS09/StatFs runtime or physical-device/release acceptance. Historical D4 owner-run wording records the original12Oct execution arrangement.
