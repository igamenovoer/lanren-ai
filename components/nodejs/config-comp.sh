#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-comp.sh [options]

Configure npm global registry mirror.

Options:
  --mirror <cn|official>      Registry to use
  --dry-run                   Print what would change, without applying
  --capture-log-file PATH     Also write logs to PATH
  -h, --help                  Show this help
EOF
}

mirror=""
dry_run=0
capture_log_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --mirror) mirror="${2-}"; shift 2 ;;
    --mirror=*) mirror="${1#*=}"; shift ;;
    --dry-run) dry_run=1; shift ;;
    --capture-log-file) capture_log_file="${2-}"; shift 2 ;;
    --capture-log-file=*) capture_log_file="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$mirror" ]; then
  echo "Missing required --mirror." >&2
  usage
  exit 1
fi

case "$mirror" in
  cn) registry_url="https://registry.npmmirror.com" ;;
  official) registry_url="https://registry.npmjs.org" ;;
  *) echo "Invalid --mirror: $mirror" >&2; usage; exit 1 ;;
esac

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"
lr_log "=== Configuring Node.js (npm) Global Mirror ==="
lr_log "Selected Mirror: $mirror ($registry_url)"

if ! lr_has_cmd npm; then
  lr_die "npm command not found. Please install Node.js first."
fi

lr_log "Running: npm config set registry $registry_url"
lr_run npm config set registry "$registry_url"

lr_log "Running: npm config get registry"
current="$(npm config get registry 2>/dev/null || true)"
lr_log "Current registry: $current"

if [ "$current" = "$registry_url" ]; then
  lr_log "Configuration complete."
else
  lr_warn "Registry update might have failed. Expected '$registry_url', got '$current'."
fi

