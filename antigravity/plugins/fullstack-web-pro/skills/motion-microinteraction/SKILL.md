---
name: motion-microinteraction
description: "Thiết kế chuyển động UI có chủ đích (transitions, micro-interactions, skeleton shimmer, toast/drawer motion) bằng thuộc tính GPU-composited và tôn trọng prefers-reduced-motion. Dùng bổ sung cho ui-ux-pro-architect khi cần nâng cao cảm giác tương tác."
---

# Skill: Motion & Micro-interaction

Tạo phản hồi thị giác mượt mà, có ý nghĩa định hướng trạng thái mà không gây giật lag hay khó chịu cho người dùng nhạy cảm với chuyển động.

---

## 1. Nguyên Tắc Kỹ Thuật Chuyển Động Mượt (60fps+)
- **Chỉ animate thuộc tính GPU-composited**: Ưu tiên `transform` (`translate`, `scale`, `rotate`) và `opacity`.
- **Tránh animate thuộc tính gây reflow layout**: Không animate `width`, `height`, `top`, `left`, `margin`, `padding` (dùng `transform: scale/translate` hoặc kỹ thuật grid-template-rows cho accordion).
- **Thời lượng chuẩn (Duration & Easing)**:
  - Hover / button press / toggle nhỏ: `120–180ms` (`ease-out`).
  - Modal / Drawer / Dropdown mở vào: `200–260ms` (`cubic-bezier(0.16, 1, 0.3, 1)`).
  - Đóng ra nhanh hơn mở vào khoảng `20–30%`.

---

## 2. Khả Năng Tiếp Cận & Kiềm Chế Hiệu Ứng
- **Bắt buộc tôn trọng `prefers-reduced-motion: reduce`**: Tắt chuyển động dịch chuyển lớn, giữ thay đổi tức thời hoặc chỉ fade nhẹ `opacity`.
- **Có chủ đích, không trang trí thừa**: Mọi animation phải phục vụ 1 trong 3 mục tiêu: phản hồi thao tác (button/loading), chỉ dẫn không gian (drawer/tab indicator) hoặc chuyển trạng thái (toast/skeleton -> data).
- Không chặn thao tác click/keyboard của người dùng khi animation chưa kết thúc.
