#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./install-extensions.sh [options]

Install common VS Code extensions using the 'code' CLI.

Options:
  --capture-log-file PATH   Also write logs to PATH
  --dry-run                 Print what would change, without installing
  -h, --help                Show this help
EOF
}

capture_log_file=""
dry_run=0

while [ $# -gt 0 ]; do
  case "$1" in
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
lr_log "=== Installing Visual Studio Code extensions ==="
lr_log ""

if ! lr_has_cmd code; then
  lr_warn "VS Code CLI 'code' not found on PATH. Skipping extension installation."
  exit 0
fi

lr_log "Using VS Code CLI at: $(command -v code)"

extensions="
ms-python.python
eamodio.gitlens
shd101wyy.markdown-preview-enhanced
mechatroner.rainbow-csv
GrapeCity.gc-excelviewer
openai.chatgpt
anthropic.claude-code
saoudrizwan.claude-dev
"

printf '%s\n' "$extensions" | while IFS= read -r ext; do
  [ -z "$ext" ] && continue
  lr_log "Installing VS Code extension: $ext"
  lr_run code --install-extension "$ext" --force || lr_warn "Failed to install extension: $ext"
done

lr_log "Extension installation finished."

