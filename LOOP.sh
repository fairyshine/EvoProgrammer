#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$LIB_DIR/common.sh"

# Shared helpers keep validation and command preview logic consistent.
source "$COMMON_LIB"

PROMPT="${EVOPROGRAMMER_PROMPT:-}"
PROMPT_FILE="${EVOPROGRAMMER_PROMPT_FILE:-}"
TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"
DRY_RUN=0
declare -a CODEX_ARGS=()

usage() {
    cat <<'EOF'
Usage: ./LOOP.sh [options] [prompt]

Runs a single Codex iteration against the target directory.

Options:
  -p, --prompt TEXT         Prompt to pass to Codex.
  -f, --prompt-file FILE    Read the prompt from a file.
  -t, --target-dir DIR      Repository directory to run in.
  -a, --codex-arg ARG       Extra argument to pass to 'codex exec'. Repeat as needed.
      --dry-run             Print the command instead of running it.
  -h, --help                Show this help text.

Environment variables:
  EVOPROGRAMMER_PROMPT       Prompt to pass to Codex.
  EVOPROGRAMMER_PROMPT_FILE  Read the prompt from a file.
  EVOPROGRAMMER_TARGET_DIR   Repository directory to run in. Default: current directory.
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -p|--prompt)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                exit 1
            fi
            PROMPT="$2"
            PROMPT_FILE=""
            shift 2
            ;;
        -f|--prompt-file)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                exit 1
            fi
            PROMPT_FILE="$2"
            PROMPT=""
            shift 2
            ;;
        -t|--target-dir)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                exit 1
            fi
            TARGET_DIR="$2"
            shift 2
            ;;
        -a|--codex-arg)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                exit 1
            fi
            CODEX_ARGS+=("$2")
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
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
            break
            ;;
    esac
done

if (($# > 0)); then
    PROMPT="$1"
    PROMPT_FILE=""
    shift
fi

if (($# > 0)); then
    echo "Unexpected extra arguments: $*" >&2
    exit 1
fi

if [[ -z "$PROMPT" && -z "$PROMPT_FILE" ]]; then
    PROMPT="$EVOPROGRAMMER_DEFAULT_PROMPT"
fi

resolved_prompt="$(evop_resolve_prompt "$PROMPT" "$PROMPT_FILE")"
evop_require_directory "$TARGET_DIR"

codex_cmd=(codex exec)
if ((${#CODEX_ARGS[@]} > 0)); then
    codex_cmd+=("${CODEX_ARGS[@]}")
fi
codex_cmd+=("$resolved_prompt")

if [[ "$DRY_RUN" == "1" ]]; then
    evop_print_command_preview "$TARGET_DIR" "${codex_cmd[@]}"
    exit 0
fi

evop_require_command "codex"

cd "$TARGET_DIR"
"${codex_cmd[@]}"
