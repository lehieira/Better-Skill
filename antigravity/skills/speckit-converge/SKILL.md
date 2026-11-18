---
name: speckit-converge
description: "Phase 5 Spec Kit: Nghiệm thu đa chiều và chống thoái lui trước khi bàn giao hoặc deploy — chạy toàn bộ Test Suite/Lint/Typecheck/Build, đối soát từng Acceptance Criteria (AC-xx) trong spec.md và đồng bộ Memory Bank."
---

# Skill: Spec Kit — Verification & Convergence (Phase 5)

Cổng kiểm soát chất lượng cuối cùng trước khi bàn giao tính năng cho người dùng hoặc chuyển sang quy trình `vercel-prelaunch-checklist` / `vercel-sandbox-deployer`.

---

## 1. Quy Trình Nghiệm Thu 4 Bước Bắt Buộc

1. **Chạy Kiểm Tra Toàn Hệ Thống (Zero Regression)**:
   - Sau lần chỉnh sửa code cuối cùng, chạy lại **toàn bộ** test suite, linter, typechecker và build command của dự án.
   - Không được báo "pass" nếu có test bị skip, assertion bị nới lỏng, hoặc chỉ chạy một phần test cục bộ mà không nêu rõ phạm vi.
2. **Đối Soát 100% Acceptance Criteria (`spec.md`)**:
   - Kiểm tra từng `AC-01..AC-N`: xác nhận đã có test hoặc kết quả chạy thực tế chứng minh đạt.
   - Đảm bảo mọi task trong `tasks.md` đều ở trạng thái `[x]`.
3. **Rà Soát An Ninh & Sạch Mã Nguồn Nhanh**:
   - Kiểm tra `git diff` đảm bảo không còn `TODO`/`FIXME` giữ chỗ, không log secret/PII, không sửa thừa ngoài phạm vi.
   - Nếu dự án triển khai lên Vercel hoặc chuẩn bị push GitHub -> kích hoạt `secret-leak-prevention` và `vercel-prelaunch-checklist`.
4. **Đồng Bộ Bộ Nhớ Phiên (Session Wrap-up)**:
   - Cập nhật `.antigravity/activeContext.md` và `.antigravity/progress.md` theo quy tắc `memory-bank`.

---

## 2. Mẫu Báo Cáo Nghiệm Thu Bàn Giao
- **Tóm tắt thay đổi**: Danh sách file tạo mới/chỉnh sửa kèm link đường dẫn chuẩn.
- **Kết quả kiểm chứng thực tế**: Lệnh đã chạy (`test`, `lint`, `typecheck`, `build`) + số lượng pass/fail nguyên văn từ output.
- **Bảng đối soát AC**: `AC-xx` -> Trạng thái Đạt + Tên test/bằng chứng kiểm chứng.
- **Lưu ý / Việc còn mở** (nếu có giới hạn môi trường hoặc phần ngoài phạm vi).
