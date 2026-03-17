#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Use idiomatic Cargo project structure and document crate usage clearly.\n- Favor safe Rust, explicit error handling, and strong type modeling.\n- Keep modules cohesive and write tests that fit Rust workflows.\n- Avoid unnecessary `unsafe` and explain it if it is truly required.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect crate boundaries, public APIs, and the nearest tests or benches before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Prefer explicit ownership and small changes over broad trait or lifetime rewrites."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Use check, clippy, and targeted tests before relying on a full build alone."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Public crate interfaces, async boundaries, and shared structs can cascade across the codebase."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "Cargo.toml" && return 0
    evop_profile_match_file_pattern 80 "$target_dir" "*.rs" && return 0
    evop_profile_match_prompt 40 "$prompt" "rust" && return 0
    return 1
}
