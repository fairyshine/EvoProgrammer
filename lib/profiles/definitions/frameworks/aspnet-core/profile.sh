#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Keep HTTP endpoints, middleware, DI wiring, and persistence boundaries explicit.\n- Prefer thin controllers or minimal API handlers, strongly typed contracts, and configuration that is easy to override per environment.\n- Preserve startup, auth, and observability behavior while changing request flows.\n- Keep background services, hosted workers, and infrastructure glue isolated from domain logic.'

evop_profile_apply_project_context() {
    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect Program.cs, appsettings*.json, endpoint handlers, DI registration, and integration tests before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve route contracts, options binding, and middleware ordering while changing ASP.NET Core behavior."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer dotnet build, targeted dotnet test coverage, and representative API smoke checks before broader rollout."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Middleware ordering, auth configuration, DI lifetimes, and environment-specific settings are the main ASP.NET Core risks."
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_repo_looks_like_aspnet_core "$target_dir"; then
        EVOP_PROFILE_DETECT_SCORE=95
        return 0
    fi

    evop_profile_match_prompt 42 "$prompt" "asp.net core" "aspnet core" "aspnet" && return 0
    return 1
}
