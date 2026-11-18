---
name: java-servlet-mvc-architect
description: "Kiến trúc chuẩn Java Web (Filter -> Servlet -> Service -> DAO -> JSP/JSON): quản lý JDBC Connection Pool bằng try-with-resources, Transaction commit/rollback an toàn, PreparedStatement chống SQLi, session fixation protection và XSS escaping trên JSP."
---

# Skill: Java Servlet MVC Architect

Chuẩn hóa kiến trúc backend Java Servlet/JSP sạch, không rò rỉ connection DB và phòng vệ chặt chẽ ở mọi tầng.

---

## 1. Phân Tách Tầng Nghiêm Ngặt
- **`Filter`**: Xác thực session/token, kiểm tra role route Admin, đặt UTF-8 encoding, gán CSRF token và Security Headers (`X-Content-Type-Options`, `X-Frame-Options`).
- **`Servlet` (Controller)**: Chỉ parse & validate tham số đầu vào (chống ép kiểu sai `NumberFormatException`), gọi `Service`, chọn View/JSON DTO trả về. **Không viết SQL trong Servlet hoặc JSP**.
- **`Service`**: Điều phối nghiệp vụ và quản lý ranh giới **JDBC Transaction** (`conn.setAutoCommit(false)` -> `commit()` / `rollback()` trong `catch`, khôi phục `autoCommit` và đóng connection trong `finally`/try-with-resources).
- **`DAO`**: Chỉ thực thi `PreparedStatement` tham số hóa (`?`) và map `ResultSet` sang Model/DTO.

---

## 2. An Toàn Tài Nguyên & Bảo Mật Đặc Thù Java Web
1. **Chống Connection Leak**: Mọi `Connection`, `PreparedStatement`, `ResultSet` phải nằm trong `try-with-resources`.
2. **Session Fixation & CSRF**: Gọi `request.changeSessionId()` (hoặc tạo session mới) ngay sau khi đăng nhập thành công; mọi POST/PUT/DELETE form phải kiểm tra CSRF token hợp lệ.
3. **XSS Escaping trên JSP**: Luôn dùng `<c:out value="${...}" />` hoặc `fn:escapeXml(...)`, cấm xuất thẳng `${param.x}` hay scriptlet `<%= ... %>` chưa escape ra HTML.
4. **JSON API**: Dùng serializer (Jackson/Gson) qua DTO tường minh, không nối chuỗi JSON thủ công.
