#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for clear reactive boundaries, predictable state flow, and responsive UI feedback in Shiny apps.\n- Keep data access, transformations, modules, and rendering logic separated so the app remains testable and maintainable.\n- Prefer explicit reactive contracts and narrow UI/server changes over hidden global state.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "shiny" "DESCRIPTION" "app.R" "ui.R" "server.R" && return 0
    evop_profile_match_prompt 40 "$prompt" "shiny" && return 0
    return 1
}
