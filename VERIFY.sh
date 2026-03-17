#!/bin/sh
# shellcheck shell=bash disable=SC1090,SC2034,SC2154

. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/lib/bootstrap.sh"
evop_exec_with_preferred_shell "$0" "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"
EVOP_LIB_DIR="$SCRIPT_DIR/lib"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"
AGENT_LIB="$SCRIPT_DIR/lib/agent.sh"
PROFILE_LIB="$SCRIPT_DIR/lib/profile.sh"
CLI_LIB="$SCRIPT_DIR/lib/cli.sh"
CONFIG_LIB="$SCRIPT_DIR/lib/config.sh"
VERIFY_LIB="$SCRIPT_DIR/lib/verify.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"
source "$CLI_LIB"
source "$CONFIG_LIB"
source "$VERIFY_LIB"

evop_init_common_context
VERIFY_STEPS=""
CONTINUE_ON_ERROR=0
LIST_ONLY=0
LIST_FORMAT="summary"
REQUIRE_ALL=0
REPORT_FILE=""
REPORT_FORMAT="json"

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

    while IFS= read -r item; do
        item="${item#"${item%%[![:space:]]*}"}"
        item="${item%"${item##*[![:space:]]}"}"
        [[ -n "$item" ]] || continue

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
    done < <(printf '%s\n' "$raw" | tr ',' '\n')

    printf '%s' "$normalized"
}

evop_run_verify_step() {
    local slot="$1"
    local command="$2"
    local log_file="$3"
    local exit_code=0

    evop_log_info "Running $slot: $command"
    if [[ "$DRY_RUN" == "1" ]]; then
        return 0
    fi

    mkdir -p "$(dirname "$log_file")"
    set +e
    (
        cd "$TARGET_DIR"
        evop_run_with_preferred_shell "$command"
    ) 2>&1 | tee "$log_file"
    evop_capture_pipeline_status0
    exit_code="$EVOP_PIPELINE_STATUS0"
    set -e
    return "$exit_code"
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
      --context-file FILE  Reuse an `inspect --format env` context snapshot.
      --steps CSV          Comma-separated subset of: lint,typecheck,test,build.
      --list               Print the selected verification plan and exit.
      --list-format NAME   List output format: summary, json, or env. Default: summary.
  -c, --continue-on-error  Keep going after a failed verification step.
      --require-all        Fail if any selected verification step has no detected command.
      --report-file FILE   Write a machine-readable verification summary file.
      --report-format NAME Report format: json or env. Default: json.
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
        --list-format)
            evop_require_option_value "$1" "$#"
            LIST_FORMAT="$2"
            shift 2
            ;;
        --report-file)
            evop_require_option_value "$1" "$#"
            REPORT_FILE="$2"
            shift 2
            ;;
        --report-format)
            evop_require_option_value "$1" "$#"
            REPORT_FORMAT="$2"
            shift 2
            ;;
        -c|--continue-on-error)
            CONTINUE_ON_ERROR=1
            shift
            ;;
        --require-all)
            REQUIRE_ALL=1
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
evop_validate_verify_list_format "$LIST_FORMAT"
case "$REPORT_FORMAT" in
    json|env)
        ;;
    *)
        evop_fail "Unsupported verify report format: $REPORT_FORMAT"
        ;;
esac

if (( REQUIRE_ALL == 1 )); then
    evop_require_verify_commands "$selected_steps"
fi

if (( LIST_ONLY == 1 )); then
    evop_print_verify_plan "$TARGET_DIR" "$selected_steps" "$LIST_FORMAT"
    exit 0
fi

if [[ "$DRY_RUN" == "1" ]]; then
    printf 'Target directory: %s\n' "$TARGET_DIR"
fi

verify_dir="$(evop_prepare_unique_dir "$artifacts_root" "verify")"
ran_any=0
final_status=0
evop_begin_verify_report "$TARGET_DIR" "$verify_dir" "$selected_steps" "$CONTINUE_ON_ERROR" "$DRY_RUN"

while IFS= read -r slot; do
    step_started_ms=0
    step_duration_ms=0
    step_exit_code=0
    step_log_file="$verify_dir/$slot.log"

    [[ -n "$slot" ]] || continue
    command="$(evop_get_project_command "$slot")"
    if [[ -z "$command" ]]; then
        evop_log_info "Skipping $slot: no command detected."
        evop_record_verify_step "$slot" "" "" "skipped" 0 0
        continue
    fi

    ran_any=1
    if [[ "$DRY_RUN" == "1" ]]; then
        evop_run_verify_step "$slot" "$command" "$step_log_file"
        evop_record_verify_step "$slot" "$command" "" "dry_run" 0 0
    else
        step_started_ms="$(evop_now_millis)"
        if evop_run_verify_step "$slot" "$command" "$step_log_file"; then
            step_duration_ms="$(evop_elapsed_millis_since "$step_started_ms")"
            evop_record_verify_step "$slot" "$command" "$step_log_file" "passed" 0 "$step_duration_ms"
        else
            step_exit_code=$?
            step_duration_ms="$(evop_elapsed_millis_since "$step_started_ms")"
            evop_record_verify_step "$slot" "$command" "$step_log_file" "failed" "$step_exit_code" "$step_duration_ms"
            final_status=$step_exit_code
            evop_print_stderr "Verification step '$slot' failed with exit code $final_status."
            if (( CONTINUE_ON_ERROR == 0 )); then
                EVOP_VERIFY_REPORT_FINAL_STATUS="$final_status"
                evop_write_verify_report "$REPORT_FILE" "$REPORT_FORMAT"
                exit "$final_status"
            fi
        fi
    fi
done <<<"$selected_steps"

if (( ran_any == 0 )); then
    EVOP_VERIFY_REPORT_FINAL_STATUS=1
    evop_write_verify_report "$REPORT_FILE" "$REPORT_FORMAT"
    evop_fail "No runnable verification commands were detected for the selected steps."
fi

if [[ "$DRY_RUN" != "1" ]]; then
    evop_log_info "Verification logs: $verify_dir"
fi

EVOP_VERIFY_REPORT_FINAL_STATUS="$final_status"
evop_write_verify_report "$REPORT_FILE" "$REPORT_FORMAT"

exit "$final_status"
