---
name: refactoring-surgeon
description: "Tái cấu trúc mã nguồn cũ (legacy code, god file, code trùng lặp, tight coupling) từng bước nhỏ an toàn mà giữ nguyên 100% hành vi và tương thích ngược. Chỉ dùng khi refactor; không dùng để thêm tính năng mới hay sửa bug nghiệp vụ."
---

# Skill: Refactoring Surgeon

Cải thiện cấu trúc nội bộ của mã nguồn sạch sẽ, dễ bảo trì mà không làm gãy bất kỳ hành vi đang chạy nào.

---

## 1. Quy Trình Phẫu Thuật An Toàn 4 Bước

1. **Khóa Lưới An Toàn Trước Khi Chạm Code (Safety Net)**:
   - Kiểm tra test hiện có của module sắp sửa.
   - Nếu chưa có test bao phủ hành vi hiện tại -> **viết Characterization Tests trước** và chạy PASS để khóa chuẩn hành vi cũ.
2. **Tái Cấu Trúc Theo Bước Vi Mô (Micro-Steps)**:
   - Tách từng phần nhỏ (Extract Function -> Deduplicate -> Flatten Nesting -> Introduce Interface/Adapter).
   - Giữ public API / chữ ký hàm hoặc cung cấp thin wrapper tương thích ngược cho tới khi mọi caller đã chuyển xong.
3. **Chạy Test Sau Mỗi Bước Nhỏ**:
   - Không gom 10 thay đổi kiến trúc rồi mới chạy test một lần. Mỗi bước xong phải PASS ngay mới đi tiếp.
4. **Dọn Dẹp Sau Cắt Tách**:
   - Xóa dead code, import thừa, wrapper hết hạn (nếu toàn bộ caller trong repo đã cập nhật).

---

## 2. Nguyên Tắc Cấm Khi Refactor
- **Không trộn lẫn Refactor và Feature/Bugfix trong cùng một bước** (rất khó truy hồi nếu gãy).
- **Không đổi hành vi ngầm** (ví dụ tự ý đổi mã lỗi HTTP, format ngày, thứ tự sắp xếp khi người dùng không yêu cầu).
- Luôn chạy full test suite + typecheck sau bước refactor cuối cùng.
