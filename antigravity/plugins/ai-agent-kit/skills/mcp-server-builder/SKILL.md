---
name: mcp-server-builder
description: "Xây dựng custom Model Context Protocol (MCP) Server bằng TypeScript hoặc Python: thiết kế tool/resource/prompt schema rõ ràng, validate input chặt chẽ, xử lý lỗi thân thiện cho LLM và đóng gói an toàn. Không dùng để xây MCP Apps có UI panel (dùng built-in mcp-app-development)."
---

# Skill: MCP Server Builder

Tạo mới các MCP Server tin cậy giúp Agent kết nối an toàn với API nội bộ, database hoặc công cụ chuyên biệt.

---

## 1. Thiết Kế Tool Interface Thân Thiện Cho Agent
- **Đặt tên rõ hành động (`verb_noun`)** và gom thao tác hợp lý (tránh tạo 40 tool vụn vặt làm loãng context).
- **Schema Đầu Vào Chặt Chẽ**: Dùng Zod (TS) hoặc Pydantic (Python) kèm `.describe()` rõ định dạng, đơn vị, giới hạn; đặt `limit` mặc định nhỏ và trần cứng chống tràn context trả về.
- **Phân Định Rõ Read vs Destructive Tool**: Đánh dấu annotation (`readOnlyHint`, `destructiveHint`, `idempotentHint`) trung thực để client yêu cầu xác nhận đúng chỗ.

---

## 2. Bảo Mật & Vận Hành Server
- **Không lộ secret trong tool output hay error message**: Catch exception tập trung, trả thông báo lỗi ngắn gọn giúp agent tự phục hồi (kèm gợi ý tham số hợp lệ), ghi log chi tiết ra `stderr` (với transport `stdio` — **tuyệt đối cấm `console.log`/`print` ra `stdout` làm hỏng JSON-RPC stream**).
- **Validate Path & Query**: Nếu tool đọc file/query DB -> chống path traversal (`path.resolve` nằm trong root cho phép) và chỉ dùng parameterized query.
- **Kiểm Thử**: Viết unit test cho từng tool handler + kiểm tra bằng MCP Inspector / smoke test JSON-RPC `tools/list` và `tools/call`.
