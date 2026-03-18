#!/usr/bin/env zsh

evop_load_project_context_snapshot_file() {
    local file_path="$1"
    local line=""
    local key=""
    local encoded_value=""
    local decoded_value=""

    evop_require_regular_file "$file_path" "Context file"

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        key="${line%%=*}"
        encoded_value="${line#*=}"

        case "$key" in
            EVOP_INSPECT_*)
                decoded_value="$(evop_decode_env_value "$encoded_value")"
                printf -v "$key" '%s' "$decoded_value"
                ;;
        esac
    done <"$file_path"

    [[ -n "${EVOP_INSPECT_TARGET_DIR:-}" ]] || evop_fail "Context file is missing EVOP_INSPECT_TARGET_DIR: $file_path"
}

evop_adopt_project_context_snapshot_target_dir() {
    if [[ -z "${EVOP_INSPECT_TARGET_DIR:-}" ]]; then
        return 1
    fi

    TARGET_DIR="$EVOP_INSPECT_TARGET_DIR"
}

evop_validate_project_context_snapshot_target_dir() {
    local target_dir_abs="$1"
    local snapshot_target_dir_abs=""

    snapshot_target_dir_abs="$(evop_resolve_physical_dir "${EVOP_INSPECT_TARGET_DIR:-}")"
    if [[ "$target_dir_abs" != "$snapshot_target_dir_abs" ]]; then
        evop_fail "Context file target directory does not match the requested target directory."
    fi
}

evop_project_context_snapshot_source() {
    local requested_profile="$1"
    local snapshot_profile="$2"

    if [[ -n "$requested_profile" ]]; then
        printf 'explicit'
    elif [[ -n "$snapshot_profile" ]]; then
        printf 'context-file'
    else
        printf 'none'
    fi
}

evop_apply_project_context_snapshot_command() {
    local slot="$1"
    local command=""
    local source=""
    local command_var_name=""
    local source_var_name=""
    local inspect_command_var_name=""
    local inspect_source_var_name=""

    inspect_command_var_name="EVOP_INSPECT_$(evop_project_command_env_key "$slot")_COMMAND"
    inspect_source_var_name="EVOP_INSPECT_$(evop_project_command_env_key "$slot")_COMMAND_SOURCE"
    command="${(P)inspect_command_var_name}"
    source="${(P)inspect_source_var_name:-none}"
    command_var_name="$(evop_project_command_value_var "$slot")" || return 1
    source_var_name="$(evop_project_command_source_var "$slot")" || return 1
    printf -v "$command_var_name" '%s' "$command"
    printf -v "$source_var_name" '%s' "$source"
}

evop_apply_project_context_snapshot_profile_diagnostics() {
    EVOP_PROFILE_DIAGNOSTICS_LANGUAGES="${EVOP_INSPECT_PROFILE_DETECTION_LANGUAGES:-}"
    EVOP_PROFILE_DIAGNOSTICS_FRAMEWORKS="${EVOP_INSPECT_PROFILE_DETECTION_FRAMEWORKS:-}"
    EVOP_PROFILE_DIAGNOSTICS_PROJECT_TYPES="${EVOP_INSPECT_PROFILE_DETECTION_PROJECT_TYPES:-}"
}

evop_apply_project_context_snapshot_facts_diagnostics() {
    EVOP_PROJECT_CONTEXT_FACTS_DIR="${EVOP_INSPECT_TARGET_DIR:-}"
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS="${EVOP_INSPECT_FACTS_CACHE_LOOKUPS:-0}"
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS="${EVOP_INSPECT_FACTS_CACHE_HITS:-0}"
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES="${EVOP_INSPECT_FACTS_CACHE_MISSES:-0}"
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_RELATIVE_EXISTS_ENTRIES="${EVOP_INSPECT_FACTS_CACHE_RELATIVE_EXISTS_ENTRIES:-0}"
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_LITERAL_ENTRIES="${EVOP_INSPECT_FACTS_CACHE_FILE_LITERAL_ENTRIES:-0}"
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_REGEX_ENTRIES="${EVOP_INSPECT_FACTS_CACHE_FILE_REGEX_ENTRIES:-0}"
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_FILE_TEXT_ENTRIES="${EVOP_INSPECT_FACTS_CACHE_FILE_TEXT_ENTRIES:-0}"
    EVOP_PROJECT_CONTEXT_FACTS_CACHE_COMMAND_PATH_ENTRIES="${EVOP_INSPECT_FACTS_CACHE_COMMAND_PATH_ENTRIES:-0}"
}

evop_apply_project_context_snapshot_timings() {
    EVOP_PROJECT_CONTEXT_TIMING_LANGUAGE_DETECT_MS="${EVOP_INSPECT_TIMING_LANGUAGE_DETECT_MS:-0}"
    EVOP_PROJECT_CONTEXT_TIMING_FRAMEWORK_DETECT_MS="${EVOP_INSPECT_TIMING_FRAMEWORK_DETECT_MS:-0}"
    EVOP_PROJECT_CONTEXT_TIMING_PROJECT_TYPE_DETECT_MS="${EVOP_INSPECT_TIMING_PROJECT_TYPE_DETECT_MS:-0}"
    EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS="${EVOP_INSPECT_TIMING_ANALYZE_CONTEXT_MS:-0}"
    EVOP_PROJECT_CONTEXT_TIMING_RESOLVE_PROFILES_MS="${EVOP_INSPECT_TIMING_RESOLVE_PROFILES_MS:-0}"
    EVOP_PROJECT_CONTEXT_TIMING_FINALIZE_ANALYSIS_MS="${EVOP_INSPECT_TIMING_FINALIZE_ANALYSIS_MS:-0}"
}

evop_apply_project_context_snapshot() {
    local target_dir="$1"
    local prompt="${2:-}"
    local requested_language_profile="${3:-}"
    local requested_framework_profile="${4:-}"
    local requested_project_type="${5:-}"
    local slot=""

    if [[ -n "$requested_language_profile" && "$requested_language_profile" != "${EVOP_INSPECT_LANGUAGE_PROFILE:-}" ]]; then
        evop_fail "Context file language profile does not match the requested language profile."
    fi

    if [[ -n "$requested_framework_profile" && "$requested_framework_profile" != "${EVOP_INSPECT_FRAMEWORK_PROFILE:-}" ]]; then
        evop_fail "Context file framework profile does not match the requested framework profile."
    fi

    if [[ -n "$requested_project_type" && "$requested_project_type" != "${EVOP_INSPECT_PROJECT_TYPE:-}" ]]; then
        evop_fail "Context file project type does not match the requested project type."
    fi

    evop_reset_project_context
    evop_reset_project_context_facts
    evop_reset_project_context_timings
    evop_reset_profile_diagnostics

    LANGUAGE_PROFILE="${requested_language_profile:-${EVOP_INSPECT_LANGUAGE_PROFILE:-}}"
    FRAMEWORK_PROFILE="${requested_framework_profile:-${EVOP_INSPECT_FRAMEWORK_PROFILE:-}}"
    PROJECT_TYPE="${requested_project_type:-${EVOP_INSPECT_PROJECT_TYPE:-}}"
    LANGUAGE_PROFILE_SOURCE="$(evop_project_context_snapshot_source "$requested_language_profile" "${EVOP_INSPECT_LANGUAGE_PROFILE:-}")"
    FRAMEWORK_PROFILE_SOURCE="$(evop_project_context_snapshot_source "$requested_framework_profile" "${EVOP_INSPECT_FRAMEWORK_PROFILE:-}")"
    PROJECT_TYPE_SOURCE="$(evop_project_context_snapshot_source "$requested_project_type" "${EVOP_INSPECT_PROJECT_TYPE:-}")"

    EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER="${EVOP_INSPECT_PACKAGE_MANAGER:-}"
    EVOP_PROJECT_CONTEXT_WORKSPACE_MODE="${EVOP_INSPECT_WORKSPACE_MODE:-}"
    EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES="${EVOP_INSPECT_WORKSPACE_PACKAGES:-}"
    EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG="${EVOP_INSPECT_AGENT_COMMAND_CATALOG:-}"
    EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG="${EVOP_INSPECT_AGENT_SUPPORT_TOOL_CATALOG:-}"
    EVOP_PROJECT_CONTEXT_AGENT_TOOLS="${EVOP_INSPECT_AGENT_TOOLS:-}"
    EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS="${EVOP_INSPECT_AGENT_SUPPORT_TOOLS:-}"
    EVOP_PROJECT_CONTEXT_SEARCH_ROOTS="${EVOP_INSPECT_SEARCH_ROOTS:-}"
    EVOP_PROJECT_CONTEXT_STRUCTURE="${EVOP_INSPECT_STRUCTURE:-}"
    EVOP_PROJECT_CONTEXT_CONVENTIONS="${EVOP_INSPECT_CONVENTIONS:-}"
    EVOP_PROJECT_CONTEXT_RISK_AREAS="${EVOP_INSPECT_RISK_AREAS:-}"
    EVOP_PROJECT_CONTEXT_AUTOMATION="${EVOP_INSPECT_AUTOMATION:-}"
    EVOP_PROJECT_CONTEXT_VALIDATION="${EVOP_INSPECT_VALIDATION:-}"

    while IFS= read -r slot; do
        evop_apply_project_context_snapshot_command "$slot"
    done < <(evop_project_command_slots)

    evop_apply_project_context_snapshot_profile_diagnostics
    evop_apply_project_context_snapshot_facts_diagnostics
    evop_apply_project_context_snapshot_timings
    evop_rebuild_project_context_workflow "$target_dir" "$prompt" "$LANGUAGE_PROFILE" "$FRAMEWORK_PROFILE" "$PROJECT_TYPE"
}
