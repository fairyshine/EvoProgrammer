#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$LIB_DIR/common.sh"
RUNTIME_LIB="$LIB_DIR/runtime.sh"
AGENT_LIB="$LIB_DIR/agent.sh"
PROFILE_LIB="$LIB_DIR/profile.sh"

# Shared helpers keep validation and command preview logic consistent.
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
DRY_RUN=0
declare -a AGENT_ARGS=()

write_run_metadata() {
    local path="$1"
    local status="$2"
    local started_at="$3"
    local finished_at="$4"
    local prompt_source="$5"
    local artifacts_root="$6"
    local run_dir="$7"
    local output_file="$8"

    cat >"$path" <<EOF
MODE=single
AGENT=$(printf '%q' "$AGENT")
LANGUAGE_PROFILE=$(printf '%q' "$LANGUAGE_PROFILE")
LANGUAGE_PROFILE_SOURCE=$(printf '%q' "$LANGUAGE_PROFILE_SOURCE")
PROJECT_TYPE=$(printf '%q' "$PROJECT_TYPE")
PROJECT_TYPE_SOURCE=$(printf '%q' "$PROJECT_TYPE_SOURCE")
TARGET_DIR=$(printf '%q' "$TARGET_DIR")
ARTIFACTS_ROOT=$(printf '%q' "$artifacts_root")
RUN_DIR=$(printf '%q' "$run_dir")
PROMPT_SOURCE=$(printf '%q' "$prompt_source")
STARTED_AT=$(printf '%q' "$started_at")
FINISHED_AT=$(printf '%q' "$finished_at")
STATUS=$(printf '%q' "$status")
OUTPUT_FILE=$(printf '%q' "$output_file")
EOF
}

usage() {
    cat <<'EOF'
Usage: ./LOOP.sh [options] [prompt]

Runs a single coding-agent iteration against the target directory.

Options:
  -g, --agent NAME          Agent to run: codex or claude.
      --language NAME       Language adaptation profile. Auto-detected when omitted.
      --project-type NAME   Project-type adaptation profile. Auto-detected when omitted.
  -p, --prompt TEXT         Prompt to pass to the selected agent.
  -f, --prompt-file FILE    Read the prompt from a file.
  -t, --target-dir DIR      Repository directory to run in.
  -o, --artifacts-dir DIR   Root directory used to store run artifacts.
      --agent-args JSON     JSON-like string list of extra agent arguments.
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
  EVOPROGRAMMER_AGENT        Agent to run. Default: codex
  EVOPROGRAMMER_AGENT_ARGS   JSON-like string list of extra agent arguments
  EVOPROGRAMMER_LANGUAGE_PROFILE
                           Language adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_PROJECT_TYPE
                           Project-type adaptation profile. Auto-detected when omitted.
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
        --agent-args)
            evop_require_option_value "$1" "$#"
            AGENT_ARGS_LIST="$2"
            shift 2
            ;;
        -a|--agent-arg|--codex-arg)
            evop_require_option_value "$1" "$#"
            AGENT_ARGS+=("$2")
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
evop_require_directory "$TARGET_DIR"
target_dir_abs="$(evop_resolve_physical_dir "$TARGET_DIR")"
evop_resolve_profiles "$target_dir_abs" "$resolved_prompt" "$LANGUAGE_PROFILE" "$PROJECT_TYPE"
LANGUAGE_PROFILE="$EVOP_RESOLVED_LANGUAGE_PROFILE"
LANGUAGE_PROFILE_SOURCE="$EVOP_RESOLVED_LANGUAGE_SOURCE"
PROJECT_TYPE="$EVOP_RESOLVED_PROJECT_TYPE"
PROJECT_TYPE_SOURCE="$EVOP_RESOLVED_PROJECT_SOURCE"
artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"
agent_display_name="$(evop_agent_display_name "$AGENT")"
agent_command_name="$(evop_agent_command_name "$AGENT")"
final_prompt="$(evop_compose_prompt "$resolved_prompt" "$LANGUAGE_PROFILE" "$PROJECT_TYPE")"

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
    printf 'Artifacts root: %s\n' "$artifacts_root"
    evop_print_command_preview "$TARGET_DIR" "${agent_cmd[@]}"
    exit 0
fi

evop_require_command "$agent_command_name"
evop_maybe_exclude_artifacts_dir "$TARGET_DIR" "$artifacts_root"

if [[ -n "$PROMPT_FILE" ]]; then
    prompt_source="file:$PROMPT_FILE"
else
    prompt_source="inline"
fi

run_dir="$(evop_prepare_unique_dir "$artifacts_root" "run")"
output_file="$run_dir/${AGENT}.log"
metadata_file="$run_dir/metadata.env"
command_file="$run_dir/command.txt"
prompt_file_path="$run_dir/prompt.txt"
started_at="$(evop_timestamp_utc)"

printf '%s' "$final_prompt" >"$prompt_file_path"
evop_write_command_file "$command_file" "${agent_cmd[@]}"
write_run_metadata "$metadata_file" "running" "$started_at" "" "$prompt_source" "$artifacts_root" "$run_dir" "$output_file"

printf 'Agent: %s\n' "$agent_display_name"
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
printf 'Artifacts directory: %s\n' "$run_dir"

if evop_run_and_capture "$TARGET_DIR" "$output_file" "${agent_cmd[@]}"; then
    status=0
else
    status=$?
fi

finished_at="$(evop_timestamp_utc)"
write_run_metadata "$metadata_file" "$status" "$started_at" "$finished_at" "$prompt_source" "$artifacts_root" "$run_dir" "$output_file"

exit "$status"
