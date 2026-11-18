---
name: sql-tuning-stored-proc
description: "Tối ưu truy vấn SQL Server, MySQL và PostgreSQL: xử lý câu lệnh chậm, loại bỏ N+1 query, khóa thứ tự tránh deadlock, viết truy vấn phân trang hiệu quả và stored procedure/CTE an toàn."
---

# Skill: SQL Tuning & Concurrency Control

Phân tích và tinh chỉnh các câu truy vấn SQL, giao dịch đồng thời và thủ tục lưu trữ để đạt hiệu năng cao và không deadlock.

---

## 1. Quy Trình Tối Ưu Query Chậm
1. **Đo Trước Khi Đoán**: Chạy `EXPLAIN ANALYZE` (Postgres/MySQL) hoặc Execution Plan (SQL Server) để xác định bước tốn chi phí nhất (Table Scan, Sort, Key Lookup).
2. **Sửa Các Anti-Pattern Phổ Biến**:
   - **Không bọc hàm lên cột đã đánh index trong `WHERE`**: Thay `WHERE YEAR(created_at) = 2026` bằng `WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01'` để dùng được index (SARGable).
   - **Loại bỏ `SELECT *`**: Chỉ liệt kê đúng cột cần thiết để tận dụng Covering Index và giảm I/O.
   - **Loại bỏ N+1 Query**: Gom bằng `JOIN` hoặc `WHERE id IN (...)` / batch fetch thay vì query trong vòng lặp code.
   - **Phân trang sâu**: Với bảng lớn, ưu tiên Keyset Pagination (`WHERE id < ? ORDER BY id DESC LIMIT ?`) thay vì `OFFSET` hàng trăm nghìn dòng.

---

## 2. Chống Deadlock & Race Condition
- Khi cập nhật nhiều bảng/nhiều dòng trong một transaction: **luôn khóa tài nguyên theo một thứ tự cố định** (ví dụ `ORDER BY id ASC` trước khi `SELECT ... FOR UPDATE` / `UPDLOCK`).
- Giữ transaction thật ngắn: chuẩn bị dữ liệu và gọi API bên ngoài (thanh toán, email) ở **ngoài** transaction DB khi có thể.
- Dùng câu lệnh nguyên tử (`UPDATE inventory SET stock = stock - ? WHERE id = ? AND stock >= ?`) kết hợp kiểm tra `rowsAffected == 1`.
