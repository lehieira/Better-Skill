#!/usr/bin/env bash
set -euo pipefail

TARGET_HOME="${TARGET_HOME:-$HOME}"
SKIP_COMMAND_PROBE="${SKIP_COMMAND_PROBE:-0}"

cmd_exists() {
  if [[ "$SKIP_COMMAND_PROBE" == "1" ]]; then
    return 1
  fi
  command -v "$1" >/dev/null 2>&1
}

cli_detected="false"
app_detected="false"
ide_detected="false"
vscode_installed="false"
vscode_ext="false"
evidence=""

# 1. Antigravity CLI
if cmd_exists agy; then
  cli_detected="true"
  evidence="${evidence}cli:cmd:agy,"
fi
if [[ -x "$TARGET_HOME/.local/bin/agy" ]] || [[ -d "$TARGET_HOME/.gemini/antigravity-cli" ]]; then
  cli_detected="true"
  evidence="${evidence}cli:dir,"
fi

# 2. Antigravity Desktop App
if [[ -d "$TARGET_HOME/.gemini/antigravity" ]] || [[ -d "$TARGET_HOME/.config/Antigravity" ]] || [[ -d "$TARGET_HOME/Library/Application Support/Antigravity" ]] || [[ -d "/opt/Antigravity" ]] || cmd_exists antigravity; then
  app_detected="true"
  evidence="${evidence}app,"
fi

# 3. Antigravity IDE
if [[ -d "$TARGET_HOME/.gemini/antigravity-ide" ]] || [[ -d "$TARGET_HOME/.config/Antigravity IDE" ]] || [[ -d "$TARGET_HOME/Library/Application Support/Antigravity IDE" ]] || cmd_exists antigravity-ide; then
  ide_detected="true"
  evidence="${evidence}ide,"
fi

# 4. VS Code & Extensions
if cmd_exists code || [[ -d "$TARGET_HOME/.vscode" ]] || [[ -d "$TARGET_HOME/.config/Code" ]] || [[ -d "$TARGET_HOME/Library/Application Support/Code" ]] || [[ -d "/usr/share/code" ]]; then
  vscode_installed="true"
fi

for ext_dir in "$TARGET_HOME/.vscode/extensions" "$TARGET_HOME/.vscode-insiders/extensions" "$TARGET_HOME/.vscode-oss/extensions"; do
  if [[ -d "$ext_dir" ]]; then
    vscode_installed="true"
    if find "$ext_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | grep -qiE '(antigravity|google\.gemini|gemini-code-assist|codeium)'; then
      vscode_ext="true"
      evidence="${evidence}vscode-ext:dir,"
    fi
  fi
done

if cmd_exists code; then
  if code --list-extensions 2>/dev/null | grep -qiE '(antigravity|google\.gemini|gemini-code-assist|codeium)'; then
    vscode_ext="true"
    evidence="${evidence}vscode-ext:cli,"
  fi
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  vscode_settings="$TARGET_HOME/Library/Application Support/Code/User/settings.json"
  ag_settings="$TARGET_HOME/Library/Application Support/Antigravity/User/settings.json"
else
  vscode_settings="$TARGET_HOME/.config/Code/User/settings.json"
  ag_settings="$TARGET_HOME/.config/Antigravity/User/settings.json"
fi

printf 'CLI=%s\n' "$cli_detected"
printf 'APP=%s\n' "$app_detected"
printf 'IDE=%s\n' "$ide_detected"
printf 'VSCODE_INSTALLED=%s\n' "$vscode_installed"
printf 'VSCODE_EXT=%s\n' "$vscode_ext"
printf 'VSCODE_SETTINGS=%s\n' "$vscode_settings"
printf 'ANTIGRAVITY_SETTINGS=%s\n' "$ag_settings"
printf 'EVIDENCE=%s\n' "${evidence%,}"
