#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install pixi (prefix.dev) on Linux/macOS.

Options:
  --proxy URL               HTTP/HTTPS proxy for downloads/package managers
  --accept-defaults         Use non-interactive defaults where possible
  --from-official           Prefer official sources (pixi already uses official)
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
lr_log "=== Installing pixi (prefix.dev) ==="
lr_log ""

lr_set_proxy_env "$proxy"
[ "$accept_defaults" -eq 1 ] && lr_log "Using --accept-defaults."
[ "$from_official" -eq 1 ] && lr_log "Using --from-official (pixi already uses official sources)."

if lr_has_cmd pixi && [ "$force" -ne 1 ]; then
  lr_log "pixi is already available on PATH. Use --force to reinstall."
  exit 0
fi

os="$(lr_os)"
installed=0

if [ "$os" = "macos" ] && lr_has_cmd brew; then
  if [ "$force" -eq 1 ]; then
    lr_run brew reinstall pixi && installed=1 || installed=0
  else
    lr_run brew install pixi && installed=1 || installed=0
  fi
fi

if [ "$installed" -ne 1 ]; then
  installer_url="https://pixi.sh/install.sh"
  installer_path="$LR_PKG_DIR/pixi-install.sh"

  lr_log "Downloading official pixi installer script from $installer_url ..."
  lr_download "$installer_url" "$installer_path" || lr_die "Failed to download pixi installer."
  lr_run chmod +x "$installer_path" || true

  lr_log "Running pixi installer script: $installer_path"
  lr_run sh "$installer_path" || lr_die "pixi installer script failed."
fi

if ! lr_has_cmd pixi; then
  lr_die "pixi installation completed, but 'pixi' is not on PATH."
fi

lr_log "pixi installed successfully."

