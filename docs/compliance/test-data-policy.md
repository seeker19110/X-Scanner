# Chính sách dữ liệu test — X-Scanner

> QA-DATA-001, QA-DATA-002. Cập nhật 2026-10-24 (Work ID `2026-10-24-governance-docs`). Tóm tắt trong `PROJECT.md` mục "Dữ liệu test".

## Luật

1. **Chỉ dữ liệu tổng hợp.** Ảnh test, fixture, corpus benchmark và bằng chứng UAT phải do test/tool sinh ra hoặc chụp
   từ tài liệu tự dựng (giấy in chữ mẫu, bảng ô vuông). Không dùng ảnh giấy tờ thật, CCCD, hoá đơn, hồ sơ bệnh, chữ ký.
2. **Không có "dữ liệu production".** App không có server; dữ liệu thật chỉ nằm trên máy người dùng. Không chép thư mục
   app (`documents/`, `pending-pick*/`, `session*/`) từ máy có dữ liệu thật vào repo, CI, issue hay máy dev.
3. **Không đưa nội dung tài liệu vào log, issue, PR, artifact CI** (cũng là luật trong `AGENTS.md`/`CLAUDE.md`).
4. **Tên/email/số điện thoại trong fixture** (nếu sau này cần, ví dụ OCR): chỉ dùng tên rõ ràng giả ("Nguyễn Văn Mẫu"),
   email đuôi `example.com`/`example.test`, số điện thoại không thuộc dải thật — ghi danh sách số mẫu vào file này trước khi dùng.
5. **Tiêu đề tài liệu trong test** dùng chuỗi mô tả ("Tài liệu 1", chuỗi Unicode Việt/emoji tổng hợp), không dùng tên người thật.

## Cổng đang chạy (bằng chứng, không phải lời hứa)

| Kiểm | Ở đâu | Phạm vi |
|---|---|---|
| Chặn file staged > 1 MB (`COMMIT_GUARD_MAX_FILE_BYTES=1048576`) | `scripts/githooks/pre-commit`, `scripts/_commit-guard.sh` | mọi commit trên máy có `git config core.hooksPath scripts/githooks` |
| Chặn chuỗi giống khoá/token trong diff staged | cùng file, `COMMIT_GUARD_SECRET_RE` | như trên |
| Ảnh test sinh trong mã | ví dụ `apps/mobile/test/imaging/page_render_test.dart`, `apps/mobile/test/tool/scanner_benchmark_test.dart`, corpus `apps/mobile/tool/scanner_benchmark.dart` (`docs/benchmarks/README.md`) | test Flutter |
| UAT chỉ dùng tài liệu tổng hợp | `docs/ops/android-uat.md` | quy trình thủ công |

Hook pre-commit bỏ qua được bằng `--no-verify` và chỉ chạy trên máy đã bật `core.hooksPath`. **Chưa có**: quét PII
bằng regex/Presidio trên fixture trong CI, quét bí mật toàn lịch sử (gitleaks). Đây là thay đổi cổng CI, cần chủ repo duyệt
(xem `docs/THREAT-MODEL.md` §6).

## Tệp đã có trong repo được rà

- `docs/ops/evidence/p1-android-uat-2026-10-18/` — ảnh chụp màn hình và PDF của 3 trang tổng hợp (ghi "synthetic" trong
  `docs/ops/android-uat.md`). Rà ngày 2026-10-24: không có ảnh giấy tờ cá nhân khác trong repo ngoài icon/launch image của nền tảng
  (lệnh: `find . -path ./.git -prune -o -type f \( -name '*.jpg' -o -name '*.png' -o -name '*.pdf' -o -name '*.webp' \) -print`).

## Khi lỡ commit dữ liệu thật

Coi là sự cố bảo mật SEV1 theo `docs/ops/RUNBOOK.md` §5: không chỉ xoá commit; báo chủ repo, đánh giá nghĩa vụ thông báo,
làm sạch lịch sử chỉ khi chủ repo duyệt (ruleset cấm force-push `main`).
