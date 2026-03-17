#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"
AGENT_LIB="$SCRIPT_DIR/lib/agent.sh"
PROFILE_LIB="$SCRIPT_DIR/lib/profile.sh"
CLI_LIB="$SCRIPT_DIR/lib/cli.sh"
CONFIG_LIB="$SCRIPT_DIR/lib/config.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"
source "$CLI_LIB"
source "$CONFIG_LIB"

evop_init_common_context
VERIFY_STEPS=""
CONTINUE_ON_ERROR=0
LIST_ONLY=0

evop_parse_verify_steps() {
    local raw="${1:-}"
    local normalized=""
    local item=""

    if [[ -z "$raw" ]]; then
        while IFS= read -r item; do
            [[ -n "$normalized" ]] && normalized+=$'\n'
            normalized+="$item"
        done < <(evop_project_verification_slots)
        printf '%s' "$normalized"
        return 0
    fi

    raw="${raw//,/ }"
    for item in $raw; do
        case "$item" in
            lint|typecheck|test|build)
                if [[ "$normalized" != *"$item"* ]]; then
                    [[ -n "$normalized" ]] && normalized+=$'\n'
                    normalized+="$item"
                fi
                ;;
            *)
                evop_fail "Unsupported verify step: $item"
                ;;
        esac
    done

    printf '%s' "$normalized"
}

evop_run_verify_step() {
    local slot="$1"
    local command="$2"
    local verify_dir="$3"
    local log_file="$verify_dir/$slot.log"
    local status=0

    evop_log_info "Running $slot: $command"
    if [[ "$DRY_RUN" == "1" ]]; then
        return 0
    fi

    mkdir -p "$verify_dir"
    set +e
    (
        cd "$TARGET_DIR"
        bash -lc "$command"
    ) 2>&1 | tee "$log_file"
    status="${PIPESTATUS[0]}"
    set -e
    return "$status"
}

usage() {
    cat <<'EOF'
Usage: ./VERIFY.sh [options]

Run the detected repository verification chain (lint -> typecheck -> test -> build)
using the commands inferred from the target repository.

Options:
  -g, --agent NAME         Agent profile context to use. Default: codex.
      --language NAME      Language profile. Auto-detected when omitted.
      --framework NAME     Framework profile. Auto-detected when omitted.
      --project-type NAME  Project-type profile. Auto-detected when omitted.
  -p, --prompt TEXT        Optional prompt signal used for task-kind inference.
  -f, --prompt-file FILE   Read the optional prompt signal from a file.
  -t, --target-dir DIR     Repository directory to verify.
  -o, --artifacts-dir DIR  Root directory used to store verification logs.
      --steps CSV          Comma-separated subset of: lint,typecheck,test,build.
      --list               Print the detected verification commands and exit.
  -c, --continue-on-error  Keep going after a failed verification step.
      --dry-run            Print the selected commands without running them.
  -h, --help               Show this help text.
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --steps)
            evop_require_option_value "$1" "$#"
            VERIFY_STEPS="$2"
            shift 2
            ;;
        --list)
            LIST_ONLY=1
            shift
            ;;
        -c|--continue-on-error)
            CONTINUE_ON_ERROR=1
            shift
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
            echo "Unexpected argument: $1" >&2
            exit 1
            ;;
    esac
done

if (($# > 0)); then
    echo "Unexpected extra arguments: $*" >&2
    exit 1
fi

evop_finalize_analysis_context

selected_steps="$(evop_parse_verify_steps "$VERIFY_STEPS")"

if (( LIST_ONLY == 1 )); then
    printf 'Target directory: %s\n' "$TARGET_DIR"
    while IFS= read -r slot; do
        [[ -n "$slot" ]] || continue
        command="$(evop_get_project_command "$slot")"
        [[ -n "$command" ]] || continue
        printf '%s: %s\n' "$slot" "$command"
    done <<<"$selected_steps"
    exit 0
fi

if [[ "$DRY_RUN" == "1" ]]; then
    printf 'Target directory: %s\n' "$TARGET_DIR"
fi

verify_dir="$(evop_prepare_unique_dir "$artifacts_root" "verify")"
ran_any=0
final_status=0

while IFS= read -r slot; do
    [[ -n "$slot" ]] || continue
    command="$(evop_get_project_command "$slot")"
    if [[ -z "$command" ]]; then
        evop_log_info "Skipping $slot: no command detected."
        continue
    fi

    ran_any=1
    if evop_run_verify_step "$slot" "$command" "$verify_dir"; then
        :
    else
        final_status=$?
        evop_print_stderr "Verification step '$slot' failed with exit code $final_status."
        if (( CONTINUE_ON_ERROR == 0 )); then
            exit "$final_status"
        fi
    fi
done <<<"$selected_steps"

if (( ran_any == 0 )); then
    evop_fail "No runnable verification commands were detected for the selected steps."
fi

if [[ "$DRY_RUN" != "1" ]]; then
    evop_log_info "Verification logs: $verify_dir"
fi

exit "$final_status"
