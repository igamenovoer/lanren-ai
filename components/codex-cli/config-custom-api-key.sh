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
Usage: ./config-custom-api-key.sh [options]

Configure Codex CLI to use a custom OpenAI-compatible endpoint and API key,
and skip the login screen by updating $CODEX_HOME/config.toml.

This script:
  - Creates an executable launcher at ~/.local/bin/<alias-name>
  - Updates ~/.codex/config.toml (or $CODEX_HOME/config.toml):
      - model_provider = "<alias-name>"
      - [model_providers.<alias-name>] uses env_key="OPENAI_API_KEY" and requires_openai_auth=false

Options:
  --alias-name NAME         Name of the launcher to create (e.g. codex-openai-proxy)
  --base-url URL            Base URL (optional; must start with http:// or https://)
  --api-key KEY             API key (stored in plain text in the launcher script)
  --dry-run                 Print what would change, without writing files
  --capture-log-file PATH   Also write logs to PATH
  -h, --help                Show this help
EOF
}

alias_name=""
base_url=""
api_key=""
dry_run=0
capture_log_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --alias-name) alias_name="${2-}"; shift 2 ;;
    --alias-name=*) alias_name="${1#*=}"; shift ;;
    --base-url) base_url="${2-}"; shift 2 ;;
    --base-url=*) base_url="${1#*=}"; shift ;;
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

lr_log "[codex-config-custom-api-key] Configuring Codex CLI custom endpoint and skipping login..."

if [ -z "$alias_name" ]; then
  printf "Enter alias name (e.g. codex-openai-proxy): "
  IFS= read -r alias_name || true
fi
if [ -z "$base_url" ]; then
  printf "Base URL (optional; press Enter for official OpenAI): "
  IFS= read -r base_url || true
fi
if [ -z "$api_key" ]; then
  printf "API key (stored in plain text in launcher): "
  IFS= read -r api_key || true
fi

if [ -z "$alias_name" ]; then
  lr_die "Alias name cannot be empty."
fi
echo "$alias_name" | grep -Eq '^[A-Za-z0-9_-]+$' || lr_die "Alias name has invalid characters (allowed: A-Z a-z 0-9 _ -)."
if [ "$alias_name" = "openai" ] || [ "$alias_name" = "OpenAI" ]; then
  lr_die "Alias name '$alias_name' is reserved; choose a different alias."
fi
if [ -n "$base_url" ]; then
  echo "$base_url" | grep -Eq '^https?://' || lr_die "Base URL must start with http:// or https://"
fi
if [ -z "$api_key" ]; then
  lr_die "API key cannot be empty."
fi

if ! lr_has_cmd codex; then
  lr_die "'codex' CLI not found in PATH. Install Codex CLI first (components/codex-cli/install-comp.sh)."
fi

bin_dir="${HOME:-}/.local/bin"
launcher_path="$bin_dir/$alias_name"

codex_home="${CODEX_HOME:-${HOME:-}/.codex}"
config_path="$codex_home/config.toml"

effective_base_url="$base_url"
if [ -z "$effective_base_url" ]; then
  effective_base_url="https://api.openai.com/v1"
fi

lr_log "Launcher path: $launcher_path"
lr_log "Codex config: $config_path"

if [ "$dry_run" -eq 1 ]; then
  lr_log "Dry-run: would create launcher and update model provider '$alias_name' (API key hidden)."
  exit 0
fi

mkdir -p "$bin_dir" "$codex_home"

api_key_quoted="$(lr_shell_quote "$api_key")"
base_url_quoted="$(lr_shell_quote "$base_url")"

{
  printf '%s\n' '#!/usr/bin/env sh'
  printf '%s\n' 'set -eu'
  if [ -n "$base_url" ]; then
    printf '%s\n' "export OPENAI_BASE_URL=$base_url_quoted"
  fi
  printf '%s\n' "export OPENAI_API_KEY=$api_key_quoted"
  printf '%s\n' 'exec codex "$@"'
} >"$launcher_path"

chmod +x "$launcher_path"

touch "$config_path"

tmp_file="$(mktemp "${TMPDIR:-/tmp}/codex.model.XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/codex.model.$$")"

provider_id="$alias_name"

# First pass: remove any existing provider block, replace/insert model_provider.
awk -v provider="$provider_id" '
  BEGIN {skip=0; printed_model_provider=0; has_model_providers_table=0}
  /^[[:space:]]*\[model_providers\][[:space:]]*$/ {has_model_providers_table=1}
  /^[[:space:]]*\[/ {
    if (printed_model_provider==0) {
      print "model_provider = \"" provider "\""
      printed_model_provider=1
    }
  }
  /^[[:space:]]*model_provider[[:space:]]*=/ {
    if (printed_model_provider==0) {
      print "model_provider = \"" provider "\""
      printed_model_provider=1
    }
    next
  }
  # remove provider block
  $0 ~ "^[[:space:]]*\\[model_providers\\." provider "\\][[:space:]]*$" {skip=1; next}
  skip==1 {
    if ($0 ~ /^[[:space:]]*\[/) {skip=0}
    else {next}
  }
  {print}
  END {
    if (printed_model_provider==0) {
      print "model_provider = \"" provider "\""
    }
    if (has_model_providers_table==0) {
      print ""
      print "[model_providers]"
    }
  }
' "$config_path" >"$tmp_file"

mv -f "$tmp_file" "$config_path"

{
  printf '\n[model_providers.%s]\n' "$provider_id"
  printf '%s\n' 'name = "Custom OpenAI-compatible endpoint"'
  printf 'base_url = "%s"\n' "$effective_base_url"
  printf '%s\n' 'env_key = "OPENAI_API_KEY"'
  printf '%s\n' 'env_key_instructions = "Set OPENAI_API_KEY in your environment or use the launcher created by this script."'
  printf '%s\n' 'requires_openai_auth = false'
  printf '\n'
} >>"$config_path"

lr_log "Custom Codex endpoint configured successfully."
lr_log "To use it, ensure ~/.local/bin is on PATH, then run: $alias_name"
