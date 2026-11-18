---
name: etl-csv-excel-pipeline
description: "Xây dựng pipeline đọc/ghi/làm sạch dữ liệu CSV, Excel, JSONL dung lượng lớn theo streaming/batch, validate schema từng dòng, báo cáo lỗi theo dòng và chống CSV Formula Injection khi export. Không dùng để commit file dữ liệu thật lên Git (vi phạm secret-leak-prevention)."
---

# Skill: ETL CSV & Excel Pipeline

Xử lý nhập/xuất dữ liệu bảng biểu lớn ổn định RAM, rõ ràng lỗi từng dòng và an toàn tuyệt đối khi xuất file cho người dùng tải về.

---

## 1. Import Dữ Liệu Lớn (Streaming & Row-Level Validation)
- **Giới hạn kích thước & Streaming**: Kiểm tra MIME type + kích thước tối đa; đọc bằng stream/chunk (ví dụ batch 500–1000 dòng), không load nguyên file Excel khổng lồ vào RAM.
- **Validate Schema Từng Dòng**: Chuẩn hóa encoding (UTF-8 BOM cho tiếng Việt), trim khoảng trắng, kiểm tra kiểu dữ liệu/enum/ràng buộc.
- **Chiến Lược Giao Dịch & Báo Lỗi**:
  - Thu thập danh sách lỗi chi tiết `{ rowNumber, column, message }` trả về báo cáo rõ ràng.
  - Chọn rõ giữa **All-or-Nothing** (bọc Transaction, fail 1 dòng -> rollback toàn bộ) hoặc **Partial Import** (ghi dòng hợp lệ bằng upsert idempotent, xuất file lỗi các dòng sai).

---

## 2. Export An Toàn & Chống Rò Rỉ
- **Chống CSV/Excel Formula Injection**: Mọi ô string bắt đầu bằng `=`, `+`, `-`, `@`, `\t`, `\r` phải được prefix bằng dấu nháy đơn `'` (hoặc escape an toàn) trước khi xuất.
- **Phân quyền & Dữ liệu**: Kiểm tra quyền sở hữu/tenant trước khi export; **tuyệt đối không lưu file CSV/XLSX chứa PII vào repo Git** (`secret-leak-prevention`).
