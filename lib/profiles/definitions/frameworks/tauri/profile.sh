#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep the Rust backend and frontend boundary explicit and security-conscious.\n- Favor small, auditable command surfaces and reproducible packaging.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_path_named 100 "$target_dir" "src-tauri" && return 0
    evop_profile_match_file_named 95 "$target_dir" "tauri.conf.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "tauri" && return 0
    return 1
}
