---
name: skill-architect-generator
description: "Meta-Skill thiết kế, chuẩn hóa, kiểm định và đóng gói skill hoặc plugin Antigravity mới: quyết định đặt ở Global Skills vs Plugin vs references/, sinh SKILL.md chuẩn YAML frontmatter chống đụng độ trigger, đồng bộ 2 thư mục Windows và chạy scripts/validate_skills.ps1."
---

# Skill: Skill Architect & Generator (Skill Factory)

Dùng để mở rộng hệ sinh thái skill số lượng lớn một cách có kỷ luật, không trùng lặp tên, không phình context prompt và luôn qua kiểm định tự động.

---

## 1. Cây Quyết Định Nơi Đặt Skill Mới

| Tình huống sử dụng | Nơi lưu chuẩn | Lý do |
| :--- | :--- | :--- |
| Dùng cho **mọi dự án** (TDD, Debugging, Git, DB, Security) | Global Skills: `~/.gemini/config/skills/<name>/SKILL.md` *(+ sync `~/.gemini/skills/<name>/skill.md`)* | Luôn sẵn sàng mọi workspace |
| Dùng theo **stack / chuyên ngành riêng** (AI/RAG, Java, Android, DevOps) | Plugin: `~/.gemini/config/plugins/<pack>/skills/<name>/SKILL.md` + `plugin.json` | Bật/tắt live theo dự án, tiết kiệm token nền |
| Chỉ dùng cho **1 dự án cụ thể** | Workspace: `<repo>/.agents/skills/<name>/SKILL.md` | Chia sẻ theo Git của repo, ưu tiên cao nhất |
| Tài liệu chi tiết > 200 dòng, template mẫu dài | Tách vào `references/*.md` hoặc helper vào `scripts/*` trong cùng skill | Progressive Disclosure, giữ `SKILL.md` gọn |

---

## 2. Quy Chuẩn `SKILL.md` Chống Loãng Trigger
1. **Tên (`name`)**: Bắt buộc `lowercase-kebab-case`, trùng khít tên thư mục, không trùng built-in skill (`agy-customizations`, `antigravity-guide`, `plugin`, `run-workflow`, `swarm`, `automation`, ...).
2. **Mô tả (`description`)**: 1–3 câu súc tích gồm: **làm gì** + **khi nào kích hoạt** + **ranh giới không dùng** (*"Không dùng khi..."*) để tránh xung đột trigger với skill anh em.
3. **Nội dung thân (`SKILL.md`)**: Dưới 200 dòng, ưu tiên quy trình từng bước đánh số, checklist xác minh được và bảng quyết định thay vì văn xuôi dài.

---

## 3. Quy Trình Tạo & Đồng Bộ Trên Máy Windows

1. Tạo tại `~/.gemini/config/skills/<name>/SKILL.md` (hoặc `~/.gemini/config/plugins/<pack>/skills/<name>/SKILL.md`).
2. Nếu là **Global Skill**: đồng bộ bản giống hệt sang `~/.gemini/skills/<name>/skill.md` để cả Antigravity IDE và Antigravity CLI nạp nhất quán:
   ```powershell
   $name = "<skill-name>"
   New-Item -ItemType Directory -Force "$HOME\.gemini\skills\$name" | Out-Null
   Copy-Item -Force "$HOME\.gemini\config\skills\$name\SKILL.md" "$HOME\.gemini\skills\$name\skill.md"
   ```
3. **Bắt buộc chạy kiểm định tự động** sau mỗi lần thêm/sửa skill:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "$HOME\.gemini\config\skills\skill-architect-generator\scripts\validate_skills.ps1"
   ```
4. Xác nhận đầu ra `0 errors` và đối chiếu không có warning vượt quá `MaxRecommendedLines` không cần thiết.
