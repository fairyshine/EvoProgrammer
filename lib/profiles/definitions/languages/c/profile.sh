#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep build flags, headers, and platform assumptions explicit.\n- Prefer small translation units, testable functions, and careful ownership of buffers and lifetimes.\n- Preserve ABI-sensitive interfaces and validate compiler warnings before broadening changes.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect public headers, build configuration, and the narrowest affected C modules before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep interfaces small, preserve existing compiler assumptions, and change memory ownership deliberately."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer compile validation, focused target tests, and warning-free builds before broader integration checks."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Buffer lifetimes, ownership rules, undefined behavior, and platform-specific compiler flags are the main C risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_directory_has_file_extension "$target_dir" "c" \
        && ! evop_directory_has_file_extension "$target_dir" "cpp" "cc" "cxx"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi

    evop_profile_match_prompt 35 "$prompt" "language c" "ansi c" "embedded c" && return 0
    return 1
}
