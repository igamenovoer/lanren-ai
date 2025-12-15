#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-comp.sh [options]

Configure uv global mirror (PyPI index URL) on Linux/macOS.

Options:
  --mirror <cn|aliyun|tuna|official>   Mirror preset (default: cn -> aliyun)
  --dry-run                            Print what would change, without writing files
  --capture-log-file PATH              Also write logs to PATH
  -h, --help                           Show this help
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
  mirror="cn"
fi

case "$mirror" in
  cn) mirror="aliyun" ;;
  aliyun|tuna|official) ;;
  *) echo "Invalid --mirror: $mirror" >&2; usage; exit 1 ;;
esac

case "$mirror" in
  aliyun) registry_url="https://mirrors.aliyun.com/pypi/simple/" ;;
  tuna) registry_url="https://pypi.tuna.tsinghua.edu.cn/simple" ;;
  official) registry_url="https://pypi.org/simple" ;;
esac

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"
lr_log "=== Configuring uv Global Mirror ==="
lr_log "Selected Mirror: $mirror ($registry_url)"

config_root="${XDG_CONFIG_HOME:-${HOME:-}/.config}"
config_dir="$config_root/uv"
config_path="$config_dir/uv.toml"

lr_log "Config file: $config_path"

if [ "$dry_run" -eq 1 ]; then
  lr_log "Dry-run: would ensure $config_dir exists and set:"
  lr_log "index-url = \"$registry_url\""
  exit 0
fi

mkdir -p "$config_dir"
content=""
if [ -f "$config_path" ]; then
  content="$(cat "$config_path" 2>/dev/null || true)"
fi

tmp_file="$(mktemp "${TMPDIR:-/tmp}/uv.toml.XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/uv.toml.$$")"

if printf '%s\n' "$content" | grep -Eq '^[[:space:]]*index-url[[:space:]]*='; then
  printf '%s\n' "$content" | awk -v url="$registry_url" '
    BEGIN {done=0}
    {
      if (!done && $0 ~ /^[[:space:]]*index-url[[:space:]]*=/) {
        print "index-url = \"" url "\""
        done=1
        next
      }
      print
    }
  ' >"$tmp_file"
  lr_log "Updated existing index-url configuration."
else
  # Append
  if [ -n "$content" ] && [ "$(printf '%s' "$content" | tail -c 1 2>/dev/null || echo "")" != "" ]; then
    : # best-effort; we'll ensure trailing newline below
  fi
  {
    printf '%s\n' "$content"
    [ -n "$content" ] && printf '\n'
    printf 'index-url = "%s"\n' "$registry_url"
  } >"$tmp_file"
  lr_log "Added index-url configuration."
fi

mv -f "$tmp_file" "$config_path"
lr_log "Configuration complete."

