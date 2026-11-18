#!/usr/bin/env bash
set -euo pipefail

TARGET_HOME="${TARGET_HOME:-$HOME}"
WORKSPACE=""
REPO_TAR_URL="https://github.com/lehieira/Better-Skill/archive/refs/heads/main.tar.gz"
SKILLS_ONLY=0
TERMINAL_ONLY=0
SKIP_PACKAGE_INSTALL=0
DRY_RUN=0
SKIP_COMMAND_PROBE="${SKIP_COMMAND_PROBE:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-home)
      TARGET_HOME="$2"
      shift 2
      ;;
    --workspace)
      WORKSPACE="$2"
      shift 2
      ;;
    --skills-only)
      SKILLS_ONLY=1
      shift
      ;;
    --terminal-only)
      TERMINAL_ONLY=1
      shift
      ;;
    --skip-package-install)
      SKIP_PACKAGE_INSTALL=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: install.sh [options]
  --target-home <dir>      Target home directory (default: $HOME)
  --workspace <dir>        Also install .agents/ into a project workspace
  --skills-only            Only install Antigravity skills, rules, and plugins
  --terminal-only          Only install PowerShell 7, Oh My Posh, theme, and Nerd Font
  --skip-package-install   Skip apt/dnf/pacman package & font downloads
  --dry-run                Print planned actions without writing files
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

log_step() { printf '\033[36m[Better-Skill]\033[0m %s\n' "$1"; }
log_ok()   { printf '  \033[32m[OK]\033[0m %s\n' "$1"; }
log_warn() { printf '  \033[33m[WARN]\033[0m %s\n' "$1"; }

run_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

backup_if_exists_diff() {
  local src="$1"
  local dst="$2"
  if [[ "$DRY_RUN" == "1" ]] || [[ ! -f "$dst" ]]; then
    return
  fi
  if cmp -s "$src" "$dst"; then
    return
  fi
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  cp "$dst" "${dst}.bak.${stamp}"
  log_ok "Backed up $(basename "$dst") -> $(basename "$dst").bak.${stamp}"
}

backup_file_now() {
  local target="$1"
  if [[ "$DRY_RUN" == "1" ]] || [[ ! -f "$target" ]]; then
    return
  fi
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  cp "$target" "${target}.bak.${stamp}"
  log_ok "Backed up $(basename "$target") -> $(basename "$target").bak.${stamp}"
}

merge_marked_block() {
  local target_file="$1"
  local start_marker="$2"
  local end_marker="$3"
  local block_content="$4"

  if [[ "$DRY_RUN" == "1" ]]; then
    log_step "[DryRun] Would update $target_file"
    return
  fi

  mkdir -p "$(dirname "$target_file")"
  if [[ ! -f "$target_file" ]]; then
    printf '%s\n' "$block_content" > "$target_file"
    log_ok "Created $target_file"
    return
  fi

  local tmp_out
  tmp_out="$(mktemp)"
  awk -v s="$start_marker" -v e="$end_marker" '
    $0 == s { skip=1; next }
    $0 == e { skip=0; next }
    !skip { print }
  ' "$target_file" > "$tmp_out"

  # Trim trailing blank lines cleanly before appending updated block
  local tmp_final
  tmp_final="$(mktemp)"
  awk '{ lines[NR]=$0 } END {
    last=NR
    while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
    for (i=1; i<=last; i++) print lines[i]
  }' "$tmp_out" > "$tmp_final"

  if [[ -s "$tmp_final" ]]; then
    printf '\n%s\n' "$block_content" >> "$tmp_final"
  else
    printf '%s\n' "$block_content" > "$tmp_final"
  fi

  if ! cmp -s "$target_file" "$tmp_final"; then
    backup_file_now "$target_file"
    mv "$tmp_final" "$target_file"
    log_ok "Merged Oh My Posh block into $target_file"
  else
    rm -f "$tmp_final"
    log_ok "Profile already up to date: $target_file"
  fi
  rm -f "$tmp_out"
}

merge_ide_json_settings() {
  local settings_path="$1"
  local parent_dir
  parent_dir="$(dirname "$settings_path")"
  if [[ ! -d "$parent_dir" ]] || [[ "$DRY_RUN" == "1" ]]; then
    return
  fi

  local has_pwsh="false"
  if [[ "$SKIP_COMMAND_PROBE" != "1" ]] && command -v pwsh >/dev/null 2>&1; then
    has_pwsh="true"
  fi

  if command -v python3 >/dev/null 2>&1; then
    backup_file_now "$settings_path"
    python3 - "$settings_path" "$has_pwsh" <<'PYEOF'
import json, os, re, sys
path, has_pwsh = sys.argv[1], sys.argv[2] == "true"
data = {}
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read().strip()
    if raw:
        cleaned = re.sub(r"(?m)^\s*//.*$", "", raw)
        try:
            data = json.loads(cleaned)
        except Exception:
            sys.exit(0)
data["terminal.integrated.fontFamily"] = "FiraCode Nerd Font"
if has_pwsh:
    data["terminal.integrated.defaultProfile.linux"] = "pwsh"
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
    log_ok "Merged IDE terminal settings -> $settings_path"
  fi
}

install_linux_packages() {
  local os_id="unknown"
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    os_id="${ID:-unknown}"
  fi

  log_step "Installing dependencies (curl, git, unzip, fontconfig) for distro: $os_id"
  if command -v apt-get >/dev/null 2>&1; then
    run_sudo apt-get update -qq
    run_sudo apt-get install -y -qq curl git unzip fontconfig ca-certificates tar
  elif command -v dnf >/dev/null 2>&1; then
    run_sudo dnf install -y curl git unzip fontconfig ca-certificates tar
  elif command -v pacman >/dev/null 2>&1; then
    run_sudo pacman -Sy --noconfirm --needed curl git unzip fontconfig tar
  elif command -v apk >/dev/null 2>&1; then
    run_sudo apk add --no-cache curl git unzip fontconfig ca-certificates tar bash
  elif [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    brew install git curl
  fi

  # PowerShell 7 (pwsh)
  if ! command -v pwsh >/dev/null 2>&1; then
    log_step "Installing PowerShell 7 (pwsh)..."
    if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
      brew install --cask powershell || true
    else
      local arch pwsh_arch
      arch="$(uname -m)"
      case "$arch" in
        x86_64|amd64) pwsh_arch="linux-x64" ;;
        aarch64|arm64) pwsh_arch="linux-arm64" ;;
        *) pwsh_arch="" ;;
      esac
      if [[ -n "$pwsh_arch" ]]; then
        local pwsh_ver pwsh_url tmp_pwsh
        pwsh_ver="$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | grep -oE '"tag_name":\s*"v[^"]+"' | head -n1 | sed -E 's/.*"v([^"]+)".*/\1/' || true)"
        [[ -z "$pwsh_ver" ]] && pwsh_ver="7.4.6"
        pwsh_url="https://github.com/PowerShell/PowerShell/releases/download/v${pwsh_ver}/powershell-${pwsh_ver}-${pwsh_arch}.tar.gz"
        tmp_pwsh="$(mktemp -d)"
        if curl -fsSL "$pwsh_url" -o "$tmp_pwsh/pwsh.tar.gz"; then
          local pwsh_dir="$TARGET_HOME/.local/share/powershell"
          mkdir -p "$pwsh_dir" "$TARGET_HOME/.local/bin"
          tar zxf "$tmp_pwsh/pwsh.tar.gz" -C "$pwsh_dir"
          chmod +x "$pwsh_dir/pwsh"
          ln -sf "$pwsh_dir/pwsh" "$TARGET_HOME/.local/bin/pwsh"
          export PATH="$TARGET_HOME/.local/bin:$PATH"
          log_ok "Installed PowerShell $pwsh_ver -> $TARGET_HOME/.local/bin/pwsh"
        else
          log_warn "Could not download PowerShell 7 automatically; please install pwsh manually."
        fi
        rm -rf "$tmp_pwsh"
      fi
    fi
  else
    log_ok "PowerShell 7 already installed: $(command -v pwsh)"
  fi

  # Oh My Posh
  if ! command -v oh-my-posh >/dev/null 2>&1 && [[ ! -x "$TARGET_HOME/.local/bin/oh-my-posh" ]]; then
    log_step "Installing Oh My Posh..."
    mkdir -p "$TARGET_HOME/.local/bin"
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$TARGET_HOME/.local/bin"
    export PATH="$TARGET_HOME/.local/bin:$PATH"
    log_ok "Installed Oh My Posh -> $TARGET_HOME/.local/bin/oh-my-posh"
  else
    log_ok "Oh My Posh already installed"
  fi

  # FiraCode Nerd Font
  local font_dir="$TARGET_HOME/.local/share/fonts/FiraCodeNerdFont"
  if [[ ! -d "$font_dir" ]] || [[ -z "$(ls -A "$font_dir" 2>/dev/null || true)" ]]; then
    log_step "Installing FiraCode Nerd Font..."
    local tmp_font
    tmp_font="$(mktemp -d)"
    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -o "$tmp_font/FiraCode.zip"; then
      mkdir -p "$font_dir"
      unzip -qo "$tmp_font/FiraCode.zip" "*.ttf" -d "$font_dir" || true
      if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "$font_dir" >/dev/null 2>&1 || true
      fi
      log_ok "Installed FiraCode Nerd Font -> $font_dir"
    else
      log_warn "Could not download FiraCode Nerd Font."
    fi
    rm -rf "$tmp_font"
  else
    log_ok "FiraCode Nerd Font already installed"
  fi
}

install_antigravity_assets() {
  local source_root="$1"
  local ag_src="$source_root/antigravity"
  local gemini_root="$TARGET_HOME/.gemini"
  local config_root="$gemini_root/config"

  log_step "Installing Antigravity Rules, Skills & Plugins into $gemini_root..."
  if [[ "$DRY_RUN" == "1" ]]; then
    log_step "[DryRun] Would sync $ag_src -> $gemini_root"
    return
  fi

  mkdir -p "$config_root/rules" "$config_root/skills" "$config_root/plugins" \
           "$gemini_root/rules" "$gemini_root/skills"

  backup_if_exists_diff "$ag_src/AGENTS.md" "$gemini_root/AGENTS.md"
  cp "$ag_src/AGENTS.md" "$gemini_root/AGENTS.md"
  cp "$ag_src/README.md" "$gemini_root/README.md"

  cp -a "$ag_src/rules/." "$config_root/rules/"
  cp -a "$ag_src/rules/." "$gemini_root/rules/"

  for skill_dir in "$ag_src/skills"/*; do
    [[ -d "$skill_dir" ]] || continue
    local name
    name="$(basename "$skill_dir")"
    mkdir -p "$config_root/skills/$name" "$gemini_root/skills/$name"
    cp -a "$skill_dir/." "$config_root/skills/$name/"
    cp -a "$skill_dir/." "$gemini_root/skills/$name/"
    if [[ -f "$gemini_root/skills/$name/SKILL.md" ]]; then
      mv -f "$gemini_root/skills/$name/SKILL.md" "$gemini_root/skills/$name/skill.md"
    fi
  done

  cp -a "$ag_src/plugins/." "$config_root/plugins/"

  if [[ -n "$WORKSPACE" ]]; then
    log_step "Installing workspace-scoped .agents/ into $WORKSPACE..."
    local ws_agents="$WORKSPACE/.agents"
    mkdir -p "$ws_agents/rules" "$ws_agents/skills" "$ws_agents/plugins"
    cp "$ag_src/AGENTS.md" "$ws_agents/AGENTS.md"
    cp -a "$ag_src/rules/." "$ws_agents/rules/"
    cp -a "$ag_src/skills/." "$ws_agents/skills/"
    cp -a "$ag_src/plugins/." "$ws_agents/plugins/"
    log_ok "Workspace .agents/ synced at $ws_agents"
  fi

  log_ok "Installed 24 Global Core Skills, 5 Plugins (17 skills), 9 Rules & AGENTS.md"
}

# ---------------- Main Execution ----------------
TEMP_BOOTSTRAP=""
cleanup() {
  if [[ -n "$TEMP_BOOTSTRAP" ]] && [[ -d "$TEMP_BOOTSTRAP" ]]; then
    rm -rf "$TEMP_BOOTSTRAP"
  fi
}
trap cleanup EXIT

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

SOURCE_ROOT="$SCRIPT_DIR"
if [[ -z "$SOURCE_ROOT" ]] || [[ ! -d "$SOURCE_ROOT/antigravity" ]]; then
  log_step "Bootstrapping Better-Skill bundle from GitHub..."
  TEMP_BOOTSTRAP="$(mktemp -d)"
  curl -fsSL "$REPO_TAR_URL" -o "$TEMP_BOOTSTRAP/bundle.tar.gz"
  tar -xzf "$TEMP_BOOTSTRAP/bundle.tar.gz" -C "$TEMP_BOOTSTRAP"
  SOURCE_ROOT="$(find "$TEMP_BOOTSTRAP" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z "$SOURCE_ROOT" ]] || [[ ! -d "$SOURCE_ROOT/antigravity" ]]; then
    echo "Failed to extract Better-Skill bundle." >&2
    exit 1
  fi
fi

DETECT_OUT="$(TARGET_HOME="$TARGET_HOME" SKIP_COMMAND_PROBE="$SKIP_COMMAND_PROBE" bash "$SOURCE_ROOT/scripts/detect-antigravity.sh")"
eval "$DETECT_OUT"

log_step "Detected Antigravity surfaces:"
echo "  - Antigravity CLI           : $CLI"
echo "  - Antigravity Desktop App   : $APP"
echo "  - Antigravity IDE           : $IDE"
echo "  - VS Code + Antigravity Ext : $VSCODE_EXT (VS Code installed: $VSCODE_INSTALLED)"

if [[ "$TERMINAL_ONLY" == "0" ]]; then
  install_antigravity_assets "$SOURCE_ROOT"
fi

if [[ "$SKILLS_ONLY" == "0" ]]; then
  if [[ "$SKIP_PACKAGE_INSTALL" == "0" ]] && [[ "$DRY_RUN" == "0" ]]; then
    install_linux_packages
  fi

  OMP_DST="$TARGET_HOME/.config/oh-my-posh/custom.omp.json"
  if [[ "$DRY_RUN" == "0" ]]; then
    mkdir -p "$(dirname "$OMP_DST")"
    backup_if_exists_diff "$SOURCE_ROOT/terminal/oh-my-posh/custom.omp.json" "$OMP_DST"
    cp "$SOURCE_ROOT/terminal/oh-my-posh/custom.omp.json" "$OMP_DST"
    log_ok "Installed Oh My Posh theme -> $OMP_DST"
  fi

  PWSH_PROF="$TARGET_HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
  PWSH_BLOCK="$(cat <<'EOF'
# >>> Better-Skill Oh My Posh >>>
$env:PATH = "$HOME/.local/bin:$env:PATH"
$ompConfig = [System.IO.Path]::Combine($HOME, '.config', 'oh-my-posh', 'custom.omp.json')
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $ompConfig)) {
    oh-my-posh init pwsh --config $ompConfig | Invoke-Expression
}
# <<< Better-Skill Oh My Posh <<<
EOF
)"
  merge_marked_block "$PWSH_PROF" "# >>> Better-Skill Oh My Posh >>>" "# <<< Better-Skill Oh My Posh <<<" "$PWSH_BLOCK"

  BASH_BLOCK="$(cat <<'EOF'
# >>> Better-Skill Oh My Posh >>>
export PATH="$HOME/.local/bin:$PATH"
if command -v oh-my-posh >/dev/null 2>&1 && [ -f "$HOME/.config/oh-my-posh/custom.omp.json" ]; then
  eval "$(oh-my-posh init bash --config "$HOME/.config/oh-my-posh/custom.omp.json")"
fi
# <<< Better-Skill Oh My Posh <<<
EOF
)"
  merge_marked_block "$TARGET_HOME/.bashrc" "# >>> Better-Skill Oh My Posh >>>" "# <<< Better-Skill Oh My Posh <<<" "$BASH_BLOCK"

  if [[ -f "$TARGET_HOME/.zshrc" ]] || { [[ "$SKIP_COMMAND_PROBE" != "1" ]] && command -v zsh >/dev/null 2>&1; }; then
    ZSH_BLOCK="$(cat <<'EOF'
# >>> Better-Skill Oh My Posh >>>
export PATH="$HOME/.local/bin:$PATH"
if command -v oh-my-posh >/dev/null 2>&1 && [ -f "$HOME/.config/oh-my-posh/custom.omp.json" ]; then
  eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/custom.omp.json")"
fi
# <<< Better-Skill Oh My Posh <<<
EOF
)"
    merge_marked_block "$TARGET_HOME/.zshrc" "# >>> Better-Skill Oh My Posh >>>" "# <<< Better-Skill Oh My Posh <<<" "$ZSH_BLOCK"
  fi

  merge_ide_json_settings "$VSCODE_SETTINGS"
  merge_ide_json_settings "$ANTIGRAVITY_SETTINGS"
fi

log_step "Done! Open a new terminal or run 'pwsh' to enjoy Better-Skill + Oh My Posh."
