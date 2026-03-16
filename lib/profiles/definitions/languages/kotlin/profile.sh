#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Prefer Gradle-based structure with clear source sets and explicit toolchain requirements.\n- Keep the code idiomatic, null-safe, and organized around cohesive modules.\n- Separate platform-specific integration from reusable domain logic.\n- Make testing and developer workflows easy to run locally.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_directory_has_file_pattern "$target_dir" "*.kt" "*.kts"; then
        EVOP_PROFILE_DETECT_SCORE=100
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "build.gradle" || evop_directory_has_file_named "$target_dir" "build.gradle.kts"; then
        if evop_text_contains_any "$prompt" "kotlin"; then
            EVOP_PROFILE_DETECT_SCORE=90
            return 0
        fi
    fi

    evop_profile_match_prompt 40 "$prompt" "kotlin" && return 0
    return 1
}
