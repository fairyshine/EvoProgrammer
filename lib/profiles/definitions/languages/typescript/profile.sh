#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Use clear TypeScript configuration and keep strict typing where practical.\n- Prefer maintainable module boundaries, explicit public types, and consistent package scripts.\n- Make browser/server distinctions explicit and avoid implicit any-like behavior.\n- Update type checks and tests alongside changed interfaces so contracts stay trustworthy.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && evop_directory_has_file_named "$target_dir" "tsconfig.json"; then
        EVOP_PROFILE_DETECT_SCORE=100
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "tsconfig.json"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi

    evop_profile_match_file_pattern 80 "$target_dir" "*.ts" "*.tsx" && return 0
    evop_profile_match_prompt 40 "$prompt" "typescript" && return 0
    return 1
}
