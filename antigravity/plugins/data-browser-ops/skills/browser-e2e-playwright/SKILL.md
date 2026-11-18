---
name: browser-e2e-playwright
description: "Thiết kế và debug kiểm thử trình duyệt E2E bằng Playwright: cấu trúc Page Object Model, selector bền vững (getByRole/getByLabel/data-testid), tái sử dụng auth storageState, auto-waiting không sleep cứng và trace debugging."
---

# Skill: Browser E2E Playwright Architect

Xây dựng bộ test trình duyệt end-to-end tin cậy, chạy được trên CI và dễ truy vết khi fail.

---

## 1. Quy Chuẩn Viết Test Bền Vững (Anti-Flaky)
1. **Ưu Tiên Selector Ngữ Nghĩa**:
   - Thứ tự ưu tiên: `getByRole` / `getByLabel` / `getByText` (kiểm tra luôn khả năng tiếp cận a11y) -> `getByTestId`.
   - **Cấm dùng CSS class auto-generated hoặc XPath dài dễ gãy**.
2. **Không Dùng `waitForTimeout()` Cứng**:
   - Dùng web-first assertions tự động chờ (`await expect(locator).toBeVisible()`, `waitForResponse`) thay cho sleep cố định.
3. **Cô Lập Dữ Liệu & Auth StorageState**:
   - Đăng nhập 1 lần qua setup project lưu `storageState` (gitignore file auth state!).
   - Mỗi test tạo dữ liệu với prefix/ID riêng (`test-...`) và dọn sạch sau khi xong để chạy song song nhiều worker không đụng nhau.
4. **Page Object Model (POM) Gọn Nhẹ**:
   - Gom locator & thao tác trang vào class/module Page Object khi có nhiều test dùng chung một trang; không trừu tượng hóa quá mức gây khó đọc.
5. **Chẩn Đoán Lỗi Nhanh**: Bật `trace: 'on-first-retry'`, `screenshot: 'only-on-failure'` trong `playwright.config`.
