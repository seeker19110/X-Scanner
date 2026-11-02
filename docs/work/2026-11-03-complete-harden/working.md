# Công việc: /complete — chuyển harden và audit có bằng chứng

- Work ID: 2026-11-03-complete-harden
- Trạng thái: /complete active; #74/#73 merged, repair PR#76/#77/#78 prepared; T201 full gate exit0, T202 audit schema exit0. Thiết bị/signoff chưa đạt; không Project Complete.
- Yêu cầu: chủ repo ngày03/11 "xong rồi merge chuyển qua pha /complete"; chuyển batch cũ bằng CLI stop→init (lưu state/verified, không force/khai done khi E2E còn đỏ).
- Quyền: merge #74 rồi #73 theo phụ thuộc và mở pha harden; không release/signing/cloud/secret/license selection/xoá dữ liệu thật.
- Mức: điều phối nhiều PR maintenance S, không tính năng mới; giữ nguyên approved P1/XS09, không áp roadmap advisory.
- Base: main5a8ecada2ecb6b0b86807fb2b5f2d09ee9e1d8de (#74); candidate#73 976c71d9b2a05e56dbfeb65229ca2c2a6242f595.
## Kế hoạch, hợp đồng và quyết định

1. #74 fresh gate846 Flutter/11JVM/34repo + pinnedOSV exit0, merged5a8ecad theo expected head. #73 giữ cả hai phía 4 xung đột docs; integrated full gate và hook PASS846Flutter/11JVM/38repo, CI còn chờ head976c71d.
2. /audit full theo schema3.29 vì chưa có AUDIT-STATUS.md; bảo tồn sổ COMPREHENSIVE-AUDIT-STATUS.md F001–F083, không xoá lịch sử. DATA áp dụng filesystem migration dù autodetect SQL gợi ý N/A.
3. Ba reviewer chỉ đọc, ba worktree riêng, candidate976c71d: security(SEC/DEP/CI/CFG), code(ARCH/CODE/TEST/PERF), product(A11Y/DATA/XFEAT/DOC/HAR). Không nested agent; root full gate/gitleaks/OSV; heavy Flutter/Gradle chỉ một lượt trên host.
4. Mỗi phát hiện đỏ/cam cần verifier độc lập trước sửa; test RED giữ lại rồi sửa tối thiểu. Source app bugfix PR riêng, writer/file hợp đồng riêng; root giữ docs/goals/audit/PROGRESS/phase config. Không nới gate hay dùng widget tests làm device E2E.
5. Ưu tiên đúng/bảo toàn byte trước thứ tự hình thức: nếu xác nhận mất ảnh do nhiều editor, sửa guard UI trước metadata harden; không thêm CAS/schema khi contract vốn chỉ một editor. Duyệt theo ủy quyền §3d, không phải cấp quyền sửa dữ liệu thật.
6. Phase config tái sử dụng Dart format-check và test+coverage thresholds đang có. E2E/attack/perf chưa có số đo/công cụ phù hợp sẽ ghi đúng trạng thái thiếu; không lệnh no-op, không giả xanh, không kết luận release GO.
## Bằng chứng và giới hạn
- Gitleaks8.30.1 full history --all --redact exit0:162 commits/~14.51MB/no leaks; log complete-gitleaks-all.log user-local. Pinned OSV trên cây tích hợp exit0, giữ đúng2 exceptions có hạn đã có.
- Windows C đo lại2573086720 byte; Windows ADB5037/5039 và Linux ADB đều không device. WHPX usable nhưng không boot lại khi thiếu dung lượng; P1 originals/AVD giữ nguyên. W602/F078 vẫn mở.
- Audit đang xác minh: route mở lặp dẫn stale snapshot; giữ controller/cache sau đóng; cap manifest trong migration. Không sửa source trước khi bằng chứng/plan được chốt, không gọi suy luận là heap/OOM đo được.
- Scope không gồm Dependabot#72, đổi ruleset/scheduler/auto-merge, cấp quyền KVM, chọn giấy phép hay phát hành. Sổ owner/device/legal47 MUST không được tự tick hoàn tất.
## Kế hoạch sửa tự duyệt sau xác minh — 2026-11-03
- D-009 sửa ba slice theo bằng chứng/verifier/gate chi tiết tại AUDIT-REPORT-2026-11-03.md (canonical, giữ lịch sử F001–F083); UI guard không CAS/schema, owner release sau idle/identity, UTF8 cap trước write và finite corners. Mỗi fix test RED trước, file/worktree disjoint, root docs/gates, không nested/parallel Flutter/Gradle.
