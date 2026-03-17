#!/usr/bin/env bash

evop_format_prefixed_lines() {
    local prefix="$1"
    local text="$2"
    local output=""
    local line=""

    [[ -n "$text" ]] || return 0

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        output+="$prefix$line"$'\n'
    done <<<"$text"

    printf '%s' "$output"
}

evop_format_inline_lines() {
    local text="$1"
    local output=""
    local line=""

    [[ -n "$text" ]] || return 0

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if [[ -n "$output" ]]; then
            output+=" | "
        fi
        output+="$line"
    done <<<"$text"

    printf '%s' "$output"
}

evop_json_escape() {
    local value="$1"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"

    printf '%s' "$value"
}

evop_render_json_string() {
    printf '"%s"' "$(evop_json_escape "$1")"
}

evop_render_json_string_or_null() {
    if [[ -n "$1" ]]; then
        evop_render_json_string "$1"
    else
        printf 'null'
    fi
}

evop_render_json_array_from_lines() {
    local text="$1"
    local output="["
    local line=""
    local needs_comma=0

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if (( needs_comma == 1 )); then
            output+=", "
        fi
        output+="$(evop_render_json_string "$line")"
        needs_comma=1
    done <<<"$text"

    output+="]"
    printf '%s' "$output"
}

evop_render_project_commands_json() {
    local output="{"
    local slot=""
    local command=""
    local source=""
    local needs_comma=0

    while IFS= read -r slot; do
        command="$(evop_get_project_command "$slot")"
        source="$(evop_get_project_command_source "$slot")"

        if (( needs_comma == 1 )); then
            output+=", "
        fi

        output+="$(evop_render_json_string "$slot"): {\"command\": "
        output+="$(evop_render_json_string_or_null "$command")"
        output+=", \"source\": "
        output+="$(evop_render_json_string_or_null "$source")"
        output+="}"
        needs_comma=1
    done < <(evop_project_command_slots)

    output+="}"
    printf '%s' "$output"
}

evop_append_project_command_lines() {
    local prefix="$1"
    local include_sources="${2:-0}"
    local output=""
    local slot=""
    local label=""
    local command=""
    local source=""

    while IFS= read -r slot; do
        command="$(evop_get_project_command "$slot")"
        [[ -n "$command" ]] || continue

        label="$(evop_project_command_label "$slot")"
        output+="$prefix$label: $command"

        if [[ "$include_sources" == "1" ]]; then
            source="$(evop_get_project_command_source "$slot")"
            [[ -n "$source" && "$source" != "none" ]] && output+=" [$source]"
        fi

        output+=$'\n'
    done < <(evop_project_command_slots)

    printf '%s' "$output"
}

evop_render_profile_detection_category_json() {
    local category_dir="$1"
    local output="["
    local profile_name=""
    local score=""
    local needs_comma=0

    while IFS=$'\t' read -r profile_name score; do
        [[ -n "$profile_name" ]] || continue
        if (( needs_comma == 1 )); then
            output+=", "
        fi
        output+="{\"name\": $(evop_render_json_string "$profile_name"), \"score\": $score}"
        needs_comma=1
    done < <(evop_profile_detection_candidates_sorted "$category_dir")

    output+="]"
    printf '%s' "$output"
}

evop_render_profile_detection_json() {
    local output="{"
    local category_dir=""
    local json_key=""
    local needs_comma=0

    for category_dir in languages frameworks project-types; do
        json_key="$(evop_profile_diagnostics_json_key "$category_dir")" || continue
        if (( needs_comma == 1 )); then
            output+=", "
        fi
        output+="$(evop_render_json_string "$json_key"): $(evop_render_profile_detection_category_json "$category_dir")"
        needs_comma=1
    done

    output+="}"
    printf '%s' "$output"
}

evop_render_project_context_json() {
    printf '{\n'
    printf '  "target_dir": %s,\n' "$(evop_render_json_string_or_null "${TARGET_DIR:-}")"
    printf '  "agent": %s,\n' "$(evop_render_json_string_or_null "${AGENT:-}")"
    printf '  "profiles": {"language": {"name": %s, "source": %s}, "framework": {"name": %s, "source": %s}, "project_type": {"name": %s, "source": %s}},\n' \
        "$(evop_render_json_string_or_null "${LANGUAGE_PROFILE:-}")" \
        "$(evop_render_json_string_or_null "${LANGUAGE_PROFILE_SOURCE:-}")" \
        "$(evop_render_json_string_or_null "${FRAMEWORK_PROFILE:-}")" \
        "$(evop_render_json_string_or_null "${FRAMEWORK_PROFILE_SOURCE:-}")" \
        "$(evop_render_json_string_or_null "${PROJECT_TYPE:-}")" \
        "$(evop_render_json_string_or_null "${PROJECT_TYPE_SOURCE:-}")"
    printf '  "profile_detection": %s,\n' "$(evop_render_profile_detection_json)"
    printf '  "package_manager": %s,\n' "$(evop_render_json_string_or_null "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER")"
    printf '  "workspace_mode": %s,\n' "$(evop_render_json_string_or_null "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE")"
    printf '  "commands": %s,\n' "$(evop_render_project_commands_json)"
    printf '  "search_roots": %s,\n' "$(evop_render_json_array_from_lines "${EVOP_PROJECT_CONTEXT_SEARCH_ROOTS//, /$'\n'}")"
    printf '  "structure": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_STRUCTURE")"
    printf '  "conventions": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_CONVENTIONS")"
    printf '  "risk_areas": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_RISK_AREAS")"
    printf '  "automation": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_AUTOMATION")"
    printf '  "validation": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_VALIDATION")"
    printf '  "facts_cache": %s,\n' "$(evop_render_project_context_facts_diagnostics_json)"
    printf '  "timings": %s,\n' "$(evop_render_project_context_timings_json)"
    printf '  "task_kind": %s,\n' "$(evop_render_json_string_or_null "$EVOP_PROJECT_CONTEXT_TASK_KIND")"
    printf '  "task_workflow": %s,\n' "$(evop_render_json_string_or_null "$EVOP_PROJECT_CONTEXT_TASK_WORKFLOW")"
    printf '  "search_strategy": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY")"
    printf '  "edit_strategy": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY")"
    printf '  "verification_strategy": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY")"
    printf '  "risk_focus": %s\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_RISK_FOCUS")"
    printf '}\n'
}

evop_print_env_assignment() {
    printf '%s=%q\n' "$1" "$2"
}

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

    while IFS= read -r slot; do
        command="$(evop_get_project_command "$slot")"
        source="$(evop_get_project_command_source "$slot")"
        slot_key="$(printf '%s' "$slot" | tr '[:lower:]-' '[:upper:]_')"
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
    evop_print_env_assignment "EVOP_INSPECT_TIMING_LANGUAGE_DETECT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_LANGUAGE_DETECT_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_FRAMEWORK_DETECT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_FRAMEWORK_DETECT_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_PROJECT_TYPE_DETECT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_PROJECT_TYPE_DETECT_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_ANALYZE_CONTEXT_MS" "${EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_RESOLVE_PROFILES_MS" "${EVOP_PROJECT_CONTEXT_TIMING_RESOLVE_PROFILES_MS:-0}"
    evop_print_env_assignment "EVOP_INSPECT_TIMING_FINALIZE_ANALYSIS_MS" "${EVOP_PROJECT_CONTEXT_TIMING_FINALIZE_ANALYSIS_MS:-0}"
}

evop_render_project_context_prompt() {
    local guidance=""
    local has_repo_context=0

    if [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" || -n "$EVOP_PROJECT_CONTEXT_STRUCTURE" || -n "$EVOP_PROJECT_CONTEXT_CONVENTIONS" || -n "$EVOP_PROJECT_CONTEXT_RISK_AREAS" || -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" || -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]] || evop_project_has_any_command; then
        has_repo_context=1
    fi

    if (( has_repo_context == 1 )); then
        guidance+="[Repository Context]\n"
        if [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]]; then
            guidance+="Package manager: $EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER\n"
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]]; then
            guidance+="Workspace mode: $EVOP_PROJECT_CONTEXT_WORKSPACE_MODE\n"
        fi
        if evop_project_has_any_command; then
            guidance+="Suggested commands:\n"
            guidance+="$(evop_append_project_command_lines "- ")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_STRUCTURE" ]]; then
            guidance+="Architecture hints:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_STRUCTURE")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_CONVENTIONS" ]]; then
            guidance+="Conventions to preserve:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_CONVENTIONS")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_RISK_AREAS" ]]; then
            guidance+="Risk areas:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_RISK_AREAS")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" ]]; then
            guidance+="Operational surfaces:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_AUTOMATION")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_VALIDATION" ]]; then
            guidance+="Validation plan:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_VALIDATION")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]]; then
            guidance+="Similar implementation starting points: $EVOP_PROJECT_CONTEXT_SEARCH_ROOTS\n"
        fi
        guidance+=$'\n'
    fi

    if (( has_repo_context == 1 )) && [[ -n "$EVOP_PROJECT_CONTEXT_TASK_WORKFLOW" ]]; then
        guidance+="[Recommended Workflow]\n"
        guidance+="Task kind: $EVOP_PROJECT_CONTEXT_TASK_KIND\n"
        guidance+="$EVOP_PROJECT_CONTEXT_TASK_WORKFLOW\n"
        if [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY" ]]; then
            guidance+="Search strategy:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY" ]]; then
            guidance+="Edit strategy:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY" ]]; then
            guidance+="Verification strategy:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_RISK_FOCUS" ]]; then
            guidance+="Risk focus:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_RISK_FOCUS")"
            guidance+=$'\n'
        fi
        guidance+=$'\n'
    fi

    printf '%b' "$guidance"
}

evop_print_profile_detection_report() {
    local category_dir=""
    local label=""
    local profile_name=""
    local score=""

    [[ -n "${TARGET_DIR:-}" ]] && printf 'Target directory: %s\n' "$TARGET_DIR"
    printf 'Profile detection report:\n'

    for category_dir in languages frameworks project-types; do
        label="$(evop_profile_diagnostics_label "$category_dir")" || continue
        printf '%s:\n' "$label"

        if ! evop_profile_detection_has_candidates "$category_dir"; then
            printf -- '- none\n'
            continue
        fi

        while IFS=$'\t' read -r profile_name score; do
            [[ -n "$profile_name" ]] || continue
            printf -- '- %s (score: %s)\n' "$profile_name" "$score"
        done < <(evop_profile_detection_candidates_sorted "$category_dir")
    done
}

evop_print_project_context() {
    local output_style="${1:-default}"
    local slot=""
    local label=""
    local command=""
    local source=""

    if [[ "$output_style" == "doctor" ]]; then
        [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]] && printf 'OK package-manager %s\n' "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER"
        [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]] && printf 'OK workspace-mode %s\n' "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE"
        [[ -n "$EVOP_PROJECT_CONTEXT_DEV_COMMAND" ]] && printf 'OK dev-command %s\n' "$EVOP_PROJECT_CONTEXT_DEV_COMMAND"
        [[ -n "$EVOP_PROJECT_CONTEXT_BUILD_COMMAND" ]] && printf 'OK build-command %s\n' "$EVOP_PROJECT_CONTEXT_BUILD_COMMAND"
        [[ -n "$EVOP_PROJECT_CONTEXT_TEST_COMMAND" ]] && printf 'OK test-command %s\n' "$EVOP_PROJECT_CONTEXT_TEST_COMMAND"
        [[ -n "$EVOP_PROJECT_CONTEXT_LINT_COMMAND" ]] && printf 'OK lint-command %s\n' "$EVOP_PROJECT_CONTEXT_LINT_COMMAND"
        [[ -n "$EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND" ]] && printf 'OK typecheck-command %s\n' "$EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND"
        [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]] && printf 'OK search-roots %s\n' "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS"
        [[ -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" ]] && printf 'OK automation %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_AUTOMATION")"
        [[ -n "$EVOP_PROJECT_CONTEXT_TASK_KIND" ]] && printf 'OK task-kind %s\n' "$EVOP_PROJECT_CONTEXT_TASK_KIND"
        [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY" ]] && printf 'OK search-strategy %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY")"
        [[ -n "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY" ]] && printf 'OK edit-strategy %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY")"
        [[ -n "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY" ]] && printf 'OK verification-strategy %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY")"
        [[ -n "$EVOP_PROJECT_CONTEXT_RISK_FOCUS" ]] && printf 'OK risk-focus %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_RISK_FOCUS")"
        return 0
    fi

    [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]] && printf 'Package manager: %s\n' "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER"
    [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]] && printf 'Workspace mode: %s\n' "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE"
    while IFS= read -r slot; do
        command="$(evop_get_project_command "$slot")"
        [[ -n "$command" ]] || continue
        label="$(evop_project_command_label "$slot")"
        source="$(evop_get_project_command_source "$slot")"
        printf '%s command: %s' "$label" "$command"
        [[ -n "$source" && "$source" != "none" ]] && printf ' [%s]' "$source"
        printf '\n'
    done < <(evop_project_command_slots)
    [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]] && printf 'Search roots: %s\n' "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS"
    if [[ -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" ]]; then
        printf 'Operational surfaces:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_AUTOMATION")"
    fi
    [[ -n "$EVOP_PROJECT_CONTEXT_TASK_KIND" ]] && printf 'Task kind: %s\n' "$EVOP_PROJECT_CONTEXT_TASK_KIND"
    [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY" ]] && printf 'Search strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY" ]] && printf 'Edit strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY" ]] && printf 'Verification strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_RISK_FOCUS" ]] && printf 'Risk focus: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_RISK_FOCUS")"
}

evop_print_project_inspection_report() {
    [[ -n "${TARGET_DIR:-}" ]] && printf 'Target directory: %s\n' "$TARGET_DIR"
    [[ -n "${AGENT:-}" ]] && printf 'Agent: %s\n' "$AGENT"
    evop_print_resolved_profile "Language profile" "$LANGUAGE_PROFILE" "$LANGUAGE_PROFILE_SOURCE"
    evop_print_resolved_profile "Framework profile" "$FRAMEWORK_PROFILE" "$FRAMEWORK_PROFILE_SOURCE"
    evop_print_resolved_profile "Project type" "$PROJECT_TYPE" "$PROJECT_TYPE_SOURCE"

    [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]] && printf 'Package manager: %s\n' "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER"
    [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]] && printf 'Workspace mode: %s\n' "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE"

    if evop_project_has_any_command; then
        printf 'Suggested commands:\n'
        printf '%s\n' "$(evop_append_project_command_lines "- " 1)"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_STRUCTURE" ]]; then
        printf 'Architecture hints:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_STRUCTURE")"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_CONVENTIONS" ]]; then
        printf 'Conventions:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_CONVENTIONS")"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_RISK_AREAS" ]]; then
        printf 'Risk areas:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_RISK_AREAS")"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" ]]; then
        printf 'Operational surfaces:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_AUTOMATION")"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_VALIDATION" ]]; then
        printf 'Validation plan:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_VALIDATION")"
    fi
}

evop_print_project_inspection_diagnostics() {
    local line=""

    evop_print_project_inspection_report
    printf 'Inspection diagnostics:\n'
    printf -- '- Facts directory: %s\n' "${EVOP_PROJECT_CONTEXT_FACTS_DIR:-unknown}"
    while IFS= read -r line; do
        printf -- '- %s\n' "$line"
    done < <(evop_print_project_context_facts_diagnostics)
    while IFS= read -r line; do
        printf -- '- Timing %s\n' "$line"
    done < <(evop_print_project_context_timings)
    while IFS= read -r line; do
        [[ "$line" == Target\ directory:* ]] && continue
        [[ "$line" == Profile\ detection\ report:* ]] && continue
        printf -- '- %s\n' "$line"
    done < <(evop_print_profile_detection_report)
}

evop_print_project_inspection_timings() {
    printf 'Inspection timings (ms):\n'
    while IFS= read -r line; do
        printf -- '- %s\n' "$line"
    done < <(evop_print_project_context_timings)
}
