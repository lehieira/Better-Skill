---
name: speckit-tasks
description: "Phase 3 Spec Kit: Phân rã spec.md và plan.md thành danh sách tác vụ nguyên tử 2-5 phút (.specify/specs/<feature>/tasks.md), gắn mã AC-xx, thứ tự phụ thuộc và cặp TDD Test-First trước Implementation. Dùng ngay sau speckit-plan."
---

# Skill: Spec Kit — Bite-Sized Tasks (Phase 3)

Chia nhỏ kế hoạch kiến trúc thành các nhiệm vụ độc lập, nhỏ gọn (2–5 phút/task), giúp thực thi TDD kỷ luật và dễ kiểm soát hồi quy.

---

## 1. Nguyên Tắc Phân Rã Task
1. **Nhỏ & Nguyên tử**: Mỗi task chỉ chạm 1–2 file hoặc 1 unit logic/component rõ ràng.
2. **TDD First**: Với mọi task logic/API/DAO/Service, bước viết Test (để thấy FAIL) **phải nằm trước** bước viết Implementation.
3. **Traceability**: Mọi task đều phải gắn ít nhất 1 mã `AC-xx` từ `spec.md` (hoặc ghi rõ `[Infra/Foundation]`).
4. **Đánh dấu song song**: Dùng thẻ `[P]` cho các task cùng tầng không chạm chung file và không phụ thuộc lẫn nhau.

---

## 2. Đầu Ra Bắt Buộc: `.specify/specs/<feature-slug>/tasks.md`

```markdown
# Tasks: <Tên tính năng>

## Phase A: Foundation / Schema / Types
- [ ] T001 [Foundation] Tạo schema/migration & validation DTO tại `<file>`

## Phase B: Backend / Business Logic (TDD Red -> Green)
- [ ] T002 [AC-01, AC-02] Viết unit/integration tests cho `<service/endpoint>` (kỳ vọng FAIL)
- [ ] T003 [AC-01, AC-02] Cài đặt `<service/endpoint>` với query scoping & transaction để PASS T002

## Phase C: Frontend / UI Integration
- [ ] T004 [P] [AC-03] Viết component tests cho 4 trạng thái (Loading/Empty/Error/Data) & double-submit
- [ ] T005 [AC-03] Cài đặt UI component tuân thủ design tokens & a11y để PASS T004

## Phase D: Verification Gate
- [ ] T006 Chạy full test suite, lint, typecheck/build và đối soát 100% AC trong `spec.md`
```

---

## 3. Checklist Trước Khi Sang Phase 4 (`speckit-implement`)
1. Không có task nào gộp cả Backend + Frontend + DB chung 1 đầu việc lớn.
2. Không có task nào thiếu bước test hoặc thiếu file đích cụ thể.
3. Thứ tự phụ thuộc đảm bảo chạy được test liên tục qua từng task mà không gãy build giữa chừng.
