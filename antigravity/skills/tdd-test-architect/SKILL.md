---
name: tdd-test-architect
description: "Thiết kế kiến trúc kiểm thử (Unit, Integration, Contract, E2E) và kỹ thuật TDD, test fixtures, mocking boundary và test data ẩn danh. Dùng bổ trợ cho speckit-implement và speckit-tasks; không thay thế browser-e2e-playwright hay api-load-testing-k6."
---

# Skill: TDD Test Architect

Thiết kế bộ test có giá trị bảo vệ cao, chạy nhanh, không flaky và không phụ thuộc vào dữ liệu thật.

---

## 1. Ma Trận Chọn Tầng Kiểm Thử

| Tầng | Mục tiêu kiểm chứng | Quy tắc thiết kế |
| :--- | :--- | :--- |
| **Unit Test** | Pure logic, validator, parser, state machine, tính tiền/phân quyền | Chạy < 5ms/test; chỉ mock I/O bên ngoài, không mock logic đang test |
| **Integration Test** | API handler + Validation + DB query scoping + Transaction/Lock | Dùng test DB/testcontainers hoặc transaction rollback; test đủ 200/400/401/403/404/409 |
| **Contract Test** | Schema request/response giữa Frontend & Backend | Khớp DTO, kiểu dữ liệu, pagination và error envelope |
| **E2E Smoke** | Luồng sống còn (login -> tạo -> cập nhật -> xóa) | Giữ số lượng ít, ưu tiên `data-testid` / semantic role (`getByRole`), cấm `sleep` cứng |

---

## 2. Bốn Nguyên Tắc Chống Test Giả Tạo (Anti-False-Positive)
1. **Verify Red trước khi tin Green**: Bài test mới bắt buộc phải từng chạy FAIL khi logic chưa tồn tại.
2. **Test hành vi, không test chi tiết nội bộ**: Khẳng định output, DB state và HTTP status; tránh assert số lần gọi hàm nội bộ dễ gãy khi refactor.
3. **100% Dữ Liệu Ẩn Danh**: Dùng factory/faker với email `@example.com`/`@test.local`, SĐT giả định (`0900000000`) theo `secret-leak-prevention`.
4. **Độc Lập Thứ Tự Chạy**: Mỗi test tự tạo & dọn fixture riêng; chạy đơn lẻ hay chạy song song đều cho cùng kết quả.
