# Bug Report: `install.sh` crashes with `cli:dir: command not found` when multiple Antigravity surfaces are detected

- **Status**: `[RESOLVED]`
- **Environment**: Linux (`root@Homelab`), `curl -fsSL https://raw.githubusercontent.com/lehieira/Better-Skill/main/install.sh | bash`
- **Expected**: `install.sh` parses all detected Antigravity surface flags and evidence cleanly, then installs skills, rules, plugins, PowerShell 7, Oh My Posh, and Nerd Font.
- **Actual**: Fails immediately after extracting bundle:
  `bash: line 366: cli:dir: command not found`
- **Root Cause**: `install.sh` used `eval "$DETECT_OUT"` on unquoted `KEY=value` lines emitted by `scripts/detect-antigravity.sh`. When multiple surfaces were detected (producing `EVIDENCE=cli:cmd:agy;cli:dir;...`), `;` acted as a shell command separator inside `eval`, causing bash to try running `cli:dir` as a command (and would similarly break on spaces in macOS `Application Support` paths).
- **Fix Summary**:
  1. Replaced `eval "$DETECT_OUT"` in `install.sh` with a safe `while IFS='=' read -r key val` parser (`case "$key" in ...`).
  2. Updated `scripts/detect-antigravity.sh` to emit `,`-delimited `EVIDENCE` via `printf`.
  3. Added `/usr/local/bin` target when running as `root`, `libicu` install support, and rate-limit-free PowerShell release redirect lookup for Linux Homelab/VPS reliability.
- **Repro Command**: `wsl -d Ubuntu -- bash /mnt/c/Users/lehie/Better-Skill/tests/test_linux.sh` (Step `[3/4]` multi-surface regression test).
