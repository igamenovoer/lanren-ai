#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install Bun (JavaScript runtime) on Linux/macOS via the official installer.

Options:
  --proxy URL               HTTP/HTTPS proxy for downloads
  --accept-defaults         Use non-interactive defaults where possible (no-op)
  --from-official           Prefer official sources (default)
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
lr_log "=== Installing Bun (JavaScript runtime) ==="
lr_log ""

lr_set_proxy_env "$proxy"
[ "$accept_defaults" -eq 1 ] && lr_log "Using --accept-defaults (no-op for Bun installer)."
[ "$from_official" -eq 1 ] && lr_log "Using --from-official."

if lr_has_cmd bun && [ "$force" -ne 1 ]; then
  lr_log "Bun is already available on PATH (bun found). Use --force to reinstall."
  exit 0
fi

if ! lr_has_cmd bash; then
  lr_die "bash is required to run the Bun installer."
fi

installer_url="https://bun.sh/install"
installer_path="$LR_PKG_DIR/bun-install.sh"

lr_log "Downloading Bun installer script from $installer_url ..."
lr_download "$installer_url" "$installer_path"
lr_run chmod +x "$installer_path" || true

lr_log "Running Bun installer script: $installer_path"
lr_run bash "$installer_path" || lr_die "Bun installer failed."

if ! lr_has_cmd bun; then
  lr_warn "Bun installer completed, but 'bun' is not on PATH in this shell."
  lr_warn "Restart your shell, or ensure ~/.bun/bin is on PATH."
else
  lr_log "Detected bun:  $(bun --version 2>/dev/null || true)"
fi

if lr_has_cmd bunx; then
  lr_log "Detected bunx: $(bunx --version 2>/dev/null || true)"
else
  lr_warn "'bunx' not found on PATH; ensure Bun was installed correctly and restart your shell."
fi

lr_log "Bun installation finished."

