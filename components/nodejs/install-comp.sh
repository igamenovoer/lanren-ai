#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install Node.js (LTS preferred) on Linux/macOS.

Options:
  --proxy URL               HTTP/HTTPS proxy for downloads/package managers
  --accept-defaults         Use non-interactive defaults where possible
  --from-official           Prefer official sources (affects guidance only)
  --force                   Reinstall even if already installed
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
lr_log "=== Installing Node.js (LTS preferred) ==="
lr_log ""

lr_set_proxy_env "$proxy"

if lr_has_cmd node && [ "$force" -ne 1 ]; then
  lr_log "Node.js is already available on PATH (node found). Use --force to reinstall."
  exit 0
fi

os="$(lr_os)"
sudo_prefix="$(lr_sudo)"
installed=0

if [ "$os" = "macos" ]; then
  if lr_has_cmd brew; then
    if [ "$force" -eq 1 ]; then
      lr_run brew reinstall node && installed=1 || installed=0
    else
      lr_run brew install node && installed=1 || installed=0
    fi
  else
    lr_warn "Homebrew not found; cannot auto-install Node.js on macOS."
  fi
elif [ "$os" = "linux" ]; then
  if lr_has_cmd apt-get; then
    setup_url="https://deb.nodesource.com/setup_lts.x"
    setup_path="$LR_PKG_DIR/nodesource-setup_lts.x.sh"

    lr_log "Preparing NodeSource LTS repo bootstrap script..."
    lr_download "$setup_url" "$setup_path"
    lr_run chmod +x "$setup_path" || true

    if [ -n "$sudo_prefix" ]; then
      lr_run "$sudo_prefix" apt-get update || true
      if [ "$accept_defaults" -eq 1 ]; then
        lr_run "$sudo_prefix" apt-get install -y ca-certificates curl gnupg || true
      else
        lr_run "$sudo_prefix" apt-get install ca-certificates curl gnupg || true
      fi

      lr_log "Running NodeSource setup (LTS)..."
      lr_run "$sudo_prefix" bash "$setup_path" || true

      if [ "$accept_defaults" -eq 1 ]; then
        lr_run "$sudo_prefix" apt-get install -y nodejs && installed=1 || installed=0
      else
        lr_run "$sudo_prefix" apt-get install nodejs && installed=1 || installed=0
      fi
    else
      lr_run apt-get update || true
      lr_run bash "$setup_path" || true
      if [ "$accept_defaults" -eq 1 ]; then
        lr_run apt-get install -y nodejs && installed=1 || installed=0
      else
        lr_run apt-get install nodejs && installed=1 || installed=0
      fi
    fi
  else
    lr_warn "apt-get not found; cannot auto-install Node.js on this Linux distro."
  fi
else
  lr_warn "Unsupported OS: $os"
fi

if [ "$installed" -eq 1 ] && lr_has_cmd node; then
  lr_log "Node.js installed successfully: $(node --version 2>/dev/null || true)"
  exit 0
fi

lr_log ""
lr_log "Manual installation guidance:"
if [ "$from_official" -ne 1 ]; then
  lr_log "- China mirror for Node.js releases: https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/"
fi
lr_log "- Official downloads: https://nodejs.org/en/download"
lr_log "- Linux (recommended): use your distro packages or NodeSource LTS (https://github.com/nodesource/distributions)."
lr_log "- macOS (Apple Silicon): brew install node"
lr_log ""
lr_die "Node.js installation did not complete successfully."

