# Feature spec: P0 foundation — app Flutter kiểm chứng được và hợp đồng trang

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | `docs/goals/2026-10-11-p0-foundation.md` · Work ID `2026-10-11-p0-foundation` |
| Spec owner | Phiên chính (Claude Code), `/auto-complete` |
| State | **Approved for implementation** |
| Approver / date | Chủ repo, xác nhận trực tiếp trong phiên — 2026-10-11 |
| Last updated | 2026-10-11 |

## 1. Problem, user và evidence

Repo chưa có app; build/typecheck N/A nên mọi việc sản phẩm (P0–P4) bị chặn. Nghiên cứu §7 yêu cầu chốt
hợp đồng trang/tọa độ trước khi chia việc Android/iOS/xử lý ảnh. Người dùng trực tiếp của slice này là
người phát triển X-Scanner; người dùng cuối chưa nhận tính năng mới.

## 2. Outcome, baseline, target và guardrails

- Baseline: `dev-task.sh gate` PASS chỉ với kiểm tra khung; build/typecheck **N/A**.
- Target: gate chạy **build APK debug, analyze, format, unit/widget test** thật, cục bộ và trên CI.
- Guardrails: không camera/OCR/upload/log tài liệu; không dependency bên thứ ba ngoài `flutter_lints`;
  không tuyên bố iOS/thiết bị/scan đã kiểm chứng; không chi phí mới.

## 3. Research current state

Flutter stable 3.47.7 / Dart 3.13.5, Android cmdline-tools 23.0 (nguồn và sha ở ADR-0002, truy cập 2026-10-11).
Template Flutter 3.47.7: compileSdk/targetSdk 36, minSdk 24, AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, Java ≥17.
`scripts/check-adoption.py` chặn `apps/` khi build/typecheck còn N/A — cổng phải đổi cùng lúc thêm app.

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | Không tốn công | Không mở được cổng thật | Loại |
| Flutter + lõi Dart thuần (ADR-0002) | Một UI codebase, test rẻ trên Linux | Camera/depth cần native sau | **Chọn** |
| Native Kotlin + Swift | Camera trực tiếp | Hai UI codebase | Loại |
| Thêm `ScanSession`/lưu phiên ngay | Gần P1 | Nhu cầu chưa tới, thêm code | Hoãn sang P1 |

## 5. Scope / non-goals

Scope: `apps/mobile` (Flutter create, Android+iOS khai báo), màn hình nền tối giản, lõi `PageQuad`/`ScanPage`,
cổng gate + CI, cập nhật guard `check-adoption.py` và tài liệu trạng thái.
Non-goals: camera, depth, OCR, PDF, lưu trữ, quyền hệ thống, build iOS, release/ký số, license sản phẩm,
branch protection, dữ liệu kiểm thử thật.

## 6. User journeys và mọi state

Mở app → màn hình nền nêu rõ chưa có chức năng chụp. Không có loading/error/offline vì không I/O.

## 7. Functional requirements

- FR-1 `PageQuad`: bốn góc TL, TR, BR, BL trong tọa độ chuẩn hóa `[0,1]` của **ảnh gốc chưa xoay**
  (gốc trên-trái, y hướng xuống); chỉ tạo được khi hữu hạn, trong biên, lồi chặt, thuận chiều kim đồng hồ
  và diện tích ≥ `PageQuad.minArea` (0,01 = 1% khung). `PageQuad.fullFrame` là cả khung.
- FR-2 `ScanPage`: `id` và `originalPath` không rỗng, không đổi sau khi tạo; `quad` (mặc định fullFrame) và
  `quarterTurns` (chuẩn hóa về 0–3) là tham số chỉnh sửa; mọi chỉnh sửa trả bản mới, giữ nguyên bản gốc.
- FR-3 Lõi không import Flutter (`package:flutter`) để dùng lại ngoài UI.
- FR-4 App nền: tiêu đề "X-Scanner", nền Dark blue mặc định + Light qua token, chuỗi "chưa có chức năng chụp".
- FR-5 Gate: `build`, `typecheck`, `lint`, `test` thật trong `.claude/project-commands.sh`; CI chạy cùng gate.

## 8. Non-functional requirements

Không mạng, không quyền, không log nội dung. A11y: chữ dùng theme, tương phản AA từ `ColorScheme` Material 3.
Hiệu năng/thiết bị: chưa đo ở P0 (không có camera).

## 9. Acceptance criteria

- AC-1 Given bốn góc hợp lệ, When tạo `PageQuad`, Then giữ đúng tọa độ; `fullFrame` hợp lệ.
- AC-2 Given góc ngoài `[0,1]`, NaN/vô hạn, tứ giác tự cắt/lõm/ngược chiều, hoặc diện tích < 1%, When tạo, Then `ArgumentError`.
- AC-3 Given `ScanPage` có `originalPath`, When đổi quad hoặc xoay, Then trả trang mới cùng `id`/`originalPath`, trang cũ không đổi.
- AC-4 Given `id`/`originalPath` rỗng, When tạo `ScanPage`, Then `ArgumentError`; `quarterTurns` 5 hoặc -1 chuẩn hóa thành 1 hoặc 3.
- AC-5 Given app khởi động, Then thấy "X-Scanner", chế độ tối là mặc định.
- AC-6 Given `apps/` tồn tại mà build/typecheck còn lý do N/A, When chạy `check-adoption.py`, Then test đỏ.
- AC-7 Given commit trên PR, When CI chạy, Then gate build APK debug + analyze + test xanh.

## 11. Architecture và code touchpoints

- `apps/mobile/` (sinh bởi `flutter create --platforms=android,ios --org org.xscanner`), `apps/mobile/lib/main.dart`,
  `apps/mobile/lib/app/theme.dart`, `apps/mobile/lib/core/page_quad.dart`, `apps/mobile/lib/core/scan_page.dart`.
- `apps/mobile/test/core/page_quad_test.dart`, `apps/mobile/test/core/scan_page_test.dart`, `apps/mobile/test/app_test.dart`.
- `.claude/project-commands.sh`, `.github/workflows/ci.yml`, `scripts/check-adoption.py`.
- Tài liệu: `PROJECT.md`, `PROGRESS.md`, `README.md`, khối ngữ cảnh đầu `CLAUDE.md`/`AGENTS.md`, `docs/adoption/source.json` (`product_stack`).

## 12. Contract

Tọa độ dùng `Point<double>` của `dart:math`. Không API mạng. Lỗi đầu vào là `ArgumentError` tại biên tạo đối tượng.

## 13. Data contract

Không lưu trữ ở P0. `originalPath` là tham chiếu; lõi không xóa/ghi file (bảo toàn bản gốc thuộc tầng lưu trữ P1).

## 14. Security/privacy

Không quyền camera/lưu trữ, không mạng, không log. Không dữ liệu thật trong test.

## 16. Test/eval plan

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | `apps/mobile/test/core/page_quad_test.dart::accepts a valid clockwise quad` | unit |
| AC-2 | `apps/mobile/test/core/page_quad_test.dart::rejects` | nhóm test ca biên |
| AC-3 | `apps/mobile/test/core/scan_page_test.dart::edits keep the original` | unit |
| AC-4 | `apps/mobile/test/core/scan_page_test.dart::normalizes quarter turns` | unit |
| AC-5 | `apps/mobile/test/app_test.dart::shows the app shell in dark mode by default` | widget |
| AC-6 | `scripts/check-adoption.py::test_app_requires_real_gates` | guard |
| AC-7 | thủ công: GitHub Actions "Repository checks" xanh trên head của PR-2 | CI run của head PR |

## 17. Slice/PR plan

PR-1 `docs`: ADR-0002, spec này, goal, hồ sơ công việc và guard AC-6 trong `scripts/check-adoption.py` (phiên chính). PR-2 `feat`: mọi touchpoint §11
(giao worker, phiên chính review/gate/tích hợp), phụ thuộc PR-1 đã merge.

## 18. Rollout/rollback

Không phát hành. Rollback = revert squash commit của PR-2; PR-1 chỉ tài liệu.

## 19. Risk, assumptions và open decisions

| Item | Verification/mitigation | Owner | Due | Decision |
| --- | --- | --- | --- | --- |
| Runner CI thiếu SDK 36/Java 17 | Chạy CI thật; AGP tự tải khi license đã chấp nhận | Phiên chính | PR-2 | Kiểm ở CI |
| Gate chậm do build APK | Đo thời gian gate; chấp nhận ở P0 | Phiên chính | PR-2 | Chấp nhận |
| Camera/depth khả thi | Spike trên thiết bị thật | Chủ repo | Sau P0 nền | BLOCKED — cần thiết bị |

## Approval

- [x] Product/scope — chỉ nền P0, không tính năng người dùng mới
- [x] UX/a11y — màn hình nền tối giản, token theme
- [x] Architecture/API/data — ADR-0002, §12–13
- [x] Security/privacy/cost — không quyền/mạng/chi phí
- [x] Test/telemetry/rollout/rollback — §16, §18
- [x] Blocking decisions closed — spike thiết bị nằm ngoài scope

**Conclusion:** **Approved for implementation**
**Approver/date:** chủ repo xác nhận trực tiếp trong phiên (a) triển khai P0 nền, (b) đổi guard AC-6, (c) merge khi CI xanh — 2026-10-11.
