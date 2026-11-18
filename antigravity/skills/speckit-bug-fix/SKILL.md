---
name: speckit-bug-fix
description: "Bugfix Step 2: Truy tìm nguyên nhân gốc rễ (Root-Cause Investigation) từ reproduction test và stack trace, sửa triệt để tại gốc nguyên nhân và kiểm tra các call-site tương tự. Dùng ngay sau speckit-bug-assess."
---

# Skill: Spec Kit — Root-Cause Fix (Step 2)

Tìm và xử lý dứt điểm nguyên nhân gốc rễ tạo ra lỗi, tuyệt đối không vá triệu chứng bề mặt hay dùng `try/catch` nuốt lỗi.

---

## 1. Quy Trình Truy Tìm Nguyên Nhân Gốc (Root-Cause Investigation)

1. **Trace Ngược Đường Đi Dữ Liệu (Backward Data-Flow Trace)**:
   - Bắt đầu từ dòng gây crash/sai kết quả -> lần ngược lên từng caller, DB query, state mutation hoặc race condition để tìm điểm đầu tiên dữ liệu/trạng thái bị sai.
2. **Kiểm Chứng Giả Thuyết (5 Whys)**:
   - Đặt câu hỏi *"Tại sao giá trị này null/lệch ở đây?"* đến khi chạm đúng bug logic, thiếu validate, thiếu lock/transaction hoặc sai giả định hợp đồng API.
   - Kiểm tra xem biến thể lỗi tương tự có tồn tại ở **các call-site/file anh em khác** không.
3. **Thiết Kế & Áp Dụng Sửa Chữa Tại Gốc**:
   - Nếu sửa lỗi ảnh hưởng kiến trúc/schema/API contract -> xác nhận qua `ask_question` (`grill-me`) trước khi sửa.
   - Sửa code gọn, sạch, tuân thủ `hardened-backend-security` (validation, scoping, atomic DB update, safe error) và `ui-ux-pro-architect` (4 UI states, anti double-submit).
   - Cập nhật mục `Root Cause` và `Fix Summary` trong `.specify/bugs/<bug-slug>.md`.

---

## 2. Chống Sửa Sai Hướng (Anti-Patterns Cấm Tuyệt Đối)
- Cấm bọc `try { ... } catch { return null }` để giấu exception.
- Cấm thêm `if (x != null)` vá ngọn khi `x` đáng lẽ không bao giờ được phép `null` tại tầng caller/DB.
- Cấm vô hiệu hóa validation, auth check hoặc nới lỏng assertion để lỗi biến mất giả tạo.
- Sửa xong -> chuyển ngay sang `speckit-bug-test`.
