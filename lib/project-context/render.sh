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

evop_render_project_context_prompt() {
    local guidance=""
    local has_repo_context=0

    if [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" || -n "$EVOP_PROJECT_CONTEXT_STRUCTURE" || -n "$EVOP_PROJECT_CONTEXT_CONVENTIONS" || -n "$EVOP_PROJECT_CONTEXT_RISK_AREAS" || -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]] || evop_project_has_any_command; then
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
    [[ -n "$EVOP_PROJECT_CONTEXT_TASK_KIND" ]] && printf 'Task kind: %s\n' "$EVOP_PROJECT_CONTEXT_TASK_KIND"
    [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY" ]] && printf 'Search strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY" ]] && printf 'Edit strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_EDIT_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY" ]] && printf 'Verification strategy: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY")"
    [[ -n "$EVOP_PROJECT_CONTEXT_RISK_FOCUS" ]] && printf 'Risk focus: %s\n' "$(evop_format_inline_lines "$EVOP_PROJECT_CONTEXT_RISK_FOCUS")"
}

evop_print_project_inspection_report() {
    [[ -n "${TARGET_DIR:-}" ]] && printf 'Target directory: %s\n' "$TARGET_DIR"
    [[ -n "${AGENT:-}" ]] && printf 'Agent: %s\n' "$AGENT"
    evop_print_current_profiles

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

    if [[ -n "$EVOP_PROJECT_CONTEXT_VALIDATION" ]]; then
        printf 'Validation plan:\n'
        printf '%s\n' "$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_VALIDATION")"
    fi
}
