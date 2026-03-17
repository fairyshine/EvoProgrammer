#!/bin/sh
# shellcheck shell=bash

. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"
EVOP_LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"

LAST_N=10
SHOW_ALL=0
TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"
ARTIFACTS_DIR="${EVOPROGRAMMER_ARTIFACTS_DIR:-}"

usage() {
    cat <<'EOF'
Usage: ./STATUS.sh [options]

Shows recent run and session history from the artifacts directory.

Options:
  --last N              Show the last N entries. Default: 10.
  --all                 Show all entries.
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
        --last)
            evop_require_option_value "$1" "$#"
            LAST_N="$2"
            shift 2
            ;;
        --all)
            SHOW_ALL=1
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

evop_validate_non_negative_integer "last" "$LAST_N"
evop_require_directory "$TARGET_DIR"
artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"

if [[ ! -d "$artifacts_root" ]]; then
    echo "No artifacts directory found: $artifacts_root"
    exit 0
fi

read_env_value() {
    local file="$1"
    local key="$2"
    local line

    line="$(grep "^${key}=" "$file" 2>/dev/null | head -n 1)" || true
    if [[ -n "$line" ]]; then
        eval "printf '%s' ${line#*=}"
    fi
}

format_entry() {
    local dir="$1"
    local name
    local metadata=""
    local agent=""
    local item_status=""
    local started=""
    local mode=""

    name="$(basename "$dir")"

    if [[ -f "$dir/session.env" ]]; then
        metadata="$dir/session.env"
        mode="session"
    elif [[ -f "$dir/metadata.env" ]]; then
        metadata="$dir/metadata.env"
        mode="run"
    else
        printf '%s  (no metadata)\n' "$name"
        return
    fi

    agent="$(read_env_value "$metadata" AGENT)"
    started="$(read_env_value "$metadata" STARTED_AT)"

    if [[ "$mode" == "session" ]]; then
        item_status="$(read_env_value "$metadata" STATE)"
        local last_iter
        last_iter="$(read_env_value "$metadata" LAST_ITERATION)"
        printf '%s  %s  agent=%s  state=%s  iterations=%s\n' "$name" "$started" "$agent" "$item_status" "$last_iter"
    else
        item_status="$(read_env_value "$metadata" STATUS)"
        printf '%s  %s  agent=%s  status=%s\n' "$name" "$started" "$agent" "$item_status"
    fi
}

entries=()
while IFS= read -r dir; do
    entries+=("$dir")
done < <(find "$artifacts_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | LC_ALL=C sort -r)

if (( ${#entries[@]} == 0 )); then
    echo "No runs found."
    exit 0
fi

if (( SHOW_ALL == 0 )); then
    limit="$LAST_N"
else
    limit="${#entries[@]}"
fi

count=0
for dir in "${entries[@]}"; do
    if (( count >= limit )); then
        break
    fi
    format_entry "$dir"
    ((count += 1))
done

printf '\n%d of %d entries shown.\n' "$count" "${#entries[@]}"
