#!/usr/bin/env zsh

EVOP_PROMPT_FACTS_PROMPT=""
EVOP_PROMPT_FACTS_TARGET_LANGUAGE=""
EVOP_PROMPT_FACTS_TARGET_FRAMEWORK=""
EVOP_PROMPT_FACTS_TARGET_PROJECT_TYPE=""
EVOP_PROMPT_FACTS_WORKSPACE_MODE=""
EVOP_PROMPT_FACTS_TASK_KIND=""

evop_reset_prompt_facts() {
    EVOP_PROMPT_FACTS_PROMPT=""
    EVOP_PROMPT_FACTS_TARGET_LANGUAGE=""
    EVOP_PROMPT_FACTS_TARGET_FRAMEWORK=""
    EVOP_PROMPT_FACTS_TARGET_PROJECT_TYPE=""
    EVOP_PROMPT_FACTS_WORKSPACE_MODE=""
    EVOP_PROMPT_FACTS_TASK_KIND=""
}

evop_prompt_fact_supported_profile() {
    local category_dir="$1"
    local value="${2:-}"

    value="$(evop_trim_whitespace "$value")"
    value="${(L)value}"
    [[ -n "$value" ]] || return 1

    if evop_profile_is_supported "$category_dir" "$value"; then
        printf '%s' "$value"
        return 0
    fi

    return 1
}

evop_prompt_fact_task_kind() {
    local value="${1:-}"

    value="$(evop_trim_whitespace "$value")"
    value="${(L)value}"

    case "$value" in
        review|bugfix|refactor|performance|feature)
            printf '%s' "$value"
            return 0
            ;;
    esac

    return 1
}

evop_prepare_prompt_facts() {
    local prompt="${1:-}"
    local line=""
    local key=""
    local value=""

    if [[ "$EVOP_PROMPT_FACTS_PROMPT" == "$prompt" ]]; then
        return 0
    fi

    evop_reset_prompt_facts
    EVOP_PROMPT_FACTS_PROMPT="$prompt"
    [[ -n "$prompt" ]] || return 0

    while IFS= read -r line; do
        [[ "$line" == *:* ]] || continue
        key="$(evop_trim_whitespace "${line%%:*}")"
        key="${(L)key}"
        value="$(evop_trim_whitespace "${line#*:}")"

        case "$key" in
            "target language")
                EVOP_PROMPT_FACTS_TARGET_LANGUAGE="$(evop_prompt_fact_supported_profile "languages" "$value" || true)"
                ;;
            "target framework")
                EVOP_PROMPT_FACTS_TARGET_FRAMEWORK="$(evop_prompt_fact_supported_profile "frameworks" "$value" || true)"
                ;;
            "target project type")
                EVOP_PROMPT_FACTS_TARGET_PROJECT_TYPE="$(evop_prompt_fact_supported_profile "project-types" "$value" || true)"
                ;;
            "workspace mode")
                EVOP_PROMPT_FACTS_WORKSPACE_MODE="$(evop_trim_whitespace "$value")"
                ;;
            "task kind")
                EVOP_PROMPT_FACTS_TASK_KIND="$(evop_prompt_fact_task_kind "$value" || true)"
                ;;
        esac
    done <<<"$prompt"
}
