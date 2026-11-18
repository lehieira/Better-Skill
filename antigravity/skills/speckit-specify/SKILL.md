---
name: speckit-specify
description: "Phase 1 Spec Kit: Chuyển yêu cầu đã chốt qua grill-me thành tài liệu đặc tả chức năng (.specify/specs/<feature>/spec.md) với User Flows, Edge Cases, ràng buộc bảo mật/UI và danh sách Tiêu chí Nghiệm thu (AC-xx) kiểm chứng được. Dùng sau Gate 0 trước khi lập kế hoạch kiến trúc."
---

# Skill: Spec Kit — Specify (Phase 1)

Chuẩn hóa việc biến yêu cầu đã được phê duyệt ở Gate 0 (`grill-me`) thành bản đặc tả rõ ràng, đo lường được và không mơ hồ trước khi thiết kế kiến trúc hay viết code.

---

## 1. Điều Kiện Tiên Quyết & Ranh Giới
- Chỉ chạy sau khi Gate 0 (`confirm-before-action` / `grill-me`) đã được người dùng chốt.
- **Tuyệt đối không viết code triển khai** trong phase này.
- Đọc tối thiểu `.antigravity/activeContext.md` (nếu có) và các file liên quan trực tiếp (cấm full scan).
- Nếu phát hiện điểm mơ hồ ảnh hưởng kiến trúc/bảo mật/UX: dừng lại gọi `ask_question` làm rõ ngay, không tự suy đoán.

---

## 2. Đầu Ra Bắt Buộc: `.specify/specs/<feature-slug>/spec.md`

Tạo file đặc tả theo cấu trúc chuẩn:

```markdown
# Feature Spec: <Tên tính năng>

## 1. Mục tiêu & Phạm vi
- **Mục tiêu nghiệp vụ**: <1-2 câu rõ giá trị>
- **In-Scope**: <những gì làm>
- **Out-of-Scope**: <những gì KHÔNG làm trong đợt này>

## 2. Actors & User Flows
- **Actor**: <Vai trò, quyền hạn>
- **Luồng chính (Happy Path)**:
  1. ...
- **Luồng phụ & Edge Cases**:
  - Dữ liệu rỗng / không hợp lệ / trùng lặp / thao tác đồng thời / mất mạng

## 3. Ràng Buộc Kỹ Thuật Bắt Buộc
- **Backend & Data** (`hardened-backend-security`): Schema validation, Ownership/IDOR scope, Transaction/Idempotency, DTO output, Rate limit/Pagination.
- **UI/UX** (`ui-ux-pro-architect`): 4 trạng thái (Loading/Empty/Error/Data), chống double-submit, a11y/mobile-first.

## 4. Tiêu Chí Nghiệm Thu (Acceptance Criteria)
- **AC-01**: Given <trạng thái>, When <hành động>, Then <kết quả đo được>.
- **AC-02**: Given <người dùng không có quyền / input sai>, When <gọi API>, Then <HTTP 403/400 + không rò rỉ stack trace>.
```

---

## 3. Checklist Tự Kiểm Trước Khi Sang Phase 2 (`speckit-plan`)
1. Mọi `AC-xx` đều **kiểm chứng được bằng test tự động** (không dùng từ mơ hồ như "nhanh", "đẹp", "ổn định" thiếu số liệu/hành vi cụ thể).
2. Có đủ ít nhất 1 AC cho **negative/security case** và 1 AC cho **error/empty state** (nếu có UI).
3. Phạm vi `Out-of-Scope` được ghi rõ để tránh scope creep khi code.
