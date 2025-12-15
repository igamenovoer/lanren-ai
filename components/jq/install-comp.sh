#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install jq (JSON processor) on Linux/macOS.

Options:
  --proxy URL               HTTP/HTTPS proxy for downloads/package managers
  --accept-defaults         Use non-interactive defaults where possible
  --from-official           Prefer official sources (no-op; jq binary uses GitHub)
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
lr_log "=== Installing jq (JSON processor) ==="
lr_log ""

lr_set_proxy_env "$proxy"
[ "$from_official" -eq 1 ] && lr_log "Using --from-official (no-op for jq)."

if lr_has_cmd jq && [ "$force" -ne 1 ]; then
  lr_log "jq is already available on PATH. Use --force to reinstall."
  exit 0
fi

os="$(lr_os)"
arch="$(lr_arch)"
sudo_prefix="$(lr_sudo)"

install_ok=0

if [ "$os" = "macos" ] && lr_has_cmd brew; then
  if [ "$force" -eq 1 ]; then
    lr_run brew reinstall jq && install_ok=1 || install_ok=0
  else
    lr_run brew install jq && install_ok=1 || install_ok=0
  fi
fi

if [ "$install_ok" -eq 0 ] && [ "$os" = "linux" ] && lr_has_cmd apt-get; then
  if [ "$accept_defaults" -eq 1 ]; then
    if [ -n "$sudo_prefix" ]; then
      lr_run "$sudo_prefix" apt-get update || true
      if [ "$force" -eq 1 ]; then
        lr_run "$sudo_prefix" apt-get install -y --reinstall jq && install_ok=1 || install_ok=0
      else
        lr_run "$sudo_prefix" apt-get install -y jq && install_ok=1 || install_ok=0
      fi
    else
      lr_run apt-get update || true
      if [ "$force" -eq 1 ]; then
        lr_run apt-get install -y --reinstall jq && install_ok=1 || install_ok=0
      else
        lr_run apt-get install -y jq && install_ok=1 || install_ok=0
      fi
    fi
  else
    if [ -n "$sudo_prefix" ]; then
      lr_run "$sudo_prefix" apt-get update || true
      lr_run "$sudo_prefix" apt-get install jq && install_ok=1 || install_ok=0
    else
      lr_run apt-get update || true
      lr_run apt-get install jq && install_ok=1 || install_ok=0
    fi
  fi
fi

if [ "$install_ok" -eq 1 ] && lr_has_cmd jq; then
  lr_log "jq installed successfully."
  exit 0
fi

# Fallback: direct GitHub release binary into ~/.local/bin
bin_dir="${HOME:-}/.local/bin"
mkdir -p "$bin_dir"

case "$os/$arch" in
  linux/amd64) download_url="https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64" ;;
  linux/arm64) download_url="https://github.com/jqlang/jq/releases/latest/download/jq-linux-arm64" ;;
  macos/arm64) download_url="https://github.com/jqlang/jq/releases/latest/download/jq-macos-arm64" ;;
  macos/amd64) download_url="https://github.com/jqlang/jq/releases/latest/download/jq-macos-amd64" ;;
  *) download_url="" ;;
esac

if [ -z "$download_url" ]; then
  lr_die "Unsupported platform for jq binary download: os=$os arch=$arch"
fi

tmp_file="$LR_PKG_DIR/jq-$os-$arch"
target="$bin_dir/jq"

lr_log "Downloading jq from: $download_url"
lr_download "$download_url" "$tmp_file"
lr_run chmod +x "$tmp_file"
lr_run mv -f "$tmp_file" "$target"

if lr_has_cmd jq; then
  lr_log "jq is now available on PATH."
else
  lr_warn "jq installed to $target, but it's not on PATH in this shell."
  lr_warn "Ensure $bin_dir is on PATH (restart your shell or add it to your profile)."
fi

lr_log "jq installation finished."

