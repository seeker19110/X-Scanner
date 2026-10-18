# Công việc: W-104b — nghiên cứu bản vá decoder image

- Work ID: 2026-10-18-w104b-decoder-research
- Yêu cầu / outcome: research-only contract cho W-104b/F-004 theo phân công root; kiểm nguồn Pub và diff archive trước khi root duyệt triển khai nâng decoder.
- Trạng thái: Ready — static package maintenance audit đã bàn giao; root giữ nghiệm thu và cổng triển khai. Chưa sửa app/dependency/test hoặc chạy cổng.
- Chủ trì / writer: subagent w104b_research; chỉ ghi hồ sơ này trong worktree riêng; root giữ spec/plan/authority và tích hợp.
- Mức rủi ro / số PR: nghiên cứu cho một PR W-104b; root phân loại thay đổi thực thi. Không tự tạo PR.
- Scope / non-goal: chính thức Pub metadata/age/hash/license/publisher/SDK, toàn packaged lib diff 4.10.1→4.12.0, API reachable JPEG/PNG/WebP và thiết kế regression tổng hợp có chặn tài nguyên. Không production/test/pubspec/lock/config edits; không Flutter/compiler/test/gate/commit/push/merge/nested agent; không dữ liệu thật/OCR.
- Spec / goal / issue: docs/ops/COMPLETION-PLAN.md W-104b/F-004; docs/ops/supply-chain-exceptions.md EX-1; docs/research/2026-10-16-upgrade-research.md §6; docs/ops/dependency-updates.md; .claude/commands/deps-upgrade.md.
- Nhánh / base SHA / thời điểm reconcile: `codex/w104b-decoder` @ `314a296` · 2026-10-18T01:20:04Z

## Kế hoạch và phân công

1. Đọc luật, PROJECT/PROGRESS, hồ sơ XS07b và W104/F004/EX1; tạo hồ sơ trước nghiên cứu.
2. Xác minh UTC và Pub API sống; lưu archive/metadata ngoài repo, hash đối chiếu.
3. Đọc toàn changelog và diff lib được đóng gói; trace reachable decoder và trust boundaries hiện tại.
4. Đề xuất AC/tests RED/GREEN và instance caps cho root; bàn giao nguồn/checksum/giới hạn, giữ working.

## Quyết định và bằng chứng

- UTC tool 2026-10-18 01:20:16 UTC; mốc lịch sử EX1 2026-10-18T00:28:00.512637Z đã qua, nhưng bản đích vẫn cần Pub metadata sống trong đợt này.
- Đã đọc CLAUDE/PROJECT/PROGRESS/standard-delivery, nghiên cứu gốc11Oct + nâng cấp16Oct, dependency-updates và deps-upgrade. Gói image là ngoại lệ cần quy trình chủ động kèm regression; không áp quyền tự merge Dependabot patch/minor cho nó.
- Grep cổng hiện tại: page_render_test đã có byte/header ceiling, exact ceiling, unsupported formats và animated WebP guard; isolate_budget_test có kill/heartbeat. Không tái tạo các hàng rào này. F004 trong audit ghi PoC EXIF treo và PNG inflate2GB; không chạy lại fixture nguy hiểm đó.

## Lần thử / blocker

- Chưa thực thi test hoặc compiler, đúng contract research-only. Một lần in web-result sai kiểu tạo output dài bị cắt; không dùng output bị cắt làm bằng chứng đọc đủ, chuyển sang metadata/archive lưu riêng với hash và diff từng phần.

## Bàn giao / bước tiếp theo

- Checkpoint đầu: dự định tải Pub/archive rồi bàn giao. Checkpoint cuối bên dưới thay bước chờ này: static audit đã Ready, root giữ spec/PLAN và thực thi.

## Checkpoint static package maintenance audit — 2026-10-18

- Root thu hẹp phân công sang **chỉ audit tĩnh thư viện** sau một lỗi safety tự động ở lượt trước. Phần regression ứng dụng do root và reviewer khác giữ; không thiết kế/tạo/chạy fixture ảnh lỗi trong phạm vi tiếp nối này.
- Root đã nhận đường dẫn nguồn và kết quả audit qua collaboration. Các file root tạo trong cùng worktree (spec/hồ sơ tổng) thuộc root; worker chỉ ghi hồ sơ này. Không commit/push/merge.

### Metadata và tính nguyên vẹn

API sống được tải lúc `2026-10-18T01:20:26.426543+00:00`:

| Mục | Kết quả thực tế |
| --- | --- |
| Bản đích | [Pub image 4.12.0](https://pub.dev/api/packages/image/versions/4.12.0), đồng thời là latest trong [API package](https://pub.dev/api/packages/image) lúc tra |
| Tuổi | Published `2026-10-11T00:28:00.512637Z`; đủ 7×24 giờ tại `2026-10-18T00:28:00.512637Z`, trước thời điểm tra |
| Archive cũ | `image-4.10.1.tar.gz`, SHA256 `a1e7f4951e538a568e14b856702afc9ae1d2f4b202daced8d22c1b9cd211ce89`, khớp API và lock hiện tại |
| Archive mới | `image-4.12.0.tar.gz`, SHA256 `89ed75b2f8231fe676808c5564f9590d728024ded7ac782a7ed8474f1c95b72a`, khớp API; 527636 bytes |
| Source upstream | Tag [v4.12.0](https://github.com/brendan-duncan/image/tree/v4.12.0) trỏ `d9e495c7c3bed862ef7d52698e64e25932877ecf`; **396/396** file `lib/` của archive khớp Git blob SHA chính xác, 0 mismatch, không cần chuẩn hóa CRLF |
| License | MIT trong cả hai archive; byte-identical SHA256 `f3c17da84e0780e1c334325c73098257c32221d62498ed55ef3c1361904925aa` |
| Publisher | [API publisher hiện tại](https://pub.dev/api/packages/image/publisher) trả `loki3d.com`; API này không cung cấp lịch sử publisher từng phiên bản, không suy ra chứng thực lịch sử từ nó |
| SDK | Cả hai bản `sdk: ^3.0.0`, thoả Dart3.13.5 đi cùng Flutter3.47.7; không có Flutter constraint riêng, không yêu cầu đổi SDK |
| Native/network | Không có thư mục `android/` hoặc `ios/` trong hai archive. Soát diff không thấy thêm HTTP/socket/process launch; grep pattern là kiểm phụ, không tuyên bố full security audit |

**Đính chính được giữ lại:** thông báo đầu tiên nêu constraint `archive` tăng `^4.0.9`→`^4.5.0` nên *có thể* cần đổi bắc cầu. Đọc lock thực tại314a296 xác minh đã ghim **archive4.5.1**, SHA256 `f773153144ce0456ae77d96bd247f2efd58efe4f3e5ad42616d0385c031aea11`; constraint mới chấp nhận bản đó. Không cần chủ động nâng archive. Solver/lock diff thực tế vẫn phải do root kiểm sau khi resolve.

[API archive4.5.1](https://pub.dev/api/packages/archive/versions/4.5.1) tải mới và archive hash khớp lock; SDK `>=3.0.0 <4.0.0`, publisher hiện tại `loki3d.com`, MIT. Bản này phát hành `2026-10-11T14:33:40.521718Z`, chưa đủ 7 ngày lúc tra01:21Z nhưng **đã tồn tại trong lock**, không phải dependency được nâng trong W104b. Nếu solver đổi thêm package thì mỗi package mới phải qua lại policy1–4, không dùng audit này thay thế.

### Phạm vi mã đã đọc

- Inventory **151 file lib thay đổi**: formats75, image23, color12, filter18, transform10, util6, draw3, exif2, font1, command1. Không đổi public export file `lib/image.dart`.
- Đọc toàn CHANGELOG phần 4.10.2/4.11.0/4.11.1/4.12.0; diff lib đầy đủ được lưu. Đọc hunks từng nhóm, mở full call flow reachable JPEG/PNG/WebP, EXIF, pixel/setters, rotation/resize và PNG/JPEG encoder; các nhóm không gọi từ app được soát changed-code hunks và inventory. Không coi changelog là bằng chứng runtime.
- JPEG: header read không còn chuẩn bị pixel coefficients; decoder nhận instance `maxPixels`; baseline dùng MCU bands và writer chung, progressive dùng coefficients phẳng; có restart fallback khi metadata/scan đến muộn. `scale` mặc định1, không bật tính năng scaled decode trong outcome này.
- PNG: instance cap, input rows qua lazy stream, xử lý uint8/uint16 và grayscale-alpha theo storage đúng, PNG encoding row-wise với IDAT/fdAT chunks. `cICP.colourPrimaries` đổi thành `colorPrimaries`; app không dùng API này.
- WebP: cap là thuộc tính instance, không phải named constructor; các đường lossy/lossless đổi đọc/ghi trực tiếp buffer, giữ ICC name hợp lệ; animation aggregate budget tồn tại ở full-animation decode. App dùng frame0 và vẫn từ chối animated WebP.
- Color/Pixel/ImageData: thay đổi hai kênh thành gray+alpha nhất quán, `setRgb` giữ alpha, `setRgba` ghi `a` vào alpha. `copyRotate` byte path nay giữ hai kênh. Existing XS07b workaround vẫn cho kết quả đúng vì truyền alpha ở cảg/a, nhưng comment mô tả setter cũ phải được đối chiếu khi root nâng.
- JPEG encoding: YUV fast path RGB(A), blend vào locals thay vì mutate source; hai kênh tiếp tục đường fallback và chỉ blend khi pixel.length>3 như bản cũ. Không lấy thay đổi này làm quyền tự đổi chính sách alpha JPEG.
- Transforms: rotation/flip byte paths, orientation3 sửa hàng giữa chiều cao lẻ, copyResize gộp EXIF mapping; in-place resize có nhánh tránh overlap và cache cubic rows. App dùng copyResize average, không in-place resize.
- Phần còn lại: decoder bounds/error wrapping cho định dạng app không nhận; encoder empty-image checks; filters/LUT/ring buffers và scratch reuse; flood fill iterative; font limits; ICC/inflate helper; output buffer growth. Không mở các tính năng này trong app.
- Đọc các phần liên quan của archive4.5.1: `ZLibDecoder`, native/web chunk decoder, `InputDecodeStream`, cùng CHANGELOG4.4.0/4.5.0/4.5.1. Lazy input là window/chunk consumption, **không** tương đương hard RAM quota theo maxPixels; không claim đúng bộ nhớ bằng kích thước output.

### Tương thích điểm gọi và giới hạn nghiệm thu

`rg` xác minh import `package:image/` production chỉ tại `lib/imaging/page_render.dart`, và tooling tại `tool/scanner_benchmark.dart`; các import còn lại trong test. Không có consumer `JpegComponent.blocks` hoặc `PngCicpData.colourPrimaries`, nên hai breaking API nội bộ nêu trong changelog không đòi thay callsite app hiện tại.

- Cần truyền cap trước `startDecode` theo đúng từng API, giữ manual header check; tránh dựa vào static default. Upstream quy ước cap<=0 là tắt giới hạn khác contract app; root xử lý biên app trước decode.
- Header inspection PNG/WebP nay có thể throw `ImageException` khi cap bị vượt; public nullable `imageSizeOf` và callers cần được root giữ đúng contract. Không dùng blanket catch mới nếu không có căn cứ.
- PNG/JPEG byte stream có thể khác vì encoder thay đổi; so dimensions/pixels/orientation/source ownership và file mở được, không lấy byte snapshot của codec cũ làm chuẩn chất lượng mặc định. Existing identity/gray-alpha regressions và benchmark tooling cần chạy trên dependency mới.
- Các số tăng tốc/giảm RAM trong changelog là upstream claims, chưa đo trên X-Scanner; host/device/corpus baseline không được relabel sau đổi binary/lock.
- Audit tĩnh không chứng minh build, gate, regression, device camera/share/iOS/release hoặc đóng EX1; tất cả còn do root chạy và đối chiếu head thật.

### Đối chiếu nguồn ngoài

| Đã có và sâu hơn | Quyết định |
| --- | --- |
| App nhận JPEG/PNG/WebP theo nội dung, 64MiB, isolate budget có kill/chờ exit, original ownership | Giữ; không thay bằng chỉ upstream default cap hoặc lỗi wrapper |

| Đã có nhưng nông hơn | Chỉ điểm cần nối |
| --- | --- |
| Manual header pixel cap đã có, upstream mới thêm cap instance ở allocation path | Root nối đúng instance API, giữ guard hiện có và regression; không đổi global |
| Workaround gray-alpha hiện có, upstream mới sửa setters/rotation | Review comment/code theo dependency mới, giữ tests; không áp thêm alpha compositing |

| Chưa có / chưa cần | Điều kiện xem lại |
| --- | --- |
| JPEG scale1/2/4/8 chưa dùng | XS07 outcome riêng sau khi W104b hoàn tất, có baseline/geometry/quality evidence; không bật trong dependency PR |
| Các decoder/filter/command API ngoài call graph hiện tại | Chưa cần; xem lại chỉ khi spec sản phẩm mới duyệt consumer tương ứng |

### Artifact bàn giao (ngoài Git)

Thư mục `/home/liend/.local/share/x-scanner/w104b-research-evidence-20261018/` giữ metadata JSON, ba archive và source giải nén. `summary.json` giữ URLs/checksums/thời điểm tra; `static-audit-proof.json` giữ inventory/tag hash/network-pattern scan/license proof. `inventory.json` SHA256 `e69da5119c117bb945c110ae91d968110c0c5781ffa372cbdbb4993caef409d9`; `lib-diff.txt` SHA256 `8acc495c7de3bfae5473a17e7211bfdeab01efce376cf9cf7334f142e69ed4e9` (14047 dòng). Các file `*-review.diff` chia nhóm và `*-changes.diff` bỏ context/comment để đọc code; bản diff gốc giữ nguyên.

Snapshot worker trước bàn giao: app pubspec SHA256 `56f92848a610321f6e06f59c85612bfa2c0c01d46c86273fa5459bcafc70e12c`, lock `523343cede1f4cd599148238954824a887f17fcd239998d461221ebebe687ea6`, page_render `4d7e682fb98e7bedcf1385add0a804686048f2514e8dd2c10048cc12bd4c4135`, page_render_test `88a3c3ff382e49e775368e1f7e4910c7e3949b52f272cb8bb65c179028e1b89b`, tất cả khớp baseline314a296. Không chạy Flutter/compiler/test/gate và không có kết luận RED/GREEN từ worker này.

**Bước tiếp theo:** root đọc metadata/audit, nghiệm thu scope đã thu hẹp và triển khai theo spec/PLAN của root; worker dừng ghi tại hồ sơ này. Giữ working.md cho đến khi root chốt evidence và PR thực tế.

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

- Chưa Done; root nghiệm thu research rồi đưa hồ sơ vào PR thích hợp. Không có claim RED/GREEN/gate/CI/merge từ nghiên cứu này.
