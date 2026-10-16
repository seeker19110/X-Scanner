# Công việc: Triển khai ưu tiên XS-04 với APK UAT kiểm chứng được

- Work ID: 2026-10-16-android-uat-artifacts
- Yêu cầu / outcome: chủ repo yêu cầu triển khai theo ưu tiên báo cáo, cài toolchain, tự quyết kỹ thuật, chạy đủ gate và mở PR. Đợt đầu tạo APK UAT kiểm chứng được sau full gate.
- Trạng thái: Ready — full gate cục bộ/pre-commit PASS; PR #52 mở, chưa merge.
- Chủ trì / writer: phiên chính.
- Mức rủi ro / số PR: S (CI/config và tài liệu); một PR gồm nghiên cứu đang giữ cục bộ và phần triển khai XS-04 này. Một outcome nên phiên chính tự làm.
- Scope / non-goal: Flutter 3.47.7/Dart 3.13.5, JDK/Android SDK cục bộ; bundle APK debug/checksum/build SHA/PR head SHA/SDK metadata sau gate; hướng dẫn UAT. Không đổi source app, schema, dependency pub, settings repo, bật migration, release hoặc merge PR.
- Spec / goal / issue: báo cáo `docs/research/2026-10-16-upgrade-research.md` §6; XS-04; AC-9 spec P1 vẫn là UAT thủ công, chưa đóng từ artifact.
- Nhánh / base SHA / thời điểm reconcile: `chore/android-uat-artifacts` @ `cda650f` · 2026-10-16T10:27:47Z; fetch origin/main giữ nguyên base, 0 PR mở.

## Kế hoạch và phân công

1. Cài toolchain trong `/home/liend/.local/share/x-scanner`, kiểm checksum Flutter/Android CLI; dùng env riêng, không sửa Git global.
2. CI giữ cùng job/gate, thêm gói UAT sau gate xanh và action upload ghim SHA; chỉ upload năm file đã chọn.
3. Thêm runbook UAT, cập nhật README/CODEMAP/PROGRESS và giữ nghiên cứu trong cùng PR; không làm lại việc đã merge.
4. Chạy full gate, chạy đúng lệnh tạo bundle và kiểm checksum trên APK thật; kiểm YAML/action và tự review diff.
5. Commit/push nhánh riêng, mở PR đủ template/Work ID; kiểm CI đúng head và artifact, giữ PR mở để chủ repo review.

## Quyết định và bằng chứng

- Ngày 16/10, image 4.12.0 chưa đủ 7 ngày theo spec P1 §3/EX-1. Giữ W-104b từ 18/10 · loại nâng sớm không có ngoại lệ · bậc 1. Làm XS-04 tiếp theo như báo cáo cho phép khi ưu tiên trước đang chờ điều kiện.
- Chọn upload-artifact v7.0.2 (phát hành 07/10, Node 24), ref commit `cf430e030ddbb5b0abf93d22962f4752f3646cd9` kiểm qua GitHub API/action.yml · loại tag nổi và release mới hơn chưa đủ tuổi · bậc 1.
- Tách BUILD_COMMIT (checkout thực, merge SHA ở pull_request) và SOURCE_COMMIT (PR head) · loại gắn nhãn head cho binary build từ merge SHA · bậc 1. Thêm run_attempt trong tên artifact để rerun không trùng tên.
- Dùng cấu hình workflow và lệnh chuẩn install/git/sha256sum · loại script đóng gói riêng và dependency mới · bậc 2. Ngoại lệ TDD số 3: chỉ config thuần và tài liệu, không thêm logic ứng dụng; kiểm lệnh với APK thật và kiểm end-to-end qua artifact CI.
- Không có sudo không mật khẩu; cài JDK từ package Ubuntu vào thư mục riêng, cấu hình truststore từ CA hệ thống. Android CLI bị HTTP_PROXY/HTTPS_PROXY rỗng làm lỗi parse → chỉ unset các biến proxy trong tiến trình sdkmanager.
- Toolchain đã kiểm: Flutter 3.47.7 / Dart 3.13.5; OpenJDK 21.0.12.1; Android platform 36, Build Tools 36.0.0, NDK 28.2.13676358. `flutter doctor -v` xác nhận Android toolchain và mọi license đã được chấp nhận. Thiếu Chrome/Linux desktop là ngoài gate Android, không được dùng để tuyên bố hỗ trợ hai nền tảng đó.
- Lệnh người dùng `flutter`, `dart`, `java`, `javac`, `sdkmanager`, `adb` được thêm vào ~/.local/bin, wrapper nạp env riêng. Không ghi đè command có sẵn; không sửa Git toàn cục. Env bỏ biến proxy chỉ khi rỗng, giữ proxy có cấu hình.
- actionlint 1.7.12 kiểm workflow PASS; YAML và năm shell block parse được. Tám tài liệu thay đổi có 41 link nội bộ hợp lệ và không whitespace thừa.
- Build đầu cục bộ: APK debug đã tạo (163224305 byte); merged release manifest PASS allowlist permissions/exported và allowBackup=false. SDK tự bổ sung Platform 35/CMake 3.22.1 cho plugin. Full gate chưa kết luận khi mới build xong.
- Kiểm gói UAT bằng chính shell block đọc từ workflow trên APK thật: bốn checksum OK, BUILD_COMMIT/SOURCE_COMMIT khớp checkout cục bộ và FLUTTER.json xác nhận 3.47.7. Sửa một byte/sidecar SOURCE_COMMIT trong bundle thử → checksum FAIL đúng file; khôi phục → bốn OK. `apksigner verify --verbose` xác minh APK v2 signature, 1 signer.
- Lượt gate tiếp theo hoàn thành build/release manifest, analyze 0 issues, lint 47 checks và format 55 file/0 changed. Test adoption/manifest/hook đã chạy nhưng bị ngắt giữa hook suite khi phiên bị dừng; chưa tới Flutter test, không coi là full PASS. Chạy lại đủ gate từ đầu trên cache hiện có, log `gate-android-uat-final.log` ngoài repo.
- Lượt `gate-android-uat-final.log`: build/release manifest PASS, analyze 0 issues, format 55/0 changed, adoption 7/7, manifest self-test 10/10, hai hook suites và Flutter 546/546 PASS. Cổng tổng vẫn BLOCKED vì writer sửa hồ sơ/stage index khi gate đang chạy; không commit theo kết quả này. Đóng băng file/index cho lượt gate ổn định tiếp theo và chỉ commit sau PASS.
- Lượt ổn định `gate-android-uat-stable.log`: **PASS 4/4**, exit 0, Flutter **546/546**, build APK/release manifest PASS, analyze 0 issues, lint 47 checks, format 55/0 changed, adoption 7/7, manifest 10/10 và hai hook suites PASS. Context trước checkpoint: `cda650f310d326b612db4712503fdac0d8047108:b2968da5106c353b8297b59df2dd8521f7e67ed0:e2d854199ac1066f2a4057c9d1002ac6da8724e9`. Commit tiếp theo vẫn đi qua hook chạy gate trên snapshot đã cập nhật hồ sơ.
- Commit `3251652` được ghi sau pre-commit PASS 4/4, Flutter 546/546; đã push nhánh riêng và mở [PR #52](https://github.com/seeker19110/X-Scanner/pull/52), gắn vào chat. Không bật auto-merge hoặc merge. Checkpoint link PR đi trong cùng PR qua hook full gate trước khi ghi commit tài liệu; CI head cuối và artifact được đối chiếu trên PR khi bàn giao.

## Lần thử / blocker

- API Adoptium trả 403 một lần → dùng package OpenJDK 21 headless từ apt index hệ thống, không tải binary từ mirror không kiểm chứng.
- sdkmanager báo malformed proxy một lần → sửa môi trường tiến trình, không sửa proxy toàn hệ thống.
- Truststore PKCS12 tự dựng có cert nhưng Java SSL không nạp được anchor khi không có password; đổi sang JKS từ đúng CA hệ thống, SDK download/license check thành công; không tắt TLS verification.
- Lượt gate đầu bị ngắt trước APK và không trả kết quả đầy đủ khi môi trường phiên được cập nhật; không tính là PASS. Chạy lại gate với log riêng, dùng cache đã tải.
- Lượt sau bị ngắt ở test hooks; không có failure của source được kết luận từ việc này. Các tiến trình gate của X-Scanner đã dừng trước khi chạy lại; không dừng tác vụ repo khác trên máy.
- Một lần snapshot guard phát hiện thay đổi do writer trong lúc gate chạy; sửa bằng không ghi/stage gì trong lượt kiểm tra. Không bỏ guard hoặc dùng no-verify.
- Chưa có UAT AC-9 thực; không dùng kết quả test giả để đóng tiêu chí này.

## Bàn giao / bước tiếp theo

- Kiểm CI đúng head cuối của PR #52 và tải artifact để xác minh SHA/checksum; bàn giao PR mở. Bundle thử nằm ngoài repo ở `/home/liend/.local/share/x-scanner/uat-validation/x-scanner-uat`. AC-9 UAT thật và W-104b từ 18/10 vẫn mở.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- PR #52 đã mở, chưa merge; giữ working.md. Nghiệm thu phần chuẩn bị UAT theo bằng chứng gate/bundle; AC-9 không đóng từ artifact.

## Review và quyền merge bổ sung — 2026-10-16

- Chủ repo yêu cầu review kỹ PR #52, xử lý mọi vấn đề, merge khi đủ điều kiện, rồi nâng cấp tiếp theo ưu tiên báo cáo; quyền merge #52 được cấp trực tiếp trong phiên. Không cấp quyền release hay migration dữ liệu thật PR-4b.
- Reconcile: origin/main vẫn cda650f, PR #52 head 9b5572b, CI success, không comment/review tồn đọng; working tree sạch trước checkpoint.
- Kế hoạch: review độc lập ở worktree chỉ đọc, phiên chính review bảo mật/luồng artifact và chạy lại full gate; sửa nếu có finding được chứng minh; squash merge đúng head sau mọi cổng; reconcile hồ sơ vào PR ưu tiên kế tiếp.
- Phân công: reviewer không sửa file/không commit/merge; worktree riêng pr52-review ở head 9b5572b. Phiên chính là writer duy nhất của hồ sơ tổng, chịu trách nhiệm gate và merge. Các đơn vị PR phụ thuộc chạy tuần tự theo §3c.
- Review độc lập `review_pr52` trên worktree riêng và review phiên chính: `review-findings/1` findings=[]; đã đối chiếu toàn bộ diff, TRAPS, source action tại SHA ghim, env/shell, thứ tự gate/upload, giới hạn EX-1/AC-9. Không có finding correctness/security phải sửa.
- Tái kiểm gói CI run 38918903197 trên head 9b5572b trong phiên review: bốn checksum OK, metadata khớp head/Flutter 3.47.7, apksigner v2 hợp lệ; không lấy lời khai lượt trước làm bằng chứng mới.
- Full gate trong phiên review: PASS 4/4, Flutter 546/546, analyze 0 issues, format 55/0 changed, release manifest PASS; adoption 7/7, manifest self-test 10/10, hai hook suites PASS. Log đầy đủ ngoài repo: pr52-review-gate.log; các ca âm manifest/secret/giá trị -1 là test dự kiến, không phải lỗi cổng. Commit checkpoint vẫn đi qua pre-commit gate, CI sẽ kiểm head mới trước merge.
