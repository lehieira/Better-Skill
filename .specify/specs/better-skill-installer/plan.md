# Architectural Plan: Better-Skill Installer & Terminal Pack

## 1. Tổng Quan Kiến Trúc
- **Đóng gói chuẩn (`antigravity/` + `terminal/`)**: Copy có chọn lọc và chuẩn hóa từ `~/.gemini` và cấu hình terminal máy mẫu, loại bỏ hoàn toàn đường dẫn cứng hoặc tên user cá nhân.
- **Tách Module Nhận Diện (`scripts/detect-antigravity.ps1` & `.sh`)**: Trả về object/JSON chuẩn xác định 4 bề mặt (`cli`, `app`, `ide`, `vscode_ext`) + đường dẫn cài đặt và file `settings.json` tương ứng của IDE/VS Code.
- **Remote Self-Bootstrap**: Cả `install.ps1` và `install.sh` tự phát hiện chạy từ repo local hay chạy qua pipe (`irm ... | iex` / `curl ... | bash`); nếu chạy qua pipe sẽ tự tải archive nhánh `main` về thư mục tạm và dọn sạch sau khi hoàn tất.
- **Merge An Toàn Có Backup**: Sử dụng parser JSON gốc (`ConvertFrom-Json` trên PS, `python3`/`jq`/node fallback hoặc tạo mới chuẩn trên Linux) để merge Windows Terminal `settings.json` và VS Code/Antigravity `settings.json`, luôn ghi bản backup `.bak.<timestamp>` trước khi thay đổi.

## 2. Danh Sách File Dự Kiến
- `[+]` `.gitignore`
- `[+]` `antigravity/{AGENTS.md,README.md,rules/*,skills/*,plugins/*}`
- `[+]` `terminal/oh-my-posh/custom.omp.json`
- `[+]` `terminal/powershell/Microsoft.PowerShell_profile.ps1`
- `[+]` `terminal/windows-powershell/Microsoft.PowerShell_profile.ps1`
- `[+]` `terminal/windows-terminal/settings.template.json`
- `[+]` `scripts/detect-antigravity.ps1`, `scripts/detect-antigravity.sh`
- `[+]` `install.ps1`, `install.sh`
- `[+]` `tests/BetterSkill.Tests.ps1`, `tests/test_linux.sh`
- `[*]` `README.md`

## 3. Chiến Lược Kiểm Thử (TDD)
1. **Viết trước bộ test (`tests/BetterSkill.Tests.ps1` theo Pester 3.4 & `tests/test_linux.sh`)** kiểm tra tất cả `AC-01` → `AC-08` trên các thư mục sandbox cô lập (`TestDrive` / `$env:TEMP` / `/tmp`).
2. Chạy test xác nhận **FAIL (Red)** trước khi tạo scripts triển khai.
3. Cài đặt scripts & đóng gói `antigravity/` + `terminal/` cho tới khi toàn bộ test trên cả **Windows PowerShell 5.1**, **PowerShell 7**, và **WSL Ubuntu `bash`** **PASS (Green)**.
4. Kiểm định lại bằng `validate_skills.ps1` và quét `secret-leak-prevention` trước khi commit & push lên `origin main`.
