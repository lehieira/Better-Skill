---
name: web-performance-optimizer
description: "Đo lường và tối ưu hiệu năng Frontend & Core Web Vitals (LCP, INP, CLS): code splitting, font/image optimization, chống request waterfall, memoization có đo đạc và giảm JS bundle. Không dùng cho tối ưu SQL query backend (dùng sql-tuning-stored-proc hoặc database-architect-migrator)."
---

# Skill: Web Performance Optimizer

Tối ưu tốc độ tải trang và độ mượt tương tác dựa trên số liệu Core Web Vitals thực tế, tránh tối ưu mù quáng.

---

## 1. Xử Lý Theo 3 Chỉ Số Core Web Vitals

| Chỉ số | Nguyên nhân phổ biến | Giải pháp ưu tiên |
| :--- | :--- | :--- |
| **LCP** (< 2.5s) | Ảnh hero nặng, lazy-load nhầm ảnh above-the-fold, CSS/JS chặn render | Đặt `priority`/`fetchPriority="high"` cho ảnh LCP, định dạng AVIF/WebP, dùng `next/font` hoặc `font-display: swap` |
| **CLS** (< 0.1) | Ảnh/iframe/ads thiếu kích thước, font fallback nhảy dòng, banner chèn đẩy nội dung | Khai báo `width`/`height` hoặc `aspect-ratio`, skeleton giữ đúng kích thước khối thật |
| **INP** (< 200ms) | Main thread bị chặn bởi JS nặng, re-render toàn cây component khi gõ input | Debounce search/filter, tách state cục bộ xuống component con, virtualization cho danh sách dài (> 100 dòng) |

---

## 2. Loại Bỏ Request Waterfall & Bundle Phình To
- Gọi song song các fetch độc lập (`Promise.all`) thay vì `await` nối tiếp nhau.
- Lazy-load (`dynamic()` / `React.lazy`) cho thư viện nặng chỉ dùng theo thao tác (biểu đồ, trình soạn thảo rich text, export PDF/Excel).
- Kiểm tra kích thước bundle trước và sau thay đổi; không cài thư viện cồng kềnh khi native Web API hoặc hàm 10 dòng làm tốt hơn.
