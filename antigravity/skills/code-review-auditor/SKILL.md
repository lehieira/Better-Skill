---
name: code-review-auditor
description: "Tự kiểm định (self-review) git diff hoặc PR trước khi bàn giao: phát hiện lỗ hổng logic, edge cases, race condition, memory/resource leak, code trùng lặp và vi phạm tiêu chuẩn sạch. Không thay thế 3 chốt Vercel của vercel-prelaunch-checklist."
---

# Skill: Code Review Auditor

Đóng vai Senior Reviewer đọc soát lại toàn bộ thay đổi (`git diff`) với con mắt phản biện trước khi nghiệm thu.

---

## 1. Quy Trình Audit 5 Trục (Đọc Trực Tiếp `git diff`)

1. **Tính Đúng Đắn & Edge Cases**:
   - Xử lý ra sao với `null`/`undefined`, mảng rỗng, số âm/0, chuỗi dài quá giới hạn, múi giờ, ký tự Unicode?
   - Có nhánh `if/else` hoặc `switch` nào bị rơi sót (missing default / early return)?
2. **Concurrency, Resource & Hiệu Năng**:
   - Có nguy cơ Race Condition (check-then-act không atomic) hay N+1 query trong vòng lặp?
   - Connection DB, file stream, timer/event listener có được đóng/cleanup ở `finally`/unmount?
3. **Chất Lượng Thiết Kế (Clean Code)**:
   - Có block code lặp lại cần rút thành 1 helper dùng chung?
   - Hàm có quá dài hoặc lồng `if` sâu (> 3 cấp)? Có magic numbers/strings nên tách hằng số?
   - Biến/kiểu có nhất quán với quy ước sẵn có của repo (không tự đẻ pattern lạc quẻ)?
4. **Ranh Giới Bảo Mật & UI Nhanh**:
   - Không có `TODO/FIXME` giữ chỗ cho auth/validation; không lọt secret/PII trong diff.
   - Đủ 4 UI states & loading lock nếu có sửa giao diện.
5. **Phạm Vi Thay Đổi (Diff Hygiene)**:
   - Không sửa lạc đề sang file không liên quan; giữ nguyên comment/docstring cũ hợp lệ.

---

## 2. Phân Loại Phát Hiện Khi Báo Cáo
- **Blocker (Phải sửa ngay)**: Sai logic, mất dữ liệu, lỗ hổng bảo mật, leak tài nguyên, gãy build/test.
- **Should-Fix (Nên sửa trước bàn giao)**: Code trùng lặp, thiếu test case biên, hàm quá phức tạp.
- **Nit (Tùy chọn)**: Đặt tên, format nhỏ (không làm nhiễu diff nếu không cần).
