# Better-Skill 🚀

Bộ cài đặt đa nền tảng (**Windows & Linux**) giúp triển khai nhanh toàn bộ hệ sinh thái **Antigravity Skills, Rules & Plugins** kèm **Oh My Posh + FiraCode Nerd Font + Custom Theme** (và tự cài **Windows Terminal + PowerShell 7** trên Windows) lên bất kỳ máy tính nào.

---

## ⚡ Cài Đặt Nhanh 1 Dòng

### Windows (PowerShell 5.1 hoặc PowerShell 7)
```powershell
irm https://raw.githubusercontent.com/lehieira/Better-Skill/main/install.ps1 | iex
```

### Linux (Ubuntu / Debian / Fedora / Arch / Alpine)
```bash
curl -fsSL https://raw.githubusercontent.com/lehieira/Better-Skill/main/install.sh | bash
```

---

## ✨ Tính Năng Chính

1. **Tự động nhận diện toàn bộ bề mặt Antigravity trên máy**:
   - **Antigravity CLI** (`agy`, `~/.gemini/antigravity-cli`) -> đồng bộ `~/.gemini/skills/*/skill.md` + `rules/` + `AGENTS.md`.
   - **Antigravity Desktop App (2.0)** (`~/.gemini/antigravity`, `%APPDATA%/Antigravity`, `~/.config/Antigravity`) -> đồng bộ `~/.gemini/config/{skills,plugins,rules}`.
   - **Antigravity IDE** (`~/.gemini/antigravity-ide`) -> đồng bộ `~/.gemini/config/` và cấu hình font terminal IDE.
   - **VS Code + Extension Antigravity / Gemini / Codeium** -> tự phát hiện extension, đồng bộ Global + tùy chọn inject `.agents/` vào project workspace (`-Workspace` / `--workspace`), đồng thời gán `terminal.integrated.fontFamily` sang `FiraCode Nerd Font`.
   - Kể cả trên máy mới tinh chưa cài app nào, bộ `~/.gemini/` vẫn được dựng sẵn để sử dụng ngay khi cài Antigravity.

2. **Đầy đủ 24 Global Core Skills + 5 Plugins (17 Skills) + 9 Rules**:
   - **7 Rules & Skills nền tảng**: `grill-me`, `hardened-backend-security`, `ui-ux-pro-architect`, `secret-leak-prevention`, `software-diagram-architect`, `vercel-prelaunch-checklist`, `vercel-sandbox-deployer`.
   - **10 Spec Kit, Memory & Meta Skills**: `speckit-specify`, `speckit-plan`, `speckit-tasks`, `speckit-implement`, `speckit-converge`, `speckit-bug-assess`, `speckit-bug-fix`, `speckit-bug-test`, `memory-bank-manager`, `skill-architect-generator` (kèm `validate_skills.ps1`).
   - **7 Core Engineering Skills**: `systematic-debugging`, `tdd-test-architect`, `code-review-auditor`, `refactoring-surgeon`, `api-contract-designer`, `database-architect-migrator`, `git-workflow-hygiene`.
   - **5 Specialized Plugins** (`~/.gemini/config/plugins/`): `fullstack-web-pro`, `devops-prod-ops`, `ai-agent-kit`, `java-enterprise-sql`, `data-browser-ops`.

3. **Tự động cài & đồng bộ Terminal chuẩn đẹp (`custom.omp.json`)**:
   - **Chỉ trên Windows**: Tự kiểm tra version và cài trực tiếp qua `Add-AppxPackage` (có fallback `winget`) cho **Windows Terminal `1.25.3131.0`** ([`Microsoft.WindowsTerminal_1.25.3131.0_8wekyb3d8bbwe.msixbundle`](https://github.com/microsoft/terminal/releases/download/v1.25.3131.0/Microsoft.WindowsTerminal_1.25.3131.0_8wekyb3d8bbwe.msixbundle)) và **PowerShell `7.7.0`** ([`PowerShell-7.7.0.msixbundle`](https://github.com/PowerShell/PowerShell/releases/download/v7.7.0/PowerShell-7.7.0.msixbundle)), cùng **Oh My Posh**, **FiraCode Nerd Font** và **Git**; merge profile `/~` (`💫`) với `FiraCode Nerd Font Mono` size `10` semi-bold.
   - **Trên Linux**: Không cài PowerShell 7 hay Windows Terminal; cài **Oh My Posh**, **FiraCode Nerd Font** và đồng bộ `custom.omp.json` cho `bash`/`zsh`.
   - **Safe Merge & Auto-Backup (`.bak.<timestamp>`)**: Giữ nguyên profile/keybinding/alias sẵn có trên mọi máy.

---

## 🛠️ Tùy Chọn Khi Chạy Từ Repo Clone

```bash
git clone https://github.com/lehieira/Better-Skill.git
cd Better-Skill
```

### Windows (`install.ps1`)
```powershell
# Cài đầy đủ (Skills + Terminal + Pwsh 7 + Oh My Posh + Font)
.\install.ps1

# Chỉ cài Skills/Rules/Plugins (không đụng Terminal)
.\install.ps1 -SkillsOnly

# Chỉ cài Terminal + PowerShell 7 + Oh My Posh
.\install.ps1 -TerminalOnly

# Cài thêm .agents/ vào 1 dự án cụ thể (cho Antigravity IDE / VS Code)
.\install.ps1 -Workspace "D:\Projects\my-app"

# Chạy thử không ghi file
.\install.ps1 -DryRun
```

### Linux (`install.sh`)
```bash
./install.sh
./install.sh --skills-only
./install.sh --terminal-only
./install.sh --workspace /path/to/project
./install.sh --dry-run
```

---

## 🧪 Tự Kiểm Định

```powershell
# Windows (PowerShell 5.1 hoặc PowerShell 7)
Invoke-Pester .\tests\BetterSkill.Tests.ps1
```

```bash
# Linux
bash ./tests/test_linux.sh
```
