#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-custom-api-key.sh [options]

Create a launcher to run Claude Code with a custom Anthropic-compatible base URL
and API key, bypassing permission prompts via --dangerously-skip-permissions.

This script creates an executable launcher at ~/.local/bin/<alias-name>.

Options:
  --alias-name NAME         Name of the launcher to create (e.g. claude-kimi)
  --base-url URL            Base URL (optional; must start with http:// or https://)
  --api-key KEY             API key (stored in plain text in the launcher script)
  --primary-model NAME      Optional primary (big) model name
  --secondary-model NAME    Optional secondary (small) model name (defaults to primary)
  --dry-run                 Print what would change, without writing files
  --capture-log-file PATH   Also write logs to PATH
  -h, --help                Show this help
EOF
}

alias_name=""
base_url=""
api_key=""
primary_model=""
secondary_model=""
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
    --primary-model) primary_model="${2-}"; shift 2 ;;
    --primary-model=*) primary_model="${1#*=}"; shift ;;
    --secondary-model) secondary_model="${2-}"; shift 2 ;;
    --secondary-model=*) secondary_model="${1#*=}"; shift ;;
    --dry-run) dry_run=1; shift ;;
    --capture-log-file) capture_log_file="${2-}"; shift 2 ;;
    --capture-log-file=*) capture_log_file="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"

lr_log "[claude-config-custom-api-key] Configuring Claude Code launcher..."

if [ -z "$alias_name" ]; then
  printf "Enter alias name (e.g. claude-kimi): "
  IFS= read -r alias_name || true
fi
if [ -z "$base_url" ]; then
  printf "Base URL (optional; press Enter for official endpoint): "
  IFS= read -r base_url || true
fi
if [ -z "$api_key" ]; then
  printf "API key (stored in plain text in launcher): "
  IFS= read -r api_key || true
fi
if [ -z "$primary_model" ]; then
  printf "Primary model (optional; press Enter to skip): "
  IFS= read -r primary_model || true
fi
if [ -n "$primary_model" ] && [ -z "$secondary_model" ]; then
  printf "Secondary model (optional; press Enter to reuse primary): "
  IFS= read -r secondary_model || true
fi

if [ -z "$alias_name" ]; then
  lr_die "Alias name cannot be empty."
fi
echo "$alias_name" | grep -Eq '^[A-Za-z0-9_-]+$' || lr_die "Alias name has invalid characters (allowed: A-Z a-z 0-9 _ -)."
if [ -n "$base_url" ]; then
  echo "$base_url" | grep -Eq '^https?://' || lr_die "Base URL must start with http:// or https://"
fi
if [ -z "$api_key" ]; then
  lr_die "API key cannot be empty."
fi

if [ -n "$primary_model" ] && [ -z "$secondary_model" ]; then
  secondary_model="$primary_model"
fi

if ! lr_has_cmd claude; then
  lr_die "'claude' CLI not found in PATH. Install Claude Code CLI first."
fi

bin_dir="${HOME:-}/.local/bin"
launcher_path="$bin_dir/$alias_name"

lr_log "Launcher path: $launcher_path"
if [ "$dry_run" -eq 1 ]; then
  lr_log "Dry-run: would create launcher (API key hidden)."
  exit 0
fi

mkdir -p "$bin_dir"

api_key_quoted="$(lr_shell_quote "$api_key")"
base_url_quoted="$(lr_shell_quote "$base_url")"
primary_quoted="$(lr_shell_quote "$primary_model")"
secondary_quoted="$(lr_shell_quote "$secondary_model")"

{
  printf '%s\n' '#!/usr/bin/env sh'
  printf '%s\n' 'set -eu'
  if [ -n "$base_url" ]; then
    printf '%s\n' "export ANTHROPIC_BASE_URL=$base_url_quoted"
  fi
  printf '%s\n' "export ANTHROPIC_API_KEY=$api_key_quoted"
  if [ -n "$primary_model" ]; then
    printf '%s\n' "export ANTHROPIC_MODEL=$primary_quoted"
    printf '%s\n' "export ANTHROPIC_DEFAULT_OPUS_MODEL=$primary_quoted"
    printf '%s\n' "export ANTHROPIC_DEFAULT_SONNET_MODEL=$primary_quoted"
    printf '%s\n' "export ANTHROPIC_DEFAULT_HAIKU_MODEL=$secondary_quoted"
    printf '%s\n' "export CLAUDE_CODE_SUBAGENT_MODEL=$secondary_quoted"
  fi
  printf '%s\n' 'exec claude --dangerously-skip-permissions "$@"'
} >"$launcher_path"

chmod +x "$launcher_path"

lr_log "Launcher created. Ensure ~/.local/bin is on PATH, then run: $alias_name"

# Optional: update ~/.claude/settings.json apiKeyHelper if present
settings_file="${HOME:-}/.claude/settings.json"
if [ -f "$settings_file" ] && grep -q '"apiKeyHelper"' "$settings_file" 2>/dev/null; then
  printf "Found existing apiKeyHelper in %s. Update with new key? [y/N] " "$settings_file"
  IFS= read -r ans || true
  if echo "$ans" | grep -Eq '^[Yy]$'; then
    ts="$(date +%Y%m%d%H%M%S 2>/dev/null || date)"
    backup_file="$settings_file.bak.$ts"
    cp -f "$settings_file" "$backup_file"
    lr_warn "Backed up settings.json to $backup_file"

    if lr_has_cmd jq && jq empty <"$settings_file" >/dev/null 2>&1; then
      lr_log "Updating settings.json via jq"
      tmp_json="$(mktemp "${TMPDIR:-/tmp}/claude.settings.XXXXXX" 2>/dev/null || echo "${TMPDIR:-/tmp}/claude.settings.$$")"
      jq --arg key "$api_key" '.apiKeyHelper = ("echo " + $key)' "$settings_file" >"$tmp_json"
      mv -f "$tmp_json" "$settings_file"
    elif lr_has_cmd node; then
      lr_log "Updating settings.json via node"
      lr_run_masked "node <update settings.json apiKeyHelper>" node - "$settings_file" "$api_key" <<'NODE'
const fs = require("fs");
const file = process.argv[2];
const key = process.argv[3];
let obj = {};
try {
  const text = fs.readFileSync(file, "utf8");
  obj = JSON.parse(text);
} catch {
  obj = {};
}
obj.apiKeyHelper = "echo " + key;
fs.writeFileSync(file, JSON.stringify(obj, null, 2), { encoding: "utf8" });
NODE
    else
      lr_warn "Neither jq nor node available to update $settings_file; skipped."
    fi
  else
    lr_warn "Skipped settings.json update."
  fi
fi
