#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

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

if lr_has_cmd codex; then
  lr_log "Codex CLI installed successfully: $(codex --version 2>/dev/null || true)"
else
  lr_warn "'codex' command not found on PATH after installation."
  lr_warn "Ensure your global npm bin directory is on PATH."
fi

