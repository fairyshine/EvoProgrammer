#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer package-aware Dart structure with `lib/`, `test/`, and explicit `pubspec.yaml` dependencies.\n- Keep widgets, services, and platform adapters separated so logic stays importable and testable.\n- Favor null-safe APIs, predictable async flows, and reproducible `dart`/`flutter` tooling commands.\n- Use focused unit, widget, or integration tests around changed behavior instead of hiding logic in entrypoints.'

evop_profile_apply_project_context() {
    local target_dir="$1"

    evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect package layout, app entrypoints, platform adapters, and the nearest tests before editing."
    evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep business logic outside UI or bootstrap files so changed behavior remains easy to test."
    evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Run analyzer checks first, then prefer targeted `dart test` or `flutter test` coverage around the changed flow."
    evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Async state, platform-channel boundaries, generated code, and null-safety regressions are the main risks."

    if [[ -d "$target_dir/test" || -d "$target_dir/integration_test" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Existing Dart or Flutter tests are present; extend the nearest coverage before broadening end-to-end checks."
    fi
}

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "pubspec.yaml" && return 0
    evop_profile_match_file_pattern 82 "$target_dir" "*.dart" && return 0
    evop_profile_match_prompt 45 "$prompt" "dart" "flutter" && return 0
    return 1
}
