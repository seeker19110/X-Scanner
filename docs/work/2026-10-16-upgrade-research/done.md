# Công việc: Nghiên cứu nâng cấp X-Scanner từ mã nguồn, repo sở hữu và nguồn chính thức

- Work ID: 2026-10-16-upgrade-research
- Yêu cầu / outcome: chủ repo yêu cầu pull và nghiên cứu nâng cấp từ repo sở hữu và internet. Đầu ra: hiện trạng đã kiểm, đối chiếu nguồn ngoài, thứ tự nâng cấp và tiêu chí nghiệm thu có thể triển khai tiếp.
- Trạng thái: Done — nghiên cứu và XS-04 đã vào PR #52, squash merged f753933; nghiên cứu ngoài scope giữ ADVISORY.
- Chủ trì / writer: phiên chính.
- Mức rủi ro / số PR: S, chỉ tài liệu; một đơn vị thay đổi tài liệu, phiên chính tự làm.
- Scope / non-goal: đọc mã/test/CI hiện có, repo công khai của chủ sở hữu và tài liệu chính thức; lưu báo cáo trong docs/research. Không sửa source, nâng dependency, bật migration PR-4b, đổi settings, merge, release hay tạo lịch.
- Spec / goal / issue: không cần spec cho nghiên cứu mức S; nối kế hoạch `docs/plans/2026-10-12-comprehensive-development-plan.md` bằng ID XS hiện có.
- Nhánh / base SHA / thời điểm reconcile: `docs/upgrade-research-2026-10-16` @ `cda650f` · 2026-10-16T10:16:25Z

## Kế hoạch và phân công

1. Đọc CLAUDE/AGENTS, PROJECT/PROGRESS, hai hồ sơ P1 đang mở và lịch sử XS-09 PR-4a; đối chiếu Git/PR/CI.
2. Lần main → controller → storage/imaging/export và test tương ứng; phân biệt code đang chạy với code chưa nối.
3. Đọc stored, X-Templates, projects-template, X-Studio, dhcb; kiểm lại các gợi ý bằng cổng và nguồn upstream.
4. Lưu `docs/research/2026-10-16-upgrade-research.md`, thêm đường dẫn README/PROGRESS; review sự kiện, nguồn, link và diff.
5. Kiểm tra repo chạy được tại đây; ghi rõ giới hạn full gate. Không commit khi gate chưa xanh.

## Quyết định và bằng chứng

- Thư mục ban đầu rỗng, không có .git → clone đúng repo, rồi `git pull --ff-only`: Already up to date, main `cda650f310d326b612db4712503fdac0d8047108`; đặt core.hooksPath cục bộ, không đổi Git toàn cục.
- Chọn một báo cáo delta có bằng chứng · loại tự triển khai roadmap/migration từ yêu cầu nghiên cứu · bậc 1 + 2 (giữ phạm vi và tránh thay đổi dữ liệu thật; tái sử dụng ID XS).
- Chọn giữ Flutter/JSON/files hiện có · loại nhập mặc định React Native/backend/SQLite từ khung khác · bậc 2 (chưa có số đo buộc đổi stack).
- GitHub API: 0 PR mở; CI Repository checks trên đúng base thành công, run 38350895593; main.protected=false, rules/branches/main=[] (ảnh chụp trạng thái 2026-10-16, không thay settings).
- Pub API + archive image 4.12.0: phát hành 2026-10-11T00:28:00.512637Z; SHA-256 archive khớp `89ed75b2f8231fe676808c5564f9590d728024ded7ac782a7ed8474f1c95b72a`. Không cài/nâng package.
- OSV querybatch: 86 package hosted của pubspec.lock, 86 kết quả, 0 advisory trả về; không suy ra decoder an toàn (F-004 đã có bằng chứng riêng).
- Đã lưu báo cáo hiện trạng, năm repo sở hữu, lựa chọn scanner/OCR/depth, ba bảng đối chiếu adoption, thứ tự XS và protocol benchmark; README/PROGRESS có đường dẫn. Không thay đổi source hoặc lockfile.
- Kiểm repo: adoption 7/7, syntax/config 47, manifest self-test 10/10, hai bộ hook PASS. Negative manifest test in dòng FAIL có chủ đích; exit của self-test là 0.
- Review link/diff: 37 đích link nội bộ tồn tại trong bốn file, ba bảng adoption/đính chính/giới hạn kiểm chứng có mặt, không có ID nguồn web nội bộ trong báo cáo. Kiểm lại whitespace cho cả file mới trước bàn giao.
- Chuyển sang triển khai cùng ngày theo yêu cầu chủ repo: hồ sơ `2026-10-16-android-uat-artifacts` quản lý cài toolchain, full gate và PR chung. Các kết quả thiếu Flutter bên dưới thuộc thời điểm nghiên cứu, không phải trạng thái toolchain sau khi cài.

## Lần thử / blocker

- `dev-task.sh doctor` và `dev-task.sh gate` trả exit 2: thiếu flutter. Chưa chạy build/analyze/format/Flutter tests tại máy này; CI cũ chỉ chứng minh base.
- Chưa có quyền mới để bật migration PR-4b trên dữ liệu thật hoặc repository settings; nghiên cứu không phụ thuộc hai việc này.

## Bàn giao / bước tiếp theo

- Nối `docs/work/2026-10-16-android-uat-artifacts/done.md` trên nhánh `chore/android-uat-artifacts`; nghiên cứu được đưa vào cùng PR để không làm rơi thay đổi đang giữ cục bộ. Không đóng hồ sơ trước khi PR merge thật.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Nghiên cứu đã vào commit `3251652` và [PR #52](https://github.com/seeker19110/X-Scanner/pull/52), chưa merge; giữ working.md. Hoàn tất nghiên cứu không đồng nghĩa P1 đã qua UAT hay roadmap được duyệt triển khai.
- Tiêu chí nghiên cứu đạt: baseline/CI được đối chiếu, nguồn sở hữu và upstream được chỉ rõ, khuyến nghị nối ID cũ và có tiêu chí đo, không biến giả thuyết thành kết quả thực nghiệm. Phiên chính tự review theo §3d ngày 2026-10-16.

## Reconcile sau merge — 2026-10-16

- Chủ repo cấp quyền merge #52 trực tiếp; [PR #52](https://github.com/seeker19110/X-Scanner/pull/52) MERGED lúc 2026-10-16T15:18:22Z, squash SHA `f753933ae9f75c580266d52a585b4af18fc34acb`; main đã fast-forward và đối chiếu đúng SHA.
- Review độc lập và phiên chính không finding tồn đọng; local gate/pre-commit PASS 4/4 và Flutter 546/546. CI head 7974fe5, [run 38921846662](https://github.com/seeker19110/X-Scanner/actions/runs/38921846662), SUCCESS; artifact 12054733682 được upload.
- DoD của nghiên cứu/chuẩn bị gói UAT đạt; rename done.md trong PR XS-05 theo contract §3e. P1 AC-9 trên thiết bị, EX-1 và PR-4b vẫn mở trong hồ sơ riêng. Không phát hành hoặc bật auto-merge.
