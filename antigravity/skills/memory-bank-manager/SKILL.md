---
name: memory-bank-manager
description: "Quản trị bộ nhớ phiên làm việc lâu dài qua thư mục .antigravity/ (activeContext.md, progress.md, decisions.md): khởi tạo template cho dự án mới, đọc đúng mục tiêu đầu phiên tránh full scan, cập nhật cuối phiên và nén/lưu trữ khi file quá dài."
---

# Skill: Memory Bank Manager

Đồng bộ hóa bộ nhớ dự án theo rule `memory-bank` để giữ ngữ cảnh liên tục giữa các phiên chat mà không lãng phí token quét lại toàn bộ repository.

---

## 1. Cấu Trúc Thư Mục `.antigravity/` Chuẩn

```text
.antigravity/
├── activeContext.md   # Trọng tâm hiện tại, quyết định gần nhất, file nóng, bước tiếp theo (< 120 dòng)
├── progress.md        # Checklist tính năng/bug đã xong [x] và đang mở [ ] (< 150 dòng)
└── decisions.md       # Tùy chọn: Nhật ký ADR ngắn về các quyết định kiến trúc quan trọng
```

---

## 2. Quy Trình Đầu Phiên (Session Start)
1. Kiểm tra `Test-Path .antigravity` trước khi đọc code.
2. Nếu tồn tại -> đọc ngay `activeContext.md` và `progress.md`, rồi chỉ đọc đúng các file được ghi chú trong mục `Hot Files`.
3. Nếu chưa tồn tại và đây là dự án dài hạn nhiều phiên -> hỏi người dùng hoặc khởi tạo gọn khi bắt đầu task đầu tiên được duyệt.

---

## 3. Template Chuẩn Khi Khởi Tạo / Cập Nhật

### `.antigravity/activeContext.md`
```markdown
# Active Context

## Current Focus
- Mục tiêu hiện tại và thay đổi vừa hoàn tất.

## Key Technical Decisions
- Stack, pattern, ràng buộc bảo mật/UI đang áp dụng.

## Hot Files (Đọc trực tiếp khi cần)
- `src/...` — <vai trò>

## Next Steps
1. Bước tiếp theo ưu tiên.
```

### `.antigravity/progress.md`
```markdown
# Project Progress

## Completed
- [x] <Task/Feature đã nghiệm thu + ngày>

## In Progress / Backlog
- [ ] <Task đang làm hoặc sắp làm>

## Known Issues / Risks
- <Vấn đề cần lưu ý nếu có>
```

---

## 4. Quy Trình Cuối Phiên & Nén Ngữ Cảnh (Session Wrap-up & Compaction)
1. Trước khi kết thúc task đã hoàn thành: cập nhật `Current Focus`, `Hot Files`, `Next Steps` trong `activeContext.md` và đánh dấu `[x]` trong `progress.md`.
2. **Chống phình context**: Khi `progress.md` vượt quá **150 dòng**, gộp các mục `[x]` cũ thành 1 dòng tóm tắt theo milestone hoặc chuyển sang `.antigravity/archive-progress.md` để file chính luôn gọn nhẹ.
