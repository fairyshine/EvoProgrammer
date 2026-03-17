#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Follow NestJS module/controller/provider boundaries and keep dependency injection manageable.\n- Prefer clear module ownership over sprawling shared utilities.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "\"@nestjs/core\"" "package.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "nestjs" "nest.js" && return 0
    return 1
}
