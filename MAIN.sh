#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOOP_SCRIPT="$SCRIPT_DIR/LOOP.sh"
LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$LIB_DIR/common.sh"

source "$COMMON_LIB"

PROMPT="${EVOPROGRAMMER_PROMPT:-}"
PROMPT_FILE="${EVOPROGRAMMER_PROMPT_FILE:-}"
TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"
MAX_ITERATIONS="${EVOPROGRAMMER_MAX_ITERATIONS:-0}"
DELAY_SECONDS="${EVOPROGRAMMER_DELAY_SECONDS:-0}"
CONTINUE_ON_ERROR="${EVOPROGRAMMER_CONTINUE_ON_ERROR:-0}"
DRY_RUN=0
declare -a LOOP_ARGS=()

usage() {
    cat <<'EOF'
Usage: ./MAIN.sh [options] [prompt]

Runs Codex repeatedly against this repository.

Options:
  -p, --prompt TEXT           Prompt to pass to Codex.
  -f, --prompt-file FILE      Read the prompt from a file before each iteration.
  -t, --target-dir DIR        Repository directory to run in.
  -n, --max-iterations NUM    0 means run forever.
  -d, --delay-seconds NUM     Delay between runs.
  -c, --continue-on-error     Keep looping after a failed run.
  -a, --codex-arg ARG         Extra argument to pass to 'codex exec'. Repeat as needed.
      --dry-run               Print the next iteration command and exit.
  -h, --help                  Show this help text.

Environment variables:
    EVOPROGRAMMER_PROMPT             Prompt to pass to Codex.
    EVOPROGRAMMER_PROMPT_FILE        Read the prompt from a file before each iteration.
    EVOPROGRAMMER_TARGET_DIR         Repository directory to run in. Default: current directory.
    EVOPROGRAMMER_MAX_ITERATIONS     0 means run forever. Default: 0.
    EVOPROGRAMMER_DELAY_SECONDS      Delay between runs. Default: 0.
  EVOPROGRAMMER_CONTINUE_ON_ERROR  1 keeps looping after a failed run. Default: 0.
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
        -n|--max-iterations)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                exit 1
            fi
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        -d|--delay-seconds)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                exit 1
            fi
            DELAY_SECONDS="$2"
            shift 2
            ;;
        -c|--continue-on-error)
            CONTINUE_ON_ERROR=1
            shift
            ;;
        -a|--codex-arg)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                exit 1
            fi
            LOOP_ARGS+=(--codex-arg "$2")
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
evop_validate_non_negative_integer "EVOPROGRAMMER_MAX_ITERATIONS" "$MAX_ITERATIONS"
evop_validate_non_negative_integer "EVOPROGRAMMER_DELAY_SECONDS" "$DELAY_SECONDS"
evop_validate_zero_or_one "EVOPROGRAMMER_CONTINUE_ON_ERROR" "$CONTINUE_ON_ERROR"
evop_require_executable_file "$LOOP_SCRIPT" "Loop script"
evop_require_directory "$TARGET_DIR"

if [[ "$DRY_RUN" == "1" ]]; then
    printf 'Max iterations: %s\n' "$MAX_ITERATIONS"
    printf 'Delay seconds: %s\n' "$DELAY_SECONDS"
    printf 'Continue on error: %s\n' "$CONTINUE_ON_ERROR"
    loop_cmd=("$LOOP_SCRIPT")
    if [[ -n "$PROMPT_FILE" ]]; then
        loop_cmd+=(--prompt-file "$PROMPT_FILE")
    else
        loop_cmd+=(--prompt "$resolved_prompt")
    fi
    if ((${#LOOP_ARGS[@]} > 0)); then
        loop_cmd+=("${LOOP_ARGS[@]}")
    fi
    evop_print_command_preview "$TARGET_DIR" "${loop_cmd[@]}"
    exit 0
fi

stop_requested=0

handle_stop() {
    stop_requested=1
}

trap handle_stop INT TERM

iteration=1
while (( MAX_ITERATIONS == 0 || iteration <= MAX_ITERATIONS )); do
    if (( stop_requested == 1 )); then
        echo "Stop requested. Exiting before iteration $iteration."
        exit 0
    fi

    if [[ -n "$PROMPT_FILE" ]]; then
        echo "Starting iteration $iteration with prompt file: $PROMPT_FILE"
        loop_cmd=("$LOOP_SCRIPT" --prompt-file "$PROMPT_FILE")
    else
        echo "Starting iteration $iteration with prompt: $resolved_prompt"
        loop_cmd=("$LOOP_SCRIPT" --prompt "$resolved_prompt")
    fi
    if ((${#LOOP_ARGS[@]} > 0)); then
        loop_cmd+=("${LOOP_ARGS[@]}")
    fi

    if EVOPROGRAMMER_TARGET_DIR="$TARGET_DIR" "${loop_cmd[@]}"; then
        :
    else
        status=$?
        echo "Iteration $iteration failed with exit code $status." >&2

        if [[ "$CONTINUE_ON_ERROR" != "1" ]]; then
            exit "$status"
        fi
    fi

    ((iteration++))

    if (( DELAY_SECONDS > 0 )) && (( MAX_ITERATIONS == 0 || iteration <= MAX_ITERATIONS )); then
        sleep "$DELAY_SECONDS"
    fi
done
