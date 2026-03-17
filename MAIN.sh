#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOOP_SCRIPT="$SCRIPT_DIR/LOOP.sh"
LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$LIB_DIR/common.sh"
RUNTIME_LIB="$LIB_DIR/runtime.sh"
AGENT_LIB="$LIB_DIR/agent.sh"
PROFILE_LIB="$LIB_DIR/profile.sh"
CLI_LIB="$LIB_DIR/cli.sh"
METADATA_LIB="$LIB_DIR/metadata.sh"
CONFIG_LIB="$LIB_DIR/config.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"
source "$CLI_LIB"
source "$METADATA_LIB"
source "$CONFIG_LIB"

evop_init_common_context
MAX_ITERATIONS="${EVOPROGRAMMER_MAX_ITERATIONS:-0}"
DELAY_SECONDS="${EVOPROGRAMMER_DELAY_SECONDS:-0}"
CONTINUE_ON_ERROR="${EVOPROGRAMMER_CONTINUE_ON_ERROR:-0}"
declare -a LOOP_ARGS=()

build_loop_command() {
    local artifacts_dir="$1"

    if ((${#LOOP_ARGS[@]} > 0)); then
        evop_build_loop_command "$LOOP_SCRIPT" "$AGENT" "$resolved_prompt" "$PROMPT_FILE" "$LANGUAGE_PROFILE" "$FRAMEWORK_PROFILE" "$PROJECT_TYPE" "$artifacts_dir" "$AGENT_ARGS_LIST" "${LOOP_ARGS[@]}"
    else
        evop_build_loop_command "$LOOP_SCRIPT" "$AGENT" "$resolved_prompt" "$PROMPT_FILE" "$LANGUAGE_PROFILE" "$FRAMEWORK_PROFILE" "$PROJECT_TYPE" "$artifacts_dir" "$AGENT_ARGS_LIST"
    fi

    loop_cmd=("${EVOP_LOOP_COMMAND[@]}")
}

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

    evop_build_common_metadata_args "$prompt_source" "$artifacts_root"
    evop_write_env_file "$path" \
        MODE "loop" \
        "${EVOP_COMMON_METADATA_ARGS[@]}" \
        SESSION_DIR "$session_dir" \
        MAX_ITERATIONS "$MAX_ITERATIONS" \
        DELAY_SECONDS "$DELAY_SECONDS" \
        CONTINUE_ON_ERROR "$CONTINUE_ON_ERROR" \
        STARTED_AT "$started_at" \
        FINISHED_AT "$finished_at" \
        STATE "$state" \
        LAST_ITERATION "$last_iteration" \
        FINAL_STATUS "$final_status"
}

usage() {
    cat <<'EOF'
Usage: ./MAIN.sh [options] [prompt]

Runs the selected coding agent repeatedly against this repository.

Options:
  -g, --agent NAME            Agent to run: codex or claude.
      --language NAME         Language adaptation profile. Auto-detected when omitted.
      --framework NAME        Framework adaptation profile. Auto-detected when omitted.
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
    EVOPROGRAMMER_FRAMEWORK_PROFILE  Framework adaptation profile. Auto-detected when omitted.
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
        -a|--agent-arg|--codex-arg)
            evop_require_option_value "$1" "$#"
            LOOP_ARGS+=(--agent-arg "$2")
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            evop_parse_common_option "$1" "$#" "${2-}"
            if (( EVOP_CLI_OPTION_HANDLED == 1 )); then
                shift "$EVOP_CLI_OPTION_SHIFT"
            else
                echo "Unknown option: $1" >&2
                exit 1
            fi
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

evop_finalize_common_context
evop_validate_non_negative_integer "EVOPROGRAMMER_MAX_ITERATIONS" "$MAX_ITERATIONS"
evop_validate_non_negative_integer "EVOPROGRAMMER_DELAY_SECONDS" "$DELAY_SECONDS"
evop_validate_zero_or_one "EVOPROGRAMMER_CONTINUE_ON_ERROR" "$CONTINUE_ON_ERROR"
evop_require_executable_file "$LOOP_SCRIPT" "Loop script"

if [[ "$DRY_RUN" == "1" ]]; then
    printf 'Agent: %s\n' "$AGENT"
    evop_print_current_profiles
    printf 'Max iterations: %s\n' "$MAX_ITERATIONS"
    printf 'Delay seconds: %s\n' "$DELAY_SECONDS"
    printf 'Continue on error: %s\n' "$CONTINUE_ON_ERROR"
    printf 'Artifacts root: %s\n' "$artifacts_root"
    build_loop_command "$artifacts_root"
    evop_print_command_preview "$TARGET_DIR" "${loop_cmd[@]}"
    exit 0
fi

stop_requested=0
evop_maybe_exclude_artifacts_dir "$TARGET_DIR" "$artifacts_root"

handle_stop() {
    stop_requested=1
}

trap handle_stop INT TERM
prompt_source="$(evop_prompt_source_label "$PROMPT_FILE")"

session_dir="$(evop_prepare_unique_dir "$artifacts_root" "session")"
session_metadata="$session_dir/session.env"
mkdir -p "$session_dir/iterations"
started_at="$(evop_timestamp_utc)"
write_session_metadata "$session_metadata" "running" "$started_at" "" "$prompt_source" "$artifacts_root" "$session_dir" 0 ""

evop_log_info "Session artifacts directory: $session_dir"
evop_print_current_profiles

iteration=1
last_iteration=0
final_status=0
while (( MAX_ITERATIONS == 0 || iteration <= MAX_ITERATIONS )); do
    if (( stop_requested == 1 )); then
        finished_at="$(evop_timestamp_utc)"
        write_session_metadata "$session_metadata" "stopped" "$started_at" "$finished_at" "$prompt_source" "$artifacts_root" "$session_dir" "$last_iteration" "$final_status"
        evop_log_info "Stop requested. Exiting before iteration $iteration."
        exit 0
    fi

    if [[ -n "$PROMPT_FILE" ]]; then
        evop_log_info "Starting iteration $iteration with prompt file: $PROMPT_FILE"
    else
        evop_log_info "Starting iteration $iteration with prompt: $resolved_prompt"
    fi
    build_loop_command "$session_dir/iterations"

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
