#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install MarkItDown via uv tool on Linux/macOS.

Options:
  --proxy URL               HTTP/HTTPS proxy for uv network access
  --accept-defaults         Use non-interactive defaults where possible (no-op)
  --from-official           Use official PyPI index (uv default)
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
lr_log "=== Installing MarkItDown (via uv tool) ==="
lr_log ""

lr_set_proxy_env "$proxy"
[ "$accept_defaults" -eq 1 ] && lr_log "Using --accept-defaults (no-op for this installer)."

if ! lr_has_cmd uv; then
  lr_die "uv is not available on PATH. Install uv first (components/uv/install-comp.sh)."
fi

if lr_has_cmd markitdown && [ "$force" -ne 1 ]; then
  lr_log "MarkItDown is already available on PATH. Use --force to reinstall."
  exit 0
fi

primary_index="https://pypi.tuna.tsinghua.edu.cn/simple"

if [ "$from_official" -eq 1 ]; then
  lr_log "Using official PyPI index (uv default)."
  unset UV_INDEX_URL 2>/dev/null || true
else
  export UV_INDEX_URL="$primary_index"
  lr_log "Using China PyPI mirror via UV_INDEX_URL: $primary_index"
  lr_log "Will fall back to official index if the mirror fails."
fi

install_rc=0
lr_log "Running: uv tool install markitdown --with \"markitdown[all]\""
if lr_run uv tool install markitdown --with "markitdown[all]"; then
  install_rc=0
else
  install_rc=$?
fi

if [ "$install_rc" -ne 0 ] && [ "$from_official" -ne 1 ]; then
  lr_warn "uv tool install via mirror failed (exit code $install_rc). Retrying against official PyPI."
  unset UV_INDEX_URL 2>/dev/null || true
  lr_run uv tool install markitdown --with "markitdown[all]" || lr_die "uv failed to install MarkItDown."
fi

lr_log "MarkItDown installed successfully via uv tool."

