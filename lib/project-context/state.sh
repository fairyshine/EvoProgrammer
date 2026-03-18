#!/usr/bin/env zsh

EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER=""
EVOP_PROJECT_CONTEXT_WORKSPACE_MODE=""
EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES=""
EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG=""
EVOP_PROJECT_CONTEXT_AGENT_TOOLS=""
EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG=""
EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS=""
EVOP_PROJECT_CONTEXT_DEV_COMMAND=""
EVOP_PROJECT_CONTEXT_DEV_COMMAND_SOURCE="none"
EVOP_PROJECT_CONTEXT_BUILD_COMMAND=""
EVOP_PROJECT_CONTEXT_BUILD_COMMAND_SOURCE="none"
EVOP_PROJECT_CONTEXT_TEST_COMMAND=""
EVOP_PROJECT_CONTEXT_TEST_COMMAND_SOURCE="none"
EVOP_PROJECT_CONTEXT_LINT_COMMAND=""
EVOP_PROJECT_CONTEXT_LINT_COMMAND_SOURCE="none"
EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND=""
EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND_SOURCE="none"
EVOP_PROJECT_CONTEXT_SEARCH_ROOTS=""
EVOP_PROJECT_CONTEXT_STRUCTURE=""
EVOP_PROJECT_CONTEXT_CONVENTIONS=""
EVOP_PROJECT_CONTEXT_RISK_AREAS=""
EVOP_PROJECT_CONTEXT_AUTOMATION=""
EVOP_PROJECT_CONTEXT_VALIDATION=""
EVOP_PROJECT_CONTEXT_TASK_KIND=""
EVOP_PROJECT_CONTEXT_TASK_WORKFLOW=""
EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY=""
EVOP_PROJECT_CONTEXT_EDIT_STRATEGY=""
EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY=""
EVOP_PROJECT_CONTEXT_RISK_FOCUS=""

evop_reset_project_context() {
    EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER=""
    EVOP_PROJECT_CONTEXT_WORKSPACE_MODE=""
    EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGES=""
    EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG=""
    EVOP_PROJECT_CONTEXT_AGENT_TOOLS=""
    EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG=""
    EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS=""
    EVOP_PROJECT_CONTEXT_DEV_COMMAND=""
    EVOP_PROJECT_CONTEXT_DEV_COMMAND_SOURCE="none"
    EVOP_PROJECT_CONTEXT_BUILD_COMMAND=""
    EVOP_PROJECT_CONTEXT_BUILD_COMMAND_SOURCE="none"
    EVOP_PROJECT_CONTEXT_TEST_COMMAND=""
    EVOP_PROJECT_CONTEXT_TEST_COMMAND_SOURCE="none"
    EVOP_PROJECT_CONTEXT_LINT_COMMAND=""
    EVOP_PROJECT_CONTEXT_LINT_COMMAND_SOURCE="none"
    EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND=""
    EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND_SOURCE="none"
    EVOP_PROJECT_CONTEXT_SEARCH_ROOTS=""
    EVOP_PROJECT_CONTEXT_STRUCTURE=""
    EVOP_PROJECT_CONTEXT_CONVENTIONS=""
    EVOP_PROJECT_CONTEXT_RISK_AREAS=""
    EVOP_PROJECT_CONTEXT_AUTOMATION=""
    EVOP_PROJECT_CONTEXT_VALIDATION=""
    EVOP_PROJECT_CONTEXT_TASK_KIND=""
    EVOP_PROJECT_CONTEXT_TASK_WORKFLOW=""
    EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY=""
    EVOP_PROJECT_CONTEXT_EDIT_STRATEGY=""
    EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY=""
    EVOP_PROJECT_CONTEXT_RISK_FOCUS=""
}

evop_append_multiline() {
    local var_name="$1"
    local line="$2"
    local current="${(P)var_name}"
    if [[ -n "$current" ]]; then
        printf -v "$var_name" '%s\n%s' "$current" "$line"
    else
        printf -v "$var_name" '%s' "$line"
    fi
}

evop_append_csv_unique() {
    local var_name="$1"
    local value="$2"
    local current="${(P)var_name}"

    if [[ -z "$value" ]]; then
        return 0
    fi

    case ",$current," in
        *,"$value",*)
            return 0
            ;;
    esac

    if [[ -n "$current" ]]; then
        printf -v "$var_name" '%s, %s' "$current" "$value"
    else
        printf -v "$var_name" '%s' "$value"
    fi
}

evop_set_command_if_empty() {
    local var_name="$1"
    local value="$2"
    local current="${(P)var_name}"

    [[ -n "$value" ]] || return 0
    if [[ -z "$current" ]]; then
        printf -v "$var_name" '%s' "$value"
    fi
}

evop_get_project_command() {
    local slot="$1"
    local var_name=""

    var_name="$(evop_project_command_value_var "$slot")" || return 1
    printf '%s' "${(P)var_name}"
}

evop_get_project_command_source() {
    local slot="$1"
    local var_name=""

    var_name="$(evop_project_command_source_var "$slot")" || return 1
    printf '%s' "${(P)var_name}"
}

evop_set_project_command_if_empty() {
    local slot="$1"
    local value="$2"
    local source="${3:-detected}"
    local value_var=""
    local source_var=""
    local current=""

    [[ -n "$value" ]] || return 0

    value_var="$(evop_project_command_value_var "$slot")" || return 1
    source_var="$(evop_project_command_source_var "$slot")" || return 1
    current="${(P)value_var}"

    if [[ -z "$current" ]]; then
        printf -v "$value_var" '%s' "$value"
        printf -v "$source_var" '%s' "$source"
    fi
}

evop_project_has_any_command() {
    local slot=""
    local value=""

    while IFS= read -r slot; do
        value="$(evop_get_project_command "$slot")"
        if [[ -n "$value" ]]; then
            return 0
        fi
    done < <(evop_project_command_slots)

    return 1
}
