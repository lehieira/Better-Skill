---
name: api-contract-designer
description: "Thiết kế hợp đồng API (REST/OpenAPI, tRPC, GraphQL): quy ước endpoint, status code, error envelope RFC 7807, cursor/offset pagination, idempotency và API versioning. Chuyên thiết kế contract; phần cài đặt bảo mật chi tiết dùng hardened-backend-security."
---

# Skill: API Contract Designer

Định nghĩa hợp đồng giao tiếp rõ ràng, nhất quán và dễ mở rộng giữa Frontend, Mobile và Backend/External Webhooks.

---

## 1. Quy Chuẩn Thiết Kế Endpoint & Payload

1. **Định Danh Tài Nguyên & Method**:
   - Dùng danh từ số nhiều kebab-case: `/api/v1/order-items`, `/api/v1/invoices/{id}/cancel`.
   - `GET` (idempotent, an toàn), `POST` (tạo mới / action có side-effect), `PATCH` (cập nhật từng phần theo whitelist), `DELETE` (xóa hoặc soft-delete).
2. **Response & Error Envelope Thống Nhất (RFC 7807 Problem Details)**:
   - Thành công trả đúng payload/DTO sạch (`{ data, meta }` hoặc object trực tiếp theo chuẩn dự án).
   - Lỗi luôn trả cấu trúc thống nhất:
     ```json
     {
       "type": "https://errors.example.com/validation-error",
       "title": "Dữ liệu đầu vào không hợp lệ",
       "status": 400,
       "code": "VALIDATION_ERROR",
       "requestId": "req_01J...",
       "errors": [{ "field": "quantity", "message": "Phải lớn hơn 0" }]
     }
     ```
3. **Pagination & Filtering Chuẩn**:
   - Hỗ trợ `limit` có trần cứng (mặc định `20`, tối đa `100`), kèm `nextCursor` (cho dữ liệu lớn/realtime) hoặc `page`/`total` (cho bảng quản trị).
   - Whitelist danh sách field được phép `sort` và `filter`.
4. **Idempotency & Versioning**:
   - Mọi `POST` tạo giao dịch/thanh toán/đơn hàng hỗ trợ header `Idempotency-Key`.
   - Không breaking change trên version cũ (chỉ thêm optional field; đổi kiểu/xóa field phải nâng version hoặc deprecate có lộ trình).
