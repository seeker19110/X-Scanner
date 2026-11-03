# Goal — cập nhật khung và xử lý phát hiện bảo mật CI

| Thuộc tính | Giá trị |
|---|---|
| Goal ID | 2026-11-03-autopilot-hardening |
| State | ACTIVE — maintenance đã merge; chủ repo yêu cầu tiếp /complete |
| Owner | Chủ repo; root điều phối, security worker worktree riêng |
| Base đã reconcile | 2f9eb53e810b84ef71b13ea76830a8ffd999edbd, main sau #74/#73/#76/#77/#78 |
| Quyền | Sửa/research/spec/branch/PR và gate trong scope; Chủ repo duyệt merge #76 → #77 → #78 → #79 theo L1 |
| Ngân sách | Phiên /autopilot hiện tại, không paid API; không chạy hai Gradle gate cùng lúc trên host 6 GB |

## Outcome và DoD

Cập nhật stable X-Templates 3.29.0, giữ gate/quyền X-Scanner và sửa các lỗi tích hợp có test RED trước. Xử lý GHSA-xxph-c9ww-hj94 vừa lộ trên CI bằng bản Guava đã vá, PR dependency riêng theo VULN-SLA; không thêm ngoại lệ để xanh. Mỗi slice S có hồ sơ riêng, không có tính năng sản phẩm mới cần spec M/L.

DoD của goal: hai outcome có PR riêng được review, full gate local và CI đúng head; Guava scan không còn finding không được xử lý; releaseRuntimeClasspath của app không đổi; source provenance/overlay/lock/license/docs cập nhật; merge chỉ do owner theo L1 và chính sách hàng đợi. Không đồng nghĩa Project Complete: W-602/F-078 UAT thư viện, khung pháp lý/license sản phẩm/phát hành vẫn chờ quyết định riêng.

## Slices và hợp đồng

| Slice | Phạm vi | PR / state | Writer / files |
|---|---|---|---|
| S1 | X-Templates3.29.0 + F081/F082 + toolchain | #73 merged d22e622, head976c71d full gate và all CI xanh | root, vendor/harness/docs; maintenance Complete |
| S2 | GHSA-xxph-c9ww-hj94, Guava build tools33.7.2 | #74 merged5a8ecad, head5e076d5 gate/OSV/all CI xanh, runtime graph unchanged | guava_security và root; maintenance Complete |

Root sở hữu PROGRESS/CODEMAP/CHANGELOG/goal; worker không sửa các file đó, không push/PR/merge. Không có hai writer cùng file, không chạy gate hai worktree đồng thời. Root review diff + kiểm độc lập trước PR. Discovery này không cấp quyền merge, không tự đổi FIFO; owner quyết thứ tự khi cần security dependency đi trước PR khung.

## Research và rủi ro

- Nguồn chính: https://github.com/google/guava/security/advisories/GHSA-xxph-c9ww-hj94 ; bản vá 33.7.2. CVSS3 upstream Moderate 5.9; GitHub advisory database/OSV dùng CVSS4 High 8.2. SLA dự án theo OSV.
- CI #73 run 41489001047, job 125426732249: 4 entry Guava affected (3 version trong app lock + 1 entry classpath settings); finding không do update framework thay dependency.
- Không coi build-classpath finding là app runtime exploit: cần graph/artifact chứng minh phạm vi. Không chạy payload khai thác gây OOM; OSV RED và actual resolution đủ cho thay đổi config dependency.
- UAT đã thử Windows WHPX (usable) nhưng hai lần thiếu chỗ tạo userdata. Chờ operator cấp ≥8 GB trống trên ổ emulator hoặc thiết bị Android; không đổi quyền host. Bằng chứng: docs/work/2026-11-03-xs09-android-uat/working.md.

## Current truth

Hai maintenance outcome đã merge theo lệnh owner03Nov, không waiver Guava: #74/5a8ecad rồi #73/d22e622, fresh gates và all CI xanh. /complete đang ở PLAN-harden-2026-11-03.md: PR #76, #77 và #78 đã merge, main `2f9eb53e810b84ef71b13ea76830a8ffd999edbd`. Gate và CI tích hợp #78 qua 851 Flutter, 11 JVM và 38 repository. Coverage 96.31% dòng và 92.41% nhánh.

Phase/audit PR#79 khai harden/format/coverage thật,13 nhóm được rà. Sổ audit ghi bốn phát hiện đã sửa trên main. Checkpoint trước tích hợp thiếu E2E. Emulator đã boot sau khi chủ repo giải phóng dung lượng. Cần APK đúng SHA main, UAT, sàn E2E và signoff.

## Operator authorization và reconcile — 2026-11-03

Chủ repo yêu cầu merge rồi chuyển /complete; #74 merged 5a8ecada2ecb6b0b86807fb2b5f2d09ee9e1d8de sau fresh gate và OSV. #73 đang tích hợp main mới, giữ cả hai phía xung đột docs; cần fresh gate/CI trên head tích hợp trước merge. Quyền phase-entry xt.yaml theo /complete đã được cấp; release/signing/dữ liệu thật vẫn ngoài quyền. Ổ C đo lại2573086720 byte, ADB5039 rỗng; UAT chưa được chứng minh.

03Nov scope nối /complete: #74 merged5a8ecad, #73 mergedd22e622 sau fresh gate/OSV và all CI green; DoD maintenance đạt. Tiếp PLAN-harden và audit13 nhóm với3 repair PR disjoint; DoD phần nối là fixes main+strict audit/floor, không gồm cấp quyền release hay chọn license. E2E/thiết bị và owner/legal/signoff còn mở, không Project Complete.
