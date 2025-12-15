#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)

# Self-contained helpers (inlined per script).
lr_os() {
  # outputs: linux | macos | unknown
  case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux) echo linux ;;
    Darwin) echo macos ;;
    *) echo unknown ;;
  esac
}

lr_arch() {
  # outputs: amd64 | arm64 | <raw>
  case "$(uname -m 2>/dev/null || echo unknown)" in
    x86_64|amd64) echo amd64 ;;
    aarch64|arm64) echo arm64 ;;
    *) uname -m 2>/dev/null || echo unknown ;;
  esac
}

lr_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

lr_shell_quote() {
  # Single-quote a string for POSIX shells.
  # Example: abc'def -> 'abc'"'"'def'
  printf "'%s'" "$(printf "%s" "${1-}" | sed "s/'/'\"'\"'/g")"
}

lr_set_proxy_env() {
  proxy="${1-}"
  if [ -n "$proxy" ]; then
    export HTTP_PROXY="$proxy" HTTPS_PROXY="$proxy"
    export http_proxy="$proxy" https_proxy="$proxy"
  fi
}

lr_init_component_log() {
  LR_COMPONENT_NAME="${1-unknown}"
  LR_CAPTURE_LOG_FILE="${2-}"
  LR_DRY_RUN="${3-0}"

  if [ -n "${LRAI_MASTER_OUTPUT_DIR:-}" ]; then
    LR_ROOT="$LRAI_MASTER_OUTPUT_DIR"
  else
    LR_ROOT="$(pwd)/lanren-cache"
  fi

  LR_LOG_DIR="$LR_ROOT/logs/$LR_COMPONENT_NAME"
  LR_PKG_DIR="$LR_ROOT/packages/$LR_COMPONENT_NAME"
  mkdir -p "$LR_LOG_DIR" "$LR_PKG_DIR"

  ts="$(date +%Y%m%d_%H%M%S 2>/dev/null || date)"
  LR_LOG_FILE="$LR_LOG_DIR/$LR_COMPONENT_NAME-$ts.log"
  : >"$LR_LOG_FILE"

  if [ -n "$LR_CAPTURE_LOG_FILE" ]; then
    cap_dir="$(dirname "$LR_CAPTURE_LOG_FILE" 2>/dev/null || echo .)"
    mkdir -p "$cap_dir"
    : >"$LR_CAPTURE_LOG_FILE"
  fi
}

lr_log() {
  msg="$*"
  if [ -n "${LR_CAPTURE_LOG_FILE:-}" ]; then
    printf '%s\n' "$msg" | tee -a "$LR_LOG_FILE" "$LR_CAPTURE_LOG_FILE"
  else
    printf '%s\n' "$msg" | tee -a "$LR_LOG_FILE"
  fi
}

lr_warn() {
  lr_log "WARNING: $*"
}

lr_err() {
  lr_log "ERROR: $*"
}

lr_die() {
  lr_err "$*"
  exit 1
}

lr_run_impl() {
  if [ "${LR_DRY_RUN:-0}" -eq 1 ]; then
    return 0
  fi
  tmp_out="$(mktemp "${TMPDIR:-/tmp}/lanren-ai.XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/lanren-ai.$$.$(date +%s)")"
  tmp_rc="$tmp_out.rc"

  (
    set +e
    "$@" >"$tmp_out" 2>&1
    echo $? >"$tmp_rc"
  )

  if [ -n "${LR_CAPTURE_LOG_FILE:-}" ]; then
    cat "$tmp_out" | tee -a "$LR_LOG_FILE" "$LR_CAPTURE_LOG_FILE"
  else
    cat "$tmp_out" | tee -a "$LR_LOG_FILE"
  fi

  rc="$(cat "$tmp_rc" 2>/dev/null || echo 1)"
  rm -f "$tmp_out" "$tmp_rc" 2>/dev/null || true
  return "$rc"
}

lr_run() {
  # Runs a command and logs its combined output while preserving the command exit code.
  # Usage: lr_run <cmd> [args...]
  lr_log "+ $*"
  lr_run_impl "$@"
}

lr_run_masked() {
  # Runs a command but logs a caller-provided, redacted description instead of the full argv.
  # Usage: lr_run_masked "<safe description>" <cmd> [args...]
  desc="${1-}"
  shift || true
  lr_log "+ $desc"
  lr_run_impl "$@"
}

lr_download() {
  # Usage: lr_download <url> <dest_path>
  url="$1"
  dest="$2"
  if lr_has_cmd curl; then
    lr_run curl -fsSL "$url" -o "$dest"
    return $?
  fi
  if lr_has_cmd wget; then
    lr_run wget -q "$url" -O "$dest"
    return $?
  fi
  lr_die "Neither curl nor wget is available for downloading: $url"
}

lr_sudo() {
  # Echo a sudo prefix if needed/available.
  if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
    echo ""
    return 0
  fi
  if lr_has_cmd sudo; then
    echo "sudo"
    return 0
  fi
  echo ""
}

usage() {
  cat <<'EOF'
Usage: ./config-tavily-mcp.sh [options]

Install the Tavily MCP server via Bun and configure it for Codex CLI by
updating $CODEX_HOME/config.toml (default: ~/.codex/config.toml).

Options:
  --api-key KEY             Tavily API key (if omitted, prompts)
  --dry-run                 Print what would change, without installing/writing
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

lr_log "=== Configure Tavily MCP for Codex CLI ==="
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
lr_log "Installing Tavily MCP server globally via Bun: $package_name"
lr_run bun add -g "$package_name" || lr_die "bun failed to install $package_name."

codex_home="${CODEX_HOME:-${HOME:-}/.codex}"
config_path="$codex_home/config.toml"

lr_log "Codex config: $config_path"

block_content="
[mcp_servers.tavily]
command = \"bunx\"
args = [\"tavily-mcp@latest\"]
env = { TAVILY_API_KEY = \"${api_key}\" }
"

if [ "$dry_run" -eq 1 ]; then
  lr_log "Dry-run: would ensure [mcp_servers] exists and write/replace:"
  lr_log "[mcp_servers.tavily] (env key hidden)"
  exit 0
fi

mkdir -p "$codex_home"
touch "$config_path"

tmp_file="$(mktemp "${TMPDIR:-/tmp}/codex.config.XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/codex.config.$$")"

awk '
  BEGIN {skip=0; has_mcp=0}
  /^[[:space:]]*\[mcp_servers\][[:space:]]*$/ {has_mcp=1}
  /^[[:space:]]*\[mcp_servers\.tavily\][[:space:]]*$/ {skip=1; next}
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

lr_log "Tavily MCP server configured (mcp_servers.tavily)."
lr_log "You can verify with: codex mcp list"
