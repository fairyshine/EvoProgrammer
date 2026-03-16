#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Use idiomatic Cargo project structure and document crate usage clearly.\n- Favor safe Rust, explicit error handling, and strong type modeling.\n- Keep modules cohesive and write tests that fit Rust workflows.\n- Avoid unnecessary `unsafe` and explain it if it is truly required.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "Cargo.toml" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.rs" && return 0
    evop_profile_match_prompt 40 "$prompt" "rust" && return 0
    return 1
}
