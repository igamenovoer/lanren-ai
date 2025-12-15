#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-vscode-app.sh [options]

Install Visual Studio Code on Linux/macOS.

Options:
  --proxy URL               HTTP/HTTPS proxy for downloads/package managers
  --accept-defaults         Use non-interactive defaults where possible
  --from-official           Prefer official download sources in guidance
  --force                   Reinstall even if 'code' is already available
  --capture-log-file PATH   Also write logs to PATH
  --dry-run                 Print what would change, without installing
  -h, --help                Show this help
EOF
}

proxy=""
accept_defaults=0
from_official=0
force=0
capture_log_file=""
dry_run=0

while [ $# -gt 0 ]; do
  case "$1" in
    --proxy|--proxy-url) proxy="${2-}"; shift 2 ;;
    --proxy=*) proxy="${1#*=}"; shift ;;
    --accept-defaults) accept_defaults=1; shift ;;
    --from-official) from_official=1; shift ;;
    --force) force=1; shift ;;
    --capture-log-file) capture_log_file="${2-}"; shift 2 ;;
    --capture-log-file=*) capture_log_file="${1#*=}"; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"
lr_log ""
lr_log "=== Installing Visual Studio Code (app) ==="
lr_log ""

lr_set_proxy_env "$proxy"

if lr_has_cmd code && [ "$force" -ne 1 ]; then
  lr_log "VS Code is already available on PATH (code found). Use --force to reinstall."
  exit 0
fi

os="$(lr_os)"
arch="$(lr_arch)"
sudo_prefix="$(lr_sudo)"
installed=0

if [ "$os" = "macos" ]; then
  if [ "$arch" != "arm64" ]; then
    lr_warn "This installer is intended for Apple Silicon macOS (arm64). Detected arch=$arch."
  fi
  if lr_has_cmd brew; then
    if [ "$force" -eq 1 ]; then
      lr_run brew reinstall --cask visual-studio-code && installed=1 || installed=0
    else
      lr_run brew install --cask visual-studio-code && installed=1 || installed=0
    fi
  else
    lr_warn "Homebrew not found; cannot auto-install VS Code on macOS."
  fi
elif [ "$os" = "linux" ]; then
  # Prefer apt-based install when available.
  if lr_has_cmd apt-get && [ -n "$sudo_prefix" ]; then
    lr_run "$sudo_prefix" apt-get update || true
    if [ "$accept_defaults" -eq 1 ]; then
      lr_run "$sudo_prefix" apt-get install -y wget gpg ca-certificates || true
    else
      lr_run "$sudo_prefix" apt-get install wget gpg ca-certificates || true
    fi

    key_url="https://packages.microsoft.com/keys/microsoft.asc"
    key_path="$LR_PKG_DIR/microsoft.asc"
    keyring_path="$LR_PKG_DIR/packages.microsoft.gpg"

    lr_log "Downloading Microsoft signing key..."
    lr_download "$key_url" "$key_path"

    lr_log "Creating keyring..."
    lr_run gpg --dearmor -o "$keyring_path" "$key_path" || true

    lr_run "$sudo_prefix" mkdir -p /etc/apt/keyrings
    lr_run "$sudo_prefix" install -m 0644 "$keyring_path" /etc/apt/keyrings/packages.microsoft.gpg

    list_file="/etc/apt/sources.list.d/vscode.list"
    repo_line="deb [arch=$arch signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
    lr_log "Adding VS Code apt repository: $repo_line"
    lr_run "$sudo_prefix" sh -c "echo \"$repo_line\" > \"$list_file\""

    lr_run "$sudo_prefix" apt-get update || true
    if [ "$accept_defaults" -eq 1 ]; then
      lr_run "$sudo_prefix" apt-get install -y code && installed=1 || installed=0
    else
      lr_run "$sudo_prefix" apt-get install code && installed=1 || installed=0
    fi
  elif lr_has_cmd snap && [ -n "$sudo_prefix" ]; then
    lr_log "Installing VS Code via snap..."
    lr_run "$sudo_prefix" snap install code --classic && installed=1 || installed=0
  else
    lr_warn "No supported installer found (apt-get+sudo or snap+sudo)."
  fi
else
  lr_warn "Unsupported OS: $os"
fi

if [ "$installed" -eq 1 ]; then
  lr_log "VS Code install finished."
  if lr_has_cmd code; then
    lr_log "VS Code CLI is available: $(code --version 2>/dev/null | head -n 1 || true)"
    exit 0
  fi
  lr_warn "'code' CLI not found on PATH after installation."
  lr_warn "On macOS you may need to run: VS Code -> Command Palette -> 'Shell Command: Install \"code\" command in PATH'."
  exit 0
fi

lr_log ""
lr_log "Manual installation guidance:"
if [ "$from_official" -ne 1 ]; then
  lr_log "- China CDN (when available): https://vscode.cdn.azure.cn/"
fi
lr_log "- Official download page: https://code.visualstudio.com/Download"
lr_log ""
lr_die "VS Code installation did not complete successfully."

