---
name: speckit-implement
description: "Phase 4 Spec Kit: Thực thi từng task trong tasks.md theo kỷ luật Superpowers TDD (Red -> Green -> Refactor), tuân thủ hardened-backend-security và ui-ux-pro-architect. Dùng ngay sau speckit-tasks để viết test và code."
---

# Skill: Spec Kit — TDD Implementation (Phase 4)

Triển khai mã nguồn sạch, an toàn và có bằng chứng kiểm thử cho từng task trong `.specify/specs/<feature-slug>/tasks.md`.

---

## 1. Kỷ Luật Superpowers TDD (Red -> Green -> Refactor)

Áp dụng bắt buộc cho mọi logic nghiệp vụ, DAO, Service, API handler, utility và interactive UI state:

1. **RED — Viết Test Trước**:
   - Tạo hoặc bổ sung test case bám sát `AC-xx` (bao gồm cả happy path, validation fail và auth/IDOR fail).
   - Chạy test runner và **xác nhận test FAIL** đúng lý do tính năng chưa được cài đặt (không phải lỗi cú pháp).
2. **GREEN — Cài Đặt Tối Thiểu & Đạt Chuẩn**:
   - Viết code hoàn chỉnh (cấm `// TODO: add auth`, cấm stub/mock giả lập logic sản phẩm).
   - Chạy lại test xác nhận **PASS**.
3. **REFACTOR — Làm Sạch Code**:
   - Loại bỏ code trùng lặp bằng helper dùng chung; giữ hàm ngắn, shallow nesting, early return.
   - Chạy lại test xác nhận vẫn **PASS**.

*(Ngoại lệ: Với pure static markup/CSS/docs không có logic, kiểm chứng bằng lint/typecheck/build + kiểm tra trực tiếp.)*

---

## 2. Ràng Buộc Chất Lượng Song Hành Khi Viết Code
- **Backend/API** (`hardened-backend-security`):
  - Validate `body`/`query`/`params` bằng schema chặt chẽ; whitelist field ghi DB (chống Mass Assignment).
  - Bắt buộc ràng buộc `user_id`/`tenant_id` ngay trong câu truy vấn theo ID (chống BOLA/IDOR).
  - Bọc Transaction + atomic update/locking cho nghiệp vụ nhạy cảm; trả Response qua DTO, không lộ stack trace/SQL error.
- **Frontend/UI** (`ui-ux-pro-architect`):
  - Đủ 4 trạng thái: Loading (Skeleton), Empty (CTA), Error (Retry thân thiện), Data (fallback `—`/`N/A`).
  - Disable nút + loading indicator khi submit (chống double-submit), modal xác nhận 2 bước cho hành động xóa/hủy.
  - Dùng semantic HTML (`<button>`, `<label>`), design tokens, hỗ trợ `Esc`/`Enter`/`focus-visible`.

---

## 3. Cập Nhật Tiến Độ Theo Từng Task
- Ngay khi hoàn tất một task và test liên quan PASS: đánh dấu `[x]` trong `tasks.md`.
- Nếu phát sinh thay đổi kiến trúc so với `plan.md`: dừng lại cập nhật `plan.md` trước khi code tiếp.
- Sau khi hoàn tất toàn bộ task -> chuyển ngay sang Phase 5 (`speckit-converge`).
