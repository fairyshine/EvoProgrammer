#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep pages, server routes, composables, and runtime config aligned with Nuxt conventions.\n- Make SSR, client hydration, and data-fetching boundaries explicit so caching and deployment behavior remain predictable.\n- Reuse the established module and auto-import patterns before introducing parallel abstractions.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "nuxt.config.js" "nuxt.config.mjs" "nuxt.config.ts" && return 0
    if evop_repo_has_node_package "$target_dir" "nuxt"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi
    evop_profile_match_prompt 40 "$prompt" "nuxt" "nuxt.js" && return 0
    return 1
}
