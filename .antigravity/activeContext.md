# Active Context

## Current Focus
- Hoàn tất toàn bộ bộ cài đa nền tảng `Better-Skill` (`install.ps1`, `install.sh`), module nhận diện bề mặt Antigravity (`detect-antigravity.ps1` & `.sh`), bộ 24 Global Core Skills + 5 Plugins (17 skills) + 9 Rules + Terminal/Oh My Posh/PowerShell 7 pack và đẩy lên GitHub `main`.

## Key Technical Decisions
- `install.ps1` và `scripts/detect-antigravity.ps1` tương thích cả Windows PowerShell 5.1 lẫn PowerShell 7 (xử lý scalar `.Count`, 2-arg path combine, UTF-8 without BOM).
- Merge an toàn cấu hình cũ (tạo `.bak.<timestamp>` trước khi cập nhật Windows Terminal / Profiles / IDE settings).
- Đóng gói tách biệt hoàn toàn khỏi state/credentials cá nhân (`config.json`, `conversations/`, `*.db`, `*.log`).

## Hot Files
- `install.ps1`, `install.sh`
- `scripts/detect-antigravity.ps1`, `scripts/detect-antigravity.sh`
- `tests/BetterSkill.Tests.ps1`, `tests/test_linux.sh`

## Next Steps
1. Người dùng có thể cài trên bất kỳ máy Windows/Linux mới bằng one-liner trong `README.md`.
