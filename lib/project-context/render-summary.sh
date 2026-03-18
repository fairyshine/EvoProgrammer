#!/usr/bin/env zsh

evop_print_project_command_report() {
    [[ -n "${TARGET_DIR:-}" ]] && printf 'Target directory: %s\n' "$TARGET_DIR"
    [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" ]] && printf 'Package manager: %s\n' "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER"
    [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE" ]] && printf 'Workspace mode: %s\n' "$EVOP_PROJECT_CONTEXT_WORKSPACE_MODE"
    if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]]; then
        printf 'Workspace packages:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES")"
    fi
    printf 'Suggested commands:\n'
    if evop_project_has_any_command; then
        printf '%s\n' "$(evop_append_project_command_lines "- " 1)"
    else
        printf -- '- none\n'
    fi
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
        [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]] && printf 'OK workspace-packages %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES")"
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
    if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]]; then
        printf 'Workspace packages:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES")"
    fi
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
    if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]]; then
        printf 'Workspace packages:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES")"
    fi

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

    [[ -n "$EVOP_PROJECT_CONTEXT_TASK_KIND" ]] && printf 'Task kind: %s\n' "$EVOP_PROJECT_CONTEXT_TASK_KIND"
    [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY" ]] && printf 'Search strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY" ]] && printf 'Edit strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY" ]] && printf 'Verification strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_RISK_FOCUS" ]] && printf 'Risk focus: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_RISK_FOCUS")"
}
