#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for navigation clarity, startup responsiveness, offline tolerance, and device-specific constraints.\n- Keep app shell concerns, domain logic, and platform integrations separated so mobile changes stay testable.\n- Account for permissions, lifecycle transitions, packaging, and small-screen ergonomics throughout the change.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect app entrypoints, navigation flow, state containers, and platform-specific adapters before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Change one user flow at a time and keep UI state, persistence, and platform wiring aligned."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer analyzer or compile checks, targeted UI tests, and representative simulator or device smoke tests."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Startup regressions, navigation breakage, permission handling, lifecycle events, and persisted state are the main mobile-app risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_profile_match_directory_text 100 "$target_dir" "flutter:" "pubspec.yaml"; then
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "AndroidManifest.xml" "Info.plist"; then
        EVOP_PROFILE_DETECT_SCORE=96
        return 0
    fi

    if evop_directory_has_path_named "$target_dir" "android" \
        && evop_directory_has_path_named "$target_dir" "ios"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi

    evop_profile_match_prompt 95 "$prompt" "mobile app" "ios app" "android app" "flutter app" "手机应用" "移动应用" && return 0
    return 1
}
