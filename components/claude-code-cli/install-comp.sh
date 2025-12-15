#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install Claude Code CLI (@anthropic-ai/claude-code) via npm on Linux/macOS and
mark onboarding as completed.

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
lr_log "=== Installing Claude Code CLI ==="
lr_log ""

lr_set_proxy_env "$proxy"
[ "$accept_defaults" -eq 1 ] && lr_log "Using --accept-defaults (no-op for this installer)."

if ! lr_has_cmd node; then
  lr_die "Node.js is not available on PATH. Install Node.js first (components/nodejs/install-comp.sh)."
fi
if ! lr_has_cmd npm; then
  lr_die "npm is not available on PATH. Reinstall Node.js with npm support."
fi

if lr_has_cmd claude && [ "$force" -ne 1 ]; then
  lr_log "Claude Code CLI is already available on PATH (claude found). Use --force to reinstall."
else
  package_name="@anthropic-ai/claude-code"
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
    lr_log "Global npm prefix is not writable ($npm_prefix); using sudo for global install."
  fi

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
fi

if lr_has_cmd claude; then
  lr_log "Claude Code CLI installed successfully: $(claude --version 2>/dev/null || true)"
else
  lr_warn "'claude' command not found on PATH after installation."
  lr_warn "Ensure your global npm bin directory is on PATH."
fi

lr_log ""
lr_log "Configuring Claude Code to skip onboarding using config-skip-login.sh..."

skip_script="$script_dir/config-skip-login.sh"
if [ ! -f "$skip_script" ]; then
  lr_die "Expected helper script not found: $skip_script"
fi

if [ "$dry_run" -eq 1 ]; then
  lr_run sh "$skip_script" --dry-run --capture-log-file "$capture_log_file" || lr_die "config-skip-login.sh failed."
else
  lr_run sh "$skip_script" --capture-log-file "$capture_log_file" || lr_die "config-skip-login.sh failed."
fi

lr_log "Claude Code onboarding/login should now be skipped on this host."

