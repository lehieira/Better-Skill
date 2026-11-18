---
name: git-workflow-hygiene
description: "Quản trị quy trình Git chuẩn: Conventional Commits, phân nhánh sạch, gộp/rebase không mất lịch sử, xử lý merge conflict an toàn và tạo release tag/changelog. Không thay thế cổng backup deploy Vercel trong vercel-sandbox-deployer."
---

# Skill: Git Workflow Hygiene

Giữ lịch sử Git rõ ràng, dễ truy vết (`git bisect`), dễ revert từng phần và an toàn tuyệt đối trước khi push.

---

## 1. Quy Chuẩn Commit & Branch
- **Branch naming**: `feat/<slug>`, `fix/<slug>`, `refactor/<slug>`, `chore/<slug>`, `docs/<slug>`.
- **Conventional Commits**: `<type>(<scope>): <mô tả ngắn gọn mệnh lệnh>`
  - Ví dụ: `feat(orders): enforce atomic stock deduction with idempotency key`
  - Các `type` chuẩn: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`, `revert`.
- **Atomic Commit**: Mỗi commit chỉ chứa 1 thay đổi logic hoàn chỉnh kèm test tương ứng; không trộn sửa format toàn file với logic fix.

---

## 2. Quy Trình An Toàn Trước Khi Commit / Push
1. Kiểm tra `git status` và `git diff --cached`:
   - Xác nhận không có file `.env`, secret, DB dump (`*.sql`, `*.csv`, `*.sqlite`), log hoặc file tạm lọt vào stage (kết hợp `secret-leak-prevention`).
2. **Xử Lý Merge / Rebase Conflict Có Kỷ Luật**:
   - Đọc hiểu cả hai nhánh (`HEAD` vs incoming) trước khi chọn giữ/gộp; **cấm bấm "accept all current/incoming" mù quáng**.
   - Sau khi resolve conflict -> bắt buộc chạy lại test suite + build trước khi `git rebase --continue` hoặc commit merge.
3. **Không Force Push Bừa Bãi**:
   - Tuyệt đối không `git push --force` lên `main`/`master`; nếu cần cập nhật branch cá nhân sau rebase chỉ dùng `--force-with-lease` khi được người dùng đồng ý.
