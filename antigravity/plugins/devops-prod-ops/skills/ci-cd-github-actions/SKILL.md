---
name: ci-cd-github-actions
description: "Thiết kế pipeline GitHub Actions cho CI/CD: lint, typecheck, unit/integration test, dependency audit, secret scan, Docker/artifact build và release gate. Không thay thế quy trình deploy Vercel Preview trong vercel-sandbox-deployer."
---

# Skill: CI/CD GitHub Actions Architect

Tự động hóa kiểm định chất lượng và phát hành an toàn trước khi code được merge hoặc deploy.

---

## 1. Cấu Trúc Pipeline Chuẩn (Fast-Fail & Caching)
1. **Trigger & Concurrency**:
   - Chạy trên `pull_request` và `push` tới branch chính (`main`); dùng `concurrency: { group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true }` để tránh tốn runner.
2. **Quyền Hạn Tối Thiểu (Least Privilege)**:
   - Khai báo tường minh `permissions: { contents: read }` ở root; chỉ cấp `packages: write` hoặc `id-token: write` ở đúng job deploy cần thiết.
3. **Thứ Tự Job Hợp Lý**:
   - **Stage 1 (Nhanh < 2 phút)**: Checkout -> Cache dependencies -> Lint + Format check + Typecheck.
   - **Stage 2 (Kiểm thử)**: Unit & Integration tests (kèm service container DB/Redis nếu cần) + Coverage/Artifact.
   - **Stage 3 (An ninh & Build)**: Dependency audit (`npm audit --audit-level=high` / `pip-audit`) + Build production (`docker build` hoặc app build).
   - **Stage 4 (Deploy Gate)**: Chỉ chạy khi push tag/main và **đạt 100% Stage 1–3**, qua GitHub Environment Protection (`production` cần manual approval nếu nhạy cảm).

---

## 2. An Toàn Workflow
- Pin version của Action rõ ràng (ví dụ `actions/checkout@v4` hoặc commit SHA cho action bên thứ 3).
- Không nội suy trực tiếp input untrusted (`github.event.issue.title`, PR title/body) vào `run:` bash inline -> truyền qua `env:` để chống command injection.
- Không in `${{ secrets.* }}` ra stdout hoặc artifact.
