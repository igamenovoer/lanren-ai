#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

VS Code component entrypoint:
  - Installs the VS Code app (install-vscode-app.sh)
  - Installs common extensions (install-extensions.sh)

Options:
  --proxy URL               HTTP/HTTPS proxy for downloads/package managers
  --accept-defaults         Use non-interactive defaults where possible
  --from-official           Prefer official download sources in guidance
  --force                   Reinstall VS Code even if already installed
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

app_script="$script_dir/install-vscode-app.sh"
ext_script="$script_dir/install-extensions.sh"

if [ ! -f "$app_script" ]; then
  echo "install-vscode-app.sh not found in $script_dir" >&2
  exit 1
fi
if [ ! -f "$ext_script" ]; then
  echo "install-extensions.sh not found in $script_dir" >&2
  exit 1
fi

set --
if [ -n "$proxy" ]; then
  set -- "$@" --proxy "$proxy"
fi
if [ "$accept_defaults" -eq 1 ]; then
  set -- "$@" --accept-defaults
fi
if [ "$from_official" -eq 1 ]; then
  set -- "$@" --from-official
fi
if [ "$force" -eq 1 ]; then
  set -- "$@" --force
fi
if [ -n "$capture_log_file" ]; then
  set -- "$@" --capture-log-file "$capture_log_file"
fi
if [ "$dry_run" -eq 1 ]; then
  set -- "$@" --dry-run
fi

sh "$app_script" "$@"

set --
if [ -n "$capture_log_file" ]; then
  set -- "$@" --capture-log-file "$capture_log_file"
fi
if [ "$dry_run" -eq 1 ]; then
  set -- "$@" --dry-run
fi

sh "$ext_script" "$@"
