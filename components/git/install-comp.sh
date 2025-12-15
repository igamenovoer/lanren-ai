#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install Git on Linux/macOS.

Options:
  --proxy URL               HTTP/HTTPS proxy for package managers
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
lr_log "=== Installing Git ==="
lr_log ""

lr_set_proxy_env "$proxy"

if lr_has_cmd git && [ "$force" -ne 1 ]; then
  lr_log "Git is already available on PATH (git found). Use --force to reinstall."
  exit 0
fi

os="$(lr_os)"
sudo_prefix="$(lr_sudo)"
install_ok=0

if [ "$os" = "macos" ]; then
  if lr_has_cmd brew; then
    if [ "$force" -eq 1 ]; then
      lr_run brew reinstall git && install_ok=1 || install_ok=0
    else
      lr_run brew install git && install_ok=1 || install_ok=0
    fi
  else
    lr_warn "Homebrew not found; cannot auto-install Git on macOS."
  fi
elif [ "$os" = "linux" ]; then
  if lr_has_cmd apt-get; then
    if [ "$accept_defaults" -eq 1 ]; then
      if [ -n "$sudo_prefix" ]; then
        lr_run "$sudo_prefix" apt-get update || true
        if [ "$force" -eq 1 ]; then
          lr_run "$sudo_prefix" apt-get install -y --reinstall git && install_ok=1 || install_ok=0
        else
          lr_run "$sudo_prefix" apt-get install -y git && install_ok=1 || install_ok=0
        fi
      else
        lr_run apt-get update || true
        if [ "$force" -eq 1 ]; then
          lr_run apt-get install -y --reinstall git && install_ok=1 || install_ok=0
        else
          lr_run apt-get install -y git && install_ok=1 || install_ok=0
        fi
      fi
    else
      if [ -n "$sudo_prefix" ]; then
        lr_run "$sudo_prefix" apt-get update || true
        lr_run "$sudo_prefix" apt-get install git && install_ok=1 || install_ok=0
      else
        lr_run apt-get update || true
        lr_run apt-get install git && install_ok=1 || install_ok=0
      fi
    fi
  elif lr_has_cmd dnf; then
    if [ -n "$sudo_prefix" ]; then
      lr_run "$sudo_prefix" dnf install -y git && install_ok=1 || install_ok=0
    else
      lr_run dnf install -y git && install_ok=1 || install_ok=0
    fi
  else
    lr_warn "No supported package manager found (apt-get/dnf)."
  fi
else
  lr_warn "Unsupported OS: $os"
fi

if [ "$install_ok" -eq 1 ] && lr_has_cmd git; then
  lr_log "Git installed successfully."
  exit 0
fi

lr_log ""
lr_log "Manual installation guidance:"
if [ "$from_official" -ne 1 ]; then
  lr_log "- China mirrors (if needed):"
  lr_log "  - https://mirrors.tuna.tsinghua.edu.cn/github-release/git-for-windows/git/ (Windows)"
  lr_log "  - https://npmmirror.com/mirrors/git-for-windows/ (Windows)"
fi
lr_log "- Linux: use your distro package manager (apt/dnf/etc)."
lr_log "- macOS: install Xcode Command Line Tools or Homebrew Git."
lr_log ""
lr_die "Git installation did not complete successfully."

