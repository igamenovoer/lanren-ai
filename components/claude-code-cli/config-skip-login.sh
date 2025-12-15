#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-skip-login.sh [options]

Mark Claude Code onboarding as completed by setting hasCompletedOnboarding=true
in ~/.claude.json.

Options:
  --dry-run                 Print what would change, without writing files
  --capture-log-file PATH   Also write logs to PATH
  -h, --help                Show this help
EOF
}

dry_run=0
capture_log_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1; shift ;;
    --capture-log-file) capture_log_file="${2-}"; shift 2 ;;
    --capture-log-file=*) capture_log_file="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"

lr_log "=== Configure Claude Code to Skip Onboarding ==="
lr_log ""

if ! lr_has_cmd node; then
  lr_die "Node.js is not available on PATH. Install Node.js first."
fi
if ! lr_has_cmd npm; then
  lr_die "npm is not available on PATH. Install Node.js (with npm) first."
fi
if ! lr_has_cmd claude; then
  lr_die "Claude Code CLI ('claude') is not on PATH. Install it first."
fi

config_file="${HOME:-}/.claude.json"
lr_log "Config file: $config_file"

if [ "$dry_run" -eq 1 ]; then
  lr_log "Dry-run: would set hasCompletedOnboarding=true in $config_file"
  exit 0
fi

# Use Node.js for JSON read/modify/write to avoid shell quoting issues.
lr_log "Updating hasCompletedOnboarding in $config_file ..."
lr_run node - "$config_file" <<'NODE'
const fs = require("fs");
const path = process.argv[2];
let obj = {};
try {
  if (fs.existsSync(path)) {
    const text = fs.readFileSync(path, "utf8").trim();
    if (text) obj = JSON.parse(text);
  }
} catch {
  obj = {};
}
obj.hasCompletedOnboarding = true;
fs.writeFileSync(path, JSON.stringify(obj, null, 2), { encoding: "utf8" });
NODE

lr_log "Claude Code onboarding has been marked as completed."
