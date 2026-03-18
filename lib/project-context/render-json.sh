#!/usr/bin/env zsh

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
    printf '  "workspace_packages": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES")"
    printf '  "agent_tools": %s,\n' "$(evop_render_json_array_from_lines "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS")"
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
