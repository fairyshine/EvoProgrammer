#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"

OLDER_THAN_DAYS=30
CLEAN_ALL=0
DRY_RUN=0
TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"
ARTIFACTS_DIR="${EVOPROGRAMMER_ARTIFACTS_DIR:-}"

usage() {
    cat <<'EOF'
Usage: ./CLEAN.sh [options]

Removes old artifact directories created by previous runs.

Options:
  --older-than DAYS     Remove artifacts older than DAYS days. Default: 30.
  --all                 Remove all artifacts regardless of age.
  --dry-run             Print what would be removed without deleting.
  -t, --target-dir DIR  Repository directory. Default: current directory.
  -o, --artifacts-dir DIR
                        Root directory used to store run artifacts.
  -h, --help            Show this help text.
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --older-than)
            evop_require_option_value "$1" "$#"
            OLDER_THAN_DAYS="$2"
            shift 2
            ;;
        --all)
            CLEAN_ALL=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -t|--target-dir)
            evop_require_option_value "$1" "$#"
            TARGET_DIR="$2"
            shift 2
            ;;
        -o|--artifacts-dir)
            evop_require_option_value "$1" "$#"
            ARTIFACTS_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

evop_validate_non_negative_integer "older-than" "$OLDER_THAN_DAYS"
evop_require_directory "$TARGET_DIR"
artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"

if [[ ! -d "$artifacts_root" ]]; then
    echo "No artifacts directory found: $artifacts_root"
    exit 0
fi

removed=0

while IFS= read -r -d '' dir; do
    if (( DRY_RUN == 1 )); then
        printf 'Would remove: %s\n' "$dir"
    else
        rm -rf "$dir"
        printf 'Removed: %s\n' "$dir"
    fi
    ((removed++))
done < <(
    if (( CLEAN_ALL == 1 )); then
        find "$artifacts_root" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null
    else
        find "$artifacts_root" -mindepth 1 -maxdepth 1 -type d -mtime +"$OLDER_THAN_DAYS" -print0 2>/dev/null
    fi
)

if (( removed == 0 )); then
    echo "No artifacts to clean."
else
    printf '%d artifact(s) %s.\n' "$removed" "$( (( DRY_RUN == 1 )) && echo "would be removed" || echo "removed")"
fi
