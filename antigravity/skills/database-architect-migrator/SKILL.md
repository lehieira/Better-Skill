---
name: database-architect-migrator
description: "Thiết kế schema CSDL quan hệ (ERD, chuẩn hóa, FK/Unique/Check constraints, composite indexes), tối ưu query với EXPLAIN ANALYZE và viết migration an toàn zero-downtime kèm rollback. Không dùng để vẽ biểu đồ thuần (dùng software-diagram-architect)."
---

# Skill: Database Architect & Migrator

Bảo đảm cấu trúc dữ liệu bền vững ở tầng DB (không chỉ dựa vào code ứng dụng) và thay đổi schema an toàn trên hệ thống đang chạy.

---

## 1. Nguyên Tắc Thiết Kế Schema Vững Chắc
1. **Ràng Buộc Tại Tầng DB**:
   - Dùng `NOT NULL`, `FOREIGN KEY`, `UNIQUE`, `CHECK` (ví dụ `balance >= 0`, `quantity > 0`) ngay trong SQL/Migration.
   - Tiền tệ dùng `DECIMAL(18,2)` hoặc số nguyên đơn vị nhỏ nhất (`BIGINT` cents/VND), **tuyệt đối cấm `FLOAT`/`DOUBLE`**.
   - Thời gian lưu `TIMESTAMPTZ` (UTC); mọi bảng nghiệp vụ có `created_at`, `updated_at` (và `deleted_at` nếu dùng soft-delete).
2. **Chiến Lược Index Đích Danh**:
   - Index cho mọi cột khóa ngoại (`FK`) và cặp cột trong `WHERE` + `ORDER BY` phổ biến (ưu tiên cột chọn lọc cao đứng trước trong composite index).
   - Kiểm tra kế hoạch thực thi (`EXPLAIN ANALYZE`) để loại bỏ Sequential Scan không cần thiết và lỗi N+1 query.

---

## 2. Quy Trình Migration Zero-Downtime (Expand-Contract)
1. **Mỗi thay đổi schema phải có đường Rollback**: Viết rõ `UP` và `DOWN` (hoặc script hoàn tác tương ứng).
2. **Tránh Lock Bảng Lâu & Breaking Change**:
   - Đổi tên/kiểu cột trên bảng lớn theo 3 bước: *Add cột mới (nullable) -> Dual-write & Backfill theo lô nhỏ -> Chuyển read sang cột mới rồi mới Drop cột cũ*.
   - Thêm cột `NOT NULL` trên bảng có sẵn dữ liệu: thêm nullable + default trước, backfill xong mới bật `SET NOT NULL`.
3. **Kiểm Thử Migration**: Chạy thử `migrate up` -> seed/test -> `migrate down` -> `migrate up` trên môi trường local/test DB trước khi bàn giao.
