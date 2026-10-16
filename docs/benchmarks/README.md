# XS-06a — corpus tổng hợp và baseline host

Tooling nội bộ mức S đo lõi thumbnail/render/PDF trước tối ưu; không đổi app hoặc
dependency, không gọi API và không dùng tài liệu thật. Fixture chỉ gồm hình học và
marker màu khác nhau giữa trang, không có chữ Việt/OCR/font/ảnh tải ngoài. Mảng màu
phẳng nén tốt, không đại diện độ phức tạp hoặc kích thước JPEG của ảnh tài liệu thật.

## Chạy tái lập

Cần toolchain Flutter/Dart đã ghim, Linux với coreutils `mkdir` và `sha256sum` trên
PATH. Từ gốc repo, kiểm môi trường bằng `bash scripts/dev-task.sh doctor`.
Mọi lệnh Dart và binary dưới đây chạy trong `apps/mobile` để đọc đúng `pubspec.lock`.
Đặt corpus, binary và kết quả ngoài repo. Ví dụ tạo corpus 12 MP một trang:

```bash
cd apps/mobile
benchmark_dir="${XDG_DATA_HOME:-$HOME/.local/share}/x-scanner/benchmarks"
mkdir -p "$benchmark_dir"
app_sha="$(git rev-parse HEAD)"

dart run tool/scanner_benchmark.dart generate "$benchmark_dir/corpus-12mp-1" 4000 3000 1
dart compile exe tool/scanner_benchmark.dart -o "$benchmark_dir/scanner-benchmark"

"$benchmark_dir/scanner-benchmark" thumbnail "$benchmark_dir/corpus-12mp-1" "$app_sha" > "$benchmark_dir/thumbnail-12mp-1.json"
"$benchmark_dir/scanner-benchmark" render-pdf "$benchmark_dir/corpus-12mp-1" "$app_sha" > "$benchmark_dir/pdf-12mp-1.json"

sha256sum --zero pubspec.lock tool/scanner_benchmark.dart > "$benchmark_dir/source-checksums.nul"
(
  cd "$benchmark_dir"
  sha256sum --zero scanner-benchmark corpus-12mp-1/manifest.json
) > "$benchmark_dir/artifact-checksums.nul"
(
  cd "$benchmark_dir/corpus-12mp-1"
  sha256sum --zero manifest.json page-*.jpg
) > "$benchmark_dir/corpus-checksums.nul"
```

`generate` yêu cầu đường dẫn mới có parent tồn tại. Nếu đã chạy trước, chọn tên mới.
Generation/compilation chạy riêng, không nằm trong thời gian xử lý trang. Mỗi lệnh
đo mở **một process mới cho một case**. Test tiny gọi API nhiều lần trong Flutter test
chỉ kiểm hành vi; số thời gian/RSS từ test không dùng làm baseline. `dart run` cũng
có thể smoke CLI nhưng phải ghi rõ JIT, không trộn với AOT.
Ca test tên thư mục chứa newline/backslash chỉ chạy ngoài Windows vì Win32 không
cho các ký tự đó trong tên; Linux CI vẫn chạy đủ 46 ca. Điều này không xác nhận
CLI hoặc toàn bộ app gate đã được kiểm trên Windows.

`APP_SHA` phải đúng 40 ký tự hex, không whitespace/newline. Tool chỉ kiểm cú pháp,
không chứng thực binary build từ SHA đó. Freeze source trước baseline; bằng chứng
ghi app commit, SHA256 source tool/lockfile/binary/manifest và lệnh compile/run thật.
Source chưa commit phải ghi rõ, không gán số đo của nó cho một commit sạch. Không
lưu đường dẫn cá nhân trong record hoặc provenance chia sẻ; checksum trên dùng tên
tương đối. Các giá trị chưa biết/chưa đo giữ null.

## CLI, corpus và hàng rào

```text
generate NEW_DIR WIDTH HEIGHT PAGES
thumbnail CORPUS_DIR APP_SHA
render-pdf CORPUS_DIR APP_SHA
```

- Dimensions là số nguyên dương, mỗi chiều không quá 65535 (JPEG SOF 16 bit), tổng
  không quá 50.000.000 pixel; 1–100 trang. Kiểm phép chia trước phép nhân để tránh
  overflow. Mỗi JPEG không quá 64 MiB; manifest không quá 64 KiB.
- Manifest v1 có đúng `schemaVersion`, `generator` (`x-scanner-geometric-v1`),
  `seed` (20261016), `width`, `height`, `pageCount`, `pages`. Mỗi trang có đúng
  `file` (`page-001.jpg` đến `page-100.jpg` theo thứ tự) và `sha256` của byte JPEG.
  Không timestamp, path hoặc nội dung người dùng. Cùng recipe/seed/dependency đã
  ghim tạo byte và manifest giống nhau. Marker giữ checksum mỗi trang khác nhau,
  kể cả fixture một pixel, để PDF không gộp thành một ảnh duy nhất.
- `generate` gọi `mkdir` qua argument array để chiếm đường dẫn mới atomically;
  từng file tạo exclusive. Từ chối file/thư mục/symlink đã tồn tại, không overwrite,
  không xóa partial corpus khi lỗi. Manifest hoàn chỉnh ghi cuối; corpus dở không
  đo được. Muốn thử lại phải chọn đường dẫn mới.
- Preflight chỉ nhận generator/schema/seed đã biết và tên trang cố định; từ chối
  symlink ở corpus/manifest/trang. Đọc bằng file handle đúng length đã kiểm trần,
  băm buffer đã giới hạn qua stdin của `sha256sum --zero` bằng argument array, không
  shell. So checksum trước khi probe header; kiểm JPEG magic và dimensions thực
  bằng `imageSizeOf` trong `runWithinBudget` với `decodeBudget` của production.
- Giữ corpus **bất biến trong toàn lần chạy**. Production core đọc lại original
  sau preflight; tool không chống actor sửa file đồng thời hoặc bảo đảm loại bỏ
  TOCTOU. Không sửa original/manifest để chạy lại, không dùng scan/OCR thật.
- Exit 0 = lệnh hoàn thành; 2 = CLI sai; 1 = corpus/I/O/decoder/đóng gói lỗi. Lỗi
  chỉ có thông báo cố định trên stderr, không JSON thành công, path hay nội dung
  exception. Lưu cả exit status; stdout rỗng không phải PASS.

## Bản ghi và phạm vi đo

Mỗi lệnh đo thành công ghi một dòng JSON, `schemaVersion: 1`:

| Trường | Ý nghĩa |
| --- | --- |
| `appSha`, `fixtureId`, `fixtureSha256` | Commit operator cung cấp, ID generator/dimensions/pages, SHA256 byte manifest. |
| `width`, `height`, `pageCount` | Dimensions JPEG gốc đã probe và số trang. |
| `host`, `runtime`, `buildMode` | OS, architecture, Dart version; `host-dart` không phải Flutter profile/release. Không hostname, username, path. |
| `engines` | Tên production core/function + SHA256 `pubspec.lock`; `imageVersion`/`pdfVersion` null vì không trích version. Không hardcode version dễ lỗi sau nâng dependency. |
| `recipeRevision`, `stage` | Recipe 0: thumbnail mặc định 1024 px; hoặc full-frame, không xoay, JPEG production rồi PDF. |
| `durationMs` | Wall time xử lý sau preflight/lock hash; gồm tạo tempdir PDF, không gồm cleanup hoặc ghi JSON. |
| `renderDurationMs` | Vòng lặp production `thumbnail` hoặc `renderPage` tuần tự, gồm I/O/isolate của core. Không gồm tạo tempdir. |
| `packageDurationMs`, `writeDurationMs` | PDF `buildPdf` qua `Isolate.run` như app; ghi file `flush: true`. Thumbnail để null vì không đo hai pha này. |
| `outputBytes` | Tổng byte JPEG thumbnail hoặc độ dài PDF thật đã ghi; không phải byte originals hay dung lượng disk đang giữ. |
| `peakProcessRssBytes`, `currentRssBytes` | High-water RSS toàn process và RSS lúc ghi record, tính bằng byte. Peak gồm setup/preflight/isolate; không phải peak từng pha, Dart heap hoặc Android PSS. |
| `cancelLatencyMs` | null: không đo hủy. |
| `ioCache`, `rssScope`, `outcome` | `uncontrolled`, `process-lifetime-including-setup`, `success`. |

PDF render từng trang full resolution, giữ mỗi JPEG buffer độc lập rồi đóng gói như
app; không dùng thumbnail hoặc renderer giả. PDF được ghi vào thư mục tạm duy nhất
do invocation tạo, chỉ dọn thư mục đó và không giữ PDF sau đo. Original/manifest
không thay đổi; không xóa corpus/bản gốc người dùng.

Thời gian dùng [Dart Stopwatch](https://api.dart.dev/dart-core/Stopwatch-class.html).
Ý nghĩa RSS theo [Dart ProcessInfo](https://api.dart.dev/dart-io/ProcessInfo-class.html).
High-water RSS process không reset cho từng stage; preflight có thể là đỉnh. Không
trừ setup để giả thành peak xử lý. Trường chưa đo để null, không điền 0 hoặc suy đoán.
Không ngưỡng tốc độ/RSS trong CI, không nhận p95 từ ít mẫu.

## Protocol baseline và dữ liệu còn thiếu

Ma trận cần đo riêng từng stage và số trang 1 / 10 / 30 / 100:

| Case | Width × height | Pixel |
| --- | --- | --- |
| 12 MP | 4000 × 3000 | 12.000.000 |
| 24 MP | 6000 × 4000 | 24.000.000 |
| 48 MP | 8000 × 6000 | 48.000.000 |

Đây là **protocol**, không phải bằng chứng 100 trang/48 MP đã đạt. Ghi số mẫu thật,
raw JSON/exit status, stage, process mode, source/lock/binary/corpus hash, điều kiện
host và giới hạn. Lưu kết quả ngoài repo hoặc evidence tổng hợp đã kiểm riêng tư
trên PR; không tự upload corpus thật.

Process mới làm sạch trạng thái trong process nhưng **không phải cold disk**:
checksum/header preflight đã đọc originals và có thể làm ấm cache OS. I/O cache luôn
ghi uncontrolled. Chưa đo cold storage được kiểm soát; không đổi nhãn thành cold vì
khởi động lại process. CLI hiện không đo warm cùng process. Nếu cần warm app sau này,
định nghĩa riêng cache/warm-up/điều kiện/cửa sổ RSS; không trộn với baseline hiện tại.

Chỉ công bố p95 khi có ít nhất 30 mẫu độc lập cho **mỗi case/stage/điều kiện**. Giữ
raw mẫu, báo cả sample count/lần lỗi; dùng nearest rank
`sorted[ceil(0.95 * n) - 1]`, không bỏ outlier im lặng. Vài smoke/baseline đầu không đủ
tính p95 hoặc xác nhận mục tiêu p95 2 giây đề xuất.

Device benchmark phải đo riêng trên máy vật lý, Flutter profile, ghi model/OS/app
commit, nhiệt/pin, độ phân giải, camera/ánh sáng/cache.
[Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance) hướng
dẫn profile trên thiết bị thật. Host Dart AOT không đo UI, controller/camera/depth,
share sheet, hủy export hoặc phục hồi phiên.

XS-06 corpus chất lượng đầy đủ vẫn mở: 120 trang Việt/Anh và tình huống mờ/chói/cong,
ground truth, bảo toàn chữ, camera/device và tài liệu dài. Ảnh thật phải giữ riêng,
có quyền sử dụng, tách holdout theo **tài liệu vật lý** (không để cùng trang/biến thể
lọt cả tuning và holdout). Ground truth OCR cần người kiểm tay, quy ước Unicode NFC
trước so CER; dấu tiếng Việt tính là nội dung. Không bịa text thiếu. Tool này không
nhận corpus đó hoặc chạy OCR.

AC-9 UAT, chất lượng scan/OCR, build iOS và release cần bằng chứng riêng. Đợt khởi tạo
host ít mẫu không nghiệm thu các mục này hoặc toàn XS-06.

## XS-07a: so sánh fidelity và render toàn khung

[Spec XS-07a](../specs/2026-10-17-xs07a-full-frame-render.md) sửa sai lệch pixel identity
và tránh vòng nội suy khi quad chính xác bằng fullFrame và output không đổi kích thước.
Preview đã cắt dùng thumbnail rồi rectify; crop thật hoặc downsize vẫn dùng thuật toán cũ.
Stage benchmark `thumbnail` chỉ chạy thumbnail, không gọi rectify, là đối chứng cho thay đổi này.
Không thay decoder, trần ảnh, ngân sách isolate, PDF writer hoặc dependency.
Regression exact PNG/rotation, ownership và metadata chạy trong gate; không đặt
ngưỡng thời gian/RSS vào unit tests.

Execution evidence của Work ID `2026-10-17-xs07a-full-frame-render` đặt trên PR cùng
Work ID: source SHA, binary/tool/lock/corpus hashes, toàn raw JSONL và bảng
min/median/max. Trước là binary AOT thật từ source `935083e` đã kiểm hash (source
core/tool/lock không đổi trong review54); sau compile từ commit sạch của PR mới.
Không gán tên SHA mới cho binary cũ hoặc dùng20sample lịch sử thay phép đo mới.

Protocol matched: cùng corpus hình học4000×3000,1/10trang, hai stage
thumbnail/render-pdf,5process mới cho mỗi tổ hợp stage/corpus/version =40process.
Mỗi sample lẻ chạy before→after, sample chẵn after→before để giảm lệch do thứ tự;
không chạy fullgate/compiler khác cùng lúc. Xác minh input hashes trước/sau và
không đổi tool/lock; compile ngoài vùng đo. Ghi mọi lỗi thật, giữ dữ liệu dở nếu lỗi,
không chọn bỏ sample chậm. Host/RSS/cache/synthetic limits ở trên vẫn áp dụng;
đây không là p95, cold-disk, thiết bị,100trang hoặc nghiệm thu camera/OCR/release.

Hồ sơ: [XS-07a](../work/2026-10-17-xs07a-full-frame-render/working.md).
