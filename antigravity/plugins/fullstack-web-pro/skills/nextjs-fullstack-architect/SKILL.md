---
name: nextjs-fullstack-architect
description: "Kiến trúc Next.js App Router & React hiện đại: phân tách ranh giới Server/Client Components, Server Actions an toàn, chiến lược caching/revalidation và streaming/Suspense. Không dùng cho thuần CSS/a11y cơ bản (đã có ui-ux-pro-architect)."
---

# Skill: Next.js Fullstack Architect

Thiết kế ứng dụng Next.js/React hiệu năng cao, không rò rỉ dữ liệu server ra client bundle và kiểm soát chặt chẽ mutation.

---

## 1. Ranh Giới Server vs Client Components
- **Mặc định dùng Server Component (`page.tsx`, `layout.tsx`, fetch DB/API nội bộ)**: giữ secret, SDK DB và logic nhạy cảm hoàn toàn trên server.
- **Chỉ đặt `'use client'` ở nút lá tương tác nhỏ nhất** (form, modal, chart, filter bar) — tránh gắn `'use client'` ở root layout gây phình JS bundle.
- **Không truyền object DB thô xuống Client Component**: luôn map qua DTO chỉ chứa field cần hiển thị.

---

## 2. Server Actions & Data Mutation An Toàn
- Mọi Server Action đều là **public HTTP endpoint**: bắt buộc kiểm tra **Auth Session + Role/Ownership (`user_id`/`tenant_id`) + Zod validation** ngay đầu hàm (tuân thủ `hardened-backend-security`).
- Bọc `revalidatePath` / `revalidateTag` đích danh sau mutation; dùng `useActionState` / pending state để chống double-submit.

---

## 3. Caching, Streaming & Error Boundary
- Dùng `<Suspense fallback={<Skeleton />}>` bọc vùng fetch chậm để tránh chặn toàn trang (streaming SSR) và giữ ổn định CLS.
- Phân tách rõ `loading.tsx`, `error.tsx` (có nút `reset()` thử lại) và `not-found.tsx` cho từng route segment.
- Ghi rõ `cache: 'no-store'` cho dữ liệu cá nhân nhạy cảm; tránh cache chéo giữa các user.
