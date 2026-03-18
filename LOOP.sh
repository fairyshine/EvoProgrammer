#!/bin/sh
# shellcheck shell=bash

. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
EVOP_LIB_DIR="$LIB_DIR"
COMMON_LIB="$LIB_DIR/common.sh"
RUNTIME_LIB="$LIB_DIR/runtime.sh"
AGENT_LIB="$LIB_DIR/agent.sh"
PROFILE_LIB="$LIB_DIR/profile.sh"
CLI_LIB="$LIB_DIR/cli.sh"
METADATA_LIB="$LIB_DIR/metadata.sh"
CONFIG_LIB="$LIB_DIR/config.sh"
HOOKS_LIB="$LIB_DIR/hooks.sh"
GIT_LIB="$LIB_DIR/git.sh"

# Shared helpers keep validation and command preview logic consistent.
source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"
source "$CLI_LIB"
source "$METADATA_LIB"
source "$CONFIG_LIB"
source "$HOOKS_LIB"
source "$GIT_LIB"

evop_init_common_context
declare -a AGENT_ARGS=()

write_run_metadata() {
    local metadata_path="$1"
    local run_status="$2"
    local started_at="$3"
    local finished_at="$4"
    local prompt_source="$5"
    local artifacts_root="$6"
    local run_dir="$7"
    local output_file="$8"

    evop_build_common_metadata_args "$prompt_source" "$artifacts_root"
    evop_write_env_file "$metadata_path" \
        MODE "single" \
        "${EVOP_COMMON_METADATA_ARGS[@]}" \
        RUN_DIR "$run_dir" \
        STARTED_AT "$started_at" \
        FINISHED_AT "$finished_at" \
        STATUS "$run_status" \
        OUTPUT_FILE "$output_file"
}

usage() {
    cat <<'EOF'
Usage: ./LOOP.sh [options] [prompt]

Runs a single coding-agent iteration against the target directory.

Options:
  -g, --agent NAME          Agent to run: codex or claude.
      --language NAME       Language adaptation profile. Auto-detected when omitted.
      --framework NAME      Framework adaptation profile. Auto-detected when omitted.
      --project-type NAME   Project-type adaptation profile. Auto-detected when omitted.
  -p, --prompt TEXT         Prompt to pass to the selected agent.
  -f, --prompt-file FILE    Read the prompt from a file.
  -t, --target-dir DIR      Repository directory to run in.
  -o, --artifacts-dir DIR   Root directory used to store run artifacts.
      --context-file FILE   Reuse an `inspect --format env` context snapshot.
      --agent-args JSON     JSON-like string list of extra agent arguments.
      --auto-commit         Commit this iteration's new git changes after a successful run.
      --auto-commit-message TEXT
                            Override the auto-commit message for this iteration.
  -a, --agent-arg ARG       Extra argument to pass to the agent CLI. Repeat as needed.
      --codex-arg ARG       Backward-compatible alias for --agent-arg.
      --dry-run             Print the command instead of running it.
  -h, --help                Show this help text.

Environment variables:
  EVOPROGRAMMER_PROMPT       Prompt to pass to the selected agent.
  EVOPROGRAMMER_PROMPT_FILE  Read the prompt from a file.
  EVOPROGRAMMER_TARGET_DIR   Repository directory to run in. Default: current directory.
  EVOPROGRAMMER_ARTIFACTS_DIR
                           Root directory used to store run artifacts.
                           Default: TARGET_DIR/.evoprogrammer/runs
  EVOPROGRAMMER_CONTEXT_FILE
                           Reuse an `inspect --format env` context snapshot.
  EVOPROGRAMMER_AGENT        Agent to run. Default: codex
  EVOPROGRAMMER_AGENT_ARGS   JSON-like string list of extra agent arguments
  EVOPROGRAMMER_LANGUAGE_PROFILE
                           Language adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_FRAMEWORK_PROFILE
                           Framework adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_PROJECT_TYPE
                           Project-type adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_AUTO_COMMIT
                           1 commits new iteration changes after success. Default: 0.
  EVOPROGRAMMER_AUTO_COMMIT_MESSAGE
                           Override the auto-commit message for this iteration.
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -a|--agent-arg|--codex-arg)
            evop_require_option_value "$1" "$#"
            AGENT_ARGS+=("$2")
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
evop_validate_zero_or_one "EVOPROGRAMMER_AUTO_COMMIT" "$AUTO_COMMIT"
agent_display_name="$(evop_agent_display_name "$AGENT")"
agent_command_name="$(evop_agent_command_name "$AGENT")"
final_prompt="$(evop_compose_prompt "$resolved_prompt" "$LANGUAGE_PROFILE" "$FRAMEWORK_PROFILE" "$PROJECT_TYPE")"

if [[ -n "$AGENT_ARGS_LIST" ]]; then
    evop_parse_string_list "$AGENT_ARGS_LIST"
    if ((${#EVOP_PARSED_LIST[@]} > 0)); then
        AGENT_ARGS+=("${EVOP_PARSED_LIST[@]}")
    fi
fi

if ((${#AGENT_ARGS[@]} > 0)); then
    evop_build_agent_command "$AGENT" "$target_dir_abs" "$final_prompt" "${AGENT_ARGS[@]}"
else
    evop_build_agent_command "$AGENT" "$target_dir_abs" "$final_prompt"
fi
agent_cmd=("${EVOP_AGENT_COMMAND[@]}")

if [[ "$DRY_RUN" == "1" ]]; then
    evop_print_key_value "Agent:" "$AGENT"
    evop_print_current_profiles
    evop_print_key_value "Artifacts root:" "$artifacts_root"
    evop_print_key_value "Auto commit:" "$AUTO_COMMIT"
    if [[ -n "$AUTO_COMMIT_MESSAGE" ]]; then
        evop_print_key_value "Auto commit message:" "$AUTO_COMMIT_MESSAGE"
    fi
    evop_print_command_preview "$TARGET_DIR" "${agent_cmd[@]}"
    exit 0
fi

evop_require_command "$agent_command_name"
evop_maybe_exclude_artifacts_dir "$TARGET_DIR" "$artifacts_root"
prompt_source="$(evop_prompt_source_label "$PROMPT_FILE")"

run_dir="$(evop_prepare_unique_dir "$artifacts_root" "run")"
output_file="$run_dir/${AGENT}.log"
metadata_file="$run_dir/metadata.env"
command_file="$run_dir/command.txt"
prompt_file_path="$run_dir/prompt.txt"
started_at="$(evop_timestamp_utc)"

printf '%s' "$final_prompt" >"$prompt_file_path"
evop_write_command_file "$command_file" "${agent_cmd[@]}"
write_run_metadata "$metadata_file" "running" "$started_at" "" "$prompt_source" "$artifacts_root" "$run_dir" "$output_file"

evop_log_event "info" "Agent: $agent_display_name"
evop_print_current_profiles
evop_log_event "info" "Artifacts directory: $run_dir"

if [[ "$AUTO_COMMIT" == "1" ]]; then
    evop_git_snapshot_iteration_baseline "$TARGET_DIR" || true
fi

evop_run_hook "$TARGET_DIR" "pre-iteration"

if evop_run_and_capture "$TARGET_DIR" "$output_file" "${agent_cmd[@]}"; then
    run_status=0
else
    run_status=$?
fi

evop_run_hook "$TARGET_DIR" "post-iteration"

finished_at="$(evop_timestamp_utc)"

if [[ "$run_status" == "0" && "$AUTO_COMMIT" == "1" ]]; then
    if evop_git_auto_commit_iteration "$TARGET_DIR" "$AUTO_COMMIT_MESSAGE" "$resolved_prompt"; then
        :
    else
        run_status=$?
    fi
fi

write_run_metadata "$metadata_file" "$run_status" "$started_at" "$finished_at" "$prompt_source" "$artifacts_root" "$run_dir" "$output_file"

exit "$run_status"
