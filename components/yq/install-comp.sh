#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install yq (mikefarah/yq) on Linux/macOS.

Options:
  --proxy URL               HTTP/HTTPS proxy for downloads/package managers
  --accept-defaults         Use non-interactive defaults where possible
  --from-official           Prefer official sources (no-op; yq binary uses GitHub)
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
lr_log "=== Installing yq (YAML/JSON/XML processor) ==="
lr_log ""

lr_set_proxy_env "$proxy"
[ "$from_official" -eq 1 ] && lr_log "Using --from-official (no-op for yq)."

if lr_has_cmd yq && [ "$force" -ne 1 ]; then
  lr_log "yq is already available on PATH. Use --force to reinstall."
  exit 0
fi

os="$(lr_os)"
arch="$(lr_arch)"

# Prefer brew on macOS when available.
if [ "$os" = "macos" ] && lr_has_cmd brew; then
  if [ "$force" -eq 1 ]; then
    lr_run brew reinstall yq || true
  else
    lr_run brew install yq || true
  fi
  if lr_has_cmd yq; then
    lr_log "yq installed successfully via Homebrew."
    exit 0
  fi
fi

# Prefer apt on Linux when available (note: distro yq packages may differ).
sudo_prefix="$(lr_sudo)"
if [ "$os" = "linux" ] && lr_has_cmd apt-get; then
  if [ "$accept_defaults" -eq 1 ]; then
    if [ -n "$sudo_prefix" ]; then
      lr_run "$sudo_prefix" apt-get update || true
      lr_run "$sudo_prefix" apt-get install -y yq || true
    else
      lr_run apt-get update || true
      lr_run apt-get install -y yq || true
    fi
  else
    if [ -n "$sudo_prefix" ]; then
      lr_run "$sudo_prefix" apt-get update || true
      lr_run "$sudo_prefix" apt-get install yq || true
    else
      lr_run apt-get update || true
      lr_run apt-get install yq || true
    fi
  fi
  if lr_has_cmd yq; then
    lr_log "yq installed successfully via apt-get."
    lr_warn "Note: some distros ship a different 'yq'. If you need mikefarah/yq, use the GitHub binary fallback."
    exit 0
  fi
fi

# Fallback: direct GitHub release binary into ~/.local/bin (mikefarah/yq)
bin_dir="${HOME:-}/.local/bin"
mkdir -p "$bin_dir"

case "$os/$arch" in
  linux/amd64) download_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" ;;
  linux/arm64) download_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm64" ;;
  macos/arm64) download_url="https://github.com/mikefarah/yq/releases/latest/download/yq_darwin_arm64" ;;
  macos/amd64) download_url="https://github.com/mikefarah/yq/releases/latest/download/yq_darwin_amd64" ;;
  *) download_url="" ;;
esac

if [ -z "$download_url" ]; then
  lr_die "Unsupported platform for yq binary download: os=$os arch=$arch"
fi

tmp_file="$LR_PKG_DIR/yq-$os-$arch"
target="$bin_dir/yq"

lr_log "Downloading yq from: $download_url"
lr_download "$download_url" "$tmp_file"
lr_run chmod +x "$tmp_file"
lr_run mv -f "$tmp_file" "$target"

if lr_has_cmd yq; then
  lr_log "yq is now available on PATH."
else
  lr_warn "yq installed to $target, but it's not on PATH in this shell."
  lr_warn "Ensure $bin_dir is on PATH (restart your shell or add it to your profile)."
fi

lr_log "yq installation finished."

