#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
MAIN_SCRIPT="$SCRIPT_DIR/MAIN.sh"
LOOP_SCRIPT="$SCRIPT_DIR/LOOP.sh"

source "$COMMON_LIB"

TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"

usage() {
    cat <<'EOF'
Usage: ./DOCTOR.sh [options]

Checks whether EvoProgrammer can run in the requested target directory.

Options:
  -t, --target-dir DIR   Repository directory to validate.
  -h, --help             Show this help text.

Environment variables:
  EVOPROGRAMMER_TARGET_DIR  Repository directory to validate. Default: current directory.
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -t|--target-dir)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                exit 1
            fi
            TARGET_DIR="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            echo "Unexpected argument: $1" >&2
            exit 1
            ;;
    esac
done

if (($# > 0)); then
    echo "Unexpected extra arguments: $*" >&2
    exit 1
fi

evop_require_executable_file "$MAIN_SCRIPT" "Main script"
evop_require_executable_file "$LOOP_SCRIPT" "Loop script"
evop_require_directory "$TARGET_DIR"
evop_require_command "codex"

printf 'OK main-script %s\n' "$MAIN_SCRIPT"
printf 'OK loop-script %s\n' "$LOOP_SCRIPT"
printf 'OK target-dir %s\n' "$TARGET_DIR"
printf 'OK codex %s\n' "$(command -v codex)"
