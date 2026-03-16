#!/usr/bin/env bash

evop_detect_task_workflow() {
    local prompt="${1:-}"

    if evop_text_contains_any "$prompt" "review" "code review" "审查" "评审"; then
        EVOP_PROJECT_CONTEXT_TASK_KIND="review"
        EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Inspect the touched paths first, prioritize bugs, regressions, and missing tests, and keep summaries secondary."
        return 0
    fi

    if evop_text_contains_any "$prompt" "bug" "fix" "error" "failing" "regression" "修复" "报错"; then
        EVOP_PROJECT_CONTEXT_TASK_KIND="bugfix"
        EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Reproduce or localize the failure path first, apply the smallest coherent fix, and add targeted verification."
        return 0
    fi

    if evop_text_contains_any "$prompt" "refactor" "cleanup" "clean up" "restructure" "重构"; then
        EVOP_PROJECT_CONTEXT_TASK_KIND="refactor"
        EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Preserve behavior, move one boundary at a time, and compare against existing call sites before broad cleanup."
        return 0
    fi

    if evop_text_contains_any "$prompt" "performance" "optimize" "latency" "slow" "性能" "优化"; then
        EVOP_PROJECT_CONTEXT_TASK_KIND="performance"
        EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Measure or localize the hotspot first, optimize the smallest hot path, and re-verify correctness after the change."
        return 0
    fi

    EVOP_PROJECT_CONTEXT_TASK_KIND="feature"
    EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Find the nearest existing implementation first, extend types, data flow, and tests together, and avoid inventing a parallel pattern."
}

evop_detect_language_workflow() {
    local language_profile="$1"

    case "$language_profile" in
        python)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect package entrypoints, service modules, schemas, and tests before editing."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep framework glue thin and move changed behavior into importable, testable modules."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer static checks and targeted pytest coverage before broader integration validation."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Watch import-time side effects, environment-dependent behavior, and untyped data crossing module boundaries."
            ;;
        typescript|javascript)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect components, state modules, API adapters, and affected tests before editing."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Update public types, runtime guards, and UI or service behavior together to avoid drift."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Run lint, type checks when available, focused tests, and then the relevant build path."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Browser/server boundaries, shared types, and stale state transitions can create wide regressions."
            ;;
        rust)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect crate boundaries, public APIs, and the nearest tests or benches before editing."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Prefer explicit ownership and small changes over broad trait or lifetime rewrites."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Use check, clippy, and targeted tests before relying on a full build alone."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Public crate interfaces, async boundaries, and shared structs can cascade across the codebase."
            ;;
        go)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect package boundaries, handlers, and interface consumers before editing."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Prefer small packages, explicit errors, and simple concurrency over abstraction-heavy rewrites."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Use focused package tests first, then broader go test or vet style checks."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Interface drift, nil handling, and goroutine lifecycles can cause subtle regressions."
            ;;
    esac
}

evop_detect_project_type_workflow() {
    local project_type="$1"

    case "$project_type" in
        web-app)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect user-facing routes, components, client state, and API integration paths first."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Change user flows end-to-end: types, data loading, loading or error states, and UI tests together."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prioritize user-flow regression checks and confirm the production build still works."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Routing, auth, caching, and shared frontend contracts deserve extra scrutiny."
            ;;
        backend-service)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect request handlers, schemas, service logic, persistence, and contract tests first."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve API contracts, validation behavior, and error semantics while changing internals."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prioritize contract tests, integration tests, and schema or migration safety checks."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "API compatibility, idempotency, persistence changes, and background jobs are high-risk."
            ;;
        cli-tool)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect command parsing, config loading, and command-specific tests before editing."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Keep stdout, stderr, exit codes, and help text behavior consistent with existing commands."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer command-level regression tests plus manual checks for representative invocations."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Flag parsing changes, shell-facing output, and backward compatibility are the main risks."
            ;;
        library)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect exported interfaces, examples, and compatibility-sensitive tests first."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Minimize churn in public APIs and update docs or examples alongside behavior changes."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prioritize API-level tests, examples, and compatibility checks before release-oriented builds."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Public interfaces, semantic versioning expectations, and cross-package consumers deserve extra care."
            ;;
        data-pipeline)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect input parsing, transforms, output sinks, and retry or scheduling paths first."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve data contracts, checkpoint semantics, and rerun safety while changing logic."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer fixture-based data regression tests and rerun or idempotency validation."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Schema drift, partial writes, duplicate processing, and observability gaps are high-risk."
            ;;
        single-player-game|online-game|mobile-game|browser-game)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect the gameplay loop, state transitions, scene or system wiring, and input handling first."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Change one gameplay boundary at a time and keep assets, state, and player feedback in sync."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer play-loop validation, state transition checks, and performance-sensitive smoke tests."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "State desync, input regressions, save data, and resource loading are the primary risks."
            ;;
    esac
}

evop_detect_task_kind_workflow() {
    case "$EVOP_PROJECT_CONTEXT_TASK_KIND" in
        review)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect the changed paths and surrounding callers before forming conclusions."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Do not optimize for rewrites; prioritize concrete defects, regressions, and missing tests."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Anchor findings to existing behavior, affected tests, and contract surfaces."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Focus on correctness, regressions, and unverified assumptions instead of style."
            ;;
        bugfix)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Trace the failing path or closest reproduction before changing unrelated code."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Apply the smallest coherent fix and keep unrelated cleanup out of scope."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Re-run the closest failing checks first, then the normal verification chain."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Regression risk is highest around call sites that depended on the old failure mode."
            ;;
        refactor)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Map callers, shared interfaces, and tests before moving boundaries."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve behavior, migrate one seam at a time, and compare before and after call paths."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer equivalence-focused tests and broad type or compile checks after each move."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Behavioral drift and missed edge-case coverage are the main refactor risks."
            ;;
        performance)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Localize the hotspot, expensive render path, or slow query before editing."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Optimize the narrowest hot path first and avoid speculative architectural changes."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Verify both correctness and the targeted latency or throughput path after changes."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Caching mistakes, stale data, and concurrency regressions often hide behind performance work."
            ;;
        feature|*)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Find the nearest existing implementation and mirror its structure before adding new code."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Extend types, behavior, and tests together instead of introducing a parallel pattern."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Confirm the new path works end-to-end and that adjacent flows still behave correctly."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Partial integration is the main risk: types, storage, APIs, and UI can drift if changed separately."
            ;;
    esac
}

evop_finalize_workflow_strategy() {
    if [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Start with these repository paths: $EVOP_PROJECT_CONTEXT_SEARCH_ROOTS"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_LINT_COMMAND" || -n "$EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND" || -n "$EVOP_PROJECT_CONTEXT_TEST_COMMAND" || -n "$EVOP_PROJECT_CONTEXT_BUILD_COMMAND" ]]; then
        local verification_summary="Use the repository verification chain in this order:"
        [[ -n "$EVOP_PROJECT_CONTEXT_LINT_COMMAND" ]] && verification_summary+=" lint"
        [[ -n "$EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND" ]] && verification_summary+=" -> typecheck"
        [[ -n "$EVOP_PROJECT_CONTEXT_TEST_COMMAND" ]] && verification_summary+=" -> test"
        [[ -n "$EVOP_PROJECT_CONTEXT_BUILD_COMMAND" ]] && verification_summary+=" -> build"
        evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "$verification_summary"
    fi
}

evop_analyze_project_context() {
    local target_dir="$1"
    local prompt="${2:-}"
    local language_profile="${3:-}"
    local framework_profile="${4:-}"
    local project_type="${5:-}"

    evop_reset_project_context
    EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER="$(evop_choose_package_manager "$target_dir" "$language_profile" || true)"
    EVOP_PROJECT_CONTEXT_WORKSPACE_MODE="$(evop_detect_workspace_mode "$target_dir")"

    evop_detect_command_hints "$target_dir" "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" "$language_profile"
    evop_detect_structure_hints "$target_dir"
    evop_detect_conventions "$target_dir" "$language_profile"
    evop_detect_risk_areas "$target_dir"
    evop_detect_validation_hints
    evop_detect_task_workflow "$prompt"

    if [[ -z "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]]; then
        if [[ -d "$target_dir/src" ]]; then
            EVOP_PROJECT_CONTEXT_SEARCH_ROOTS="src"
        elif [[ -n "$framework_profile" || -n "$project_type" ]]; then
            EVOP_PROJECT_CONTEXT_SEARCH_ROOTS="."
        fi
    fi

    evop_detect_language_workflow "$language_profile"
    evop_detect_project_type_workflow "$project_type"
    evop_detect_task_kind_workflow
    evop_finalize_workflow_strategy
}
