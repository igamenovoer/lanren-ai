#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$script_dir/../_lib/lanren-shlib.sh"

usage() {
  cat <<'EOF'
Usage: ./config-comp.sh [options]

Configure pixi global mirrors (conda-forge and PyPI).

Options:
  --mirror <cn|official>                     Preset for both conda+PyPI (default: cn)
  --mirror-conda <cn|official|tuna>          Conda mirror override
  --mirror-pypi <cn|official|aliyun|tuna>    PyPI mirror override
  --dry-run                                  Print what would change, without applying
  --capture-log-file PATH                    Also write logs to PATH
  -h, --help                                 Show this help
EOF
}

mirror=""
mirror_conda=""
mirror_pypi=""
dry_run=0
capture_log_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --mirror) mirror="${2-}"; shift 2 ;;
    --mirror=*) mirror="${1#*=}"; shift ;;
    --mirror-conda) mirror_conda="${2-}"; shift 2 ;;
    --mirror-conda=*) mirror_conda="${1#*=}"; shift ;;
    --mirror-pypi) mirror_pypi="${2-}"; shift 2 ;;
    --mirror-pypi=*) mirror_pypi="${1#*=}"; shift ;;
    --dry-run) dry_run=1; shift ;;
    --capture-log-file) capture_log_file="${2-}"; shift 2 ;;
    --capture-log-file=*) capture_log_file="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$mirror" ] && [ -z "$mirror_conda" ] && [ -z "$mirror_pypi" ]; then
  mirror="cn"
fi

case "$mirror" in
  ""|cn|official) ;;
  *) echo "Invalid --mirror: $mirror" >&2; usage; exit 1 ;;
esac

case "$mirror_conda" in
  ""|cn|official|tuna) ;;
  *) echo "Invalid --mirror-conda: $mirror_conda" >&2; usage; exit 1 ;;
esac

case "$mirror_pypi" in
  ""|cn|official|aliyun|tuna) ;;
  *) echo "Invalid --mirror-pypi: $mirror_pypi" >&2; usage; exit 1 ;;
esac

component_name=$(basename "$script_dir")
lr_init_component_log "$component_name" "$capture_log_file" "$dry_run"
lr_log "=== Configuring pixi Global Mirrors ==="

if ! lr_has_cmd pixi; then
  lr_die "pixi command not found. Install pixi first."
fi

urls_tuna_conda="https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge"
urls_tuna_pypi="https://pypi.tuna.tsinghua.edu.cn/simple"
urls_aliyun_pypi="https://mirrors.aliyun.com/pypi/simple/"

effective_conda="$mirror"
effective_pypi="$mirror"

[ -n "$mirror_conda" ] && effective_conda="$mirror_conda"
[ -n "$mirror_pypi" ] && effective_pypi="$mirror_pypi"

# aliases
[ "$effective_conda" = "cn" ] && effective_conda="tuna"
[ "$effective_pypi" = "cn" ] && effective_pypi="tuna"

# Conda config
if [ -n "$effective_conda" ]; then
  if [ "$effective_conda" = "official" ]; then
    lr_log "Unsetting conda-forge mirrors..."
    lr_run pixi config unset mirrors --global || true
  elif [ "$effective_conda" = "tuna" ]; then
    json_val="{ \"https://conda.anaconda.org/conda-forge\": [\"$urls_tuna_conda\"] }"
    lr_log "Setting conda-forge mirror to tuna ($urls_tuna_conda)..."
    lr_run pixi config set mirrors "$json_val" --global
  fi
fi

# PyPI config
pypi_key="pypi-config.index-url"
if [ -n "$effective_pypi" ]; then
  if [ "$effective_pypi" = "official" ]; then
    lr_log "Unsetting PyPI index-url..."
    lr_run pixi config unset "$pypi_key" --global || true
  else
    pypi_url=""
    [ "$effective_pypi" = "tuna" ] && pypi_url="$urls_tuna_pypi"
    [ "$effective_pypi" = "aliyun" ] && pypi_url="$urls_aliyun_pypi"
    if [ -n "$pypi_url" ]; then
      lr_log "Setting PyPI index-url to $effective_pypi ($pypi_url)..."
      lr_run pixi config set "$pypi_key" "$pypi_url" --global
    fi
  fi
fi

lr_log "Configuration complete."

