#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep component structure, composables, and state boundaries coherent and idiomatic to Vue.\n- Prefer maintainable single-file component organization over overly dense files.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "vue.config.js" && return 0
    evop_profile_match_directory_text 95 "$target_dir" "\"vue\"" "package.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "vue" && return 0
    return 1
}
