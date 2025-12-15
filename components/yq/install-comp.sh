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
