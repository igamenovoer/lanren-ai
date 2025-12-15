#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-comp.sh [options]

Install PowerShell 7 (LTS) on Linux/macOS.

On macOS (Apple Silicon), prefers Homebrew.
On Linux, installs a user-scoped pwsh from official GitHub release tarballs
and symlinks it into ~/.local/bin/pwsh.

Options:
  --proxy URL               HTTP/HTTPS proxy for downloads/package managers
  --accept-defaults         Use non-interactive defaults where possible (no-op)
  --from-official           Prefer official sources (default)
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
lr_log "=== Installing PowerShell 7 (LTS) ==="
lr_log ""

lr_set_proxy_env "$proxy"
[ "$accept_defaults" -eq 1 ] && lr_log "Using --accept-defaults (no-op for this installer)."
[ "$from_official" -eq 1 ] && lr_log "Using --from-official."

if lr_has_cmd pwsh && [ "$force" -ne 1 ]; then
  lr_log "PowerShell 7 is already available on PATH (pwsh found). Use --force to reinstall."
  exit 0
fi

powershell_version="7.4.13"
os="$(lr_os)"
arch="$(lr_arch)"

if [ "$os" = "macos" ]; then
  if [ "$arch" != "arm64" ]; then
    lr_warn "This installer is intended for Apple Silicon macOS (arm64). Detected arch=$arch."
  fi
  if lr_has_cmd brew; then
    if [ "$force" -eq 1 ]; then
      lr_run brew reinstall powershell || lr_die "brew reinstall powershell failed."
    else
      lr_run brew install powershell || lr_die "brew install powershell failed."
    fi
    if lr_has_cmd pwsh; then
      lr_log "PowerShell installed successfully: $(pwsh --version 2>/dev/null || true)"
      exit 0
    fi
    lr_warn "brew completed, but pwsh is not on PATH in this shell."
  else
    lr_warn "Homebrew not found; falling back to tarball install."
  fi
fi

case "$os/$arch" in
  linux/amd64) tar_name="powershell-$powershell_version-linux-x64.tar.gz" ;;
  linux/arm64) tar_name="powershell-$powershell_version-linux-arm64.tar.gz" ;;
  macos/arm64) tar_name="powershell-$powershell_version-osx-arm64.tar.gz" ;;
  macos/amd64) tar_name="powershell-$powershell_version-osx-x64.tar.gz" ;;
  *) lr_die "Unsupported platform for PowerShell tarball: os=$os arch=$arch" ;;
esac

download_url="https://github.com/PowerShell/PowerShell/releases/download/v$powershell_version/$tar_name"
tar_path="$LR_PKG_DIR/$tar_name"

if ! lr_has_cmd tar; then
  lr_die "tar is required to install PowerShell from tarball."
fi

install_root="${HOME:-}/.local/share/powershell"
install_dir="$install_root/$powershell_version"
bin_dir="${HOME:-}/.local/bin"
pwsh_link="$bin_dir/pwsh"

lr_log "Downloading PowerShell tarball: $download_url"
lr_download "$download_url" "$tar_path"

lr_log "Installing to: $install_dir"
lr_run mkdir -p "$install_dir" "$bin_dir"

lr_log "Extracting: $tar_path"
lr_run tar -xzf "$tar_path" -C "$install_dir"

lr_log "Linking pwsh into PATH: $pwsh_link -> $install_dir/pwsh"
lr_run ln -sf "$install_dir/pwsh" "$pwsh_link"

if lr_has_cmd pwsh; then
  lr_log "PowerShell installed successfully: $(pwsh --version 2>/dev/null || true)"
else
  lr_warn "Installed pwsh to $pwsh_link, but it's not on PATH in this shell."
  lr_warn "Ensure $bin_dir is on PATH (restart your shell or add it to your profile)."
fi

