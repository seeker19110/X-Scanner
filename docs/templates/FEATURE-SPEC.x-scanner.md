<!--
Mẫu spec riêng của X-Scanner (WF-SDD-002/003, PM-SPEC-003/004/020), dẫn xuất từ
docs/framework/templates/FEATURE-SPEC.template.md (bản khung, giữ nguyên vì được ghim checksum
trong docs/framework/FRAMEWORK-VERSION). Áp dụng cho spec MỚI lập từ 2026-10-24.
Spec đã Approved trước ngày đó được giữ nguyên (grandfathered): không viết lại, không thêm S-NNN/D-NNN hồi tố;
chỉ sửa khi có thay đổi được duyệt lại.
-->

# Feature spec: <Tên capability>

| Thuộc tính | Giá trị |
| --- | --- |
| Issue / Goal | |
| Spec owner | |
| State | Draft / In review / **Approved for implementation** |
| Approver / date | |
| Last updated | |

> Không code khi chưa **Approved for implementation**.
>
> **Spec gọn (mức M)** — tính năng gọn một PR, không chạm mốc §9 (`standard-delivery.md` §3c): chỉ bắt buộc
> mục 1, 2, 5, 6 (bảng S-NNN), 9, 9b, 11 và Approval; xoá các mục còn lại. AC vẫn đánh mã `AC-n` và map tới test. Mức L dùng
> đủ mẫu; chạm mốc §9 giữa chừng thì nâng lên mức L trước khi code tiếp.

## 1. Problem, user và evidence

## 2. Outcome, baseline, target và guardrails

## 3. Research current state

Code/data/user/source/constraint; ghi link/version/access date cho nguồn thay đổi theo thời gian.

## 4. Alternatives và decision

| Option | Benefits | Cost/risk | Decision |
| --- | --- | --- | --- |
| Do nothing | | | |
| A | | | |
| B | | | |

## 5. Scope / non-goals

## 6. User journeys, scenario và mọi state

Happy/loading/empty/error/offline/permission/limit/conflict/retry/recovery. Mỗi scenario có ID **S-NNN** ổn định
(đánh số trong spec này, không tái dùng), viết Given/When/Then, và có ≥ 1 test tự động mang ID đó trong tên test
(vd `test('S-001: …')`). Scenario chưa có test = tính năng chưa Done.

| ID | Given | When | Then | Loại (happy/lỗi/biên) |
| --- | --- | --- | --- | --- |
| S-001 | | | | happy |
| S-002 | | | | lỗi |

## 7. Functional requirements

FR-1...

## 8. Non-functional requirements

Security/privacy/a11y/performance/reliability/compatibility/cost/safety.

## 9. Acceptance criteria

Máy kiểm được: Given/When/Then **hoặc** bảng input → output. Mỗi AC có ID `AC-n`, có ít nhất **một AC ca lỗi**, và
một dòng trong bảng AC → bằng chứng (§16). AC tham chiếu scenario S-NNN khi phủ cùng hành vi.

| ID | Given | When | Then | Scenario | Ca lỗi? |
| --- | --- | --- | --- | --- | --- |
| AC-1 | | | | S-001 | không |
| AC-2 | | | | S-002 | có |

## 9b. Ca biên

Rà đủ 8 nhóm; nhóm không liên quan ghi "không áp dụng" **kèm lý do** (không bỏ trống). Mỗi ca áp dụng trỏ tới AC/S.

| Nhóm | Ca cụ thể | AC/S | Hoặc: không áp dụng vì |
| --- | --- | --- | --- |
| Rỗng/null (0 trang, tên rỗng, file 0 byte) | | | |
| Cực đại (ảnh 64 MiB, 50 MP, 100 trang, tên 120 ký tự) | | | |
| Trùng lặp/idempotency (bấm hai lần, chạy lại sau lỗi) | | | |
| Song song (hai thao tác cùng tài liệu, huỷ giữa chừng) | | | |
| Mất mạng/ngắt giữa chừng (app bị dừng, hết pin, hết bộ nhớ) | | | |
| Thời gian/múi giờ (UTC lưu, giờ địa phương hiển thị) | | | |
| Quyền (Android, file ngoài sandbox, symlink) | | | |
| Tiền/đơn vị (px/pt/dp, byte/MiB) | | | |

## 10. UX/content/accessibility

## 11. Architecture và code touchpoints

## 12. API/event contract

Auth, validation, idempotency, error, pagination, timeout/retry/versioning.

## 13. Data contract/migration

Schema/index/constraint/ownership/retention/backfill/verify/compatibility/recovery.

## 14. Security/privacy/abuse cases

## 15. Observability và operations

Metric/event/log không PII, dashboard/alert/health/runbook/owner.

## 16. Test/eval plan

Unit/integration/E2E/a11y/performance/concurrent/retry/migration/manual/UAT/AI eval phù hợp profile.

| AC | Bằng chứng | Ghi chú |
| --- | --- | --- |
| AC-1 | `apps/mobile/test/<file>::<tên test>` hoặc `thủ công: <cách quan sát>` hoặc `chưa có — <lý do>` | |

| Scenario | Test mang ID | Ghi chú |
| --- | --- | --- |
| S-001 | `apps/mobile/test/<file>::S-001: <tên>` | |

Test viết **từ spec** (AC/S), không chỉ test sinh từ diff. PR `feat` liệt kê map AC/S → test.

Bằng chứng phải chứng minh **hành vi** của AC (vd "không xem được dữ liệu tài khoản khác" → test
phân quyền), không phải file tồn tại hay HTTP 200. Contract C-4 đỏ khi AC thiếu dòng hoặc tham chiếu
không có thật; `scripts/spec-compiler.sh --trace <spec>` chỉ xanh khi không còn "chưa có". Spec gọn
không có §16 thì đặt bảng ngay dưới §9. Kết quả chạy nằm ở CI/evidence của đúng commit, không chép vào đây.

## 17. Slice/PR plan

Dependency, một outcome/PR, rollout order.

## 18. Rollout/rollback

Staging/canary/go-no-go/feature flag/migration/revert/reconciliation.

## 19. Risk, assumptions và open decisions

| Item | Verification/mitigation | Owner | Due | Decision |
| --- | --- | --- | --- | --- |

### Câu hỏi mở

Điểm spec không nói, nhiều cách hiểu, hoặc mâu thuẫn với code/spec khác: ghi ở đây, **không lấp ngầm**; subagent không tự chọn.
Đóng bằng quyết định `D-NNN` (ghi ở `docs/autopilot/DECISIONS.md` khi phiên chính quyết theo tiêu chí chất lượng cuối) hoặc
tên người + ngày.

| # | Câu hỏi | Lựa chọn | Trạng thái | Đã quyết |
| --- | --- | --- | --- | --- |
| Q-1 | | | mở / đã đóng | `D-NNN` hoặc `<tên>, <YYYY-MM-DD>` |

Không Approved khi còn blocking decision hoặc câu hỏi mở chặn.

## Approval

- [ ] Product/scope
- [ ] UX/a11y
- [ ] Architecture/API/data
- [ ] Security/privacy/cost
- [ ] Test/telemetry/rollout/rollback
- [ ] Blocking decisions closed

**Conclusion:** Draft / In review / **Approved for implementation**  
**Approver/date:**
