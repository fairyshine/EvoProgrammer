#!/usr/bin/env bash

EVOP_RESOLVED_LANGUAGE_PROFILE=""
EVOP_RESOLVED_LANGUAGE_SOURCE="none"
EVOP_RESOLVED_FRAMEWORK_PROFILE=""
EVOP_RESOLVED_FRAMEWORK_SOURCE="none"
EVOP_RESOLVED_PROJECT_TYPE=""
EVOP_RESOLVED_PROJECT_SOURCE="none"

evop_resolve_profiles() {
    local target_dir="$1"
    local prompt="${2:-}"
    local requested_language_profile="${3:-}"
    local requested_framework_profile="${4:-}"
    local requested_project_type="${5:-}"

    EVOP_RESOLVED_LANGUAGE_PROFILE="$requested_language_profile"
    EVOP_RESOLVED_LANGUAGE_SOURCE="none"
    EVOP_RESOLVED_FRAMEWORK_PROFILE="$requested_framework_profile"
    EVOP_RESOLVED_FRAMEWORK_SOURCE="none"
    EVOP_RESOLVED_PROJECT_TYPE="$requested_project_type"
    EVOP_RESOLVED_PROJECT_SOURCE="none"

    if [[ -n "$requested_language_profile" ]]; then
        EVOP_RESOLVED_LANGUAGE_SOURCE="explicit"
    elif EVOP_RESOLVED_LANGUAGE_PROFILE="$(evop_detect_language_profile "$target_dir" "$prompt")"; then
        EVOP_RESOLVED_LANGUAGE_SOURCE="auto"
    else
        EVOP_RESOLVED_LANGUAGE_PROFILE=""
    fi

    if [[ -n "$requested_framework_profile" ]]; then
        EVOP_RESOLVED_FRAMEWORK_SOURCE="explicit"
    elif EVOP_RESOLVED_FRAMEWORK_PROFILE="$(evop_detect_framework_profile "$target_dir" "$prompt")"; then
        EVOP_RESOLVED_FRAMEWORK_SOURCE="auto"
    else
        EVOP_RESOLVED_FRAMEWORK_PROFILE=""
    fi

    if [[ -n "$requested_project_type" ]]; then
        EVOP_RESOLVED_PROJECT_SOURCE="explicit"
    elif EVOP_RESOLVED_PROJECT_TYPE="$(evop_detect_project_type "$target_dir" "$prompt")"; then
        EVOP_RESOLVED_PROJECT_SOURCE="auto"
    else
        EVOP_RESOLVED_PROJECT_TYPE=""
    fi
}

evop_apply_resolved_profiles() {
    LANGUAGE_PROFILE="$EVOP_RESOLVED_LANGUAGE_PROFILE"
    LANGUAGE_PROFILE_SOURCE="$EVOP_RESOLVED_LANGUAGE_SOURCE"
    FRAMEWORK_PROFILE="$EVOP_RESOLVED_FRAMEWORK_PROFILE"
    FRAMEWORK_PROFILE_SOURCE="$EVOP_RESOLVED_FRAMEWORK_SOURCE"
    PROJECT_TYPE="$EVOP_RESOLVED_PROJECT_TYPE"
    PROJECT_TYPE_SOURCE="$EVOP_RESOLVED_PROJECT_SOURCE"
}

evop_print_resolved_profile() {
    local label="$1"
    local value="${2:-}"
    local source="${3:-none}"
    local separator=": "

    if [[ -z "$value" ]]; then
        return 0
    fi

    if [[ "$label" == OK\ * ]]; then
        separator=" "
    fi

    printf '%s%s%s' "$label" "$separator" "$value"
    if [[ "$source" == "auto" ]]; then
        printf ' (auto-detected)'
    fi
    printf '\n'
}

evop_print_current_profiles() {
    local output_style="${1:-default}"
    local language_label="Language profile"
    local framework_label="Framework profile"
    local project_label="Project type"

    if [[ "$output_style" == "doctor" ]]; then
        language_label="OK language-profile"
        framework_label="OK framework-profile"
        project_label="OK project-type"
    fi

    evop_print_resolved_profile "$language_label" "$LANGUAGE_PROFILE" "$LANGUAGE_PROFILE_SOURCE"
    evop_print_resolved_profile "$framework_label" "$FRAMEWORK_PROFILE" "$FRAMEWORK_PROFILE_SOURCE"
    evop_print_resolved_profile "$project_label" "$PROJECT_TYPE" "$PROJECT_TYPE_SOURCE"
}

evop_compose_prompt() {
    local prompt="$1"
    local language_profile="${2:-}"
    local framework_profile="${3:-}"
    local project_type="${4:-}"
    local guidance=""

    if [[ -n "$language_profile" ]]; then
        guidance+="[Language Adaptation]\n"
        guidance+="Target language: $language_profile\n"
        guidance+="$(evop_language_guidance "$language_profile")\n\n"
    fi

    if [[ -n "$framework_profile" ]]; then
        guidance+="[Framework Adaptation]\n"
        guidance+="Target framework: $framework_profile\n"
        guidance+="$(evop_framework_guidance "$framework_profile")\n\n"
    fi

    if [[ -n "$project_type" ]]; then
        guidance+="[Project-Type Adaptation]\n"
        guidance+="Target project type: $project_type\n"
        guidance+="$(evop_project_type_guidance "$project_type")\n\n"
    fi

    if [[ -z "$guidance" ]]; then
        printf '%s' "$prompt"
        return 0
    fi

    printf '%b' "${guidance}[User Request]\n${prompt}"
}
