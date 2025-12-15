#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

winget is a Windows-only component. This script exists for parity and exits
successfully on Linux/macOS.

Options:
  --capture-log-file PATH   Also write logs to PATH
  --dry-run                 Print what would change (no-op)
  -h, --help                Show this help
EOF
}

capture_log_file=""
dry_run=0

while [ $# -gt 0 ]; do
  case "$1" in
    --capture-log-file) capture_log_file="${2-}"; shift 2 ;;
    --capture-log-file=*) capture_log_file="${1#*=}"; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"
lr_log "=== winget (Windows-only) ==="
lr_log "No action on $(lr_os)."

