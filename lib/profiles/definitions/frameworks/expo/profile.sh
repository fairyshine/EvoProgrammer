#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep app routing, screen state, and Expo-managed native capabilities aligned across iOS, Android, and web targets when present.\n- Preserve startup flow, permissions, updates, and native module assumptions instead of hiding them behind ad hoc wrappers.\n- Prefer Expo conventions for app config, navigation, assets, and device APIs before introducing custom native glue.\n- Make simulator, device, and EAS build expectations explicit when they matter to the change.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect app/, App.tsx or App.js, app.json or app.config.*, and any ios/ or android/ native surfaces before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep route flow, shared UI state, and Expo app configuration aligned so device behavior does not drift."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer expo start or package scripts, targeted Jest coverage, and representative simulator or device smoke checks."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Navigation drift, config plugins, permissions, OTA update assumptions, and native module compatibility are the main Expo risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && {
            evop_repo_has_node_package "$target_dir" "expo" "expo-router";
        }; then
        EVOP_PROFILE_DETECT_SCORE=97
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" \
        "app.json" \
        "app.config.js" \
        "app.config.cjs" \
        "app.config.mjs" \
        "app.config.ts" \
        && evop_repo_has_node_package "$target_dir" "expo"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi

    evop_profile_match_prompt 44 "$prompt" "expo" "expo router" && return 0
    return 1
}
