#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-context7-mcp.sh [options]

Install the Context7 MCP server (npm) and configure it for Claude Code CLI
(user scope) via:
  claude mcp add -s user context7 context7-mcp

Options:
  --dry-run                 Print what would change, without installing/configuring
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

lr_log "=== Configure Context7 MCP for Claude Code (user scope) ==="
lr_log ""

if ! lr_has_cmd node; then
  lr_die "Node.js is not available on PATH. Install Node.js first."
fi
if ! lr_has_cmd npm; then
  lr_die "npm is not available on PATH. Install Node.js (with npm) first."
fi
if ! lr_has_cmd claude; then
  lr_die "Claude Code CLI ('claude') is not on PATH. Install it first."
fi

package_name="@upstash/context7-mcp"
lr_log "Ensuring Context7 MCP server is available via npm: $package_name"

sudo_prefix="$(lr_sudo)"
use_sudo=0
npm_prefix="$(npm prefix -g 2>/dev/null || true)"
if [ -n "$npm_prefix" ] && [ ! -w "$npm_prefix" ] && [ -n "$sudo_prefix" ]; then
  use_sudo=1
  lr_log "Global npm prefix is not writable ($npm_prefix); using sudo for global install."
fi

if [ "$use_sudo" -eq 1 ]; then
  lr_run "$sudo_prefix" npm install -g "$package_name" || lr_warn "npm global install failed; npx may still work."
else
  lr_run npm install -g "$package_name" || lr_warn "npm global install failed; npx may still work."
fi

scope="user"
mcp_name="context7"

lr_log "Removing existing '$mcp_name' server in scope '$scope' (if any)..."
lr_run claude mcp remove -s "$scope" "$mcp_name" || true

lr_log "Adding '$mcp_name' server in scope '$scope'..."
lr_run claude mcp add -s "$scope" "$mcp_name" "context7-mcp" || lr_die "Failed to add Context7 MCP server."

lr_log "Context7 MCP server has been configured. Verify with: claude mcp list"

