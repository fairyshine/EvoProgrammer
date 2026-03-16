#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep component boundaries intentional, state flow unidirectional, and rendering paths easy to reason about.\n- Separate presentational UI, hooks, and side effects so interaction logic stays testable.\n- Reuse existing component and design-system patterns before introducing new abstractions.\n- Make loading, error, and empty states explicit when changing user-facing flows.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_directory_text 100 "$target_dir" "\"react\"" "package.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "react" && return 0
    return 1
}
