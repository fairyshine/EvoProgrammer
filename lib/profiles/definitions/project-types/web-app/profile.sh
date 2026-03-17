#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for user flows, deployment clarity, frontend/backend boundaries, and maintainable page or route structure.\n- Prefer production-ready structure over a one-off prototype dump.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect user-facing routes, components, client state, and API integration paths first."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Change user flows end-to-end: types, data loading, loading or error states, and UI tests together."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prioritize user-flow regression checks and confirm the production build still works."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Routing, auth, caching, and shared frontend contracts deserve extra scrutiny."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_path_named 60 "$target_dir" "public" "src" && return 0
    evop_profile_match_prompt 60 "$prompt" "web app" "website" "landing page" "dashboard" "frontend" && return 0
    return 1
}
