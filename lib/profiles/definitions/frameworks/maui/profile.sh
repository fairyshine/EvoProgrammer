#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep shared UI, view models, and device-specific platform glue clearly separated.\n- Preserve navigation, async state updates, permissions, and resource packaging across Android, iOS, Windows, and MacCatalyst targets.\n- Prefer reusable app logic over platform-conditional branching inside screens.\n- Treat XAML, handlers, and startup wiring as first-class integration boundaries.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect MauiProgram.cs, shared views or view models, Resources/, and Platforms/ before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep shared UI logic, dependency registration, and platform-specific handlers aligned so device behavior does not drift."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer dotnet build, targeted dotnet test coverage, and representative simulator or device smoke checks for changed flows."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Platform-specific handlers, permissions, lifecycle events, and multi-target resource packaging are the main .NET MAUI risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_repo_looks_like_dotnet_maui "$target_dir"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi

    evop_profile_match_prompt 42 "$prompt" "maui" ".net maui" && return 0
    return 1
}
