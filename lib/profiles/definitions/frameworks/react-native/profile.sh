#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep JavaScript or TypeScript screens, shared state, and native platform glue clearly separated.\n- Preserve navigation, bridge assumptions, Metro configuration, and device-specific behavior across Android and iOS targets.\n- Prefer established React Native patterns for app startup, screen composition, and native module integration before inventing a parallel layer.\n- Treat permissions, deep links, push notifications, and native build wiring as first-class constraints.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect App.tsx or App.js, metro.config.*, react-native.config.*, navigation setup, and any ios/ or android/ native glue before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep screen logic, shared state, and native integration aligned so JavaScript and platform behavior do not drift."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer react-native start or package scripts, targeted Jest coverage, and representative simulator or device smoke checks."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Bridge boundaries, Metro config, permissions, native dependency wiring, and navigation regressions are the main React Native risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_repo_has_node_package "$target_dir" "expo" "expo-router"; then
        return 1
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && evop_repo_has_node_package "$target_dir" "react-native"; then
        EVOP_PROFILE_DETECT_SCORE=96
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" \
        "metro.config.js" \
        "metro.config.cjs" \
        "metro.config.mjs" \
        "metro.config.ts" \
        "react-native.config.js" \
        "react-native.config.cjs" \
        "react-native.config.mjs" \
        "react-native.config.ts"; then
        EVOP_PROFILE_DETECT_SCORE=92
        return 0
    fi

    evop_profile_match_prompt 43 "$prompt" "react native" "react-native" && return 0
    return 1
}
