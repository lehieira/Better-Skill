---
name: docker-compose-architect
description: "Thiết kế Dockerfile multi-stage tối ưu image, chạy non-root user, .dockerignore sạch secret và docker-compose.yml với healthcheck, dependency order và volume isolation. Dùng khi containerize hoặc cấu hình môi trường Docker dev/prod."
---

# Skill: Docker & Compose Architect

Xây dựng container nhẹ, build nhanh theo layer cache và hạn chế tối đa bề mặt tấn công trong runtime.

---

## 1. Quy Chuẩn `Dockerfile` Production-Ready
1. **Multi-Stage Build**:
   - Stage `deps`/`builder`: cài build tools và compile mã nguồn; Stage `runner`: dùng base image tối giản (`alpine`/`distroless`/`slim`) gắn phiên bản cụ thể (tránh `:latest` trôi nổi).
   - Tối ưu layer cache: copy `package*.json` / `requirements.txt` / `pom.xml` và chạy install **trước** khi `COPY . .`.
2. **Bảo Mật Container**:
   - Tạo và chuyển sang **non-root user** (`USER appuser`) trước `CMD`/`ENTRYPOINT`.
   - Tuyệt đối không `COPY .env*` hay private key vào image; bắt buộc tạo `.dockerignore` loại bỏ `.git`, `node_modules`, `.env*`, `*.log`, `*.sqlite`, `tests/`.
   - Truyền runtime secrets qua environment variables hoặc Docker secrets, không bake qua `ARG`/`ENV` chứa giá trị thật.

---

## 2. Quy Chuẩn `compose.yaml`
- Mọi service stateful (`postgres`, `redis`, `mysql`) phải có **`healthcheck`** rõ ràng (`pg_isready`, `redis-cli ping`) và named volume riêng.
- Service app dùng `depends_on: { db: { condition: service_healthy } }` thay vì chờ mù hoặc `sleep`.
- Chỉ expose port cần thiết ra `127.0.0.1:<port>:<port>` ở local dev; cô lập service nội bộ trên bridge network riêng.
- Kiểm chứng sau khi viết: `docker compose config` (valid syntax) + `docker compose build` + `docker compose up -d` kiểm tra status `healthy`.
