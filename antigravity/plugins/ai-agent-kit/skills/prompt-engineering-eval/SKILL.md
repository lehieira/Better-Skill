---
name: prompt-engineering-eval
description: "Thiết kế prompt sản phẩm cho LLM (system prompt, few-shot, structured JSON output, chống prompt injection) kèm bộ đánh giá định lượng (Eval dataset, rubric chấm điểm, đo latency/cost). Dùng khi tích hợp tính năng AI vào ứng dụng."
---

# Skill: Prompt Engineering & Evals

Chuyển việc viết prompt từ thử-sai cảm tính thành quy trình kỹ thuật có schema ràng buộc và benchmark đo đạc được.

---

## 1. Thiết Kế Prompt Có Cấu Trúc & Phòng Vệ
1. **Phân Tách Rõ Vai Trò & Ranh Giới Dữ Liệu**:
   - Đặt chỉ thị hệ thống (`system`) tách biệt hoàn toàn với dữ liệu người dùng hoặc tài liệu truy xuất (`<user_input>`, `<context>`).
   - Bổ sung hướng dẫn xử lý fallback tường minh khi thiếu dữ liệu (*"Trả về `insufficient_context`, không tự bịa"*).
2. **Structured Output Bắt Buộc**:
   - Dùng JSON Schema / Pydantic / Zod schema cho mọi đầu ra được code tiêu thụ; xác thực lại output ở server trước khi xử lý tiếp.
3. **Chống Prompt Injection & Lạm Dụng Chi Phí**:
   - Không tin tưởng dữ liệu từ web/file upload đưa vào prompt như là lệnh điều khiển.
   - Đặt `max_tokens`, timeout hợp lý và rate limit theo user/IP (kết hợp `vercel-prelaunch-checklist`).

---

## 2. Quy Trình Đánh Giá (Evals Before Shipping)
- Xây dựng bộ test tối thiểu **15–30 mẫu** đại diện: *Happy path*, *Edge cases (rỗng, đa ngôn ngữ, quá dài)* và *Adversarial cases (prompt injection, câu hỏi ngoài phạm vi)*.
- Đo 3 nhóm chỉ số trước và sau khi sửa prompt: **Schema Validity Rate (100%)**, **Task Accuracy / Groundedness**, và **Token Cost + p95 Latency**.
