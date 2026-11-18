# Feature Spec: Better-Skill Cross-Platform Installer & Terminal Pack

## 1. Mục tiêu & Phạm vi
- **Mục tiêu nghiệp vụ**: Xây dựng bộ cài đặt đa nền tảng (`Windows` & `Linux`) cho repo `Better-Skill` giúp cài đặt tự động toàn bộ hệ sinh thái Antigravity (9 Rules, 24 Global Core Skills, 5 Plugins / 17 Skills, `AGENTS.md`), tự động nhận diện bề mặt Antigravity đang sử dụng (CLI, App, IDE, VS Code extension) và tự cài Terminal + PowerShell 7 + Oh My Posh + FiraCode Nerd Font + theme/profile y hệt máy mẫu.
- **In-Scope**:
  - Đóng gói sạch `antigravity/` (`AGENTS.md`, `README.md`, `rules/`, `skills/`, `plugins/`) không chứa secret, PII hay đường dẫn cá nhân cứng.
  - Đóng gói `terminal/` (`custom.omp.json`, `PowerShell 7` & `Windows PowerShell` profiles, `Windows Terminal` template).
  - Module nhận diện bề mặt `scripts/detect-antigravity.ps1` và `scripts/detect-antigravity.sh` (CLI / Desktop App / IDE / VS Code extension).
  - Bộ cài `install.ps1` (tương thích PS 5.1 & Pwsh 7, chạy cả local lẫn remote `irm | iex`) và `install.sh` (Ubuntu/Debian/Fedora/Arch, chạy cả local lẫn `curl | bash`).
  - Merge an toàn cấu hình cũ (backup `.bak.<timestamp>` trước khi ghi).
  - Bộ kiểm thử tự động (`tests/BetterSkill.Tests.ps1`, `tests/test_linux.sh`) + đẩy sạch lên `https://github.com/lehieira/Better-Skill.git`.
- **Out-of-Scope**:
  - Không đồng bộ lịch sử chat (`conversations/`), `brain/`, `config.json` máy cá nhân hoặc credentials lên GitHub.
  - Không tự ý bật/tắt plugin trong `config.json` của người dùng bằng ghi đè thô.

## 2. Actors & User Flows
- **Actor**: Lập trình viên cài trên máy mới hoặc đồng bộ sang máy Windows/Linux khác (có thể đã cài sẵn CLI, App, IDE, VS Code extension hoặc chưa cài bất kỳ bề mặt nào).
- **Luồng chính**:
  1. Người dùng chạy `install.ps1` (Windows) hoặc `install.sh` (Linux) từ local hoặc one-liner trên GitHub.
  2. Script kiểm tra công cụ & cài gói còn thiếu (Windows Terminal, PowerShell 7, Oh My Posh, FiraCode Nerd Font, Git) trừ khi truyền `--skip-package-install`.
  3. Script nhận diện các bề mặt Antigravity hiện có trên máy và thông báo rõ từng bề mặt tìm thấy.
  4. Script đồng bộ `AGENTS.md`, `rules/`, `skills/` (tới cả `~/.gemini/config/skills/*/SKILL.md` và `~/.gemini/skills/*/skill.md`), `plugins/` (tới `~/.gemini/config/plugins/`), và tùy chọn `.agents/` nếu có `--workspace`.
  5. Script backup `.bak` và merge theme Oh My Posh (`custom.omp.json`), PowerShell profile, Windows Terminal `settings.json` (profile `/~` với `FiraCode Nerd Font Mono`), và terminal font trong VS Code/Antigravity IDE `settings.json`.
  6. Chạy xác minh lại bộ skill vừa cài (`0 errors`).

## 3. Ràng Buộc Kỹ Thuật & An Ninh
- **Secret & PII Hygiene** (`secret-leak-prevention`): Tuyệt đối không chứa đường dẫn user cá nhân cứng (`C:\Users\<username>`), email cá nhân, SĐT, token, `.env`, `*.db`, `*.log` trong repo đẩy lên GitHub.
- **Safe Merge & Idempotency**: Chạy `install.ps1` / `install.sh` nhiều lần không làm nhân đôi dòng trong PowerShell/Bash profile và không làm mất profile/keybinding khác trong Windows Terminal hoặc VS Code.
- **PS 5.1 Backward Compatibility**: `install.ps1` và `detect-antigravity.ps1` phải chạy được ngay trên Windows PowerShell 5.1 mặc định của Windows trước khi PowerShell 7 được cài.

## 4. Tiêu Chí Nghiệm Thu (Acceptance Criteria)
- **AC-01**: Given thư mục `Better-Skill/antigravity/`, When chạy `validate_skills.ps1` trỏ vào bộ đóng gói và sau khi cài vào `$TargetHome`, Then tất cả 24 global skills + 17 plugin skills (5 plugins) pass với `0 errors`.
- **AC-02**: Given môi trường giả lập có `agy`, `.gemini/antigravity`, `.gemini/antigravity-ide`, hoặc `.vscode/extensions/*antigravity*`, When chạy `detect-antigravity.ps1` / `detect-antigravity.sh`, Then nhận diện chính xác từng bề mặt (`cli`, `app`, `ide`, `vscode_ext`) trên cả Windows và Linux.
- **AC-03**: Given máy Windows trống (isolated `$TargetHome`), When chạy `install.ps1 -TargetHome <tmp> -SkipPackageInstall`, Then tạo đủ `~/.gemini/config/{skills,plugins,rules}`, `~/.gemini/{skills,rules,AGENTS.md}`, `~/.config/oh-my-posh/custom.omp.json` và profiles PowerShell 7 + 5.1.
- **AC-04**: Given file `settings.json` của Windows Terminal đã có sẵn profile `Ubuntu` và keybinding riêng, When chạy `install.ps1` (merge mode), Then tạo file `.bak.*`, giữ nguyên `Ubuntu` + keybinding cũ, thêm/cập nhật profile `/~` (`💫`, `FiraCode Nerd Font Mono`, size `10`, `semi-bold`) làm `defaultProfile` với đường dẫn `pwsh.exe` động.
- **AC-05**: Given chạy `install.ps1` hoặc `install.sh` lần thứ 2 liên tiếp (idempotent), When kiểm tra PowerShell profile / `.bashrc`, Then block `oh-my-posh` chỉ xuất hiện đúng 1 lần.
- **AC-06**: Given môi trường Linux (WSL Ubuntu `bash`), When chạy `install.sh --target-home <tmp> --skip-package-install`, Then cài đủ 24 global skills + 5 plugins + 9 rules + `custom.omp.json` + `~/.config/powershell/Microsoft.PowerShell_profile.ps1` + `.bashrc` hook với exit code `0`.
- **AC-07**: Given tham số `-Workspace <dir>` / `--workspace <dir>`, When chạy installer, Then tạo đủ `<dir>/.agents/{skills,rules,plugins,AGENTS.md}`.
- **AC-08**: Given toàn bộ repo `Better-Skill`, When chạy bộ quét PII/Secret trong test suite, Then không phát hiện đường dẫn user cá nhân cứng, email/SĐT thật, token hay file nhạy cảm trước khi push lên GitHub.
