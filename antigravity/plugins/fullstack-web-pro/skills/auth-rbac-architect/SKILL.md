---
name: auth-rbac-architect
description: "Thiết kế luồng xác thực và phân quyền (Session cookie, JWT, OAuth2/OIDC, RBAC/ABAC, CSRF, refresh token rotation, password hashing và rate limiting). Dùng khi xây dựng login, phân quyền hoặc bảo vệ route; kết hợp cùng hardened-backend-security."
---

# Skill: Auth & RBAC Architect

Thiết kế hệ thống xác thực và kiểm soát truy cập chặt chẽ ở tầng server, chống leo thang đặc quyền và chiếm đoạt phiên.

---

## 1. Xác Thực & Quản Lý Phiên (Session / Token)
- **Password Hashing**: Chỉ dùng `argon2id` hoặc `bcrypt` (cost >= 12); chuẩn hóa email lowercase/trim, không phân biệt thông báo sai email vs sai mật khẩu khi login (`Invalid credentials`).
- **Cookie Session** *(ưu tiên cho Web App)*: Bắt buộc cờ `HttpOnly`, `Secure` (production), `SameSite=Lax` (hoặc `Strict`), `Path=/`. Không lưu JWT/refresh token vào `localStorage`.
- **JWT & Refresh Token Rotation** *(khi dùng stateless/mobile)*: Access token ngắn hạn (5–15 phút); Refresh token lưu hash trong DB, xoay vòng mỗi lần refresh và thu hồi toàn bộ chuỗi nếu phát hiện dùng lại (reuse detection).

---

## 2. Phân Quyền RBAC/ABAC & Chống Leo Thang Đặc Quyền
- **Deny by default**: Mọi route/action mặc định từ chối trừ khi khai báo rõ vai trò/quyền hợp lệ.
- **Kiểm tra 2 lớp**:
  1. Role/Permission guard (`requireRole` / `requirePermission`) ở server handler/middleware.
  2. Ownership scoping (`WHERE id = ? AND owner_id = ?`) ngay trong truy vấn DB.
- **Thao tác nhạy cảm**: Đổi mật khẩu/email, kích hoạt 2FA, thu hồi API key phải yêu cầu xác thực lại mật khẩu hiện tại và vô hiệu hóa các session cũ.
- **Chống Brute-Force & CSRF**: Rate limit theo IP + tài khoản cho `/login`, `/register`, `/forgot-password`, `/verify-otp`; kiểm tra `Origin`/`Referer` hoặc CSRF token cho form/cookie mutation.
