#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Keep runtime and tooling choices explicit and lightweight.\n- Use consistent scripts, module boundaries, and dependency management.\n- Avoid unnecessary build complexity and document local development clearly.\n- Keep browser/server assumptions obvious in the project layout.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_directory_has_file_named "$target_dir" "package.json" && ! evop_directory_has_file_named "$target_dir" "tsconfig.json"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi

    evop_profile_match_file_pattern 80 "$target_dir" "*.js" "*.jsx" "*.mjs" "*.cjs" && return 0
    evop_profile_match_prompt 40 "$prompt" "javascript" "node.js" "nodejs" && return 0
    return 1
}
