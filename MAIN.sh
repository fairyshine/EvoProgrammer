#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOOP_SCRIPT="$SCRIPT_DIR/LOOP.sh"
LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$LIB_DIR/common.sh"
RUNTIME_LIB="$LIB_DIR/runtime.sh"
AGENT_LIB="$LIB_DIR/agent.sh"
PROFILE_LIB="$LIB_DIR/profile.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"

PROMPT="${EVOPROGRAMMER_PROMPT:-}"
PROMPT_FILE="${EVOPROGRAMMER_PROMPT_FILE:-}"
TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"
ARTIFACTS_DIR="${EVOPROGRAMMER_ARTIFACTS_DIR:-}"
AGENT="${EVOPROGRAMMER_AGENT:-$EVOPROGRAMMER_DEFAULT_AGENT}"
AGENT_ARGS_LIST="${EVOPROGRAMMER_AGENT_ARGS:-}"
LANGUAGE_PROFILE="${EVOPROGRAMMER_LANGUAGE_PROFILE:-}"
PROJECT_TYPE="${EVOPROGRAMMER_PROJECT_TYPE:-}"
LANGUAGE_PROFILE_SOURCE="none"
PROJECT_TYPE_SOURCE="none"
MAX_ITERATIONS="${EVOPROGRAMMER_MAX_ITERATIONS:-0}"
DELAY_SECONDS="${EVOPROGRAMMER_DELAY_SECONDS:-0}"
CONTINUE_ON_ERROR="${EVOPROGRAMMER_CONTINUE_ON_ERROR:-0}"
DRY_RUN=0
declare -a LOOP_ARGS=()

write_session_metadata() {
    local path="$1"
    local state="$2"
    local started_at="$3"
    local finished_at="$4"
    local prompt_source="$5"
    local artifacts_root="$6"
    local session_dir="$7"
    local last_iteration="$8"
    local final_status="$9"

    cat >"$path" <<EOF
MODE=loop
AGENT=$(printf '%q' "$AGENT")
LANGUAGE_PROFILE=$(printf '%q' "$LANGUAGE_PROFILE")
LANGUAGE_PROFILE_SOURCE=$(printf '%q' "$LANGUAGE_PROFILE_SOURCE")
PROJECT_TYPE=$(printf '%q' "$PROJECT_TYPE")
PROJECT_TYPE_SOURCE=$(printf '%q' "$PROJECT_TYPE_SOURCE")
TARGET_DIR=$(printf '%q' "$TARGET_DIR")
ARTIFACTS_ROOT=$(printf '%q' "$artifacts_root")
SESSION_DIR=$(printf '%q' "$session_dir")
PROMPT_SOURCE=$(printf '%q' "$prompt_source")
MAX_ITERATIONS=$(printf '%q' "$MAX_ITERATIONS")
DELAY_SECONDS=$(printf '%q' "$DELAY_SECONDS")
CONTINUE_ON_ERROR=$(printf '%q' "$CONTINUE_ON_ERROR")
STARTED_AT=$(printf '%q' "$started_at")
FINISHED_AT=$(printf '%q' "$finished_at")
STATE=$(printf '%q' "$state")
LAST_ITERATION=$(printf '%q' "$last_iteration")
FINAL_STATUS=$(printf '%q' "$final_status")
EOF
}

usage() {
    cat <<'EOF'
Usage: ./MAIN.sh [options] [prompt]

Runs the selected coding agent repeatedly against this repository.

Options:
  -g, --agent NAME            Agent to run: codex or claude.
      --language NAME         Language adaptation profile. Auto-detected when omitted.
      --project-type NAME     Project-type adaptation profile. Auto-detected when omitted.
  -p, --prompt TEXT           Prompt to pass to the selected agent.
  -f, --prompt-file FILE      Read the prompt from a file before each iteration.
  -t, --target-dir DIR        Repository directory to run in.
  -o, --artifacts-dir DIR     Root directory used to store session artifacts.
  -n, --max-iterations NUM    0 means run forever.
  -d, --delay-seconds NUM     Delay between runs.
  -c, --continue-on-error     Keep looping after a failed run.
      --agent-args JSON       JSON-like string list of extra agent arguments.
  -a, --agent-arg ARG         Extra argument to pass to the agent CLI. Repeat as needed.
      --codex-arg ARG         Backward-compatible alias for --agent-arg.
      --dry-run               Print the next iteration command and exit.
  -h, --help                  Show this help text.

Environment variables:
    EVOPROGRAMMER_PROMPT             Prompt to pass to the selected agent.
    EVOPROGRAMMER_PROMPT_FILE        Read the prompt from a file before each iteration.
    EVOPROGRAMMER_AGENT              Agent to run. Default: codex
    EVOPROGRAMMER_AGENT_ARGS         JSON-like string list of extra agent arguments
    EVOPROGRAMMER_LANGUAGE_PROFILE   Language adaptation profile. Auto-detected when omitted.
    EVOPROGRAMMER_PROJECT_TYPE       Project-type adaptation profile. Auto-detected when omitted.
    EVOPROGRAMMER_TARGET_DIR         Repository directory to run in. Default: current directory.
    EVOPROGRAMMER_ARTIFACTS_DIR      Root directory used to store session artifacts.
                                     Default: TARGET_DIR/.evoprogrammer/runs
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
            evop_require_option_value "$1" "$#"
            PROMPT="$2"
            PROMPT_FILE=""
            shift 2
            ;;
        -f|--prompt-file)
            evop_require_option_value "$1" "$#"
            PROMPT_FILE="$2"
            PROMPT=""
            shift 2
            ;;
        -g|--agent)
            evop_require_option_value "$1" "$#"
            AGENT="$2"
            shift 2
            ;;
        --language)
            evop_require_option_value "$1" "$#"
            LANGUAGE_PROFILE="$2"
            shift 2
            ;;
        --project-type)
            evop_require_option_value "$1" "$#"
            PROJECT_TYPE="$2"
            shift 2
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
        -n|--max-iterations)
            evop_require_option_value "$1" "$#"
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        -d|--delay-seconds)
            evop_require_option_value "$1" "$#"
            DELAY_SECONDS="$2"
            shift 2
            ;;
        -c|--continue-on-error)
            CONTINUE_ON_ERROR=1
            shift
            ;;
        --agent-args)
            evop_require_option_value "$1" "$#"
            AGENT_ARGS_LIST="$2"
            shift 2
            ;;
        -a|--agent-arg|--codex-arg)
            evop_require_option_value "$1" "$#"
            LOOP_ARGS+=(--agent-arg "$2")
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
evop_validate_agent "$AGENT"
evop_validate_language_profile "$LANGUAGE_PROFILE"
evop_validate_project_type "$PROJECT_TYPE"
evop_validate_non_negative_integer "EVOPROGRAMMER_MAX_ITERATIONS" "$MAX_ITERATIONS"
evop_validate_non_negative_integer "EVOPROGRAMMER_DELAY_SECONDS" "$DELAY_SECONDS"
evop_validate_zero_or_one "EVOPROGRAMMER_CONTINUE_ON_ERROR" "$CONTINUE_ON_ERROR"
evop_require_executable_file "$LOOP_SCRIPT" "Loop script"
evop_require_directory "$TARGET_DIR"
target_dir_abs="$(evop_resolve_physical_dir "$TARGET_DIR")"
evop_resolve_profiles "$target_dir_abs" "$resolved_prompt" "$LANGUAGE_PROFILE" "$PROJECT_TYPE"
LANGUAGE_PROFILE="$EVOP_RESOLVED_LANGUAGE_PROFILE"
LANGUAGE_PROFILE_SOURCE="$EVOP_RESOLVED_LANGUAGE_SOURCE"
PROJECT_TYPE="$EVOP_RESOLVED_PROJECT_TYPE"
PROJECT_TYPE_SOURCE="$EVOP_RESOLVED_PROJECT_SOURCE"
artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"

if [[ "$DRY_RUN" == "1" ]]; then
    printf 'Agent: %s\n' "$AGENT"
    if [[ -n "$LANGUAGE_PROFILE" ]]; then
        printf 'Language profile: %s' "$LANGUAGE_PROFILE"
        if [[ "$LANGUAGE_PROFILE_SOURCE" == "auto" ]]; then
            printf ' (auto-detected)'
        fi
        printf '\n'
    fi
    if [[ -n "$PROJECT_TYPE" ]]; then
        printf 'Project type: %s' "$PROJECT_TYPE"
        if [[ "$PROJECT_TYPE_SOURCE" == "auto" ]]; then
            printf ' (auto-detected)'
        fi
        printf '\n'
    fi
    printf 'Max iterations: %s\n' "$MAX_ITERATIONS"
    printf 'Delay seconds: %s\n' "$DELAY_SECONDS"
    printf 'Continue on error: %s\n' "$CONTINUE_ON_ERROR"
    printf 'Artifacts root: %s\n' "$artifacts_root"
    loop_cmd=("$LOOP_SCRIPT" --agent "$AGENT")
    if [[ -n "$LANGUAGE_PROFILE" ]]; then
        loop_cmd+=(--language "$LANGUAGE_PROFILE")
    fi
    if [[ -n "$PROJECT_TYPE" ]]; then
        loop_cmd+=(--project-type "$PROJECT_TYPE")
    fi
    if [[ -n "$PROMPT_FILE" ]]; then
        loop_cmd+=(--prompt-file "$PROMPT_FILE")
    else
        loop_cmd+=(--prompt "$resolved_prompt")
    fi
    loop_cmd+=(--artifacts-dir "$artifacts_root")
    if [[ -n "$AGENT_ARGS_LIST" ]]; then
        loop_cmd+=(--agent-args "$AGENT_ARGS_LIST")
    fi
    if ((${#LOOP_ARGS[@]} > 0)); then
        loop_cmd+=("${LOOP_ARGS[@]}")
    fi
    evop_print_command_preview "$TARGET_DIR" "${loop_cmd[@]}"
    exit 0
fi

stop_requested=0
evop_maybe_exclude_artifacts_dir "$TARGET_DIR" "$artifacts_root"

handle_stop() {
    stop_requested=1
}

trap handle_stop INT TERM

if [[ -n "$PROMPT_FILE" ]]; then
    prompt_source="file:$PROMPT_FILE"
else
    prompt_source="inline"
fi

session_dir="$(evop_prepare_unique_dir "$artifacts_root" "session")"
session_metadata="$session_dir/session.env"
mkdir -p "$session_dir/iterations"
started_at="$(evop_timestamp_utc)"
write_session_metadata "$session_metadata" "running" "$started_at" "" "$prompt_source" "$artifacts_root" "$session_dir" 0 ""

printf 'Session artifacts directory: %s\n' "$session_dir"
if [[ -n "$LANGUAGE_PROFILE" ]]; then
    printf 'Language profile: %s' "$LANGUAGE_PROFILE"
    if [[ "$LANGUAGE_PROFILE_SOURCE" == "auto" ]]; then
        printf ' (auto-detected)'
    fi
    printf '\n'
fi
if [[ -n "$PROJECT_TYPE" ]]; then
    printf 'Project type: %s' "$PROJECT_TYPE"
    if [[ "$PROJECT_TYPE_SOURCE" == "auto" ]]; then
        printf ' (auto-detected)'
    fi
    printf '\n'
fi

iteration=1
last_iteration=0
final_status=0
while (( MAX_ITERATIONS == 0 || iteration <= MAX_ITERATIONS )); do
    if (( stop_requested == 1 )); then
        finished_at="$(evop_timestamp_utc)"
        write_session_metadata "$session_metadata" "stopped" "$started_at" "$finished_at" "$prompt_source" "$artifacts_root" "$session_dir" "$last_iteration" "$final_status"
        echo "Stop requested. Exiting before iteration $iteration."
        exit 0
    fi

    if [[ -n "$PROMPT_FILE" ]]; then
        echo "Starting iteration $iteration with prompt file: $PROMPT_FILE"
        loop_cmd=("$LOOP_SCRIPT" --agent "$AGENT" --prompt-file "$PROMPT_FILE")
    else
        echo "Starting iteration $iteration with prompt: $resolved_prompt"
        loop_cmd=("$LOOP_SCRIPT" --agent "$AGENT" --prompt "$resolved_prompt")
    fi
    if [[ -n "$LANGUAGE_PROFILE" ]]; then
        loop_cmd+=(--language "$LANGUAGE_PROFILE")
    fi
    if [[ -n "$PROJECT_TYPE" ]]; then
        loop_cmd+=(--project-type "$PROJECT_TYPE")
    fi
    loop_cmd+=(--artifacts-dir "$session_dir/iterations")
    if [[ -n "$AGENT_ARGS_LIST" ]]; then
        loop_cmd+=(--agent-args "$AGENT_ARGS_LIST")
    fi
    if ((${#LOOP_ARGS[@]} > 0)); then
        loop_cmd+=("${LOOP_ARGS[@]}")
    fi

    if EVOPROGRAMMER_TARGET_DIR="$TARGET_DIR" "${loop_cmd[@]}"; then
        last_iteration="$iteration"
        final_status=0
    else
        status=$?
        last_iteration="$iteration"
        final_status="$status"
        echo "Iteration $iteration failed with exit code $status." >&2

        if [[ "$CONTINUE_ON_ERROR" != "1" ]]; then
            finished_at="$(evop_timestamp_utc)"
            write_session_metadata "$session_metadata" "failed" "$started_at" "$finished_at" "$prompt_source" "$artifacts_root" "$session_dir" "$last_iteration" "$final_status"
            exit "$status"
        fi
    fi

    ((iteration++))

    if (( DELAY_SECONDS > 0 )) && (( MAX_ITERATIONS == 0 || iteration <= MAX_ITERATIONS )); then
        sleep "$DELAY_SECONDS"
    fi
done

finished_at="$(evop_timestamp_utc)"
write_session_metadata "$session_metadata" "completed" "$started_at" "$finished_at" "$prompt_source" "$artifacts_root" "$session_dir" "$last_iteration" "$final_status"
