#!/usr/bin/env zsh

evop_print_project_inspection_env() {
    local slot=""
    local command=""
    local source=""
    local slot_key=""

    evop_print_env_assignment "EVOP_INSPECT_TARGET_DIR" "${TARGET_DIR:-}"
    evop_print_env_assignment "EVOP_INSPECT_AGENT" "${AGENT:-}"
    evop_print_env_assignment "EVOP_INSPECT_LANGUAGE_PROFILE" "${LANGUAGE_PROFILE:-}"
    evop_print_env_assignment "EVOP_INSPECT_LANGUAGE_PROFILE_SOURCE" "${LANGUAGE_PROFILE_SOURCE:-}"
    evop_print_env_assignment "EVOP_INSPECT_FRAMEWORK_PROFILE" "${FRAMEWORK_PROFILE:-}"
    evop_print_env_assignment "EVOP_INSPECT_FRAMEWORK_PROFILE_SOURCE" "${FRAMEWORK_PROFILE_SOURCE:-}"
    evop_print_env_assignment "EVOP_INSPECT_PROJECT_TYPE" "${PROJECT_TYPE:-}"
    evop_print_env_assignment "EVOP_INSPECT_PROJECT_TYPE_SOURCE" "${PROJECT_TYPE_SOURCE:-}"
    evop_print_env_assignment "EVOP_INSPECT_PACKAGE_MANAGER" "${EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER:-}"
    evop_print_env_assignment "EVOP_INSPECT_WORKSPACE_MODE" "${EVOP_PROJECT_CONTEXT_WORKSPACE_MODE:-}"
    evop_print_env_assignment "EVOP_INSPECT_WORKSPACE_PACKAGES" "${EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES:-}"
    evop_print_env_assignment "EVOP_INSPECT_AGENT_COMMAND_CATALOG" "${EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG:-}"
    evop_print_env_assignment "EVOP_INSPECT_AGENT_SUPPORT_TOOL_CATALOG" "${EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG:-}"
    evop_print_env_assignment "EVOP_INSPECT_AGENT_TOOLS" "${EVOP_PROJECT_CONTEXT_AGENT_TOOLS:-}"
    evop_print_env_assignment "EVOP_INSPECT_AGENT_SUPPORT_TOOLS" "${EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS:-}"

    while IFS= read -r slot; do
        command="$(evop_get_project_command "$slot")"
        source="$(evop_get_project_command_source "$slot")"
        slot_key="$(evop_project_command_env_key "$slot")"
        evop_print_env_assignment "EVOP_INSPECT_${slot_key}_COMMAND" "$command"
        evop_print_env_assignment "EVOP_INSPECT_${slot_key}_COMMAND_SOURCE" "$source"
    done < <(evop_project_command_slots)

    evop_print_env_assignment "EVOP_INSPECT_SEARCH_ROOTS" "${EVOP_PROJECT_CONTEXT_SEARCH_ROOTS:-}"
    evop_print_env_assignment "EVOP_INSPECT_STRUCTURE" "${EVOP_PROJECT_CONTEXT_STRUCTURE:-}"
    evop_print_env_assignment "EVOP_INSPECT_CONVENTIONS" "${EVOP_PROJECT_CONTEXT_CONVENTIONS:-}"
    evop_print_env_assignment "EVOP_INSPECT_RISK_AREAS" "${EVOP_PROJECT_CONTEXT_RISK_AREAS:-}"
    evop_print_env_assignment "EVOP_INSPECT_AUTOMATION" "${EVOP_PROJECT_CONTEXT_AUTOMATION:-}"
    evop_print_env_assignment "EVOP_INSPECT_VALIDATION" "${EVOP_PROJECT_CONTEXT_VALIDATION:-}"
    evop_print_env_assignment "EVOP_INSPECT_TASK_KIND" "${EVOP_PROJECT_CONTEXT_TASK_KIND:-}"
    evop_print_env_assignment "EVOP_INSPECT_TASK_WORKFLOW" "${EVOP_PROJECT_CONTEXT_TASK_WORKFLOW:-}"
    evop_print_env_assignment "EVOP_INSPECT_SEARCH_STRATEGY" "${EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY:-}"
    evop_print_env_assignment "EVOP_INSPECT_EDIT_STRATEGY" "${EVOP_PROJECT_CONTEXT_EDIT_STRATEGY:-}"
    evop_print_env_assignment "EVOP_INSPECT_VERIFICATION_STRATEGY" "${EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY:-}"
    evop_print_env_assignment "EVOP_INSPECT_RISK_FOCUS" "${EVOP_PROJECT_CONTEXT_RISK_FOCUS:-}"
    evop_print_env_assignment "EVOP_INSPECT_PROFILE_DETECTION_LANGUAGES" "$(evop_profile_detection_candidates_sorted languages)"
    evop_print_env_assignment "EVOP_INSPECT_PROFILE_DETECTION_FRAMEWORKS" "$(evop_profile_detection_candidates_sorted frameworks)"
    evop_print_env_assignment "EVOP_INSPECT_PROFILE_DETECTION_PROJECT_TYPES" "$(evop_profile_detection_candidates_sorted project-types)"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_BACKEND" "${EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND:-}"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_LOOKUPS" "${EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_HITS" "${EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_MISSES" "${EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES:-0}"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_HIT_RATE_PERCENT" "$(evop_project_context_cache_hit_rate_percent)"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_RELATIVE_EXISTS_ENTRIES" "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_FILE_LITERAL_ENTRIES" "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_FILE_REGEX_ENTRIES" "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_FILE_TEXT_ENTRIES" "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_COMMAND_AVAILABILITY_ENTRIES" "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_COMMAND_AVAILABILITY_CACHE)"
    evop_print_env_assignment "EVOP_INSPECT_FACTS_CACHE_COMMAND_PATH_ENTRIES" "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_COMMAND_PATH_CACHE)"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_LANGUAGE_DETECT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_LANGUAGE_DETECT_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_FRAMEWORK_DETECT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_FRAMEWORK_DETECT_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_PROJECT_TYPE_DETECT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_PROJECT_TYPE_DETECT_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_ANALYZE_CONTEXT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_RESOLVE_PROFILES_MS" "${EVOP_PROJECT_CONTEXT_TIMING_RESOLVE_PROFILES_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_FINALIZE_ANALYSIS_MS" "${EVOP_PROJECT_CONTEXT_TIMING_FINALIZE_ANALYSIS_MS:-0}"
}

evop_print_project_agent_catalog_env() {
    local output_kind="${1:-all}"

    evop_print_env_assignment "EVOP_AGENT_CATALOG_TARGET_DIR" "${TARGET_DIR:-}"
    evop_print_env_assignment "EVOP_AGENT_CATALOG_AGENT" "${AGENT:-}"
    evop_print_env_assignment "EVOP_AGENT_CATALOG_LANGUAGE_PROFILE" "${LANGUAGE_PROFILE:-}"
    evop_print_env_assignment "EVOP_AGENT_CATALOG_LANGUAGE_PROFILE_SOURCE" "${LANGUAGE_PROFILE_SOURCE:-}"
    evop_print_env_assignment "EVOP_AGENT_CATALOG_PACKAGE_MANAGER" "${EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER:-}"
    evop_print_env_assignment "EVOP_AGENT_CATALOG_WORKSPACE_MODE" "${EVOP_PROJECT_CONTEXT_WORKSPACE_MODE:-}"
    evop_print_env_assignment "EVOP_AGENT_CATALOG_WORKSPACE_PACKAGES" "${EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES:-}"
    evop_print_env_assignment "EVOP_AGENT_CATALOG_KIND" "$output_kind"
    if [[ "$output_kind" == "support" ]]; then
        evop_print_env_assignment "EVOP_AGENT_CATALOG_COMMAND_CATALOG" ""
        evop_print_env_assignment "EVOP_AGENT_CATALOG_TOOLS" ""
    else
        evop_print_env_assignment "EVOP_AGENT_CATALOG_COMMAND_CATALOG" "${EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG:-}"
        evop_print_env_assignment "EVOP_AGENT_CATALOG_TOOLS" "${EVOP_PROJECT_CONTEXT_AGENT_TOOLS:-}"
    fi
    if [[ "$output_kind" == "commands" ]]; then
        evop_print_env_assignment "EVOP_AGENT_CATALOG_SUPPORT_TOOL_CATALOG" ""
        evop_print_env_assignment "EVOP_AGENT_CATALOG_SUPPORT_TOOLS" ""
    else
        evop_print_env_assignment "EVOP_AGENT_CATALOG_SUPPORT_TOOL_CATALOG" "${EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG:-}"
        evop_print_env_assignment "EVOP_AGENT_CATALOG_SUPPORT_TOOLS" "${EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS:-}"
    fi
    evop_print_env_assignment "EVOP_AGENT_CATALOG_TIMING_ANALYZE_CONTEXT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS:-0}"
    evop_print_env_assignment "EVOP_AGENT_CATALOG_TIMING_FINALIZE_ANALYSIS_MS" "${EVOP_PROJECT_CONTEXT_TIMING_FINALIZE_ANALYSIS_MS:-0}"
}
