---
name: incident-postmortem-runbook
description: "Quy trình phản ứng sự cố production (triage, khoanh vùng bán kính ảnh hưởng, quyết định rollback/feature-flag, bảo toàn log bằng chứng) và viết tài liệu Postmortem (RCA + Action Items phòng ngừa). Dùng khi hệ thống đang lỗi trên môi trường live/staging."
---

# Skill: Incident Response & Postmortem Runbook

Ưu tiên hàng đầu khi sự cố xảy ra là **khôi phục dịch vụ an toàn nhanh nhất**, sau đó mới tìm hiểu gốc rễ và ngăn tái diễn.

---

## 1. Quy Trình Xử Lý Khẩn (Mitigate First)

1. **Đánh Giá Mức Độ & Khoanh Vùng (Triage)**:
   - Xác định ảnh hưởng: toàn hệ thống hay 1 endpoint/tenant? Lỗi bắt đầu từ mốc thời gian/deploy/migration nào?
2. **Bảo Toàn Bằng Chứng Trước Khi Khởi Động Lại**:
   - Lưu snapshot log lỗi, metric bất thường, mã lỗi HTTP và phiên bản commit/tag đang chạy.
3. **Khôi Phục Dịch Vụ An Toàn**:
   - Nếu mới deploy -> ưu tiên **Rollback** về tag ổn định gần nhất (hoặc tắt feature flag / revert commit lỗi).
   - Nếu có DB migration đi kèm -> kiểm tra tương thích ngược của dữ liệu trước khi rollback app; không chạy lệnh xóa dữ liệu nóng vội.
4. **Xác Nhận Phục Hồi**: Kiểm tra `/readyz`, luồng nghiệp vụ chính và tỷ lệ lỗi `5xx` trở về mức bình thường.

---

## 2. Cấu Trúc Tài Liệu Postmortem (Blameless RCA)
- **Tóm tắt sự cố & Impact**: Thời gian bắt đầu/kết thúc, số user/request bị ảnh hưởng.
- **Timeline chi tiết**: Mốc phát hiện -> điều tra -> giảm thiểu -> phục hồi hoàn toàn.
- **Root Cause (5 Whys)**: Nguyên nhân kỹ thuật gốc rễ và lý do lỗ hổng lọt qua test/CI.
- **Action Items (Có người chịu trách nhiệm & tiêu chí hoàn thành)**:
  - Sửa bug gốc + thêm Regression Test (`speckit-bug-*`).
  - Bổ sung alert / guard / CI check để không thể lặp lại lỗi tương tự.
