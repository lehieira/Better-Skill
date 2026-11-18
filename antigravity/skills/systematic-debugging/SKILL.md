---
name: systematic-debugging
description: "Điều tra lỗi phức tạp đa tầng (logs, network, DB lock/state, race condition, git bisect, profiler) khi chưa rõ nguyên nhân gốc. Dùng kết hợp trước speckit-bug-assess hoặc khi gặp lỗi ngẫu nhiên (flaky/intermittent); không dùng để viết code sửa trực tiếp khi chưa tái hiện."
---

# Skill: Systematic Debugging

Quy trình điều tra khoa học giúp khoanh vùng nhanh lỗi khó tái hiện, lỗi phân tán (client-API-DB) hoặc lỗi thoái lui theo lịch sử commit.

---

## 1. Bốn Chiến Lược Khoanh Vùng Đích Danh
1. **Binary Search bằng `git bisect`** *(khi lỗi mới xuất hiện từ một thay đổi gần đây)*:
   - Xác định commit `good` cuối cùng và commit `bad` hiện tại -> rút ngắn hàng trăm commit chỉ còn vài bước kiểm tra.
2. **Trace Đầy Đủ Điểm Ranh Giới (Boundary Tracing)**:
   - Ghi nhận đồng bộ: Request payload (client gửi) -> Middleware/Auth -> Service input -> Câu SQL + tham số -> DB state -> Response JSON.
   - Tìm **ranh giới đầu tiên** nơi giá trị lệch khỏi kỳ vọng.
3. **Cô Lập Điều Kiện Flaky / Concurrency**:
   - Kiểm tra timeout, múi giờ (`UTC` vs local), race condition giữa 2 request song song, stale cache hoặc thứ tự chạy test không độc lập.
4. **Tách Môi Trường Tối Thiểu (Minimal Repro)**:
   - Loại bỏ dần các thành phần không liên quan để rút gọn về một script/test độc lập tái hiện 100%.

---

## 2. Quy Tắc An Toàn Khi Debug
- Đọc log & cấu hình đích danh, **cấm full codebase scan**.
- Cấm log token, mật khẩu, PII ra stdout hoặc file tạm không được gitignore.
- Nếu gắn log tạm để đo đạc: phải dọn sạch toàn bộ debug log trước khi hoàn thành.
- Ngay khi đã khoanh vùng và tái hiện ổn định -> chuyển sang `speckit-bug-assess` -> `speckit-bug-fix` -> `speckit-bug-test`.
