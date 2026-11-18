# Project Progress

## Completed
- [x] Clone repo gốc `Better-Skill` và hoàn tất Spec/Plan/Tasks
- [x] T001–T003: Đóng gói `antigravity/`, `terminal/`, `.gitignore`, `.gitattributes`
- [x] T004–T005: Viết tests TDD (`tests/BetterSkill.Tests.ps1`, `tests/test_linux.sh`)
- [x] T006–T009: Viết detector scripts, `install.ps1`, `install.sh`, `README.md`
- [x] T010–T011: Kiểm định pass 100% trên Windows PowerShell 5.1, PowerShell 7 và WSL Ubuntu `bash`; quét sạch PII/Secret và push lên GitHub
- [x] Bugfix `linux-detect-eval-crash`: thay `eval "$DETECT_OUT"` bằng line-by-line parser trong `install.sh`, bọc `main()`, guard `stdin` cho pipe `curl | bash`
- [x] Phase E: Chỉ Windows cài PowerShell 7.7.0 & Windows Terminal 1.25.3131.0 từ `.msixbundle` (`Add-AppxPackage` + fallback `winget`); Linux chỉ cài Oh My Posh + Nerd Font + `bash`/`zsh`

## In Progress / Backlog
- Không còn task tồn đọng.
