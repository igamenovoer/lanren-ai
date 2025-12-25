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
Usage: ./install-comp.sh [options]

Install OpenAI Codex CLI (@openai/codex) via npm on Linux/macOS.

Options:
  --proxy URL               HTTP/HTTPS proxy for npm network access
  --accept-defaults         Use non-interactive defaults where possible (no-op)
  --from-official           Use official npm registry (registry.npmjs.org)
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
lr_log "=== Installing OpenAI Codex CLI ==="
lr_log ""

lr_set_proxy_env "$proxy"
[ "$accept_defaults" -eq 1 ] && lr_log "Using --accept-defaults (no-op for this installer)."

# Prefer user-space Node.js installs from this repo's node component.
export PATH="${HOME}/.local/bin:${PATH:-}"

if ! lr_has_cmd node; then
  lr_die "Node.js is not available on PATH. Install Node.js first (components/nodejs/install-comp.sh)."
fi
if ! lr_has_cmd npm; then
  lr_die "npm is not available on PATH. Reinstall Node.js with npm support."
fi

package_name="@openai/codex"

is_installed=0
if npm list -g "$package_name" --depth=0 >/dev/null 2>&1; then
  if npm list -g "$package_name" --depth=0 2>/dev/null | grep -q "$package_name"; then
    is_installed=1
  fi
fi

if [ "$is_installed" -eq 1 ] && [ "$force" -ne 1 ]; then
  lr_log "Package $package_name is already installed globally. Use --force to reinstall."
  exit 0
fi

primary_registry="https://registry.npmmirror.com"
official_registry="https://registry.npmjs.org"

if [ "$from_official" -eq 1 ]; then
  registry="$official_registry"
  lr_log "Using official npm registry: $registry"
else
  registry="$primary_registry"
  lr_log "Using China npm mirror: $registry"
  lr_log "Will fall back to official registry if the mirror fails."
fi

sudo_prefix="$(lr_sudo)"
use_sudo=0
npm_prefix="$(npm prefix -g 2>/dev/null || true)"
if [ -n "$npm_prefix" ] && [ ! -w "$npm_prefix" ] && [ -n "$sudo_prefix" ]; then
  use_sudo=1
fi

# Ensure the npm global bin dir is on PATH for the remainder of this script.
npm_global_bin_dir=""
[ -n "$npm_prefix" ] && npm_global_bin_dir="$npm_prefix/bin"
if [ -n "$npm_global_bin_dir" ]; then
  export PATH="$npm_global_bin_dir:${PATH:-}"
fi

install_cmd="npm"
if [ "$use_sudo" -eq 1 ]; then
  lr_log "Global npm prefix is not writable ($npm_prefix); using sudo for global install."
  install_cmd="$sudo_prefix"
fi

install_args="install -g $package_name --registry $registry"
lr_log "Running: $install_cmd $install_args"

install_rc=0
if [ "$use_sudo" -eq 1 ]; then
  lr_run "$sudo_prefix" npm install -g "$package_name" --registry "$registry" || install_rc=$?
else
  lr_run npm install -g "$package_name" --registry "$registry" || install_rc=$?
fi

if [ "$install_rc" -ne 0 ] && [ "$from_official" -ne 1 ]; then
  lr_warn "npm install via mirror failed (exit code $install_rc). Retrying against official registry: $official_registry"
  if [ "$use_sudo" -eq 1 ]; then
    lr_run "$sudo_prefix" npm install -g "$package_name" --registry "$official_registry" || lr_die "npm failed to install $package_name."
  else
    lr_run npm install -g "$package_name" --registry "$official_registry" || lr_die "npm failed to install $package_name."
  fi
elif [ "$install_rc" -ne 0 ]; then
  lr_die "npm failed to install $package_name (exit code $install_rc)."
fi

# For user-space Node installs, the npm global bin dir is typically not on PATH.
# Link `codex` into ~/.local/bin so it is available alongside node/npm.
user_bin_dir="${HOME}/.local/bin"
if [ -n "$npm_global_bin_dir" ] && [ -x "$npm_global_bin_dir/codex" ]; then
  mkdir -p "$user_bin_dir" || true
  lr_log "Linking codex into: $user_bin_dir"
  lr_run ln -sf "$npm_global_bin_dir/codex" "$user_bin_dir/codex" || true
  export PATH="$user_bin_dir:${PATH:-}"
fi

if lr_has_cmd codex; then
  lr_log "Codex CLI installed successfully: $(codex --version 2>/dev/null || true)"
else
  lr_warn "'codex' command not found on PATH after installation."
  lr_warn "Ensure your global npm bin directory is on PATH."
fi
