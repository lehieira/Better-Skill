---
name: speckit-bug-test
description: "Bugfix Step 3: Xác minh lỗi đã được sửa triệt để — chạy lại Reproduction Test chuyển từ FAIL sang PASS, bổ sung Regression Tests cho các edge cases lân cận và chạy toàn bộ Test Suite đảm bảo Zero Regression."
---

# Skill: Spec Kit — Bug Verification & Regression Gate (Step 3)

Đảm bảo bản sửa lỗi thực sự giải quyết nguyên nhân gốc và không làm hỏng bất kỳ tính năng hiện có nào khác.

---

## 1. Quy Trình Kiểm Chứng 4 Bước

1. **Chứng Minh Reproduction Test Đã PASS (Green)**:
   - Chạy lại chính bài test tái hiện đã viết ở `speckit-bug-assess` -> xác nhận **PASS**.
2. **Bổ Sung Regression Tests Cho Vùng Lân Cận**:
   - Thêm test cho các biên liên quan (`null`/rỗng, giá trị biên, quyền truy cập sai `403`, thao tác đồng thời, lỗi mạng/DB) để lỗi không bao giờ tái phát.
3. **Chạy Toàn Bộ Test Suite & Static Checks**:
   - Chạy full test suite + lint + typecheck/build sau lần sửa cuối cùng.
   - Nếu có bất kỳ test nào fail hoặc bị skip -> phải điều tra xử lý dứt điểm trước khi báo cáo.
4. **Đóng Hồ Sơ Lỗi & Đồng Bộ Bộ Nhớ**:
   - Đánh dấu trạng thái `[RESOLVED]` trong `.specify/bugs/<bug-slug>.md` kèm kết quả chạy test thực tế.
   - Cập nhật `.antigravity/activeContext.md` và `.antigravity/progress.md`.
