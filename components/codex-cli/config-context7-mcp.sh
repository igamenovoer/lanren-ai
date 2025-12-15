#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-context7-mcp.sh [options]

Install the Context7 MCP server via Bun and configure it for Codex CLI by
updating $CODEX_HOME/config.toml (default: ~/.codex/config.toml).

Options:
  --dry-run                 Print what would change, without installing/writing
  --capture-log-file PATH   Also write logs to PATH
  -h, --help                Show this help
EOF
}

dry_run=0
capture_log_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1; shift ;;
    --capture-log-file) capture_log_file="${2-}"; shift 2 ;;
    --capture-log-file=*) capture_log_file="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"

lr_log "=== Configure Context7 MCP for Codex CLI ==="
lr_log ""

if ! lr_has_cmd node; then
  lr_die "Node.js is not available on PATH. Install Node.js first."
fi
if ! lr_has_cmd bun; then
  lr_die "Bun ('bun') is not available on PATH. Install Bun first."
fi
if ! lr_has_cmd codex; then
  lr_die "Codex CLI ('codex') is not available on PATH. Install Codex CLI first."
fi

package_name="@upstash/context7-mcp"
lr_log "Installing Context7 MCP server globally via Bun: $package_name"
lr_run bun add -g "$package_name" || lr_die "bun failed to install $package_name."

codex_home="${CODEX_HOME:-${HOME:-}/.codex}"
config_path="$codex_home/config.toml"

lr_log "Codex config: $config_path"

block_content="
[mcp_servers.context7]
command = \"bunx\"
args = [\"@upstash/context7-mcp@latest\"]
"

if [ "$dry_run" -eq 1 ]; then
  lr_log "Dry-run: would ensure [mcp_servers] exists and write/replace:"
  lr_log "$block_content"
  exit 0
fi

mkdir -p "$codex_home"
touch "$config_path"

tmp_file="$(mktemp "${TMPDIR:-/tmp}/codex.config.XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/codex.config.$$")"

# Remove existing block, ensure [mcp_servers] exists, then append block.
awk '
  BEGIN {skip=0; has_mcp=0}
  /^[[:space:]]*\[mcp_servers\][[:space:]]*$/ {has_mcp=1}
  /^[[:space:]]*\[mcp_servers\.context7\][[:space:]]*$/ {skip=1; next}
  skip==1 {
    if ($0 ~ /^[[:space:]]*\[/) {skip=0}
    else {next}
  }
  {print}
  END {
    if (has_mcp==0) {
      print ""
      print "[mcp_servers]"
    }
  }
' "$config_path" >"$tmp_file"

mv -f "$tmp_file" "$config_path"

{
  printf '\n%s\n' "$block_content"
} >>"$config_path"

lr_log "Context7 MCP server configured (mcp_servers.context7)."
lr_log "You can verify with: codex mcp list"

