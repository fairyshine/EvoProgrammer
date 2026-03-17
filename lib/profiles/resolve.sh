#!/usr/bin/env bash

# shellcheck disable=SC2034

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
    local started_ms=0
    local total_started_ms=0

    EVOP_RESOLVED_LANGUAGE_PROFILE="$requested_language_profile"
    EVOP_RESOLVED_LANGUAGE_SOURCE="none"
    EVOP_RESOLVED_FRAMEWORK_PROFILE="$requested_framework_profile"
    EVOP_RESOLVED_FRAMEWORK_SOURCE="none"
    EVOP_RESOLVED_PROJECT_TYPE="$requested_project_type"
    EVOP_RESOLVED_PROJECT_SOURCE="none"
    evop_reset_profile_diagnostics
    EVOP_PROJECT_CONTEXT_TIMING_LANGUAGE_DETECT_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_FRAMEWORK_DETECT_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_PROJECT_TYPE_DETECT_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_RESOLVE_PROFILES_MS=0

    total_started_ms="$(evop_now_millis)"

    if [[ -n "$requested_language_profile" ]]; then
        EVOP_RESOLVED_LANGUAGE_SOURCE="explicit"
    else
        started_ms="$(evop_now_millis)"
        if evop_detect_language_profile "$target_dir" "$prompt"; then
            EVOP_RESOLVED_LANGUAGE_PROFILE="$EVOP_DETECTED_PROFILE"
            EVOP_RESOLVED_LANGUAGE_SOURCE="auto"
        else
            EVOP_RESOLVED_LANGUAGE_PROFILE=""
        fi
        EVOP_PROJECT_CONTEXT_TIMING_LANGUAGE_DETECT_MS="$(evop_elapsed_millis_since "$started_ms")"
    fi

    if [[ -n "$requested_framework_profile" ]]; then
        EVOP_RESOLVED_FRAMEWORK_SOURCE="explicit"
    else
        started_ms="$(evop_now_millis)"
        if evop_detect_framework_profile "$target_dir" "$prompt"; then
            EVOP_RESOLVED_FRAMEWORK_PROFILE="$EVOP_DETECTED_PROFILE"
            EVOP_RESOLVED_FRAMEWORK_SOURCE="auto"
        else
            EVOP_RESOLVED_FRAMEWORK_PROFILE=""
        fi
        EVOP_PROJECT_CONTEXT_TIMING_FRAMEWORK_DETECT_MS="$(evop_elapsed_millis_since "$started_ms")"
    fi

    if [[ -n "$requested_project_type" ]]; then
        EVOP_RESOLVED_PROJECT_SOURCE="explicit"
    else
        started_ms="$(evop_now_millis)"
        if evop_detect_project_type "$target_dir" "$prompt"; then
            EVOP_RESOLVED_PROJECT_TYPE="$EVOP_DETECTED_PROFILE"
            EVOP_RESOLVED_PROJECT_SOURCE="auto"
        else
            EVOP_RESOLVED_PROJECT_TYPE=""
        fi
        EVOP_PROJECT_CONTEXT_TIMING_PROJECT_TYPE_DETECT_MS="$(evop_elapsed_millis_since "$started_ms")"
    fi

    started_ms="$(evop_now_millis)"
    evop_analyze_project_context "$target_dir" "$prompt" "$EVOP_RESOLVED_LANGUAGE_PROFILE" "$EVOP_RESOLVED_FRAMEWORK_PROFILE" "$EVOP_RESOLVED_PROJECT_TYPE"
    EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS="$(evop_elapsed_millis_since "$started_ms")"

    EVOP_PROJECT_CONTEXT_TIMING_RESOLVE_PROFILES_MS="$(evop_elapsed_millis_since "$total_started_ms")"
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
    evop_print_project_context "$output_style"
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

    guidance+="$(evop_render_project_context_prompt)"

    if [[ -z "$guidance" ]]; then
        printf '%s' "$prompt"
        return 0
    fi

    printf '%b' "${guidance}[User Request]\n${prompt}"
}
