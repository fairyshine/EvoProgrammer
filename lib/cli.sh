#!/usr/bin/env bash

# shellcheck disable=SC2034

EVOP_CLI_OPTION_HANDLED=0
EVOP_CLI_OPTION_SHIFT=0

evop_init_common_context() {
    PROMPT="${EVOPROGRAMMER_PROMPT:-}"
    PROMPT_FILE="${EVOPROGRAMMER_PROMPT_FILE:-}"
    TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"
    TARGET_DIR_EXPLICIT=0
    ARTIFACTS_DIR="${EVOPROGRAMMER_ARTIFACTS_DIR:-}"
    CONTEXT_FILE="${EVOPROGRAMMER_CONTEXT_FILE:-}"
    AGENT="${EVOPROGRAMMER_AGENT:-$EVOPROGRAMMER_DEFAULT_AGENT}"
    AGENT_ARGS_LIST="${EVOPROGRAMMER_AGENT_ARGS:-}"
    LANGUAGE_PROFILE="${EVOPROGRAMMER_LANGUAGE_PROFILE:-}"
    FRAMEWORK_PROFILE="${EVOPROGRAMMER_FRAMEWORK_PROFILE:-}"
    PROJECT_TYPE="${EVOPROGRAMMER_PROJECT_TYPE:-}"
    LANGUAGE_PROFILE_SOURCE="none"
    FRAMEWORK_PROFILE_SOURCE="none"
    PROJECT_TYPE_SOURCE="none"
    DRY_RUN=0
}

evop_parse_common_option() {
    local option="$1"
    local argument_count="$2"
    local option_value="${3-}"

    EVOP_CLI_OPTION_HANDLED=1
    EVOP_CLI_OPTION_SHIFT=0

    case "$option" in
        -p|--prompt)
            evop_require_option_value "$option" "$argument_count"
            PROMPT="$option_value"
            PROMPT_FILE=""
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        -f|--prompt-file)
            evop_require_option_value "$option" "$argument_count"
            PROMPT_FILE="$option_value"
            PROMPT=""
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        -g|--agent)
            evop_require_option_value "$option" "$argument_count"
            AGENT="$option_value"
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        --language)
            evop_require_option_value "$option" "$argument_count"
            LANGUAGE_PROFILE="$option_value"
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        --framework)
            evop_require_option_value "$option" "$argument_count"
            FRAMEWORK_PROFILE="$option_value"
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        --project-type)
            evop_require_option_value "$option" "$argument_count"
            PROJECT_TYPE="$option_value"
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        -t|--target-dir)
            evop_require_option_value "$option" "$argument_count"
            TARGET_DIR="$option_value"
            TARGET_DIR_EXPLICIT=1
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        -o|--artifacts-dir)
            evop_require_option_value "$option" "$argument_count"
            ARTIFACTS_DIR="$option_value"
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        --context-file)
            evop_require_option_value "$option" "$argument_count"
            CONTEXT_FILE="$option_value"
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        --agent-args)
            evop_require_option_value "$option" "$argument_count"
            AGENT_ARGS_LIST="$option_value"
            EVOP_CLI_OPTION_SHIFT=2
            ;;
        --dry-run)
            DRY_RUN=1
            EVOP_CLI_OPTION_SHIFT=1
            ;;
        -q|--quiet)
            EVOP_VERBOSITY=0
            EVOP_CLI_OPTION_SHIFT=1
            ;;
        -v|--verbose)
            EVOP_VERBOSITY=2
            EVOP_CLI_OPTION_SHIFT=1
            ;;
        *)
            EVOP_CLI_OPTION_HANDLED=0
            ;;
    esac
}

evop_parse_doctor_option() {
    local option="$1"
    local argument_count="$2"
    local option_value="${3-}"

    evop_parse_common_option "$option" "$argument_count" "$option_value"
    if (( EVOP_CLI_OPTION_HANDLED == 0 )); then
        return 1
    fi

    case "$option" in
        -g|--agent|--language|--framework|--project-type|-t|--target-dir|-o|--artifacts-dir|--context-file)
            return 0
            ;;
        *)
            evop_fail "Unsupported option for doctor: $option"
            ;;
    esac
}

evop_try_finalize_context_from_snapshot() {
    local prompt="${1:-}"

    [[ -n "$CONTEXT_FILE" ]] || return 1

    evop_load_project_context_snapshot_file "$CONTEXT_FILE"
    if (( TARGET_DIR_EXPLICIT == 0 )); then
        evop_adopt_project_context_snapshot_target_dir
        evop_load_project_config "$TARGET_DIR"
    fi

    evop_validate_agent "$AGENT"
    evop_validate_language_profile "$LANGUAGE_PROFILE"
    evop_validate_framework_profile "$FRAMEWORK_PROFILE"
    evop_validate_project_type "$PROJECT_TYPE"
    evop_require_directory "$TARGET_DIR"
    target_dir_abs="$(evop_resolve_physical_dir "$TARGET_DIR")"
    evop_validate_project_context_snapshot_target_dir "$target_dir_abs"
    evop_apply_project_context_snapshot "$target_dir_abs" "$prompt" "$LANGUAGE_PROFILE" "$FRAMEWORK_PROFILE" "$PROJECT_TYPE"
    artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"
    return 0
}

evop_finalize_common_context() {
    evop_load_project_config "$TARGET_DIR"

    if [[ -z "$PROMPT" && -z "$PROMPT_FILE" ]]; then
        PROMPT="$EVOPROGRAMMER_DEFAULT_PROMPT"
    fi

    resolved_prompt="$(evop_resolve_prompt "$PROMPT" "$PROMPT_FILE")"
    if evop_try_finalize_context_from_snapshot "$resolved_prompt"; then
        return 0
    fi

    evop_validate_agent "$AGENT"
    evop_validate_language_profile "$LANGUAGE_PROFILE"
    evop_validate_framework_profile "$FRAMEWORK_PROFILE"
    evop_validate_project_type "$PROJECT_TYPE"
    evop_require_directory "$TARGET_DIR"
    target_dir_abs="$(evop_resolve_physical_dir "$TARGET_DIR")"
    evop_resolve_profiles "$target_dir_abs" "$resolved_prompt" "$LANGUAGE_PROFILE" "$FRAMEWORK_PROFILE" "$PROJECT_TYPE"
    evop_apply_resolved_profiles
    artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"
}

evop_finalize_doctor_context() {
    evop_load_project_config "$TARGET_DIR"
    if evop_try_finalize_context_from_snapshot ""; then
        return 0
    fi

    evop_validate_agent "$AGENT"
    evop_validate_language_profile "$LANGUAGE_PROFILE"
    evop_validate_framework_profile "$FRAMEWORK_PROFILE"
    evop_validate_project_type "$PROJECT_TYPE"
    evop_require_directory "$TARGET_DIR"
    target_dir_abs="$(evop_resolve_physical_dir "$TARGET_DIR")"
    evop_resolve_profiles "$target_dir_abs" "" "$LANGUAGE_PROFILE" "$FRAMEWORK_PROFILE" "$PROJECT_TYPE"
    evop_apply_resolved_profiles
    artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"
}

evop_finalize_analysis_context() {
    local started_ms=0

    evop_reset_project_context_timings
    started_ms="$(evop_now_millis)"
    evop_load_project_config "$TARGET_DIR"
    resolved_prompt="$(evop_resolve_optional_prompt "$PROMPT" "$PROMPT_FILE")"
    if evop_try_finalize_context_from_snapshot "$resolved_prompt"; then
        return 0
    fi

    evop_validate_agent "$AGENT"
    evop_validate_language_profile "$LANGUAGE_PROFILE"
    evop_validate_framework_profile "$FRAMEWORK_PROFILE"
    evop_validate_project_type "$PROJECT_TYPE"
    evop_require_directory "$TARGET_DIR"
    target_dir_abs="$(evop_resolve_physical_dir "$TARGET_DIR")"
    evop_resolve_profiles "$target_dir_abs" "$resolved_prompt" "$LANGUAGE_PROFILE" "$FRAMEWORK_PROFILE" "$PROJECT_TYPE"
    evop_apply_resolved_profiles
    artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"
    EVOP_PROJECT_CONTEXT_TIMING_FINALIZE_ANALYSIS_MS="$(evop_elapsed_millis_since "$started_ms")"
}
