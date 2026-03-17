#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for host integration boundaries, version compatibility, and packaging clarity.\n- Keep plugin code isolated from host-specific glue as much as possible.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_prompt 40 "$prompt" "plugin" "extension" "addon" "add-on" && return 0
    return 1
}
