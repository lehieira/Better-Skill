---
name: observability-logging
description: "Thiết kế hệ thống giám sát và logging: structured JSON logs, correlation/request ID, che PII/secret trong log, healthcheck/readiness endpoints (/healthz, /readyz) và metrics cốt lõi. Dùng khi xây dựng backend production-ready."
---

# Skill: Observability & Logging

Đảm bảo khi hệ thống chạy thực tế có thể truy vết nhanh từng request lỗi mà không làm rò rỉ dữ liệu nhạy cảm.

---

## 1. Structured Logging & PII Redaction
- **Log dạng JSON có cấu trúc** (trên server): gồm `timestamp` (ISO-8601 UTC), `level` (`info`/`warn`/`error`), `requestId`, `service`, `method`, `path`, `statusCode`, `durationMs`, `message`.
- **Correlation / Request ID**:
  - Đọc `x-request-id` từ header (validate định dạng an toàn) hoặc sinh UUID mới ở middleware đầu vào; gắn vào mọi log trong vòng đời request và trả về header response để đối chiếu nhanh khi user báo lỗi.
- **Redaction Bắt Buộc (Che Dữ Liệu Nhạy Cảm)**:
  - Tuyệt đối không log `password`, `authorization`, `cookie`, `apiKey`, `token`, số CCCD, thẻ tín dụng hay raw request body nhạy cảm.
  - Cấu hình logger redact list tự động cho các key nhạy cảm (`*.password`, `*.token`, `req.headers.authorization`, `req.headers.cookie`).

---

## 2. Healthcheck & Signal Vận Hành
- Tách 2 endpoint rõ nghĩa:
  - **`GET /healthz` (Liveness)**: Xác nhận process sống, phản hồi `200 OK` nhanh không query nặng.
  - **`GET /readyz` (Readiness)**: Kiểm tra kết nối DB/Redis bằng timeout ngắn (1–2s); trả `503 Service Unavailable` (không kèm chi tiết credential/SQL) nếu dependency sập.
- Theo dõi 4 Golden Signals trên endpoint chính: **Latency (p95/p99), Traffic (RPS), Errors (tỷ lệ 5xx), Saturation (CPU/RAM/DB pool)**.
