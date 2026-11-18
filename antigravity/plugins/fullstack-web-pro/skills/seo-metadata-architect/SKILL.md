---
name: seo-metadata-architect
description: "Thiết kế Technical SEO & Metadata: title/description động, canonical URL, OpenGraph/Twitter Card, JSON-LD Schema.org, sitemap.xml, robots.txt và i18n hreflang. Dùng cho trang web công khai cần index tìm kiếm."
---

# Skill: SEO & Metadata Architect

Đảm bảo các trang công khai được công cụ tìm kiếm thu thập đúng cấu trúc, hiển thị đẹp khi chia sẻ mạng xã hội và không bị trùng lặp index.

---

## 1. Checklist Technical SEO Cốt Lõi
1. **Semantic Heading & Cấu Trúc Trang**:
   - Đúng một thẻ `<h1>` mô tả chủ đề chính trên mỗi trang; thứ tự `h1 -> h2 -> h3` không nhảy cóc.
   - URL sạch, `lowercase-kebab-case`, có nghĩa.
2. **Metadata Động & Canonical**:
   - Thiết lập `title` (50–60 ký tự), `meta description` (120–160 ký tự) duy nhất cho từng trang sản phẩm/bài viết.
   - Khai báo `<link rel="canonical">` chuẩn hóa query params; đặt `robots: noindex, nofollow` cho trang admin, giỏ hàng, checkout, kết quả tìm kiếm nội bộ.
3. **OpenGraph & Twitter Card**:
   - Đủ `og:title`, `og:description`, `og:type`, `og:url`, `og:image` (tỷ lệ 1200x630px, URL tuyệt đối).
4. **Structured Data (JSON-LD)**:
   - Gắn Schema.org hợp lệ (`Organization`, `Product`, `Article`, `BreadcrumbList`, `FAQPage`) lấy từ dữ liệu thật của trang, escape an toàn chống XSS trong `<script type="application/ld+json">`.
5. **Sitemap & Robots**:
   - Sinh `sitemap.xml` động cho các URL public có thể index (`200 OK`); cấu hình `robots.txt` chặn crawl vùng admin/API nội bộ và trỏ thẳng tới `Sitemap: https://.../sitemap.xml`.
