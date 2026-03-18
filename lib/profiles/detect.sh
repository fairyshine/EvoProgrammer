#!/usr/bin/env zsh

if [[ -z "${PROFILE_DETECT_DIR:-}" ]]; then
    if [[ -n "${PROFILE_LIB_DIR:-}" ]]; then
        PROFILE_DETECT_DIR="$PROFILE_LIB_DIR"
    else
        PROFILE_DETECT_DIR="$(evop_callsite_dir)"
    fi
fi

source "$PROFILE_DETECT_DIR/detect-helpers.sh"

EVOP_DETECTED_PROFILE=""

evop_detect_language_profile() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_prepare_prompt_facts "$prompt"
    if [[ -n "${EVOP_PROMPT_FACTS_TARGET_LANGUAGE:-}" ]]; then
        EVOP_DETECTED_PROFILE="$EVOP_PROMPT_FACTS_TARGET_LANGUAGE"
        return 0
    fi

    evop_detect_profile_via_hooks "languages" "$target_dir" "$prompt"
}

evop_detect_framework_profile() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_prepare_prompt_facts "$prompt"
    if [[ -n "${EVOP_PROMPT_FACTS_TARGET_FRAMEWORK:-}" ]]; then
        EVOP_DETECTED_PROFILE="$EVOP_PROMPT_FACTS_TARGET_FRAMEWORK"
        return 0
    fi

    evop_detect_profile_via_hooks "frameworks" "$target_dir" "$prompt"
}

evop_detect_project_type() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_prepare_prompt_facts "$prompt"
    if [[ -n "${EVOP_PROMPT_FACTS_TARGET_PROJECT_TYPE:-}" ]]; then
        EVOP_DETECTED_PROFILE="$EVOP_PROMPT_FACTS_TARGET_PROJECT_TYPE"
        return 0
    fi

    evop_detect_profile_via_hooks "project-types" "$target_dir" "$prompt"
}
