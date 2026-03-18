#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep widget boundaries intentional, navigation and state flow explicit, and platform integration isolated from product logic.\n- Preserve fast iteration, responsive rendering, and predictable asset or dependency wiring across Android and iOS targets.\n- Prefer small widget trees, testable state objects, and clear async/error states when changing user-visible flows.\n- Treat platform-specific packaging, permissions, and lifecycle hooks as first-class constraints.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect lib/, test/, integration_test/, and any android/ or ios/ platform glue before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep widget updates, state changes, and platform-specific adapters aligned so UI and device behavior do not drift."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer flutter analyze, targeted widget tests, and representative simulator smoke checks for changed flows."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Navigation regressions, async state races, platform permissions, and build target drift are the primary Flutter risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_profile_match_directory_text 100 "$target_dir" "flutter:" "pubspec.yaml"; then
        return 0
    fi

    if evop_profile_match_directory_text 100 "$target_dir" "sdk: flutter" "pubspec.yaml"; then
        return 0
    fi

    if evop_directory_has_path_named "$target_dir" "android" \
        && evop_directory_has_path_named "$target_dir" "ios" \
        && evop_directory_has_file_named "$target_dir" "pubspec.yaml"; then
        EVOP_PROFILE_DETECT_SCORE=96
        return 0
    fi

    evop_profile_match_prompt 44 "$prompt" "flutter" && return 0
    return 1
}
