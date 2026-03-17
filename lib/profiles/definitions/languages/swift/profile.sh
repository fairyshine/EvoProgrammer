#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer idiomatic Swift structure with explicit package or app targets.\n- Keep Apple-platform assumptions clear and document toolchain requirements.\n- Separate UI, state, and domain logic so the codebase stays testable.\n- Favor maintainable project organization over ad hoc file growth.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "Package.swift" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.swift" && return 0
    evop_profile_match_prompt 40 "$prompt" "swift" && return 0
    return 1
}
