#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep modules small, table shapes explicit, and side effects localized so Lua code stays easy to reason about.\n- Prefer straightforward control flow, clear data ownership, and lightweight abstractions over clever metatable tricks unless the project already depends on them.\n- Document runtime assumptions when code depends on a host engine, embedded runtime, or Lua version.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect module boundaries, runtime entrypoints, and fixture-style tests before editing Lua code."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve table contracts, module loading assumptions, and host-runtime integration points while changing behavior."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer focused script-level regression checks and representative host-runtime smoke tests."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Implicit globals, metatable side effects, and runtime-version differences are the main Lua risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 100 "$target_dir" "*.lua" && return 0
    evop_profile_match_file_pattern 95 "$target_dir" "*.rockspec" && return 0
    evop_profile_match_prompt 40 "$prompt" "lua" "luajit" && return 0
    return 1
}
