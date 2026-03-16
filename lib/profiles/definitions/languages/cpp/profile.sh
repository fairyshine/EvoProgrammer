#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Prefer a reproducible build setup such as CMake.\n- Be explicit about compiler requirements, include paths, and third-party dependencies.\n- Keep headers and source files organized for maintainability and build speed.\n- Prioritize memory safety, deterministic behavior, and practical testability.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "CMakeLists.txt" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.cpp" "*.cc" "*.cxx" "*.hpp" "*.hh" "*.hxx" && return 0
    evop_profile_match_prompt 40 "$prompt" "c++" "cpp" && return 0
    return 1
}
