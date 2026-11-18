#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DETECT_SH="$REPO_ROOT/scripts/detect-antigravity.sh"
INSTALL_SH="$REPO_ROOT/install.sh"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $msg (expected='$expected', actual='$actual')" >&2
    exit 1
  fi
}

assert_exists() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "FAIL: Missing path: $path" >&2
    exit 1
  fi
}

TMP_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

echo "[1/5] Checking scripts exist, bash syntax, and Linux does NOT install PowerShell/Windows Terminal..."
assert_exists "$DETECT_SH"
assert_exists "$INSTALL_SH"
bash -n "$DETECT_SH"
bash -n "$INSTALL_SH"
if grep -qE 'PowerShell/PowerShell/releases|powershell-.*-linux|libicu' "$INSTALL_SH"; then
  echo "FAIL: install.sh must not install PowerShell 7 on Linux" >&2
  exit 1
fi

echo "[2/5] Testing Linux Antigravity surface detection..."
HOME_ALL="$TMP_ROOT/home_all"
mkdir -p "$HOME_ALL/.gemini/antigravity-cli" \
         "$HOME_ALL/.gemini/antigravity" \
         "$HOME_ALL/.gemini/antigravity-ide" \
         "$HOME_ALL/.vscode/extensions/google.antigravity-1.0.0" \
         "$HOME_ALL/.config/Code/User"
printf '{"editor.tabSize": 2}\n' > "$HOME_ALL/.config/Code/User/settings.json"

DETECT_OUT="$(TARGET_HOME="$HOME_ALL" SKIP_COMMAND_PROBE=1 bash "$DETECT_SH")"
echo "$DETECT_OUT" | grep -q "CLI=true" || { echo "FAIL: CLI not detected"; exit 1; }
echo "$DETECT_OUT" | grep -q "APP=true" || { echo "FAIL: APP not detected"; exit 1; }
echo "$DETECT_OUT" | grep -q "IDE=true" || { echo "FAIL: IDE not detected"; exit 1; }
echo "$DETECT_OUT" | grep -q "VSCODE_EXT=true" || { echo "FAIL: VSCODE_EXT not detected"; exit 1; }

HOME_NONE="$TMP_ROOT/home_none"
mkdir -p "$HOME_NONE"
DETECT_NONE="$(TARGET_HOME="$HOME_NONE" SKIP_COMMAND_PROBE=1 bash "$DETECT_SH")"
echo "$DETECT_NONE" | grep -q "CLI=false" || { echo "FAIL: false positive CLI"; exit 1; }
echo "$DETECT_NONE" | grep -q "VSCODE_EXT=false" || { echo "FAIL: false positive VSCODE_EXT"; exit 1; }

echo "[3/5] Testing Linux install.sh with ALL surfaces detected (multi-evidence regression)..."
SANDBOX_MULTI="$TMP_ROOT/sandbox_multi"
mkdir -p "$SANDBOX_MULTI/.gemini/antigravity-cli" \
         "$SANDBOX_MULTI/.gemini/antigravity" \
         "$SANDBOX_MULTI/.gemini/antigravity-ide" \
         "$SANDBOX_MULTI/.local/bin" \
         "$SANDBOX_MULTI/.vscode/extensions/google.antigravity-1.0.0"
printf '#!/usr/bin/env bash\nexit 0\n' > "$SANDBOX_MULTI/.local/bin/agy"
chmod +x "$SANDBOX_MULTI/.local/bin/agy"

MULTI_OUT="$(PATH="$SANDBOX_MULTI/.local/bin:$PATH" bash "$INSTALL_SH" --target-home "$SANDBOX_MULTI" --skip-package-install --dry-run)"
echo "$MULTI_OUT" | grep -q "Antigravity CLI           : true" || { echo "FAIL: multi-surface CLI not true"; exit 1; }
echo "$MULTI_OUT" | grep -q "Antigravity Desktop App   : true" || { echo "FAIL: multi-surface APP not true"; exit 1; }
echo "$MULTI_OUT" | grep -q "Antigravity IDE           : true" || { echo "FAIL: multi-surface IDE not true"; exit 1; }

echo "[4/5] Testing piped stdin execution (curl | bash simulation with stdin-draining 'code' stub)..."
SANDBOX_PIPE="$TMP_ROOT/sandbox_pipe"
mkdir -p "$SANDBOX_PIPE/bin"
cat > "$SANDBOX_PIPE/bin/code" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null || true
echo "google.antigravity"
EOF
chmod +x "$SANDBOX_PIPE/bin/code"
PIPE_LOCAL_OUT="$(cat "$INSTALL_SH" | PATH="$SANDBOX_PIPE/bin:$PATH" BETTER_SKILL_SOURCE_DIR="$REPO_ROOT" bash -s -- --target-home "$SANDBOX_PIPE" --skip-package-install)"
echo "$PIPE_LOCAL_OUT" | grep -q "VS Code + Antigravity Ext : true" || { echo "FAIL: pipe mode skipped detection"; exit 1; }
echo "$PIPE_LOCAL_OUT" | grep -q "Done!" || { echo "FAIL: pipe mode exited early before Done!"; exit 1; }

echo "[5/5] Testing Linux install.sh sandbox, safe merge & idempotency..."
SANDBOX_HOME="$TMP_ROOT/sandbox_home"
SANDBOX_WS="$TMP_ROOT/workspace"
mkdir -p "$SANDBOX_HOME/.config/Code/User" "$SANDBOX_HOME/.vscode/extensions/google.antigravity-0.2.0" "$SANDBOX_WS"
printf 'alias ll="ls -la"\n' > "$SANDBOX_HOME/.bashrc"
printf '{"editor.tabSize": 2}\n' > "$SANDBOX_HOME/.config/Code/User/settings.json"

# Run 1 and Run 2 for idempotency
SKIP_COMMAND_PROBE=1 bash "$INSTALL_SH" --target-home "$SANDBOX_HOME" --workspace "$SANDBOX_WS" --skip-package-install
SKIP_COMMAND_PROBE=1 bash "$INSTALL_SH" --target-home "$SANDBOX_HOME" --workspace "$SANDBOX_WS" --skip-package-install

GLOBAL_CFG_COUNT="$(find "$SANDBOX_HOME/.gemini/config/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
GLOBAL_CLI_COUNT="$(find "$SANDBOX_HOME/.gemini/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
RULES_COUNT="$(find "$SANDBOX_HOME/.gemini/config/rules" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
PLUGINS_COUNT="$(find "$SANDBOX_HOME/.gemini/config/plugins" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

assert_eq "24" "$GLOBAL_CFG_COUNT" "global config skills count"
assert_eq "24" "$GLOBAL_CLI_COUNT" "global cli skills count"
assert_eq "9" "$RULES_COUNT" "rules count"
assert_eq "5" "$PLUGINS_COUNT" "plugins count"

assert_exists "$SANDBOX_HOME/.gemini/AGENTS.md"
assert_exists "$SANDBOX_WS/.agents/skills"
assert_exists "$SANDBOX_WS/.agents/rules"
assert_exists "$SANDBOX_WS/.agents/plugins"
assert_exists "$SANDBOX_WS/.agents/AGENTS.md"
assert_exists "$SANDBOX_HOME/.config/oh-my-posh/custom.omp.json"
if [[ -e "$SANDBOX_HOME/.config/powershell/Microsoft.PowerShell_profile.ps1" ]]; then
  echo "FAIL: Linux install.sh must not create PowerShell profile when pwsh is not installed" >&2
  exit 1
fi

# Verify .bashrc preserved alias + idempotent OMP block + created backup
grep -q 'alias ll="ls -la"' "$SANDBOX_HOME/.bashrc" || { echo "FAIL: .bashrc user alias lost"; exit 1; }
OMP_COUNT="$(grep -c '>>> Better-Skill Oh My Posh >>>' "$SANDBOX_HOME/.bashrc")"
assert_eq "1" "$OMP_COUNT" "idempotent Oh My Posh block in .bashrc"
ls "$SANDBOX_HOME"/.bashrc.bak.* >/dev/null 2>&1 || { echo "FAIL: missing .bashrc backup"; exit 1; }

# Verify VS Code settings merged safely if python3 exists
if command -v python3 >/dev/null 2>&1; then
  grep -q '"editor.tabSize"' "$SANDBOX_HOME/.config/Code/User/settings.json" || { echo "FAIL: VS Code setting lost"; exit 1; }
  grep -q 'FiraCode Nerd Font' "$SANDBOX_HOME/.config/Code/User/settings.json" || { echo "FAIL: VS Code Nerd Font missing"; exit 1; }
fi

echo "ALL LINUX TESTS PASSED!"
