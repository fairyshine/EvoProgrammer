#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer explicit project structure, predictable `dotnet` workflows, and changes that keep forms, modules, and business logic easy to follow.\n- Keep shared logic separate from UI or integration glue when evolving existing Visual Basic projects.\n- Preserve project references, configuration, and startup behavior while changing features.\n- Favor readable control flow and straightforward local run instructions.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 100 "$target_dir" "*.vbproj" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.vb" && return 0
    evop_profile_match_prompt 40 "$prompt" "visual basic" "vb.net" "vbnet" && return 0
    return 1
}
