#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep Spring modules, configuration, controllers, services, and persistence layers clearly separated.\n- Avoid magic-heavy configuration when explicit wiring is clearer.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "spring-boot" "pom.xml" "build.gradle" "build.gradle.kts" && return 0
    evop_profile_match_prompt 40 "$prompt" "spring" && return 0
    return 1
}
