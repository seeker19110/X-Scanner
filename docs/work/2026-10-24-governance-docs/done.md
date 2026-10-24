# Công việc: Tài liệu quản trị: threat model, dữ liệu, chuẩn, rủi ro, vận hành

- Work ID: 2026-10-24-governance-docs
- Yêu cầu / outcome: đóng nhóm MUST tài liệu quản trị của `BLUEPRINT.md` (batch D: SEC-TM-*, CMP-PRIV-001, PM-*, STD-*, OPS-IR-*, XC-DOCAI-*, WF-*, ARC-*, XC-GREEN-*) bằng tài liệu có bằng chứng; chỗ cần người thì ghi rõ.
- Trạng thái: Done — merge #66 (squash `9c813bd`) 2026-10-24; CI run 40068312572 xanh trên head `7609318` trước merge; 54 ID blueprint áp vào BLUEPRINT.md (D-005, D-006).
- Chủ trì / writer: subagent của phiên chính, chỉ ghi tài liệu trong worktree `/home/user/xs-d`
- Mức rủi ro / số PR: S (chỉ tài liệu, không đổi mã/CI/hook); 1 PR do phiên chính mở
- Scope / non-goal: chỉ docs/templates; không sửa code, CI, hook, `.claude/`, `.xtemplates/`, `xt.yaml`, `BLUEPRINT.md`, `PROGRESS.md`, `docs/autopilot/*`, ADR cũ, spec đã Approved, file ghim checksum trong `docs/framework/FRAMEWORK-VERSION`.
- Spec / goal / issue: `BLUEPRINT.md` (ghi chú "— Thiếu:" từng ID)
- Nhánh / base SHA / thời điểm reconcile: `local/backlog-d` @ `edbdc50` · 2026-10-24T03:28:42Z

## Kế hoạch và phân công

Một outcome (tài liệu quản trị), vài commit `docs:` theo nhóm: (1) threat model + dữ liệu/pháp lý + chuẩn + yêu cầu/rủi ro;
(2) vận hành + repo docs + mẫu; (3) kiến trúc + ADR-0012 + baseline tài nguyên. Gate chạy trước mỗi commit (hook pre-commit).

## Nguồn đã tra (URL + ngày truy cập)

| Nguồn | Dùng cho | Truy cập | Kết quả |
|---|---|---|---|
| https://congbao.chinhphu.vn/van-ban/luat-so-91-2025-qh15-45578.htm | Luật 91/2025/QH15: số hiệu, ban hành 26/06/2025, hiệu lực 01/01/2026 | 2026-10-24 (WebFetch) | chỉ metadata; toàn văn là file đính kèm không đọc được |
| https://bocongan.gov.vn/chinh-sach-phap-luat/co-so-du-lieu-van-ban/luat-bao-ve-du-lieu-ca-nhan-1753688803 | tình trạng "Còn hiệu lực" | 2026-10-24 | metadata |
| https://congbao.chinhphu.vn/van-ban/nghi-dinh-so-356-2025-nd-cp-468371.htm | NĐ 356/2025/NĐ-CP: ban hành 31/12/2025, hiệu lực 01/01/2026 | 2026-10-24 | trang không nêu quan hệ thay thế NĐ 13/2023 |
| https://publications.europa.eu/resource/celex/32016R0679 (XHTML, Accept-Language eng) | GDPR Art. 2(2)(c), Recital 18, Art. 3, Art. 99 — trích nguyên văn | 2026-10-24 (curl) | đọc được; EUR-Lex trả 202 rỗng |
| https://www.w3.org/TR/WCAG22/ | WCAG 2.2 = W3C Recommendation 12/12/2024 | 2026-10-24 | xác nhận |
| https://developer.android.com/guide/topics/ui/accessibility | hướng dẫn trợ năng Android | 2026-10-24 | trang tổng quan, không có số 48 dp (số 48 dp lấy từ test thật `androidTapTargetGuideline`) |
| https://github.com/OWASP/masvs/releases , https://mas.owasp.org/MASVS/ | MASVS 2.1.0 mới nhất; 8 nhóm kiểm soát | 2026-10-24 | xác nhận tag; định nghĩa hồ sơ MAS-L1 chưa đọc được toàn văn |
| https://www.iso.org/standard/78176.html (qua tìm kiếm; tải trực tiếp 403) | ISO/IEC 25010:2023 edition 2, 2023-11 | 2026-10-24 | tên đặc tính cần đối chiếu bản chuẩn |
| https://pub.dev/api/packages/{image,image_picker,path_provider,pdf,share_plus} + `/score` | bản mới nhất, publisher, license, discontinued | 2026-10-24 | bảng `docs/RISKS.md` §2 |
| https://endoflife.date/api/flutter.json , dart.json | EOL | 2026-10-24 | 404 (không có mục) |
| `gh run view 40055848269` | baseline CI (thời gian, số test, cỡ artifact) | 2026-10-24 | `docs/perf/baseline-2026-10-24.md` |
| `gh api repos/seeker19110/X-Scanner`, `/private-vulnerability-reporting` | secret scanning bật; PVR **tắt** | 2026-10-24 | ghi vào SECURITY.md/RUNBOOK |

## Quyết định và bằng chứng

- Không sửa `docs/ops/incident-response.md` và `docs/framework/templates/FEATURE-SPEC.template.md`: cả hai bị ghim SHA trong
  `docs/framework/FRAMEWORK-VERSION` (`test_manifest_integrity` trong `scripts/check-adoption.py`, chạy trong gate). Thay bằng:
  mục sự cố riêng trong `docs/ops/RUNBOOK.md` §5–§6 + sổ `docs/ops/incidents/`; mẫu spec riêng `docs/templates/FEATURE-SPEC.x-scanner.md`.
- Không tạo `docs/ops/INCIDENT-RESPONSE.md` (chữ hoa) vì trùng tên với `incident-response.md` trên hệ thống file không phân biệt hoa thường.
- ID tính năng giữ `FT-NN` (FEATURE-MAP) thay `F-NNN`: `F-001..F-079` đã là ID phát hiện audit, có trong tên test.
- Chuẩn bảo mật: OWASP MASVS 2.1.0 hồ sơ MAS-L1 (offline, không auth/mạng); ASVS không áp dụng. Blueprint STD-SEC-001 grep `ASVS 5.0.0 L[123]` nên **không khớp máy** — cần chủ repo chấp nhận MASVS thay ASVS.
- AGENTS.md: thay tên model Gemini cụ thể bằng tham chiếu `scripts/model-capability-tiers.json`. `CLAUDE.md` còn tên model (Sonnet/Opus/Fable) — không sửa trong việc này.
- SECURITY.md: kênh "Report a vulnerability" nhưng PVR đang tắt → ghi rõ, chủ repo phải bật; không đăng email cá nhân.
- ADR mới số 0012 (sau 0011). Nếu nhánh song song khác cũng tạo ADR-0012, phiên chính đổi số khi tích hợp.

### Bằng chứng gate (hook pre-commit, lượt này)

- `6d54901` (threat model, dữ liệu, rủi ro, PROJECT.md): `[dev-task] PASS: 4 kiểm tra`, Flutter `+806: All tests passed!`.
- `2f237f9` (vận hành, repo docs, mẫu): `[dev-task] PASS: 4 kiểm tra`, Flutter `+806: All tests passed!`.
- Commit thứ ba (kiến trúc, ADR-0012, baseline): kết quả gate ghi ở báo cáo bàn giao của subagent.
- Lượt gate đầu (trước commit) bị `BLOCKED: working tree đổi trong khi kiểm tra` vì sửa tài liệu song song — không phải lỗi mã.

## Lần thử / blocker

- Hook bash chặn `curl … | python3` (mẫu "tải-và-chạy"); đổi sang tải file rồi đọc bằng `python3 -I`.

## Bàn giao / bước tiếp theo

Phiên chính: rà diff `git log edbdc50..local/backlog-d`, mở PR với `Work ID: 2026-10-24-governance-docs`; chủ repo duyệt các mục
"cần chủ repo/luật sư xác nhận" (pháp lý, MASVS, PVR, giấy phép, SLA 14 ngày).

## Nghiệm thu cuối (chỉ điền khi đủ bằng chứng)

Chưa — chưa có PR/merge.
