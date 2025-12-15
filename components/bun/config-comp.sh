#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-comp.sh [options]

Configure Bun global registry mirror by editing ~/.bunfig.toml.

Options:
  --mirror <cn|official>     Registry mirror to use
  --dry-run                  Print what would change, without writing files
  --capture-log-file PATH    Also write logs to PATH
  -h, --help                 Show this help
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

bunfig_path="${HOME:-}/.bunfig.toml"
lr_log "=== Configuring Bun Global Mirror ==="
lr_log "Target file: $bunfig_path"
lr_log "Selected Mirror: $mirror ($registry_url)"

if [ "$dry_run" -eq 1 ]; then
  lr_log "Dry-run: would ensure the following in ~/.bunfig.toml:"
  lr_log "[install]"
  lr_log "registry = \"$registry_url\""
  exit 0
fi

content=""
if [ -f "$bunfig_path" ]; then
  content="$(cat "$bunfig_path" 2>/dev/null || true)"
fi

tmp_file="$(mktemp "${TMPDIR:-/tmp}/bunfig.toml.XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/bunfig.toml.$$")"

registry_line="registry = \"$registry_url\""

if printf '%s\n' "$content" | grep -Eq '^[[:space:]]*registry[[:space:]]*='; then
  printf '%s\n' "$content" | awk -v repl="$registry_line" '
    BEGIN {done=0}
    {
      if (!done && $0 ~ /^[[:space:]]*registry[[:space:]]*=/) {
        print repl
        done=1
        next
      }
      print
    }
  ' >"$tmp_file"
  lr_log "Updated existing registry configuration."
elif printf '%s\n' "$content" | grep -Eq '^[[:space:]]*\\[install\\][[:space:]]*$'; then
  printf '%s\n' "$content" | awk -v repl="$registry_line" '
    BEGIN {done=0}
    {
      print
      if (!done && $0 ~ /^[[:space:]]*\\[install\\][[:space:]]*$/) {
        print repl
        done=1
      }
    }
  ' >"$tmp_file"
  lr_log "Added registry configuration to existing [install] section."
else
  {
    printf '%s\n' "$content"
    [ -n "$content" ] && printf '\n'
    printf '[install]\n%s\n' "$registry_line"
  } >"$tmp_file"
  lr_log "Created [install] section with registry configuration."
fi

mv -f "$tmp_file" "$bunfig_path"
lr_log "Configuration complete."

