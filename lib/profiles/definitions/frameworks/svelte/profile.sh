#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep components small, stores intentional, and data flow explicit.\n- Favor simple reactive patterns and clear build/runtime assumptions.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "svelte.config.js" "svelte.config.cjs" "svelte.config.ts" && return 0
    evop_profile_match_directory_text 95 "$target_dir" "\"svelte\"" "package.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "svelte" && return 0
    return 1
}
