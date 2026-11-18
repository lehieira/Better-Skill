---
name: api-load-testing-k6
description: "Viết kịch bản kiểm thử chịu tải API bằng k6 (smoke, load, stress, spike test), thiết lập ngưỡng SLA thresholds (p95/p99 latency, error rate), kiểm tra rò rỉ connection pool/rate limit và phân tích điểm nghẽn."
---

# Skill: API Load Testing (k6)

Đo đạc sức chịu đựng thực tế của API và DB trước khi mở lưu lượng lớn hoặc lên production.

---

## 1. Bốn Kịch Bản Chuẩn & Ngưỡng Thresholds
1. **Smoke Test** (`1–2 VUs`, 30s): Xác nhận script đúng logic, không lỗi 500 trước khi tăng tải.
2. **Average Load Test**: Mô phỏng tải bình thường + cao điểm kỳ vọng trong 5–10 phút.
3. **Stress / Breakpoint Test**: Tăng dần `ramping-vus` để tìm ngưỡng bão hòa CPU, RAM hoặc DB connection pool.
4. **Spike Test**: Tăng đột biến lưu lượng trong thời gian ngắn để kiểm tra cơ chế auto-scale và rate limit.

---

## 2. Quy Tắc Thiết Kế Script `k6` Chính Xác
- **Đặt `thresholds` cứng để pass/fail tự động**:
  ```javascript
  export const options = {
    thresholds: {
      http_req_failed: ['rate<0.01'],      // lỗi < 1%
      http_req_duration: ['p(95)<400', 'p(99)<1000'],
    },
  };
  ```
- **Gắn `check()` cho status code và schema JSON** (tránh tình trạng server trả `200` nhưng body lỗi hoặc rate limit `429` không mong muốn bị bỏ sót).
- **Tránh Thundering Herd Giả Tạo**: Dùng `sleep(1)` hợp lý mô phỏng think-time người dùng thật giữa các bước; phân tách tải `GET` và `POST`/`PATCH` theo đúng tỷ lệ thực tế.
- **Chỉ chạy nhắm vào local/staging/sandbox được phép** — tuyệt đối không bắn stress test vào hệ thống production đang phục vụ khách thật khi chưa được duyệt.
