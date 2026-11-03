# Công việc: Giữ một editor khi mở/tạo tài liệu

- Work ID: 2026-11-03-single-editor-guard
- Trạng thái: Root đã review diff; đang full gate trước commit/PR.
- Mức: S bugfix AUD-DATA-001; candidate976c71d, nhánh nguồn codex/single-editor-guard, PR branch codex/review-single-editor-guard từ main d22e622.
- Quyền: root duyệt kế hoạch trong hồ sơ complete-harden theo yêu cầu /complete của chủ repo.
- Writer: complete_audit_security; chỉ library_screen.dart, library_screen_test.dart và hồ sơ này. Root sở hữu docs chung/PR/merge.
- Outcome: một guard giữ quyền mở/tạo suốt route và refresh; callback lặp không dựng editor thứ hai. Không thay storage/schema/CAS.
- Bằng chứng trước sửa: widget audit opened2≠1; VM dùng DocumentStore thật xác nhận stale snapshot A ghi sau A+B xoá original B (fixture tổng hợp).
- TDD: thêm hồi quy giữ callback InkWell/Semantics/create, chạy RED trước source; sửa tối thiểu rồi chạy toàn suite library_screen_test.dart.
- Không chạy full gate/commit/push; root nghiệm thu và tích hợp. Giữ working.md đến DoD và merge thật.

- RED trên source chưa sửa: `flutter test test/ui/library_screen_test.dart --plain-name AUD-DATA-001` exit1, 3 fail (hai route thay vì một với InkWell/Semantics; hai tài liệu khi gọi create lặp); log `/tmp/complete-security-audit/single-editor-red-final.log`.
- Sửa: một ownership helper cho mở/tạo, giữ qua Navigator và refresh; finally chỉ setState khi mounted. Không đổi renderer/controller/storage/schema.
- GREEN: toàn `flutter test test/ui/library_screen_test.dart` exit0,14/14 (11 cũ+3 hồi quy); `dart format` hai file không còn đổi; log `/tmp/complete-security-audit/single-editor-green.log`. Hồi quy còn kiểm bỏ callback khi route đang mở, mở lại sau refresh và callback sau unmount. Một lượt giữa chừng vấp finder sau pop trước frame; predicate chờ finder xuất hiện, không thay assertion duplicate count.
- Bàn giao: source+test+hồ sơ trong index, chỉ3 file; không full gate/commit/push. Root xác nhận main d22e622 có tree trùng candidate976c71d và sẽ nhập patch vào primary checkout, chạy full gate/CI rồi PR. Test slot và writer scope đã trả cho root.

Root nhập staged patch vào primary để dùng lại build; candidate976c71d và maind22e622 tree-identical (git diff exit0). Cùng PR có CODEMAP/TRAPS(F084)/PROGRESS. Reviewer độc lập đang kiểm; chưa merge.

Full gate lần1: keyboard_test chỉ chờ tiêu đề sau pop, FAB còn disabled do refresh chưa hoàn tất (Tab không tới). Sửa predicate test chờ FAB.onPressed != null, giữ nguyên Enter/Tab/Escape assertions; không nới app guard/coverage. Root mở rộng phạm vi thêm keyboard_test.dart sau RED tích hợp thật.

Root final full gate PASS4/4:849Flutter,11JVM(0fail/errors/skips),38repo; analyzer0, format70/0, licenses142, coverage96.29/92.37, APK234270742<245759848 và16KB/manifest PASS. Reviewer-alt max approve source và keyboard wait (không giả runtime model superiority). Log complete-single-editor-full-gate-final.log; native commit hook sẽ kiểm lại.
