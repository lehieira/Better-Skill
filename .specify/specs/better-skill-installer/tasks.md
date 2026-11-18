# Tasks: Better-Skill Installer & Terminal Pack

## Phase A: Repo Hygiene & Assets Packaging
- [x] T001 [AC-08] Tạo `.gitignore` chặn file nhạy cảm/backup/temp và `.antigravity/` memory bank ban đầu
- [x] T002 [AC-01, AC-08] Đóng gói sạch `antigravity/` (9 rules, 24 skills, 5 plugins, `AGENTS.md`, `README.md`) không chứa path/PII cá nhân
- [x] T003 [AC-03, AC-04] Đóng gói `terminal/` (`custom.omp.json`, Pwsh/WindowsPowerShell profiles, sanitized `settings.template.json`)

## Phase B: TDD Red — Tests First
- [x] T004 [AC-01..AC-08] Viết `tests/BetterSkill.Tests.ps1` (Pester 3.4) test detect surfaces, install sandbox, safe merge + `.bak`, idempotency, `-Workspace`, và secret scan
- [x] T005 [AC-02, AC-05, AC-06, AC-07] Viết `tests/test_linux.sh` test Linux surface detection, `--target-home` install, idempotent shell hooks, `--workspace`

## Phase C: Implementation (Green)
- [x] T006 [AC-02] Cài đặt `scripts/detect-antigravity.ps1` (tương thích PS 5.1 & 7) và `scripts/detect-antigravity.sh`
- [x] T007 [AC-03, AC-04, AC-05, AC-07] Cài đặt `install.ps1` (Windows Terminal + Pwsh 7 + OMP + Nerd Font + Safe Merge + Remote Zip Bootstrap)
- [x] T008 [AC-02, AC-05, AC-06, AC-07] Cài đặt `install.sh` (Ubuntu/Debian/Fedora/Arch + Pwsh 7 + OMP + Nerd Font + Bash/Zsh/Pwsh profiles + Remote Tarball Bootstrap)
- [x] T009 [AC-01..AC-08] Viết `README.md` hướng dẫn cài 1 dòng cho Windows & Linux và cách dùng các cờ tùy chọn

## Phase D: Convergence & GitHub Push
- [x] T010 Chạy toàn bộ test suite trên Windows PowerShell 5.1, PowerShell 7 và WSL Ubuntu `bash` (`100% PASS`)
- [x] T011 Quét secret/PII, chạy `validate_skills.ps1`, cập nhật `.antigravity/`, commit sạch và push lên `https://github.com/lehieira/Better-Skill.git`
