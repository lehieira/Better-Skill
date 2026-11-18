---
name: speckit-bug-assess
description: "Bugfix Step 1: Đánh giá và tái hiện lỗi một cách hệ thống — thu thập triệu chứng, môi trường, khoanh vùng code nghi ngờ và viết bài test/kịch bản tái hiện lỗi FAIL ổn định vào .specify/bugs/<bug>.md trước khi sửa bất kỳ dòng code nào."
---

# Skill: Spec Kit — Bug Assess & Reproduce (Step 1)

Cấm tuyệt đối đoán mò hoặc sửa hú họa phần ngọn. Bước này chỉ tập trung tái hiện chính xác lỗi và chứng minh bằng bài test FAIL.

---

## 1. Quy Trình 4 Bước Tái Hiện Lỗi

1. **Thu Thập Triệu Chứng & Ngữ Cảnh**:
   - Đọc `.antigravity/activeContext.md` (nếu có), log lỗi, stack trace, HTTP status, payload đầu vào và điều kiện môi trường.
   - Xác định rõ **Expected Behavior** vs **Actual Behavior**.
2. **Khoanh Vùng Có Mục Tiêu (Targeted Search)**:
   - Dùng search đích danh theo tên symbol/route/message lỗi (`rg -n`), **không quét toàn bộ repo**.
   - Đọc hàm lỗi và đường đi dữ liệu ngay tại điểm phát sinh.
3. **Viết Bài Test Tái Hiện (Reproduction Test)**:
   - Viết unit test, integration test hoặc script kiểm chứng tối giản tái hiện đúng lỗi.
   - Chạy bài test và xác nhận **FAIL ổn định (Red)** đúng thông báo/hành vi lỗi đã báo.
4. **Ghi Nhận Hồ Sơ Lỗi**: `.specify/bugs/<bug-slug>.md`:

```markdown
# Bug Report: <Tên lỗi ngắn gọn>
- **Expected**: ...
- **Actual**: ...
- **Repro Command / Test**: `<lệnh chạy test>` -> FAIL với `<tóm tắt lỗi>`
- **Suspect Area**: `<file:line>`
```

---

## 2. Cổng Chuyển Sang `speckit-bug-fix`
- Chỉ chuyển sang bước tìm nguyên nhân gốc và sửa lỗi khi đã có **bài test/kịch bản tái hiện FAIL rõ ràng**.
- Nếu không thể tái hiện sau khi thử các điều kiện hợp lý -> dùng `ask_question` hỏi thêm thông tin môi trường/dữ liệu từ người dùng.
