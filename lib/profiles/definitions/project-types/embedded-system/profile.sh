#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Optimize for hardware constraints, deterministic behavior, build reproducibility, and testability.\n- Be explicit about platform assumptions, memory limits, and deployment steps.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect board configuration, startup code, peripheral drivers, and flashing entrypoints before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve hardware assumptions, memory layout, and interrupt or timing behavior while changing logic."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer compile-time validation, board-specific smoke checks, and reproducible flash or simulation steps."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Hardware timing, memory pressure, boot sequencing, and board-specific configuration are the main embedded risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_repo_looks_like_embedded_system "$target_dir"; then
        EVOP_PROFILE_DETECT_SCORE=91
        return 0
    fi

    evop_profile_match_prompt 39 "$prompt" "embedded" "firmware" "mcu" "microcontroller" && return 0
    return 1
}
