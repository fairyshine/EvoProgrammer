#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer `mix`-driven workflows, explicit supervision boundaries, and small composable modules.\n- Keep process state, message passing, and side effects easy to reason about.\n- Add focused ExUnit coverage around changed behavior and keep configuration assumptions explicit.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect supervision trees, contexts, Mix config, and the nearest ExUnit coverage before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep OTP boundaries explicit, isolate side effects, and preserve message contracts across processes."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer mix compile, focused ExUnit coverage, and formatting checks before broader runtime validation."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Process supervision, mailbox assumptions, configuration drift, and implicit state sharing are the main Elixir risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "mix.exs" && return 0
    evop_profile_match_file_pattern 90 "$target_dir" "*.ex" "*.exs" && return 0
    evop_profile_match_prompt 40 "$prompt" "elixir" "phoenix" "mix" && return 0
    return 1
}
