#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-tavily-mcp.sh [options]

Install the Tavily MCP server (npm) and configure it for Claude Code CLI
(user scope) using:
  claude mcp add-json -s user tavily '<json>'

Options:
  --api-key KEY             Tavily API key (if omitted, prompts)
  --dry-run                 Print what would change, without installing/configuring
  --capture-log-file PATH   Also write logs to PATH
  -h, --help                Show this help
EOF
}

api_key=""
dry_run=0
capture_log_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --api-key) api_key="${2-}"; shift 2 ;;
    --api-key=*) api_key="${1#*=}"; shift ;;
    --dry-run) dry_run=1; shift ;;
    --capture-log-file) capture_log_file="${2-}"; shift 2 ;;
    --capture-log-file=*) capture_log_file="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"

lr_log "=== Configure Tavily MCP for Claude Code (user scope) ==="
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

if [ -z "$api_key" ]; then
  lr_log "A Tavily API key is required: https://app.tavily.com/home"
  if [ -n "${TAVILY_API_KEY:-}" ]; then
    lr_log "Detected existing TAVILY_API_KEY in environment."
    printf "Enter Tavily API key (press Enter to reuse env): "
    IFS= read -r input_key || true
    if [ -z "$input_key" ]; then
      api_key="$TAVILY_API_KEY"
    else
      api_key="$input_key"
    fi
  else
    printf "Enter Tavily API key: "
    IFS= read -r api_key || true
  fi
fi

if [ -z "$api_key" ]; then
  lr_die "Tavily API key cannot be empty."
fi

package_name="tavily-mcp"
lr_log "Installing Tavily MCP server globally via npm: $package_name"

sudo_prefix="$(lr_sudo)"
use_sudo=0
npm_prefix="$(npm prefix -g 2>/dev/null || true)"
if [ -n "$npm_prefix" ] && [ ! -w "$npm_prefix" ] && [ -n "$sudo_prefix" ]; then
  use_sudo=1
  lr_log "Global npm prefix is not writable ($npm_prefix); using sudo for global install."
fi

if [ "$use_sudo" -eq 1 ]; then
  lr_run "$sudo_prefix" npm install -g "$package_name" || lr_die "npm failed to install $package_name."
else
  lr_run npm install -g "$package_name" || lr_die "npm failed to install $package_name."
fi

scope="user"
mcp_name="tavily"

lr_log "Building JSON configuration..."
json="$(node -e 'console.log(JSON.stringify({type:"stdio",command:"tavily-mcp",args:[],env:{TAVILY_API_KEY:process.argv[1]}}))' "$api_key")"

lr_log "Removing existing '$mcp_name' server in scope '$scope' (if any)..."
lr_run claude mcp remove -s "$scope" "$mcp_name" || true

lr_log "Adding '$mcp_name' server in scope '$scope' via add-json..."
lr_run_masked "claude mcp add-json -s $scope $mcp_name <json>" claude mcp add-json -s "$scope" "$mcp_name" "$json" || lr_die "Failed to add Tavily MCP server."

lr_log "Tavily MCP server has been configured. Verify with: claude mcp list"
