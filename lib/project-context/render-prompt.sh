#!/usr/bin/env zsh

evop_render_project_context_prompt() {
    local guidance=""
    local has_repo_context=0

    if [[ -n "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" || -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" || -n "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS" || -n "$EVOP_PROJECT_CONTEXT_STRUCTURE" || -n "$EVOP_PROJECT_CONTEXT_CONVENTIONS" || -n "$EVOP_PROJECT_CONTEXT_RISK_AREAS" || -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" || -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]] || evop_project_has_any_command; then
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
        if [[ -n "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES" ]]; then
            guidance+="Workspace packages:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES")"
            guidance+=$'\n'
        fi
        if [[ -n "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS" ]]; then
            guidance+="Agent command surfaces:\n"
            guidance+="$(evop_format_prefixed_lines "- " "$EVOP_PROJECT_CONTEXT_AGENT_TOOLS")"
            guidance+=$'\n'
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
