#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer explicit modules, pipeline-friendly composition, and data transformations that stay easy to test.\n- Keep domain modeling precise with discriminated unions, records, and narrow side-effect boundaries.\n- Preserve project references, script entrypoints, and build targets while changing behavior.\n- Favor straightforward `dotnet` workflows and predictable local run instructions.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 100 "$target_dir" "*.fsproj" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.fs" "*.fsi" "*.fsx" && return 0
    evop_profile_match_prompt 40 "$prompt" "f#" "fsharp" && return 0
    return 1
}
