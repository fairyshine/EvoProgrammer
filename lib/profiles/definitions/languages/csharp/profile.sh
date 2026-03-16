#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Prefer maintainable solution/project structure and explicit SDK targeting.\n- Keep domain logic testable and separate from UI or engine-specific glue.\n- Use consistent naming, project references, and build commands.\n- Favor predictable tooling and clear local run instructions.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 100 "$target_dir" "*.sln" "*.csproj" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.cs" && return 0
    evop_profile_match_prompt 40 "$prompt" "c#" "dotnet" && return 0
    return 1
}
