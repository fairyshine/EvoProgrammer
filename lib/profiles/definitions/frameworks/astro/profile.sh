#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep content collections, islands, routes, and deployment adapters aligned with Astro conventions.\n- Be explicit about server-rendered versus client-hydrated boundaries so performance and bundle size stay predictable.\n- Prefer static-first structure and simple content pipelines unless the repo already depends on heavier runtime behavior.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "astro.config.js" "astro.config.mjs" "astro.config.ts" && return 0
    if evop_repo_has_node_package "$target_dir" "astro" "@astrojs/node" "@astrojs/vercel"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi
    evop_profile_match_prompt 40 "$prompt" "astro" && return 0
    return 1
}
