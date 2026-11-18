---
name: speckit-plan
description: "Phase 2 Spec Kit: Chuyển đặc tả spec.md thành bản thiết kế kiến trúc kỹ thuật (.specify/specs/<feature>/plan.md) gồm module tác động, Data Model/Migration, API Contract/DTO, 4 trạng thái UI, chiến lược Test và kế hoạch Rollback. Dùng ngay sau speckit-specify."
---

# Skill: Spec Kit — Architectural Plan (Phase 2)

Thiết kế giải pháp kỹ thuật chi tiết bám sát codebase thật, bảo đảm tính toàn vẹn dữ liệu, bảo mật phòng vệ chiều sâu và khả năng kiểm thử trước khi chia nhỏ task.

---

## 1. Quy Trình Phân Tích (Targeted Read-Only)
1. Đọc `.specify/specs/<feature-slug>/spec.md`.
2. Chỉ đọc đúng các file cấu hình, schema, router/controller, service/DAO và UI component liên quan trực tiếp để tái sử dụng helper/pattern sẵn có của repo.
3. Không sửa mã nguồn sản phẩm trong phase này.

---

## 2. Đầu Ra Bắt Buộc: `.specify/specs/<feature-slug>/plan.md`

```markdown
# Architectural Plan: <Tên tính năng>

## 1. Tổng Quan Luồng Dữ Liệu
- Mô tả ngắn luồng Request -> Auth/Validation -> Service/Transaction -> DB -> DTO Response -> UI State.

## 2. Danh Sách File Tác Động
- `[+]` `<đường dẫn>` — <vai trò>
- `[*]` `<đường dẫn>` — <thay đổi cụ thể>

## 3. Thiết Kế Dữ Liệu & API (nếu có Backend)
- **Schema / Migration**: Bảng, cột, ràng buộc NOT NULL/UNIQUE/FK, Index, kế hoạch rollback.
- **Endpoint & Validation Schema**: Method, Path, Auth requirement, Whitelist fields cho phép ghi.
- **Query Scoping & Concurrency**: Điều kiện `WHERE ... AND user_id/tenant_id = ?`, Transaction/Locking/Idempotency-Key.
- **Response DTO**: Danh sách trường trả về (loại bỏ hoàn toàn trường nhạy cảm).

## 4. Thiết Kế Giao Diện (nếu có Frontend)
- Mapping 4 trạng thái: Loading (Skeleton), Empty (CTA), Error (Retry), Data.
- Chống double-submit, xác nhận 2 bước cho thao tác hủy/xóa, Semantic HTML & Keyboard a11y.

## 5. Chiến Lược Kiểm Thử (TDD Mapping)
- **Unit Tests**: <logic thuần, validator, mapper>
- **Integration / API Tests**: <happy path + 401/403 IDOR + 400 validation + race/idempotency>
- **UI / E2E Tests**: <4 states + form submit>
```

---

## 3. Checklist Trước Khi Sang Phase 3 (`speckit-tasks`)
1. Mọi `AC-xx` trong `spec.md` đều có phần thiết kế và test tương ứng trong `plan.md`.
2. Không có logic trùng lặp hoặc tự viết lại helper đã tồn tại trong repo.
3. Ranh giới bảo mật (Auth, Scoping, Transaction, DTO) và UI states được chốt tường minh.
