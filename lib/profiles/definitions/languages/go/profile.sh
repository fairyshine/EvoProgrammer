#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Follow standard Go project layout and module conventions.\n- Keep packages small, explicit, and easy to test with `go test`.\n- Prefer simple concurrency patterns and clear error handling.\n- Minimize unnecessary abstraction and keep tooling reproducible.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "go.mod" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.go" && return 0
    evop_profile_match_prompt 40 "$prompt" "golang" " go " && return 0
    return 1
}
