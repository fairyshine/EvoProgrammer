#!/usr/bin/env zsh

evop_print_project_command_report() {
    [[ -n "${TARGET_DIR:-}" ]] && evop_print_key_value "Target directory:" "$TARGET_DIR"
    [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]] && evop_print_key_value "Package manager:" "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER"
    [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]] && evop_print_key_value "Workspace mode:" "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE"
    if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]]; then
        evop_print_section "Workspace packages:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS" ]]; then
        evop_print_section "Agent command surfaces:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_TOOLS"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS" ]]; then
        evop_print_section "Agent support tools:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS"
    fi
    evop_print_section "Suggested commands:"
    if evop_project_has_any_command; then
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done < <(evop_append_project_command_lines "" 1)
    else
        evop_print_list_item "none"
    fi
}

evop_print_project_agent_catalog_report() {
    [[ -n "${TARGET_DIR:-}" ]] && evop_print_key_value "Target directory:" "$TARGET_DIR"
    [[ -n "${AGENT:-}" ]] && evop_print_key_value "Agent:" "$AGENT"
    evop_print_resolved_profile "Language profile" "$LANGUAGE_PROFILE" "$LANGUAGE_PROFILE_SOURCE"
    [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]] && evop_print_key_value "Package manager:" "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER"
    [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]] && evop_print_key_value "Workspace mode:" "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE"
    if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]]; then
        evop_print_section "Workspace packages:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG" ]]; then
        evop_print_section "Agent command catalog:"
        while IFS=$'\t' read -r kind command source; do
            [[ -n "$kind" && -n "$command" && -n "$source" ]] || continue
            evop_print_list_item "$command [$kind; $source]"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS" ]]; then
        evop_print_section "Agent support tools:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG" ]]; then
        evop_print_section "Agent support tool catalog:"
        while IFS=$'\t' read -r name path source; do
            [[ -n "$name" && -n "$path" && -n "$source" ]] || continue
            evop_print_list_item "$name -> $path [$source]"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG"
    fi
}

evop_print_profile_detection_report() {
    local category_dir=""
    local label=""
    local profile_name=""
    local score=""

    [[ -n "${TARGET_DIR:-}" ]] && evop_print_key_value "Target directory:" "$TARGET_DIR"
    evop_print_section "Profile detection report:"

    for category_dir in languages frameworks project-types; do
        label="$(evop_profile_diagnostics_label "$category_dir")" || continue
        evop_print_section "$label:"

        if ! evop_profile_detection_has_candidates "$category_dir"; then
            evop_print_list_item "none"
            continue
        fi

        while IFS=$'\t' read -r profile_name score; do
            [[ -n "$profile_name" ]] || continue
            evop_print_list_item "$profile_name (score: $score)"
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
        [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]] && printf 'OK workspace-packages %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES")"
        [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS" ]] && printf 'OK agent-tools %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS")"
        [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS" ]] && printf 'OK agent-support-tools %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS")"
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

    [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]] && evop_print_key_value "Package manager:" "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER"
    [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]] && evop_print_key_value "Workspace mode:" "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE"
    if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]]; then
        evop_print_section "Workspace packages:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS" ]]; then
        evop_print_section "Agent command surfaces:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_TOOLS"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS" ]]; then
        evop_print_section "Agent support tools:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS"
    fi
    while IFS= read -r slot; do
        command="$(evop_get_project_command "$slot")"
        [[ -n "$command" ]] || continue
        label="$(evop_project_command_label "$slot")"
        source="$(evop_get_project_command_source "$slot")"
        printf '%s %s' "$(evop_style_text cyan "$label command:")" "$command"
        [[ -n "$source" && "$source" != "none" ]] && printf ' [%s]' "$source"
        printf '\n'
    done < <(evop_project_command_slots)
    [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]] && evop_print_key_value "Search roots:" "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS"
    if [[ -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" ]]; then
        evop_print_section "Operational surfaces:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AUTOMATION"
    fi
    [[ -n "$EVOP_PROJECT_CONTEXT_TASK_KIND" ]] && evop_print_key_value "Task kind:" "$EVOP_PROJECT_CONTEXT_TASK_KIND"
    [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY" ]] && evop_print_key_value "Search strategy:" "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY" ]] && evop_print_key_value "Edit strategy:" "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY" ]] && evop_print_key_value "Verification strategy:" "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_RISK_FOCUS" ]] && evop_print_key_value "Risk focus:" "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_RISK_FOCUS")"
}

evop_print_project_inspection_report() {
    [[ -n "${TARGET_DIR:-}" ]] && evop_print_key_value "Target directory:" "$TARGET_DIR"
    [[ -n "${AGENT:-}" ]] && evop_print_key_value "Agent:" "$AGENT"
    evop_print_resolved_profile "Language profile" "$LANGUAGE_PROFILE" "$LANGUAGE_PROFILE_SOURCE"
    evop_print_resolved_profile "Framework profile" "$FRAMEWORK_PROFILE" "$FRAMEWORK_PROFILE_SOURCE"
    evop_print_resolved_profile "Project type" "$PROJECT_TYPE" "$PROJECT_TYPE_SOURCE"

    [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]] && evop_print_key_value "Package manager:" "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER"
    [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]] && evop_print_key_value "Workspace mode:" "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE"
    if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]]; then
        evop_print_section "Workspace packages:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS" ]]; then
        evop_print_section "Agent command surfaces:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_TOOLS"
    fi
    if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS" ]]; then
        evop_print_section "Agent support tools:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS"
    fi

    if evop_project_has_any_command; then
        evop_print_section "Suggested commands:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done < <(evop_append_project_command_lines "" 1)
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_STRUCTURE" ]]; then
        evop_print_section "Architecture hints:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_STRUCTURE"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_CONVENTIONS" ]]; then
        evop_print_section "Conventions:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_CONVENTIONS"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_RISK_AREAS" ]]; then
        evop_print_section "Risk areas:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_RISK_AREAS"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" ]]; then
        evop_print_section "Operational surfaces:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_AUTOMATION"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_VALIDATION" ]]; then
        evop_print_section "Validation plan:"
        while IFS= read -r line; do
            evop_print_list_item "$line"
        done <<<"$EVOP_PROJECT_CONTEXT_VALIDATION"
    fi

    [[ -n "$EVOP_PROJECT_CONTEXT_TASK_KIND" ]] && evop_print_key_value "Task kind:" "$EVOP_PROJECT_CONTEXT_TASK_KIND"
    [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY" ]] && evop_print_key_value "Search strategy:" "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY" ]] && evop_print_key_value "Edit strategy:" "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY" ]] && evop_print_key_value "Verification strategy:" "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_RISK_FOCUS" ]] && evop_print_key_value "Risk focus:" "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_RISK_FOCUS")"
}
